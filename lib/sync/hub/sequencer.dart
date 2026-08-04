import '../../data/db/database.dart';
import '../../domain/models/event_type.dart';
import '../protocol/messages.dart';

/// Outcome of submitting one event to the sequencer.
sealed class SeqResult {
  const SeqResult();
}

class SeqAccepted extends SeqResult {
  const SeqAccepted(this.eventId, this.hubSeq, {required this.isNew});

  final String eventId;
  final int hubSeq;

  /// False when the event already existed (idempotent re-submit) — such
  /// events are ACKed but not re-broadcast.
  final bool isNew;
}

class SeqRejected extends SeqResult {
  const SeqRejected(this.eventId, this.reason);

  final String eventId;
  final String reason;
}

/// The single writer that makes `hub_seq` a gapless total order
/// (invariant §1.2).
///
/// All submissions — from client sessions AND from the Hub's own local
/// writes — funnel through one async queue, so exactly one event is
/// validated, deduplicated, numbered and persisted at a time. Dedup by
/// event_id returns the existing hub_seq (invariant §1.3: re-submitting is
/// a no-op that returns the same assignment).
class Sequencer {
  Sequencer(this._db);

  final AppDatabase _db;

  Future<void> _queue = Future.value();
  int? _nextSeq;

  /// Sequences one event. Serialized: concurrent callers are chained onto
  /// the internal queue in arrival order.
  Future<SeqResult> submit(WireEvent event) {
    final result = _queue.then((_) => _process(event));
    // Keep the chain alive even when a submission is rejected.
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<SeqResult> _process(WireEvent event) async {
    // Dedup first — a replayed event must return its original assignment
    // even if its product has since been deactivated.
    final existing = await _db.eventsDao.getById(event.eventId);
    if (existing != null) {
      if (existing.hubSeq != null) {
        return SeqAccepted(event.eventId, existing.hubSeq!, isNew: false);
      }
      // The Hub's own optimistic write: assign its number now.
      final seq = await _nextHubSeq();
      await _db.eventsDao.setHubSeq(event.eventId, seq);
      _nextSeq = seq + 1;
      return SeqAccepted(event.eventId, seq, isNew: true);
    }

    // Validate (§5 sequencer rules).
    final type = StockEventType.fromWire(event.eventType);
    if (type == null) {
      return SeqRejected(event.eventId, 'UNKNOWN_TYPE');
    }
    if (!type.allowsDelta(event.quantityDelta)) {
      return SeqRejected(event.eventId, 'BAD_DELTA');
    }
    final product = await _db.productsDao.getById(event.productId);
    if (product == null || !product.isActive) {
      return SeqRejected(event.eventId, 'UNKNOWN_PRODUCT');
    }

    final seq = await _nextHubSeq();
    await _db.transaction(() async {
      await _db.eventsDao
          .insertEvent(event.withSeq(seq).toRow().toCompanion(false));
      await _db.projectionDao.applyDelta(event.productId, event.quantityDelta);
    });
    _nextSeq = seq + 1;
    return SeqAccepted(event.eventId, seq, isNew: true);
  }

  Future<int> _nextHubSeq() async {
    if (_nextSeq != null) return _nextSeq!;
    final max = await _db.eventsDao.maxHubSeq();
    return max + 1;
  }

  /// Current highest assigned hub_seq.
  Future<int> latestSeq() async {
    if (_nextSeq != null) return _nextSeq! - 1;
    return _db.eventsDao.maxHubSeq();
  }
}

/// Watches the Hub's own pending local events (its "outbox") and feeds them
/// through the sequencer, so a sale rung up on the Hub gets a hub_seq and a
/// broadcast exactly like a client submission would.
class HubSelfSequencer {
  HubSelfSequencer(this._db, this._sequencer, this._onSequenced);

  final AppDatabase _db;
  final Sequencer _sequencer;
  final void Function(List<WireEvent> sequenced) _onSequenced;

  Stream<int>? _watch;

  void start() {
    _watch ??= _db.eventsDao.watchPendingCount()
      ..listen((count) {
        if (count > 0) _drain();
      });
  }

  bool _draining = false;

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final pending = await _db.eventsDao.pending();
      final sequenced = <WireEvent>[];
      for (final row in pending) {
        final result = await _sequencer.submit(WireEvent.fromRow(row));
        if (result is SeqAccepted && result.isNew) {
          sequenced.add(WireEvent.fromRow(row).withSeq(result.hubSeq));
        }
      }
      if (sequenced.isNotEmpty) _onSequenced(sequenced);
    } finally {
      _draining = false;
    }
  }
}
