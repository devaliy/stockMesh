import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stockmesh/data/db/database.dart';
import 'package:stockmesh/domain/inventory_service.dart';
import 'package:stockmesh/domain/models/event_type.dart';
import 'package:stockmesh/security/message_auth.dart';
import 'package:stockmesh/sync/client/sync_client.dart';
import 'package:stockmesh/sync/hub/hub_server.dart';
import 'package:stockmesh/sync/protocol/codec.dart';
import 'package:stockmesh/sync/protocol/messages.dart';
import 'package:stockmesh/sync/transport/memory_transport.dart';

import 'helpers/test_db.dart';

/// One simulated node (hub or client) with its own database — mirrors two
/// physical phones exactly, per §11 (sync engine tested without sockets).
class TestNode {
  TestNode(this.db) : inventory = InventoryService(db);

  final AppDatabase db;
  final InventoryService inventory;

  Future<void> dispose() => db.close();
}

class TestCluster {
  TestCluster._(this.hub, this.server);

  final TestNode hub;
  final HubServer server;
  final clients = <TestNode>[];
  final syncClients = <SyncClient>[];
  final pairs = <MemoryTransportPair>[];

  static const productId = 'product-1';
  static const product2Id = 'product-2';

  static Future<TestCluster> create() async {
    final hub = TestNode(testDb());
    for (final id in [productId, product2Id]) {
      await hub.db.productsDao.upsertProduct(ProductsCompanion.insert(
        id: id,
        name: 'Product $id',
        sellingPrice: const Value(1500),
        updatedAt: 1,
      ));
    }
    await hub.db.staffDao.upsertStaff(StaffCompanion.insert(
      staffRef: 'admin',
      displayName: 'Admin',
      pinHash: 'salt:hash',
      isAdmin: const Value(true),
      updatedAt: 1,
    ));
    final server = HubServer(db: hub.db);
    server.start();
    return TestCluster._(hub, server);
  }

  /// Registers a device on the hub and builds a client node whose connector
  /// dials a fresh memory pipe into the hub server.
  Future<(TestNode, SyncClient)> addClient(String deviceId,
      {String? secret}) async {
    final deviceSecret = secret ?? MessageAuth.randomSecretHex();
    await hub.db.devicesDao.upsertDevice(DevicesCompanion.insert(
      deviceId: deviceId,
      displayName: deviceId,
      role: 'ATTENDANT',
      secretHash: deviceSecret,
    ));

    final node = TestNode(testDb());
    // Clients receive reference data via CATCH_UP — no seeding.
    final client = SyncClient(
      db: node.db,
      inventoryService: node.inventory,
      deviceId: deviceId,
      secretHex: deviceSecret,
      enablePing: false,
      backoff: (_) => const Duration(milliseconds: 10),
      connector: () async {
        final pair = MemoryTransportPair();
        pairs.add(pair);
        server.attach(pair.server);
        return pair.client;
      },
    );
    clients.add(node);
    syncClients.add(client);
    return (node, client);
  }

  Future<void> dispose() async {
    for (final c in syncClients) {
      await c.stop();
    }
    await server.shutdown();
    for (final c in clients) {
      await c.dispose();
    }
    await hub.dispose();
  }
}

/// Polls until [condition] is true (real async work is involved — drift
/// streams, microtask-scheduled transports).
Future<void> eventually(Future<bool> Function() condition,
    {Duration timeout = const Duration(seconds: 5)}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condition not reached within $timeout');
}

Future<Map<String, int>> levels(AppDatabase db) async {
  final rows = await db.projectionDao.getAll();
  return {for (final r in rows) r.productId: r.quantity};
}

Future<void> expectConverged(List<TestNode> nodes) async {
  final reference = await levels(nodes.first.db);
  for (final node in nodes.skip(1)) {
    expect(await levels(node.db), reference,
        reason: 'all nodes must hold identical projections');
  }
  for (final node in nodes) {
    final before = await levels(node.db);
    await node.inventory.rebuildProjection();
    expect(await levels(node.db), before,
        reason: 'projection must equal sum of events on every node');
  }
}

