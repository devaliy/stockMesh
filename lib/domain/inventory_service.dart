import 'package:drift/drift.dart';

import '../core/ids.dart';
import '../core/result.dart';
import '../data/db/database.dart';
import 'models/event_type.dart';

/// Owns event creation and the stock_levels projection.
///
/// This class is the enforcement point for the core invariants (design.md §1):
/// * §1.1 — stock is never an editable number: every change flows through an
///   immutable, signed-delta [StockEvent]; stock_levels is a rebuildable cache.
/// * §1.3 — event_id is the idempotency key: [recordLocalEvent] and
///   [applyRemoteEvents] check the log before touching the projection, and do
///   both inside one transaction, so double-application is impossible.
/// * Pending events (hub_seq NULL) are included in the projection — deltas
///   commute, so optimistic totals equal post-sequencing totals.
class InventoryService {
  InventoryService(this._db);

  final AppDatabase _db;

  /// Creates and applies a locally-authored event (hub_seq NULL until the
  /// Hub sequences it). Pass [eventId] only to replay a known id (tests);
  /// normal callers let a fresh UUIDv7 be minted.
  Future<Result<StockEvent>> recordLocalEvent({
    required String productId,
    required StockEventType type,
    required int quantityDelta,
    required String deviceId,
    required String staffRef,
    int? unitPrice,
    String? receiptId,
    String? note,
    String? eventId,
    int? createdAt,
  }) async {
    if (!type.allowsDelta(quantityDelta)) {
      return Err('Invalid quantity for ${type.wire}');
    }
    final product = await _db.productsDao.getById(productId);
    if (product == null || !product.isActive) {
      return Err('Unknown or inactive product');
    }

    final id = eventId ?? newId();
    return _db.transaction(() async {
      final existing = await _db.eventsDao.getById(id);
      if (existing != null) return Ok(existing); // idempotent no-op

      final row = StockEventsCompanion.insert(
        eventId: id,
        productId: productId,
        eventType: type.wire,
        quantityDelta: quantityDelta,
        unitPrice: Value(unitPrice),
        receiptId: Value(receiptId),
        deviceId: deviceId,
        staffRef: staffRef,
        note: Value(note),
        createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
      );
      await _db.eventsDao.insertEvent(row);
      await _db.projectionDao.applyDelta(productId, quantityDelta);
      return Ok((await _db.eventsDao.getById(id))!);
    });
  }

  /// Applies events that arrived from the Hub (CATCH_UP / EVENT_BROADCAST),
  /// already carrying hub_seq. Client apply rule (design.md §5):
  /// * unknown event_id → insert + apply delta;
  /// * known event_id → only fill in hub_seq (own event confirmed) — the
  ///   delta was already applied optimistically, so the projection is
  ///   untouched and no duplicate is possible.
  Future<void> applyRemoteEvents(List<StockEvent> events) async {
    if (events.isEmpty) return;
    await _db.transaction(() async {
      for (final e in events) {
        final existing = await _db.eventsDao.getById(e.eventId);
        if (existing != null) {
          if (existing.hubSeq == null && e.hubSeq != null) {
            await _db.eventsDao.setHubSeq(e.eventId, e.hubSeq!);
          }
          continue;
        }
        await _db.eventsDao.insertEvent(e.toCompanion(false));
        await _db.projectionDao.applyDelta(e.productId, e.quantityDelta);
      }
    });
  }

  /// Confirms locally-authored events with their Hub-assigned sequence
  /// numbers (EVENT_ACCEPT). Projection untouched — totals already counted
  /// these deltas optimistically.
  Future<void> applyConfirmations(Map<String, int> assignments) async {
    if (assignments.isEmpty) return;
    await _db.transaction(() async {
      for (final entry in assignments.entries) {
        final existing = await _db.eventsDao.getById(entry.key);
        if (existing != null && existing.hubSeq == null) {
          await _db.eventsDao.setHubSeq(entry.key, entry.value);
        }
      }
    });
  }

  /// Rebuilds stock_levels from scratch: truncate, then re-sum every event
  /// (invariant §1.1). Used after restore and by tests to assert
  /// projection == sum(events).
  Future<void> rebuildProjection() async {
    await _db.transaction(() async {
      await _db.projectionDao.truncate();
      final rows = await _db.customSelect(
        'SELECT product_id, SUM(quantity_delta) AS total, '
        'COALESCE(MAX(hub_seq), 0) AS through_seq '
        'FROM stock_events GROUP BY product_id',
        readsFrom: {_db.stockEvents},
      ).get();
      for (final row in rows) {
        await _db.into(_db.stockLevels).insert(
              StockLevelsCompanion.insert(
                productId: row.read<String>('product_id'),
                quantity: Value(row.read<int>('total')),
                projectedThroughSeq: Value(row.read<int>('through_seq')),
              ),
            );
      }
    });
  }

  /// Physical count (design.md §4 projector rules): compares [countedQty]
  /// against the current projection and, when they differ, emits a
  /// COUNT_ADJUST event whose delta closes the gap. Raw count kept in note.
  Future<Result<StockEvent?>> recordCount({
    required String productId,
    required int countedQty,
    required String deviceId,
    required String staffRef,
  }) async {
    if (countedQty < 0) return const Err('Count cannot be negative');
    final expected = await _db.projectionDao.quantityOf(productId);
    final variance = countedQty - expected;
    if (variance == 0) return const Ok(null);
    final result = await recordLocalEvent(
      productId: productId,
      type: StockEventType.countAdjust,
      quantityDelta: variance,
      deviceId: deviceId,
      staffRef: staffRef,
      note: 'counted=$countedQty expected=$expected',
    );
    return result.when(ok: (e) => Ok(e), err: (m) => Err(m));
  }
}
