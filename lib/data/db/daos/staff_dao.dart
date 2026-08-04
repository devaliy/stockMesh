import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'staff_dao.g.dart';

/// Staff rows (PIN hashes) — Hub-owned reference data, mirrored to clients
/// via REF sync so PINs verify locally even when offline (§6.4).
@DriftAccessor(tables: [Staff])
class StaffDao extends DatabaseAccessor<AppDatabase> with _$StaffDaoMixin {
  StaffDao(super.db);

  Future<StaffData?> getByRef(String staffRef) =>
      (select(staff)..where((s) => s.staffRef.equals(staffRef)))
          .getSingleOrNull();

  Stream<List<StaffData>> watchActive() => (select(staff)
        ..where((s) => s.isActive.equals(true))
        ..orderBy([(s) => OrderingTerm.asc(s.displayName)]))
      .watch();

  Future<List<StaffData>> getActive() =>
      (select(staff)..where((s) => s.isActive.equals(true))).get();

  Future<List<StaffData>> getAll() => select(staff).get();

  Future<void> upsertStaff(StaffCompanion row) =>
      into(staff).insertOnConflictUpdate(row);

  Future<void> upsertAll(List<StaffData> rows) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(staff, rows);
    });
  }
}