void main() {
  late TestCluster cluster;

  setUp(() async {
    cluster = await TestCluster.create();
  });

  tearDown(() async => cluster.dispose());

  test('M3(a): event submitted by C1 appears at C2 with hub_seq', () async {
    final (c1, s1) = await cluster.addClient('client-1');
    final (c2, s2) = await cluster.addClient('client-2');
    s1.start();
    s2.start();
    await s1.untilLive();
    await s2.untilLive();

    // C1 sells 3 units (local optimistic write → outbox → hub).
    final result = await c1.inventory.recordLocalEvent(
      productId: TestCluster.productId,
      type: StockEventType.sale,
      quantityDelta: -3,
      deviceId: 'client-1',
      staffRef: 'admin',
    );
    expect(result.isOk, isTrue);

    await eventually(() async {
      final events = await c2.db.eventsDao.allEvents();
      return events.any((e) =>
          e.productId == TestCluster.productId &&
          e.quantityDelta == -3 &&
          e.hubSeq != null);
    });

    // The originating client's copy got its hub_seq via EVENT_ACCEPT.
    await eventually(() async {
      final pending = await c1.db.eventsDao.pending();
      return pending.isEmpty;
    });
    await expectConverged([cluster.hub, c1, c2]);
  });

  test('M3(b): client offline during 50 events reconnects and converges',
      () async {
    final (c1, s1) = await cluster.addClient('client-1');
    final (c2, s2) = await cluster.addClient('client-2');
    s1.start();
    s2.start();
    await s1.untilLive();
    await s2.untilLive();

    // C2 drops off the network.
    await cluster.pairs.last.cut();

    // 50 events land on the hub while C2 is away.
    for (var i = 0; i < 50; i++) {
      final result = await cluster.hub.inventory.recordLocalEvent(
        productId:
            i.isEven ? TestCluster.productId : TestCluster.product2Id,
        type: StockEventType.receive,
        quantityDelta: 1 + (i % 5),
        deviceId: 'hub',
        staffRef: 'admin',
      );
      expect(result.isOk, isTrue);
    }
    await eventually(() async =>
        (await cluster.hub.db.eventsDao.pending()).isEmpty);

    // C2 reconnects (its client is still running; backoff redials).
    await eventually(() async {
      final hubCount = await cluster.hub.db.eventsDao.count();
      final c2Count = await c2.db.eventsDao.count();
      return hubCount == c2Count && hubCount >= 50;
    }, timeout: const Duration(seconds: 10));

    await expectConverged([cluster.hub, c1, c2]);
  });

  test('M3(c): dropped ACK + resubmit → no duplicate, same hub_seq',
      () async {
    final (c1, s1) = await cluster.addClient('client-1');
    s1.start();
    await s1.untilLive();

    // Submit an event manually with the ACK path severed, then again with
    // it restored — simulating "C1 submits, ACK dropped, C1 resubmits".
    final pair = cluster.pairs.last;
    final event = WireEvent(
      eventId: 'evt-dropped-ack',
      productId: TestCluster.productId,
      eventType: 'RECEIVE',
      quantityDelta: 7,
      deviceId: 'client-1',
      staffRef: 'admin',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final secret = (await cluster.hub.db.devicesDao.getById('client-1'))!
        .secretHash;
    String frame() => Codec.encode(
          type: MsgType.eventSubmit,
          deviceId: 'client-1',
          payload: EventSubmitPayload(events: [event]).toJson(),
          secretHex: secret,
        );

    pair.dropToClient = true; // hub's EVENT_ACCEPT vanishes
    pair.client.send(frame());
    await eventually(() async =>
        (await cluster.hub.db.eventsDao.getById('evt-dropped-ack')) != null);
    final firstSeq = (await cluster.hub.db.eventsDao
            .getById('evt-dropped-ack'))!
        .hubSeq;
    expect(firstSeq, isNotNull);

    pair.dropToClient = false;
    pair.client.send(frame()); // resubmit

    await Future<void>.delayed(const Duration(milliseconds: 200));
    final events = await cluster.hub.db.eventsDao.allEvents();
    expect(events.where((e) => e.eventId == 'evt-dropped-ack'), hasLength(1),
        reason: 'resubmit must not duplicate');
    expect(
        (await cluster.hub.db.eventsDao.getById('evt-dropped-ack'))!.hubSeq,
        firstSeq,
        reason: 'resubmit must return the original hub_seq');
    expect(
        await cluster.hub.db.projectionDao
            .quantityOf(TestCluster.productId),
        7,
        reason: 'delta applied exactly once');
  });

  test(
      'M3(d): interleaved concurrent submits → gapless hub_seq, identical projections',
      () async {
    final (c1, s1) = await cluster.addClient('client-1');
    final (c2, s2) = await cluster.addClient('client-2');
    s1.start();
    s2.start();
    await s1.untilLive();
    await s2.untilLive();

    // Both clients write concurrently, interleaved.
    final futures = <Future<void>>[];
    for (var i = 0; i < 20; i++) {
      futures.add(c1.inventory
          .recordLocalEvent(
            productId: TestCluster.productId,
            type: StockEventType.receive,
            quantityDelta: 2,
            deviceId: 'client-1',
            staffRef: 'admin',
          )
          .then((_) {}));
      futures.add(c2.inventory
          .recordLocalEvent(
            productId: TestCluster.product2Id,
            type: StockEventType.receive,
            quantityDelta: 3,
            deviceId: 'client-2',
            staffRef: 'admin',
          )
          .then((_) {}));
    }
    await Future.wait(futures);

    await eventually(() async {
      final c1Pending = await c1.db.eventsDao.pending();
      final c2Pending = await c2.db.eventsDao.pending();
      final hubCount = await cluster.hub.db.eventsDao.count();
      final c1Count = await c1.db.eventsDao.count();
      final c2Count = await c2.db.eventsDao.count();
      return c1Pending.isEmpty &&
          c2Pending.isEmpty &&
          hubCount == 40 &&
          c1Count == 40 &&
          c2Count == 40;
    }, timeout: const Duration(seconds: 10));

    // Gapless, total order 1..40 on the hub (invariant §1.2).
    final seqs = (await cluster.hub.db.eventsDao.allEvents())
        .map((e) => e.hubSeq)
        .whereType<int>()
        .toList()
      ..sort();
    expect(seqs, List.generate(40, (i) => i + 1));

    await expectConverged([cluster.hub, c1, c2]);
    expect(await cluster.hub.db.projectionDao
        .quantityOf(TestCluster.productId), 40);
    expect(await cluster.hub.db.projectionDao
        .quantityOf(TestCluster.product2Id), 60);
  });

  test('M3(e): revoked device HELLO is rejected', () async {
    final (c1, s1) = await cluster.addClient('client-1');
    await cluster.hub.db.devicesDao.revoke('client-1');

    var revoked = false;
    final client = SyncClient(
      db: c1.db,
      inventoryService: c1.inventory,
      deviceId: s1.deviceId,
      secretHex: s1.secretHex,
      enablePing: false,
      backoff: (_) => const Duration(milliseconds: 10),
      onRevoked: () => revoked = true,
      connector: () async {
        final pair = MemoryTransportPair();
        cluster.pairs.add(pair);
        cluster.server.attach(pair.server);
        return pair.client;
      },
    );
    client.start();

    await eventually(() async => revoked);
    expect(client.state, ClientState.disconnected);
    await client.stop();
  });

  test('wrong secret is rejected with BAD_AUTH and nothing leaks', () async {
    final (c1, _) = await cluster.addClient('client-1');

    final imposter = SyncClient(
      db: c1.db,
      inventoryService: c1.inventory,
      deviceId: 'client-1',
      secretHex: MessageAuth.randomSecretHex(), // not the registered secret
      enablePing: false,
      backoff: (_) => const Duration(milliseconds: 50),
      connector: () async {
        final pair = MemoryTransportPair();
        cluster.pairs.add(pair);
        cluster.server.attach(pair.server);
        return pair.client;
      },
    );
    imposter.start();

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(imposter.state, isNot(ClientState.live));
    expect(await c1.db.eventsDao.count(), 0,
        reason: 'no CATCH_UP data may reach an unauthenticated device');
    await imposter.stop();
  });

  test('tampered frame is dropped silently (flip one byte)', () async {
    final (_, s1) = await cluster.addClient('client-1');
    s1.start();
    await s1.untilLive();

    final pair = cluster.pairs.last;
    final secret =
        (await cluster.hub.db.devicesDao.getById('client-1'))!.secretHash;
    final legit = Codec.encode(
      type: MsgType.eventSubmit,
      deviceId: 'client-1',
      payload: EventSubmitPayload(events: [
        WireEvent(
          eventId: 'evt-tampered',
          productId: TestCluster.productId,
          eventType: 'RECEIVE',
          quantityDelta: 5,
          deviceId: 'client-1',
          staffRef: 'admin',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        )
      ]).toJson(),
      secretHex: secret,
    );
    // Flip the delta 5 → 9 without recomputing the MAC.
    final tampered = legit.replaceFirst('"quantity_delta":5', '"quantity_delta":9');
    expect(tampered, isNot(legit));
    pair.client.send(tampered);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(await cluster.hub.db.eventsDao.getById('evt-tampered'), isNull,
        reason: 'MAC failure must drop the frame');
  });

  test('REF_UPDATE: product edits on the hub reach live clients', () async {
    final (c1, s1) = await cluster.addClient('client-1');
    s1.start();
    await s1.untilLive();

    await eventually(() async =>
        (await c1.db.productsDao.getById(TestCluster.productId)) != null);

    await cluster.hub.db.productsDao.upsertProduct(ProductsCompanion(
      id: const Value(TestCluster.productId),
      name: const Value('Renamed Product'),
      sellingPrice: const Value(9900),
      unit: const Value('pcs'),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));

    await eventually(() async {
      final p = await c1.db.productsDao.getById(TestCluster.productId);
      return p?.name == 'Renamed Product' && p?.sellingPrice == 9900;
    });
  });
}
