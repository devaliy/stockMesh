import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../security/message_auth.dart';
import '../protocol/codec.dart';
import '../protocol/messages.dart';
import '../transport/transport.dart';
import 'hub_server.dart';
import 'sequencer.dart';

enum SessionState { awaitHello, streaming, closed }

/// Per-client state machine on the Hub (design.md §5):
/// `AWAIT_HELLO → (auth) → CATCH_UP → STREAMING`.
///
/// Frames that fail MAC verification are dropped silently (M5 acceptance);
/// only a valid HELLO can move the session forward, and a revoked device
/// gets HELLO_REJECT{REVOKED} and the socket closed.
///
/// The transport subscription is owned by [HubServer.attach]; frames arrive
/// via [handleRaw] and disconnects via [onTransportClosed].
class HubSession {
  HubSession({
    required this.transport,
    required this.server,
    required AppDatabase database,
    required Sequencer eventSequencer,
  })  : _db = database,
        _sequencer = eventSequencer;

  final Transport transport;
  final HubServer server;
  final AppDatabase _db;
  final Sequencer _sequencer;

  SessionState state = SessionState.awaitHello;
  final String sessionId = newId();

  /// Set after a successful HELLO.
  String? deviceId;
  String? _secret;

  static const int catchUpChunk = 500;

  /// Processes one raw frame from this session's transport.
  Future<void> handleRaw(String raw) async {
    final frame = Codec.parse(raw);
    if (frame == null) return; // malformed → drop silently

    // Pairing is handled by the server before a session exists; a pairing
    // frame arriving here is a protocol violation → drop.
    if (Codec.isPairingType(frame.type)) return;

    if (state == SessionState.awaitHello) {
      if (frame.type != MsgType.hello) return;
      await _handleHello(raw, frame);
      return;
    }

    // STREAMING: every frame must verify under the authenticated secret and
    // claim the authenticated device id.
    final secret = _secret;
    if (secret == null) return;
    if (frame.deviceId != deviceId) return;
    if (!Codec.verify(raw, frame, secret)) {
      server.log('MAC failure from $deviceId — frame dropped');
      return;
    }

    switch (frame.type) {
      case MsgType.eventSubmit:
        await _handleSubmit(frame);
      case MsgType.ping:
        _send(MsgType.pong, const <String, dynamic>{});
      case MsgType.pong:
        break; // liveness bookkeeping is in the server's ping loop
      default:
        break;
    }
    _touch();
  }

  Future<void> _handleHello(String raw, Frame frame) async {
    final payload = HelloPayload.fromJson(frame.payload);
    final device = await _db.devicesDao.getById(payload.deviceId);

    if (device == null || device.secretHash.isEmpty) {
      _reject(RejectReason.badAuth);
      return;
    }
    if (device.isRevoked) {
      _reject(RejectReason.revoked);
      return;
    }
    if (frame.v != kProtocolVersion) {
      _reject(RejectReason.version);
      return;
    }

    // Two proofs, both under the registered secret: the envelope MAC and
    // the nonce-bound challenge response.
    if (!Codec.verify(raw, frame, device.secretHash)) {
      _reject(RejectReason.badAuth);
      return;
    }
    final expectedChallenge = MessageAuth.challengeResponse(
      secretHex: device.secretHash,
      deviceId: payload.deviceId,
      nonce: frame.nonce,
    );
    if (!MessageAuth.verifyHex(expectedChallenge, payload.challengeResponse)) {
      _reject(RejectReason.badAuth);
      return;
    }

    deviceId = payload.deviceId;
    _secret = device.secretHash;

    final latest = await _sequencer.latestSeq();
    _send(
      MsgType.helloAck,
      HelloAckPayload(
        hubTimeMs: DateTime.now().millisecondsSinceEpoch,
        latestSeq: latest,
        sessionId: sessionId,
      ).toJson(),
    );

    final cursor = await _sendCatchUp(
        fromSeq: payload.lastAckedSeq,
        refSince: payload.refSnapshotAt,
        includeRef: true);

    // Register for broadcasts, then run one closing sweep: anything
    // sequenced between the last chunk query and registration would
    // otherwise fall in a gap — neither caught up nor broadcast. Duplicates
    // from the overlap are harmless (client apply is idempotent, §1.3).
    state = SessionState.streaming;
    server.registerStreaming(this);
    await _sendCatchUp(fromSeq: cursor, refSince: 0, includeRef: false);
    _touch();
  }

