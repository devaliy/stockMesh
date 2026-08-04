import 'dart:async';

import 'transport.dart';

/// In-memory duplex pipe used by all sync-engine tests (§11: no real sockets
/// in tests). Create a [MemoryTransportPair]; hand [client] to a SyncClient
/// and [server] to the HubServer. [severed] simulates a network partition:
/// frames are dropped while true, and [cut] closes both ends like a socket
/// reset.
class MemoryTransportPair {
  MemoryTransportPair() {
    client = _MemoryTransport(this, _toClient, _toServer);
    server = _MemoryTransport(this, _toServer, _toClient);
  }

  final _toClient = StreamController<String>.broadcast(sync: true);
  final _toServer = StreamController<String>.broadcast(sync: true);

  late final Transport client;
  late final Transport server;

  /// While true, frames in both directions vanish (lossy partition).
  bool severed = false;

  /// Drops frames sent client→hub while true (used to test lost ACKs: the
  /// submit arrives, the accept comes back, but a re-submit sees dedup).
  bool dropToServer = false;

  /// Drops frames sent hub→client while true.
  bool dropToClient = false;

  /// Hard-close both endpoints, as a socket reset would.
  Future<void> cut() async {
    await client.close();
    await server.close();
  }
}

class _MemoryTransport implements Transport {
  _MemoryTransport(this._pair, this._rx, this._tx);

  final MemoryTransportPair _pair;
  final StreamController<String> _rx;
  final StreamController<String> _tx;
  bool _open = true;

  @override
  Stream<String> get incoming => _rx.stream;

  @override
  bool get isOpen => _open && !_rx.isClosed;

  @override
  void send(String frame) {
    if (!_open || _tx.isClosed || _pair.severed) return;
    if (identical(this, _pair.client) && _pair.dropToServer) return;
    if (identical(this, _pair.server) && _pair.dropToClient) return;
    // Deliver asynchronously so send() never re-enters handlers.
    scheduleMicrotask(() {
      if (!_tx.isClosed && !_pair.severed) _tx.add(frame);
    });
  }

  @override
  Future<void> close() async {
    if (!_open) return;
    _open = false;
    // Deferred like send() so frames written just before close still arrive
    // (a real socket flushes its write buffer on graceful close too).
    final done = Completer<void>();
    scheduleMicrotask(() async {
      if (!_tx.isClosed) await _tx.close();
      if (!_rx.isClosed) await _rx.close();
      done.complete();
    });
    return done.future;
  }
}
