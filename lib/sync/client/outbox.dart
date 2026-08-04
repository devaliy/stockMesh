import '../../data/db/database.dart';
import '../protocol/messages.dart';

/// The client's queue of locally-authored events awaiting sequencing
/// (`hub_seq IS NULL`, invariant §1.4 — a disconnected client keeps writing
/// and replays on reconnect with zero loss and zero duplicates).
///
/// Deliberately stateless between reads: the database IS the queue, so a
/// process kill loses nothing. Duplicate submission after a dropped ACK is
/// safe because the sequencer's event_id dedup returns the original hub_seq.
class Outbox {
  Outbox(this._db);

  final AppDatabase _db;

  /// Everything pending, oldest first, as wire events.
  Future<List<WireEvent>> pendingEvents() async {
    final rows = await _db.eventsDao.pending();
    return rows.map(WireEvent.fromRow).toList(growable: false);
  }

  Stream<int> watchPendingCount() => _db.eventsDao.watchPendingCount();
}
