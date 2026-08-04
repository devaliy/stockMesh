import 'dart:math';

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

/// §11 property test: random interleavings of writes and disconnects across
/// 1 hub + 2 clients must always converge — identical projections on all
/// three nodes, each equal to the sum of its events.
///
/// Seeds per run: pass `--dart-define=CONVERGENCE_SEEDS=100` in CI; the
/// default keeps local runs quick while still probing many interleavings.
const _seedCount =
    int.fromEnvironment('CONVERGENCE_SEEDS', defaultValue: 12);

const _products = ['p-alpha', 'p-beta', 'p-gamma'];

Future<void> _runSeed(int seed) async {
  final random = Random(seed);

  final hubDb = testDb();
  final hubInventory = InventoryService(hubDb);
  for (final id in _products) {
    await hubDb.productsDao.upsertProduct(ProductsCompanion.insert(
      id: id,
      name: id,
      sellingPrice: const Value(1000),
      updatedAt: 1,
    ));
  }
  final server = HubServer(db: hubDb);
  server.start();

  final nodes = <({
    AppDatabase db,
    InventoryService inventory,
    SyncClient client,
    List<MemoryTransportPair> pairs,
    String id,
  })>[];

  for (var i = 0; i < 2; i++) {
    final deviceId = 'client-$i';
    final secret = MessageAuth.randomSecretHex();
    await hubDb.devicesDao.upsertDevice(DevicesCompanion.insert(
      deviceId: deviceId,
      displayName: deviceId,
      role: 'ATTENDANT',
      secretHash: secret,
    ));
    final db = testDb();
    final inventory = InventoryService(db);
    final pairs = <MemoryTransportPair>[];
    final client = SyncClient(
      db: db,
      inventoryService: inventory,
      deviceId: deviceId,
      secretHex: secret,
      enablePing: false,
      backoff: (_) => const Duration(milliseconds: 5),
      connector: () async {
        final pair = MemoryTransportPair();
        pairs.add(pair);
        server.attach(pair.server);
        return pair.client;
      },
    );
    client.start();
    nodes.add((
      db: db,
      inventory: inventory,
      client: client,
      pairs: pairs,
      id: deviceId,
    ));
  }

  // Random walk: writes on random nodes, interleaved with disconnects.
  final writers = <({InventoryService inventory, String id})>[
    (inventory: hubInventory, id: 'hub'),
    for (final n in nodes) (inventory: n.inventory, id: n.id),
  ];
  final opCount = 30 + random.nextInt(30);
  for (var op = 0; op < opCount; op++) {
    final roll = random.nextInt(10);
    if (roll < 8) {
      final writer = writers[random.nextInt(writers.length)];
      final type = random.nextBool()
          ? StockEventType.receive
          : StockEventType.adjust;
      final magnitude = 1 + random.nextInt(9);
      final delta = type == StockEventType.receive
          ? magnitude
          : (random.nextBool() ? magnitude : -magnitude);
      await writer.inventory.recordLocalEvent(
        productId: _products[random.nextInt(_products.length)],
        type: type,
        quantityDelta: delta,
        deviceId: writer.id,
        staffRef: 'admin',
      );
    } else {
      // Sever a random client's current link; backoff redials automatically.
      final node = nodes[random.nextInt(nodes.length)];
      if (node.pairs.isNotEmpty) {
        await node.pairs.last.cut();
      }
    }
    if (random.nextInt(4) == 0) {
      await Future<void>.delayed(Duration(milliseconds: random.nextInt(10)));
    }
  }

  // Convergence: all nodes hold every event and identical projections.
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (true) {
    final hubPending = await hubDb.eventsDao.pending();
    final counts = [
      await hubDb.eventsDao.count(),
      for (final n in nodes) await n.db.eventsDao.count(),
    ];
    final pendings = [
      hubPending.length,
      for (final n in nodes) (await n.db.eventsDao.pending()).length,
    ];
    final allEqual = counts.toSet().length == 1;
    final nonePending = pendings.every((p) => p == 0);
    if (allEqual && nonePending) break;
    if (DateTime.now().isAfter(deadline)) {
      fail('seed $seed did not converge: counts=$counts pending=$pendings');
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }

  Future<Map<String, int>> levelsOf(AppDatabase db) async {
    final rows = await db.projectionDao.getAll();
    return {
      for (final r in rows)
        if (r.quantity != 0) r.productId: r.quantity
    };
  }

  final reference = await levelsOf(hubDb);
  for (final n in nodes) {
    expect(await levelsOf(n.db), reference,
        reason: 'seed $seed: ${n.id} projection diverged');
  }
  // Golden rule (§11): projection == sum(events) everywhere.
  await hubInventory.rebuildProjection();
  expect(await levelsOf(hubDb), reference, reason: 'seed $seed: hub rebuild');
  for (final n in nodes) {
    final before = await levelsOf(n.db);
    await n.inventory.rebuildProjection();
    expect(await levelsOf(n.db), before,
        reason: 'seed $seed: ${n.id} rebuild');
  }

  for (final n in nodes) {
    await n.client.stop();
  }
  await server.shutdown();
  for (final n in nodes) {
    await n.db.close();
  }
  await hubDb.close();
}

void main() {
  for (var seed = 1; seed <= _seedCount; seed++) {
    test('random interleaving converges (seed $seed)', () => _runSeed(seed),
        timeout: const Timeout(Duration(minutes: 2)));
  }
}
