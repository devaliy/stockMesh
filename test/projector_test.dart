import 'dart:math';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:stockmesh/data/db/database.dart';
import 'package:stockmesh/domain/inventory_service.dart';
import 'package:stockmesh/domain/models/event_type.dart';
import 'package:stockmesh/domain/sales_service.dart';

import 'helpers/test_db.dart';

Future<List<String>> seedProducts(AppDatabase db, int count) async {
  final ids = <String>[];
  for (var i = 0; i < count; i++) {
    final id = 'product-$i';
    ids.add(id);
    await db.productsDao.upsertProduct(ProductsCompanion.insert(
      id: id,
      name: 'Product $i',
      sellingPrice: Value(1000 + i * 100),
      updatedAt: 1,
    ));
  }
  return ids;
}

Future<Map<String, int>> levelsOf(AppDatabase db) async {
  final rows = await db.projectionDao.getAll();
  return {for (final r in rows) r.productId: r.quantity};
}

Future<Map<String, int>> sumsFromEvents(AppDatabase db) async {
  final events = await db.eventsDao.allEvents();
  final sums = <String, int>{};
  for (final e in events) {
    sums[e.productId] = (sums[e.productId] ?? 0) + e.quantityDelta;
  }
  return sums;
}

void main() {
  late AppDatabase db;
  late InventoryService inventory;

  setUp(() {
    db = testDb();
    inventory = InventoryService(db);
  });

  tearDown(() async => db.close());

  test('M1(a): N random events then rebuild yields identical stock_levels',
      () async {
    final products = await seedProducts(db, 5);
    final random = Random(42);
    final types = [
      StockEventType.receive,
      StockEventType.sale,
      StockEventType.adjust,
      StockEventType.damage,
      StockEventType.saleReturn,
    ];

    for (var i = 0; i < 200; i++) {
      final type = types[random.nextInt(types.length)];
      final magnitude = random.nextInt(20) + 1;
      final delta = switch (type.sign) {
        DeltaSign.positive => magnitude,
        DeltaSign.negative => -magnitude,
        DeltaSign.any => random.nextBool() ? magnitude : -magnitude,
      };
      final result = await inventory.recordLocalEvent(
        productId: products[random.nextInt(products.length)],
        type: type,
        quantityDelta: delta,
        deviceId: 'device-1',
        staffRef: 'admin',
      );
      expect(result.isOk, isTrue);
    }

    final before = await levelsOf(db);
    expect(before, await sumsFromEvents(db),
        reason: 'incremental projection must equal sum of deltas');

    await inventory.rebuildProjection();
    expect(await levelsOf(db), before,
        reason: 'rebuild must reproduce the incremental projection exactly');
  });

  test('M1(b): double-applying the same event_id is a no-op', () async {
    final products = await seedProducts(db, 1);

    final first = await inventory.recordLocalEvent(
      productId: products[0],
      type: StockEventType.receive,
      quantityDelta: 10,
      deviceId: 'device-1',
      staffRef: 'admin',
      eventId: 'fixed-event-id',
    );
    expect(first.isOk, isTrue);

    final second = await inventory.recordLocalEvent(
      productId: products[0],
      type: StockEventType.receive,
      quantityDelta: 10,
      deviceId: 'device-1',
      staffRef: 'admin',
      eventId: 'fixed-event-id',
    );
    expect(second.isOk, isTrue);

    expect(await db.eventsDao.count(), 1);
    expect(await db.projectionDao.quantityOf(products[0]), 10);

    // Same guarantee for the remote-apply path (CATCH_UP replays, dropped
    // ACK resubmits).
    final event = (await db.eventsDao.allEvents()).single;
    final sequenced = event.copyWith(hubSeq: const Value(7));
    await inventory.applyRemoteEvents([sequenced]);
    await inventory.applyRemoteEvents([sequenced]);

    expect(await db.eventsDao.count(), 1);
    expect(await db.projectionDao.quantityOf(products[0]), 10);
    expect((await db.eventsDao.getById('fixed-event-id'))!.hubSeq, 7,
        reason: 're-apply of a known event only fills in hub_seq');
  });

  test('event type sign rules are enforced', () async {
    final products = await seedProducts(db, 1);

    Future<bool> ok(StockEventType type, int delta) async {
      final r = await inventory.recordLocalEvent(
        productId: products[0],
        type: type,
        quantityDelta: delta,
        deviceId: 'd',
        staffRef: 's',
      );
      return r.isOk;
    }

    expect(await ok(StockEventType.sale, 5), isFalse);
    expect(await ok(StockEventType.sale, -5), isTrue);
    expect(await ok(StockEventType.receive, -5), isFalse);
    expect(await ok(StockEventType.receive, 5), isTrue);
    expect(await ok(StockEventType.adjust, 0), isFalse);
    expect(await ok(StockEventType.damage, -2), isTrue);

    final unknown = await inventory.recordLocalEvent(
      productId: 'missing-product',
      type: StockEventType.receive,
      quantityDelta: 1,
      deviceId: 'd',
      staffRef: 's',
    );
    expect(unknown.isOk, isFalse);
  });

  test('checkout groups lines under one receipt with negative deltas',
      () async {
    final products = await seedProducts(db, 3);
    for (final id in products) {
      await inventory.recordLocalEvent(
        productId: id,
        type: StockEventType.receive,
        quantityDelta: 50,
        deviceId: 'd',
        staffRef: 's',
      );
    }

    final sales = SalesService(db, inventory);
    final result = await sales.checkout(
      lines: [
        CartLine(productId: products[0], quantity: 2, unitPrice: 1000),
        CartLine(productId: products[1], quantity: 1, unitPrice: 1100),
        CartLine(productId: products[2], quantity: 4, unitPrice: 1200),
      ],
      deviceId: 'device-1',
      staffRef: 'admin',
    );
    expect(result.isOk, isTrue);

    final receiptId = result.requireValue;
    final lines = await db.eventsDao.byReceipt(receiptId);
    expect(lines, hasLength(3));
    for (final line in lines) {
      expect(line.eventType, 'SALE');
      expect(line.quantityDelta, isNegative);
      expect(line.hubSeq, isNull, reason: 'local events await sequencing');
    }
    expect(await db.projectionDao.quantityOf(products[0]), 48);
    expect(await db.projectionDao.quantityOf(products[2]), 46);
  });

  test('recordCount emits COUNT_ADJUST closing the variance', () async {
    final products = await seedProducts(db, 1);
    await inventory.recordLocalEvent(
      productId: products[0],
      type: StockEventType.receive,
      quantityDelta: 60,
      deviceId: 'd',
      staffRef: 's',
    );

    final result = await inventory.recordCount(
      productId: products[0],
      countedQty: 57,
      deviceId: 'd',
      staffRef: 'admin',
    );
    expect(result.isOk, isTrue);
    final event = result.requireValue!;
    expect(event.eventType, 'COUNT_ADJUST');
    expect(event.quantityDelta, -3);
    expect(event.note, contains('counted=57'));
    expect(event.note, contains('expected=60'));
    expect(await db.projectionDao.quantityOf(products[0]), 57);

    // Matching count produces no event at all.
    final noop = await inventory.recordCount(
      productId: products[0],
      countedQty: 57,
      deviceId: 'd',
      staffRef: 'admin',
    );
    expect(noop.isOk, isTrue);
    expect(noop.requireValue, isNull);
  });
}
