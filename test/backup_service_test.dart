import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockmesh/data/backup_service.dart';
import 'package:stockmesh/data/db/daos/app_state_dao.dart';
import 'package:stockmesh/data/db/database.dart';
import 'package:stockmesh/domain/inventory_service.dart';
import 'package:stockmesh/domain/models/event_type.dart';

import 'helpers/test_db.dart';

void main() {
  test('M6: backup on device A restores on device B; projection rebuilds',
      () async {
    final a = testDb();
    final inventoryA = InventoryService(a);

    await a.productsDao.upsertProduct(ProductsCompanion.insert(
      id: 'p1',
      name: 'Peak Milk',
      sellingPrice: const Value(45000),
      updatedAt: 10,
    ));
    await a.staffDao.upsertStaff(StaffCompanion.insert(
      staffRef: 'admin',
      displayName: 'Admin',
      pinHash: 'salt:hash',
      isAdmin: const Value(true),
      updatedAt: 10,
    ));
    await a.appStateDao.set(StateKeys.businessName, 'Mama Nkechi');
    await a.appStateDao.set(StateKeys.role, 'HUB');
    await a.devicesDao.upsertDevice(DevicesCompanion.insert(
      deviceId: 'hub-1',
      displayName: 'Hub',
      role: 'HUB',
      secretHash: '',
    ));
    await a.devicesDao.upsertDevice(DevicesCompanion.insert(
      deviceId: 'client-1',
      displayName: 'Attendant',
      role: 'ATTENDANT',
      secretHash: 'secret-hex',
    ));

    await inventoryA.recordLocalEvent(
      productId: 'p1',
      type: StockEventType.receive,
      quantityDelta: 60,
      deviceId: 'hub-1',
      staffRef: 'admin',
    );
    await inventoryA.recordLocalEvent(
      productId: 'p1',
      type: StockEventType.sale,
      quantityDelta: -12,
      unitPrice: 45000,
      deviceId: 'hub-1',
      staffRef: 'admin',
    );

    final bytes = await BackupService(a).createBackup('1234');

    // Wrong PIN fails, and fails safely.
    final b = testDb();
    final bad = await BackupService(b).restoreBackup(bytes, '9999');
    expect(bad.isOk, isFalse);
    expect(await b.eventsDao.count(), 0);

    final good = await BackupService(b).restoreBackup(bytes, '1234');
    expect(good.isOk, isTrue);
    expect(good.requireValue, 'Mama Nkechi');

    // Events identical, projection rebuilt from the log (§7).
    expect(await b.eventsDao.count(), 2);
    expect(await b.projectionDao.quantityOf('p1'), 48);
    expect(await b.appStateDao.get(StateKeys.role), 'HUB');

    // Old client pairings invalid; the hub row survives.
    final restoredClient = await b.devicesDao.getById('client-1');
    expect(restoredClient!.isRevoked, isTrue);
    final restoredHub = await b.devicesDao.getById('hub-1');
    expect(restoredHub!.isRevoked, isFalse);

    // Golden rule after restore: rebuild changes nothing.
    final before = await b.projectionDao.quantityOf('p1');
    await InventoryService(b).rebuildProjection();
    expect(await b.projectionDao.quantityOf('p1'), before);

    await a.close();
    await b.close();
  });

  test('corrupted backup bytes are rejected', () async {
    final db = testDb();
    final service = BackupService(db);
    final garbage = List<int>.generate(200, (i) => i % 251);
    final result = await service.restoreBackup(
        Uint8List.fromList(garbage), '1234');
    expect(result.isOk, isFalse);
    await db.close();
  });
}
