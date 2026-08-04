import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'devices_dao.g.dart';

/// Device registry access. Lives on the Hub as the authority; clients keep a
/// read-only mirror for display.
@DriftAccessor(tables: [Devices])
class DevicesDao extends DatabaseAccessor<AppDatabase> with _$DevicesDaoMixin {
  DevicesDao(super.db);

  Future<Device?> getById(String deviceId) =>
      (select(devices)..where((d) => d.deviceId.equals(deviceId)))
          .getSingleOrNull();

  Stream<List<Device>> watchAll() => (select(devices)
        ..orderBy([(d) => OrderingTerm.asc(d.displayName)]))
      .watch();

  Future<List<Device>> getAll() => select(devices).get();

  Future<void> upsertDevice(DevicesCompanion row) =>
      into(devices).insertOnConflictUpdate(row);

  /// Revocation (§6.5): next HELLO from this device gets HELLO_REJECT.
  Future<void> revoke(String deviceId) =>
      (update(devices)..where((d) => d.deviceId.equals(deviceId)))
          .write(const DevicesCompanion(isRevoked: Value(true)));

  Future<void> touchLastSeen(String deviceId, int atMs) =>
      (update(devices)..where((d) => d.deviceId.equals(deviceId)))
          .write(DevicesCompanion(lastSeenAt: Value(atMs)));

  Future<void> setLastAckedSeq(String deviceId, int seq) =>
      (update(devices)..where((d) => d.deviceId.equals(deviceId)))
          .write(DevicesCompanion(lastAckedSeq: Value(seq)));
}
