import 'dart:async';

import '../../data/db/database.dart';
import '../protocol/messages.dart';
import '../transport/transport.dart';
import 'hub_session.dart';
import 'sequencer.dart';

/// The Hub's connection registry and fan-out point.
///
/// Transport-agnostic: anything that can produce [Transport]s can attach
/// clients (a real ServerSocket in M4, memory pipes in tests). Owns the
/// [Sequencer] — the single writer that keeps hub_seq gapless (§1.2) — and
/// re-broadcasts accepted events to every other STREAMING session.
class HubServer {
  HubServer({
    required AppDatabase db,
    this.onLog,
    this.onClientCountChanged,
    this.onOnlineDevicesChanged,
  }) : _db = db {
    sequencer = Sequencer(db);
    _selfSequencer = HubSelfSequencer(db, sequencer, (sequenced) {
      broadcastEvents(sequenced, exceptSession: null);
    });
  }

  /// The device_id the Hub stamps on frames it sends.
  static const hubWireId = 'hub';

  final AppDatabase _db;
  final void Function(String message)? onLog;
  final void Function(int count)? onClientCountChanged;
  final void Function(Set<String> deviceIds)? onOnlineDevicesChanged;

  late final Sequencer sequencer;
  late final HubSelfSequencer _selfSequencer;

  final _sessions = <HubSession>[];
  final _streaming = <HubSession>{};

  StreamSubscription<List<Product>>? _productWatch;
  StreamSubscription<List<StaffData>>? _staffWatch;
  bool _refWatchPrimed = false;
  bool _staffWatchPrimed = false;

  /// Hook for the pairing service (M5) — set before attach()ing transports.
  Future<bool> Function(Transport transport, String raw)? pairingHandler;

  /// Starts hub-side background work: sequencing the Hub's own local writes
  /// and pushing REF_UPDATE when reference data changes.
  void start() {
    _selfSequencer.start();
    _productWatch ??= _db.productsDao.watchSearch('').listen((_) {
      // First emission is the current state, not a change.
      if (_refWatchPrimed) _broadcastRefUpdate();
      _refWatchPrimed = true;
    });
    _staffWatch ??= _db.staffDao.watchActive().listen((_) {
      if (_staffWatchPrimed) _broadcastRefUpdate();
      _staffWatchPrimed = true;
    });
  }

  /// Adopts an incoming connection. The first frame decides: a PAIR_REQUEST
  /// goes to the pairing handler; anything else starts a normal session.
  /// Frames are processed strictly in arrival order (futures are chained),
  /// which the HELLO → CATCH_UP → STREAMING handshake depends on.
  void attach(Transport transport) {
    HubSession? session;
    var pairing = false;
    var chain = Future<void>.value();

    Future<void> handleFirst(String raw) async {
      final handler = pairingHandler;
      if (handler != null && raw.contains('"${MsgType.pairRequest}"')) {
        pairing = true;
        await handler(transport, raw);
        return;
      }
      session = HubSession(
        transport: transport,
        server: this,
        database: _db,
        eventSequencer: sequencer,
      );
      _sessions.add(session!);
      await session!.handleRaw(raw);
    }

    transport.incoming.listen((raw) {
      chain = chain.then((_) async {
        if (pairing) return;
        if (session == null) {
          await handleFirst(raw);
        } else {
          await session!.handleRaw(raw);
        }
      });
    }, onDone: () {
      chain = chain.then((_) {
        session?.onTransportClosed();
        if (session == null) transport.close();
      });
    }, onError: (Object _) {
      chain = chain.then((_) {
        session?.onTransportClosed();
        if (session == null) transport.close();
      });
    });
  }

  void registerStreaming(HubSession session) {
    _streaming.add(session);
    onClientCountChanged?.call(_streaming.length);
    _notifyOnline();
  }

  void unregister(HubSession session) {
    _sessions.remove(session);
    if (_streaming.remove(session)) {
      onClientCountChanged?.call(_streaming.length);
      _notifyOnline();
    }
  }

  void _notifyOnline() {
    onOnlineDevicesChanged?.call({
      for (final s in _streaming)
        if (s.deviceId != null) s.deviceId!,
    });
  }

  int get streamingCount => _streaming.length;

  /// Fans sequenced events out to every STREAMING session except the
  /// submitter (which learns its assignments via EVENT_ACCEPT).
  void broadcastEvents(List<WireEvent> events, {HubSession? exceptSession}) {
    if (events.isEmpty) return;
    final payload = EventBroadcastPayload(events: events).toJson();
    for (final session in List.of(_streaming)) {
      if (identical(session, exceptSession)) continue;
      session.sendFromServer(MsgType.eventBroadcast, payload);
    }
  }

  Future<void> _broadcastRefUpdate() async {
    final products =
        (await _db.productsDao.getAll()).map(WireProduct.fromRow).toList();
    final staff =
        (await _db.staffDao.getAll()).map(WireStaff.fromRow).toList();
    final payload =
        RefUpdatePayload(products: products, staff: staff).toJson();
    for (final session in List.of(_streaming)) {
      session.sendFromServer(MsgType.refUpdate, payload);
    }
  }

  /// Disconnects a device immediately (used after revocation so the next
  /// HELLO gets bounced rather than waiting for a timeout).
  void kick(String deviceId) {
    for (final session in List.of(_sessions)) {
      if (session.deviceId == deviceId) session.close();
    }
  }

  void log(String message) => onLog?.call(message);

  Future<void> shutdown() async {
    await _productWatch?.cancel();
    await _staffWatch?.cancel();
    _productWatch = null;
    _staffWatch = null;
    for (final session in List.of(_sessions)) {
      session.close();
    }
    _sessions.clear();
    _streaming.clear();
    onClientCountChanged?.call(0);
  }
}
