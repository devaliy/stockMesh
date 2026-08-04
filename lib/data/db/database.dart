import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/app_state_dao.dart';
import 'daos/devices_dao.dart';
import 'daos/events_dao.dart';
import 'daos/products_dao.dart';
import 'daos/projection_dao.dart';
import 'daos/staff_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Products, StockEvents, Devices, Staff, StockLevels, AppState],
  daos: [ProductsDao, EventsDao, DevicesDao, StaffDao, ProjectionDao, AppStateDao],
)
class AppDatabase extends _$AppDatabase {
  /// Production constructor — opens `stockmesh.sqlite` in app documents.
  AppDatabase() : super(driftDatabase(name: 'stockmesh'));

  /// Test/tooling constructor — pass `NativeDatabase.memory()`.
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    // Partial index makes the outbox query (hub_seq IS NULL) O(pending).
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_pending ON stock_events(hub_seq) '
        'WHERE hub_seq IS NULL');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_product ON stock_events(product_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_events_receipt ON stock_events(receipt_id)');
  }
}
