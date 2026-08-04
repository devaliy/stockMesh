import 'dart:async';
import 'dart:math';

import '../../data/db/daos/app_state_dao.dart';
import '../../data/db/database.dart';
import '../../domain/inventory_service.dart';
import '../../security/message_auth.dart';
import '../protocol/codec.dart';
import '../protocol/messages.dart';
import '../transport/transport.dart';
import 'outbox.dart';

/// Client connection states (design.md §5). SYNCING covers catch-up +
/// outbox flush; LIVE means broadcasts flow.
enum ClientState { disconnected, discovering, connecting, syncing, live }

/// The client half of the sync engine: connect / authenticate / catch up /
/// flush outbox / stream — then reconnect forever with exponential backoff
/// (1s→2s→4s… cap 30s).
///
/// Transport-agnostic: [connector] yields a fresh [Transport] per attempt
/// (memory pipes in tests, discovery + WebSocket in production).
/// Correctness invariants enforced here:
/// * §1.4 — everything arriving via CATCH_UP/EVENT_BROADCAST goes through
///   [InventoryService.applyRemoteEvents], which is idempotent by event_id.
/// * §1.2 — `last_acked_seq` only advances from Hub-sequenced data; local
///   clocks play no part.
class SyncClient {
  SyncClient({
    required AppDatabase db,
    required InventoryService inventoryService,
    required this.connector,
    required this.deviceId,
    required this.secretHex,
    this.onState,
    this.onRevoked,
    Duration Function(int attempt)? backoff,
    this.pingInterval = const Duration(seconds: 15),
    this.enablePing = true,
  })  : _db = db,
        _inventory = inventoryService,
        _outbox = Outbox(db),
        _backoff = backoff ?? _defaultBackoff;

  final AppDatabase _db;
  final InventoryService _inventory;
  final Outbox _outbox;
  final Future<Transport> Function() connector;
  final String deviceId;
  final String secretHex;
  final void Function(ClientState state)? onState;

  /// Fired when the Hub says REVOKED — the app must wipe and re-onboard
  /// (§6.5); the client stops reconnecting.
  final void Function()? onRevoked;
  final Duration Function(int attempt) _backoff;
  final Duration pingInterval;

  /// Tests with fake clocks disable the periodic ping.
  final bool enablePing;

  ClientState _state = ClientState.disconnected;
  ClientState get state => _state;

  Transport? _transport;
  StreamSubscription<String>? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _attempt = 0;
  int _missedPongs = 0;
  bool _running = false;
  bool _catchUpDone = false;
  bool _flushing = false;
  bool _flushQueued = false;
  StreamSubscription<int>? _outboxWatch;
  Completer<void>? _liveWait;

  static Duration _defaultBackoff(int attempt) =>
      Duration(seconds: min(30, 1 << min(attempt, 5)));

  void start() {
    if (_running) return;
    _running = true;
    _connect();
    // New local writes while LIVE flush immediately.
    _outboxWatch ??= _outbox.watchPendingCount().listen((count) {
      if (count > 0 && _state == ClientState.live) _flushOutbox();
    });
  }

  Future<void> stop() async {
    _running = false;
    _reconnectTimer?.cancel();
    await _outboxWatch?.cancel();
    _outboxWatch = null;
    await _teardown();
    _setState(ClientState.disconnected);
  }

  /// Completes the next time the client reaches LIVE (test convenience).
  Future<void> untilLive() {
    if (_state == ClientState.live) return Future.value();
    _liveWait ??= Completer<void>();
    return _liveWait!.future;
  }

  void _setState(ClientState next) {
    if (_state == next) return;
    _state = next;
    onState?.call(next);
    if (next == ClientState.live) {
      _liveWait?.complete();
      _liveWait = null;
    }
  }

