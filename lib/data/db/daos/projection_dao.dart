import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'projection_dao.g.dart';

/// The stock_levels projection cache (invariant §1.1: always rebuildable as
/// sum of event deltas — see `InventoryService.rebuildProjection`).
@DriftAccessor(tables: [StockLevels])
class ProjectionDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectionDaoMixin {
  ProjectionDao(super.db);

  /// Adds [delta] to a product's cached quantity (upsert). Callers must have
  /// already guaranteed idempotence by checking the event log — this method
  /// itself is a blind accumulator.
  Future<void> applyDelta(String productId, int delta) async {
    await into(stockLevels).insert(
      StockLevelsCompanion.insert(productId: productId, quantity: Value(delta)),
      onConflict: DoUpdate(
        (old) => StockLevelsCompanion.custom(
          quantity: old.quantity + Variable<int>(delta),
        ),
      ),
    );
  }

  Future<int> quantityOf(String productId) async {
    final row = await (select(stockLevels)
          ..where((l) => l.productId.equals(productId)))
        .getSingleOrNull();
    return row?.quantity ?? 0;
  }

  Stream<int> watchQuantity(String productId) => (select(stockLevels)
        ..where((l) => l.productId.equals(productId)))
      .watchSingleOrNull()
      .map((row) => row?.quantity ?? 0);

  /// Map of productId → quantity for every product with a level row.
  Stream<Map<String, int>> watchAllLevels() =>
      select(stockLevels).watch().map((rows) =>
          {for (final r in rows) r.productId: r.quantity});

  Future<List<StockLevel>> getAll() => select(stockLevels).get();

  Future<void> truncate() => delete(stockLevels).go();
}