  /// Streams events after [fromSeq] in ≤[catchUpChunk] pieces; returns the
  /// last hub_seq sent. Reference data rides the first chunk only — rows
  /// newer than [refSince] (Hub is authoritative; no merging).
  Future<int> _sendCatchUp({
    required int fromSeq,
    required int refSince,
    required bool includeRef,
  }) async {
    final products = !includeRef
        ? const <WireProduct>[]
        : (await _db.productsDao.getAll())
            .where((p) => p.updatedAt > refSince)
            .map(WireProduct.fromRow)
            .toList();
    final staff = !includeRef
        ? const <WireStaff>[]
        : (await _db.staffDao.getAll())
            .where((s) => s.updatedAt > refSince)
            .map(WireStaff.fromRow)
            .toList();

    var cursor = fromSeq;
    var first = true;
    while (true) {
      final events =
          await _db.eventsDao.afterSeq(cursor, limit: catchUpChunk);
      final last = events.isEmpty ? cursor : events.last.hubSeq!;
      final done = events.length < catchUpChunk;
      _send(
        MsgType.catchUp,
        CatchUpPayload(
          events: events.map(WireEvent.fromRow).toList(),
          refProducts: first ? products : const [],
          refStaff: first ? staff : const [],
          throughSeq: last,
          done: done,
        ).toJson(),
      );
      first = false;
      cursor = last;
      if (done) break;
    }

    if (deviceId != null) {
      await _db.devicesDao.setLastAckedSeq(deviceId!, cursor);
    }
    return cursor;
  }

  Future<void> _handleSubmit(Frame frame) async {
    final payload = EventSubmitPayload.fromJson(frame.payload);
    final assignments = <SeqAssignment>[];
    final rejections = <EventRejection>[];
    final broadcast = <WireEvent>[];

    for (final event in payload.events) {
      // The submitting session's identity wins over whatever device_id the
      // payload claims — a client cannot forge another device's events.
      final result = await _sequencer.submit(event);
      switch (result) {
        case SeqAccepted(:final eventId, :final hubSeq, :final isNew):
          assignments.add(SeqAssignment(eventId: eventId, hubSeq: hubSeq));
          if (isNew) broadcast.add(event.withSeq(hubSeq));
        case SeqRejected(:final eventId, :final reason):
          rejections.add(EventRejection(eventId: eventId, reason: reason));
      }
    }

    if (assignments.isNotEmpty) {
      _send(MsgType.eventAccept,
          EventAcceptPayload(assignments: assignments).toJson());
      final acked = assignments.map((a) => a.hubSeq).reduce(
          (a, b) => a > b ? a : b);
      if (deviceId != null) {
        await _db.devicesDao.setLastAckedSeq(deviceId!, acked);
      }
    }
    if (rejections.isNotEmpty) {
      _send(MsgType.eventReject,
          EventRejectPayload(rejections: rejections).toJson());
    }
    if (broadcast.isNotEmpty) {
      server.broadcastEvents(broadcast, exceptSession: this);
    }
  }

  void _reject(String reason) {
    _send(MsgType.helloReject, HelloRejectPayload(reason: reason).toJson());
    close();
  }

  /// Sends a frame authenticated with this session's device secret. The Hub
  /// signs with the same shared secret, proving to the client that it is
  /// talking to the paired Hub.
  void _send(String type, Map<String, dynamic> payload) {
    transport.send(Codec.encode(
      type: type,
      deviceId: HubServer.hubWireId,
      payload: payload,
      secretHex: _secret,
    ));
  }

  /// Server-initiated send (broadcasts, ref updates, pings).
  void sendFromServer(String type, Map<String, dynamic> payload) =>
      _send(type, payload);

  void _touch() {
    final id = deviceId;
    if (id != null) {
      _db.devicesDao
          .touchLastSeen(id, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Called by the server when this session's transport closes or errors.
  void onTransportClosed() {
    if (state == SessionState.closed) return;
    state = SessionState.closed;
    server.unregister(this);
  }

  void close() {
    transport.close();
    onTransportClosed();
  }
}
