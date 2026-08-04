import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'events_dao.g.dart';

/// Access to the append-only stock event log (invariant §1.1).
///
/// The ONLY permitted mutation of an existing row is filling in a NULL
/// `hub_seq` when the Hub confirms an event — everything else is insert-only.
@DriftAccessor(tables: [StockEvents])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  Future<bool> exists(String eventId) async {
    final row = await (selectOnly(stockEvents)
          ..addColumns([stockEvents.eventId])
          ..where(stockEvents.eventId.equals(eventId)))
        .getSingleOrNull();
    return row != null;
  }

  Future<StockEvent?> getById(String eventId) =>
      (select(stockEvents)..where((e) => e.eventId.equals(eventId)))
          .getSingleOrNull();

  Future<void> insertEvent(StockEventsCompanion row) =>
      into(stockEvents).insert(row);

  /// Outbox: locally-authored events the Hub has not sequenced yet.
  /// Ordered by event_id — UUIDv7 is time-ordered, which preserves the
  /// author's intent order without trusting wall clocks across devices.
  Future<List<StockEvent>> pending() => (select(stockEvents)
        ..where((e) => e.hubSeq.isNull())
        ..orderBy([(e) => OrderingTerm.asc(e.eventId)]))
      .get();

  Stream<int> watchPendingCount() {
    final c = countAll();
    final q = selectOnly(stockEvents)
      ..addColumns([c])
      ..where(stockEvents.hubSeq.isNull());
    return q.watchSingle().map((row) => row.read(c) ?? 0);
  }

  /// Confirms a pending event with its Hub-assigned sequence number.
  Future<void> setHubSeq(String eventId, int seq) =>
      (update(stockEvents)..where((e) => e.eventId.equals(eventId)))
          .write(StockEventsCompanion(hubSeq: Value(seq)));

  /// Highest hub_seq held locally (0 when none).
  Future<int> maxHubSeq() async {
    final maxSeq = stockEvents.hubSeq.max();
    final row = await (selectOnly(stockEvents)..addColumns([maxSeq])).getSingle();
    return row.read(maxSeq) ?? 0;
  }

  /// Sequenced events strictly after [seq], in hub_seq order — the CATCH_UP
  /// source query on the Hub.
  Future<List<StockEvent>> afterSeq(int seq, {int? limit}) {
    final q = select(stockEvents)
      ..where((e) => e.hubSeq.isNotNull() & e.hubSeq.isBiggerThanValue(seq))
      ..orderBy([(e) => OrderingTerm.asc(e.hubSeq)]);
    if (limit != null) q.limit(limit);
    return q.get();
  }

  Future<List<StockEvent>> byReceipt(String receiptId) =>
      (select(stockEvents)..where((e) => e.receiptId.equals(receiptId))).get();

  /// Events with created_at in [fromMs, toMs) — reporting only; display
  /// timestamps are fine for reports, never for sync ordering.
  Future<List<StockEvent>> inCreatedRange(int fromMs, int toMs) =>
      (select(stockEvents)
            ..where((e) =>
                e.createdAt.isBiggerOrEqualValue(fromMs) &
                e.createdAt.isSmallerThanValue(toMs)))
          .get();

  Stream<List<StockEvent>> watchRecentSales({int limit = 20}) =>
      (select(stockEvents)
            ..where((e) => e.eventType.equals('SALE'))
            ..orderBy([(e) => OrderingTerm.desc(e.createdAt)])
            ..limit(limit))
          .watch();

  Future<List<StockEvent>> allEvents() => select(stockEvents).get();

  Future<int> count() async {
    final c = countAll();
    final row =
        await (selectOnly(stockEvents)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