  Future<void> _connect() async {
    if (!_running) return;
    _setState(ClientState.discovering);
    final Transport transport;
    try {
      transport = await connector();
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    if (!_running) {
      await transport.close();
      return;
    }

    _transport = transport;
    _catchUpDone = false;
    _missedPongs = 0;
    _setState(ClientState.connecting);

    _sub = transport.incoming.listen(
      (raw) => _onFrame(raw),
      onDone: _onDisconnected,
      onError: (Object _) => _onDisconnected(),
    );

    await _sendHello();
    _setState(ClientState.syncing);

    if (enablePing) {
      _pingTimer = Timer.periodic(pingInterval, (_) => _pingTick());
    }
  }

  Future<void> _sendHello() async {
    final lastAcked =
        await _db.appStateDao.getInt(StateKeys.lastAckedSeq) ?? 0;
    final refSnapshotAt = await _refSnapshotAt();
    final nonce = MessageAuth.nonce();
    final payload = HelloPayload(
      deviceId: deviceId,
      lastAckedSeq: lastAcked,
      refSnapshotAt: refSnapshotAt,
      challengeResponse: MessageAuth.challengeResponse(
        secretHex: secretHex,
        deviceId: deviceId,
        nonce: nonce,
      ),
    );
    _send(MsgType.hello, payload.toJson(), nonce: nonce);
  }

  Future<int> _refSnapshotAt() async {
    var latest = 0;
    for (final p in await _db.productsDao.getAll()) {
      if (p.updatedAt > latest) latest = p.updatedAt;
    }
    for (final s in await _db.staffDao.getAll()) {
      if (s.updatedAt > latest) latest = s.updatedAt;
    }
    return latest;
  }

  Future<void> _onFrame(String raw) async {
    final frame = Codec.parse(raw);
    if (frame == null) return;

    // HELLO_REJECT arrives before the Hub will sign frames for us — handle
    // it unauthenticated but treat it only as a disconnect hint.
    if (frame.type == MsgType.helloReject) {
      final reason = HelloRejectPayload.fromJson(frame.payload).reason;
      if (reason == RejectReason.revoked) {
        _running = false;
        await _teardown();
        _setState(ClientState.disconnected);
        onRevoked?.call();
        return;
      }
      // BAD_AUTH / VERSION: keep retrying slowly — the registry may be
      // restored from backup or the app updated.
      _onDisconnected();
      return;
    }

    // Everything else must carry a valid MAC under our shared secret.
    if (!Codec.verify(raw, frame, secretHex)) return;

    switch (frame.type) {
      case MsgType.helloAck:
        break; // informational; catch-up chunks follow
      case MsgType.catchUp:
        await _applyCatchUp(CatchUpPayload.fromJson(frame.payload));
      case MsgType.eventAccept:
        await _applyAccept(EventAcceptPayload.fromJson(frame.payload));
      case MsgType.eventReject:
        await _applyReject(EventRejectPayload.fromJson(frame.payload));
      case MsgType.eventBroadcast:
        await _applyBroadcast(
            EventBroadcastPayload.fromJson(frame.payload));
      case MsgType.refUpdate:
        await _applyRefUpdate(RefUpdatePayload.fromJson(frame.payload));
      case MsgType.ping:
        _send(MsgType.pong, const <String, dynamic>{});
      case MsgType.pong:
        _missedPongs = 0;
      default:
        break;
    }
  }

  Future<void> _applyCatchUp(CatchUpPayload payload) async {
    await _applyRef(payload.refProducts, payload.refStaff);
    await _inventory
        .applyRemoteEvents(payload.events.map((e) => e.toRow()).toList());
    await _advanceAck();
    if (payload.done && !_catchUpDone) {
      _catchUpDone = true;
      await _flushOutbox();
      _attempt = 0;
      _setState(ClientState.live);
    }
  }

  Future<void> _applyBroadcast(EventBroadcastPayload payload) async {
    await _inventory
        .applyRemoteEvents(payload.events.map((e) => e.toRow()).toList());
    await _advanceAck();
  }

  Future<void> _applyAccept(EventAcceptPayload payload) async {
    await _inventory.applyConfirmations({
      for (final a in payload.assignments) a.eventId: a.hubSeq,
    });
    await _advanceAck();
  }

  Future<void> _applyReject(EventRejectPayload payload) async {
    // A rejected event will never sequence. Remove it and repair the
    // projection so this replica converges with the Hub's truth.
    for (final rejection in payload.rejections) {
      final event = await _db.eventsDao.getById(rejection.eventId);
      if (event == null || event.hubSeq != null) continue;
      await _db.transaction(() async {
        await _db.projectionDao
            .applyDelta(event.productId, -event.quantityDelta);
        await (_db.delete(_db.stockEvents)
              ..where((e) => e.eventId.equals(rejection.eventId)))
            .go();
      });
    }
  }

  Future<void> _applyRefUpdate(RefUpdatePayload payload) =>
      _applyRef(payload.products, payload.staff);

  Future<void> _applyRef(
      List<WireProduct> products, List<WireStaff> staff) async {
    if (products.isNotEmpty) {
      await _db.productsDao
          .upsertAll(products.map((p) => p.toRow()).toList());
    }
    if (staff.isNotEmpty) {
      await _db.staffDao.upsertAll(staff.map((s) => s.toRow()).toList());
    }
  }

  /// Advances last_acked_seq to the highest CONTIGUOUS hub_seq held
  /// (design.md §5 client apply rule). Never to the max seen: an accept for
  /// seq N can outrun the broadcast of N−1 on the hub side, and acking past
  /// that hole would make the next CATCH_UP skip it forever.
  Future<void> _advanceAck() async {
    final current =
        await _db.appStateDao.getInt(StateKeys.lastAckedSeq) ?? 0;
    var next = current;
    for (final row in await _db.eventsDao.afterSeq(current)) {
      if (row.hubSeq == next + 1) {
        next++;
      } else {
        break;
      }
    }
    if (next > current) {
      await _db.appStateDao.setInt(StateKeys.lastAckedSeq, next);
    }
  }

  Future<void> _flushOutbox() async {
    // Coalesce: one in-flight submit; if writes land mid-flush, run again.
    if (_flushing) {
      _flushQueued = true;
      return;
    }
    _flushing = true;
    try {
      do {
        _flushQueued = false;
        final pending = await _outbox.pendingEvents();
        if (pending.isEmpty) break;
        _send(MsgType.eventSubmit,
            EventSubmitPayload(events: pending).toJson());
      } while (_flushQueued);
    } finally {
      _flushing = false;
    }
  }

  void _pingTick() {
    _missedPongs++;
    if (_missedPongs > 2) {
      // Dead after 2 misses (§5).
      _onDisconnected();
      return;
    }
    _send(MsgType.ping, const <String, dynamic>{});
  }

  void _send(String type, Map<String, dynamic> payload, {String? nonce}) {
    _transport?.send(Codec.encode(
      type: type,
      deviceId: deviceId,
      payload: payload,
      secretHex: secretHex,
      nonce: nonce,
    ));
  }

  Future<void> _teardown() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _transport?.close();
    _transport = null;
  }

  void _onDisconnected() {
    if (_transport == null && _state == ClientState.disconnected) return;
    _teardown();
    _setState(ClientState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_running) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_backoff(_attempt), () {
      _attempt++;
      _connect();
    });
  }
}
