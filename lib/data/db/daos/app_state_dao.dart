import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'app_state_dao.g.dart';

/// Well-known app_state keys (design.md §4).
abstract final class StateKeys {
  static const role = 'role'; // HUB | ATTENDANT | STOCKTAKER
  static const businessName = 'business_name';
  static const currency = 'currency';
  static const ownDeviceId = 'own_device_id';
  static const ownDeviceName = 'own_device_name';
  static const ownSecret = 'own_secret'; // client HMAC secret (hex)
  static const hubLastKnownIp = 'hub_last_known_ip';
  static const lastAckedSeq = 'last_acked_seq'; // client-side high-water mark
  static const onboardingDone = 'onboarding_done';
  static const lastBackupAt = 'last_backup_at';
}

@DriftAccessor(tables: [AppState])
class AppStateDao extends DatabaseAccessor<AppDatabase> with _$AppStateDaoMixin {
  AppStateDao(super.db);

  Future<String?> get(String key) async {
    final row = await (select(appState)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Stream<String?> watch(String key) =>
      (select(appState)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<void> set(String key, String value) =>
      into(appState).insertOnConflictUpdate(
          AppStateCompanion.insert(key: key, value: value));

  Future<void> remove(String key) =>
      (delete(appState)..where((s) => s.key.equals(key))).go();

  Future<Map<String, String>> getAll() async {
    final rows = await select(appState).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<int?> getInt(String key) async {
    final v = await get(key);
    return v == null ? null : int.tryParse(v);
  }

  Future<void> setInt(String key, int value) => set(key, value.toString());
}
