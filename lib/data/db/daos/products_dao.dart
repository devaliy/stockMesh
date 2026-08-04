import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'products_dao.g.dart';

/// Reference-data access for products. Writes happen only on the Hub
/// (invariant §1.5) or when a client applies a REF_UPDATE/CATCH_UP snapshot.
@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Stream<List<Product>> watchActive() {
    return (select(products)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  /// Search by name substring, or exact SKU/barcode match.
  Stream<List<Product>> watchSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return watchActive();
    final like = '%${q.replaceAll('%', r'\%')}%';
    return (select(products)
          ..where((p) =>
              p.isActive.equals(true) &
              (p.name.like(like) | p.sku.equals(q) | p.barcode.equals(q)))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<Product?> getById(String id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Product?> getByBarcode(String code) => (select(products)
        ..where((p) => p.barcode.equals(code) & p.isActive.equals(true))
        ..limit(1))
      .getSingleOrNull();

  Future<List<Product>> getAll() => select(products).get();

  Future<int> countActive() async {
    final c = countAll();
    final q = selectOnly(products)
      ..addColumns([c])
      ..where(products.isActive.equals(true));
    final row = await q.getSingle();
    return row.read(c) ?? 0;
  }

  Future<void> upsertProduct(ProductsCompanion row) =>
      into(products).insertOnConflictUpdate(row);

  /// Applies a Hub reference snapshot. The Hub is authoritative, so rows
  /// always overwrite the local copy (clients never edit products).
  Future<void> upsertAll(List<Product> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(products, rows);
    });
  }
}
