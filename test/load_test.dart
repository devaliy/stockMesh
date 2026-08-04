import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockmesh/data/db/database.dart';
import 'package:stockmesh/domain/inventory_service.dart';
import 'package:stockmesh/domain/models/event_type.dart';
import 'package:stockmesh/security/message_auth.dart';
import 'package:stockmesh/sync/client/sync_client.dart';
import 'package:stockmesh/sync/hub/hub_server.dart';
import 'package:stockmesh/sync/transport/memory_transport.dart';

import 'helpers/test_db.dart';

/// M7 load test: 8 headless clients catching up on a 2,000-event log must
/// all converge in under 10 seconds (design.md M7 acceptance).
void main() {
  test('8 clients × 2,000-event catch-up converges in < 10 s', () async {
    final hubDb = testDb();
    final hubInventory = InventoryService(hubDb);
    const productCount = 20;
    for (var i = 0; i < productCount; i++) {
      await hubDb.productsDao.upsertProduct(ProductsCompanion.insert(
        id: 'p$i',
        name: 'Product $i',
        sellingPrice: Value(1000 + i),
        updatedAt: 1,
      ));
    }

    // Seed 2,000 sequenced events directly through the hub's own path.
    final server = HubServer(db: hubDb);
    server.start();
    for (var i = 0; i < 2000; i++) {
      await hubInventory.recordLocalEvent(
        productId: 'p${i % productCount}',
        type: StockEventType.receive,
        quantityDelta: 1 + (i % 7),
        deviceId: 'hub',
        staffRef: 'admin',
      );
    }
    // Let the self-sequencer assign every hub_seq before clients dial in.
    final seedDeadline = DateTime.now().add(const Duration(seconds: 30));
    while ((await hubDb.eventsDao.pending()).isNotEmpty) {
      if (DateTime.now().isAfter(seedDeadline)) {
        fail('hub never finished sequencing its own events');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(await hubDb.eventsDao.maxHubSeq(), 2000);

    final stopwatch = Stopwatch()..start();
    final clients = <SyncClient>[];
    final dbs = <AppDatabase>[];
    for (var i = 0; i < 8; i++) {
      final secret = MessageAuth.randomSecretHex();
      final deviceId = 'load-client-$i';
      await hubDb.devicesDao.upsertDevice(DevicesCompanion.insert(
        deviceId: deviceId,
        displayName: deviceId,
        role: 'ATTENDANT',
        secretHash: secret,
      ));
      final db = testDb();
      dbs.add(db);
      final client = SyncClient(
        db: db,
        inventoryService: InventoryService(db),
        deviceId: deviceId,
        secretHex: secret,
        enablePing: false,
        backoff: (_) => const Duration(milliseconds: 20),
        connector: () async {
          final pair = MemoryTransportPair();
          server.attach(pair.server);
          return pair.client;
        },
      );
      clients.add(client);
      client.start();
    }

    await Future.wait(clients.map((c) =>
        c.untilLive().timeout(const Duration(seconds: 10))));

    // LIVE means catch-up finished; verify the data actually landed.
    for (final db in dbs) {
      expect(await db.eventsDao.count(), 2000);
      expect(await db.eventsDao.maxHubSeq(), 2000);
    }
    stopwatch.stop();
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)),
        reason: '8×2,000-event catch-up took ${stopwatch.elapsed}');

    // And the projections agree with the hub, product by product.
    final hubLevels = {
      for (final l in await hubDb.projectionDao.getAll())
        l.productId: l.quantity
    };
    for (final db in dbs) {
      final levels = {
        for (final l in await db.projectionDao.getAll())
          l.productId: l.quantity
      };
      expect(levels, hubLevels);
    }

    for (final c in clients) {
      await c.stop();
    }
    await server.shutdown();
    for (final db in dbs) {
      await db.close();
    }
    await hubDb.close();
  }, timeout: const Timeout(Duration(minutes: 3)));
}
