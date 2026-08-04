/// Transport abstraction (design.md §11): the sync engine never touches real
/// sockets directly, so every unit/integration test runs against
/// `memory_transport.dart` and production runs against `ws_transport.dart`.
abstract interface class Transport {
  /// Frames from the peer. Closes when the connection drops; a stream error
  /// also means the connection is dead.
  Stream<String> get incoming;

  /// Sends one frame. Silently drops if the connection is already closed —
  /// the disconnect will surface through [incoming] closing.
  void send(String frame);

  /// True until [close] or peer disconnect.
  bool get isOpen;

  Future<void> close();
}
