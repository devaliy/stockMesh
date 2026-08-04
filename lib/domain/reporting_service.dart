import 'package:drift/drift.dart';

import '../data/db/database.dart';

/// Aggregates for the Reports screen. All queries read the event log —
/// reports are projections too, so they need no extra bookkeeping and are
/// reactive via drift's stream queries.
class ReportingService {
  ReportingService(this._db);

  final AppDatabase _db;

  /// Sales summary between [fromMs, toMs) using SALE minus RETURN.
  /// created_at is a display timestamp; ranges are for humans, so this is
  /// the one place clock-derived values are acceptable (never for sync).
  Stream<SalesSummary> watchSalesSummary(int fromMs, int toMs) {
    final query = _db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN event_type = 'SALE'
          THEN -quantity_delta * COALESCE(unit_price, 0) ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN event_type = 'RETURN'
          THEN quantity_delta * COALESCE(unit_price, 0) ELSE 0 END), 0)
          AS revenue,
        COALESCE(SUM(CASE WHEN event_type = 'SALE'
          THEN -quantity_delta ELSE 0 END), 0) AS units,
        COUNT(DISTINCT CASE WHEN event_type = 'SALE'
          THEN receipt_id END) AS receipts
      FROM stock_events
      WHERE created_at >= ? AND created_at < ?
      ''',
      variables: [Variable.withInt(fromMs), Variable.withInt(toMs)],
      readsFrom: {_db.stockEvents},
    );
    return query.watchSingle().map((row) => SalesSummary(
          revenueKobo: row.read<int>('revenue'),
          unitsSold: row.read<int>('units'),
          receiptCount: row.read<int>('receipts'),
        ));
  }

  Stream<List<ProductSales>> watchTopProducts(int fromMs, int toMs,
      {int limit = 5}) {
    final query = _db.customSelect(
      '''
      SELECT p.id, p.name,
        SUM(-e.quantity_delta) AS units,
        SUM(-e.quantity_delta * COALESCE(e.unit_price, 0)) AS revenue
      FROM stock_events e JOIN products p ON p.id = e.product_id
      WHERE e.event_type = 'SALE' AND e.created_at >= ? AND e.created_at < ?
      GROUP BY p.id, p.name
      ORDER BY revenue DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withInt(fromMs),
        Variable.withInt(toMs),
        Variable.withInt(limit),
      ],
      readsFrom: {_db.stockEvents, _db.products},
    );
    return query.watch().map((rows) => [
          for (final row in rows)
            ProductSales(
              productId: row.read<String>('id'),
              name: row.read<String>('name'),
              unitsSold: row.read<int>('units'),
              revenueKobo: row.read<int>('revenue'),
            )
        ]);
  }

  Stream<List<StaffSales>> watchStaffSales(int fromMs, int toMs) {
    final query = _db.customSelect(
      '''
      SELECT e.staff_ref, COALESCE(s.display_name, e.staff_ref) AS name,
        SUM(-e.quantity_delta * COALESCE(e.unit_price, 0)) AS revenue,
        COUNT(DISTINCT e.receipt_id) AS receipts
      FROM stock_events e LEFT JOIN staff s ON s.staff_ref = e.staff_ref
      WHERE e.event_type = 'SALE' AND e.created_at >= ? AND e.created_at < ?
      GROUP BY e.staff_ref ORDER BY revenue DESC
      ''',
      variables: [Variable.withInt(fromMs), Variable.withInt(toMs)],
      readsFrom: {_db.stockEvents, _db.staff},
    );
    return query.watch().map((rows) => [
          for (final row in rows)
            StaffSales(
              staffRef: row.read<String>('staff_ref'),
              name: row.read<String>('name'),
              revenueKobo: row.read<int>('revenue'),
              receiptCount: row.read<int>('receipts'),
            )
        ]);
  }

  /// Active products at or below their low-stock threshold.
  Stream<List<LowStockItem>> watchLowStock() {
    final query = _db.customSelect(
      '''
      SELECT p.id, p.name, p.low_stock_threshold,
        COALESCE(l.quantity, 0) AS quantity
      FROM products p LEFT JOIN stock_levels l ON l.product_id = p.id
      WHERE p.is_active = 1 AND p.low_stock_threshold > 0
        AND COALESCE(l.quantity, 0) <= p.low_stock_threshold
      ORDER BY quantity ASC
      ''',
      readsFrom: {_db.products, _db.stockLevels},
    );
    return query.watch().map((rows) => [
          for (final row in rows)
            LowStockItem(
              productId: row.read<String>('id'),
              name: row.read<String>('name'),
              quantity: row.read<int>('quantity'),
              threshold: row.read<int>('low_stock_threshold'),
            )
        ]);
  }

  /// Inventory valuation at cost price — dashboard "stock value" card.
  Stream<int> watchStockValueKobo() {
    final query = _db.customSelect(
      '''
      SELECT COALESCE(SUM(l.quantity * p.cost_price), 0) AS value
      FROM stock_levels l JOIN products p ON p.id = l.product_id
      WHERE p.is_active = 1 AND l.quantity > 0
      ''',
      readsFrom: {_db.products, _db.stockLevels},
    );
    return query.watchSingle().map((row) => row.read<int>('value'));
  }

  /// CSV of sales lines in the range — exported via share sheet.
  Future<String> salesCsv(int fromMs, int toMs) async {
    final events = await _db.eventsDao.inCreatedRange(fromMs, toMs);
    final products = {for (final p in await _db.productsDao.getAll()) p.id: p};
    final buffer = StringBuffer(
        'created_at,receipt_id,product,event_type,quantity,unit_price_kobo,line_total_kobo,staff_ref,device_id\r\n');
    for (final e in events) {
      final name = _csvEscape(products[e.productId]?.name ?? e.productId);
      final qty = -e.quantityDelta;
      final price = e.unitPrice ?? 0;
      if (e.eventType != 'SALE' && e.eventType != 'RETURN') continue;
      buffer.write(DateTime.fromMillisecondsSinceEpoch(e.createdAt)
          .toIso8601String());
      buffer.write(',${e.receiptId ?? ''},$name,${e.eventType},'
          '$qty,$price,${qty * price},${_csvEscape(e.staffRef)},'
          '${_csvEscape(e.deviceId)}\r\n');
    }
    return buffer.toString();
  }

  String _csvEscape(String value) {
    if (value.contains(RegExp(r'[",\r\n]'))) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class SalesSummary {
  const SalesSummary({
    required this.revenueKobo,
    required this.unitsSold,
    required this.receiptCount,
  });

  final int revenueKobo;
  final int unitsSold;
  final int receiptCount;

  static const empty = SalesSummary(revenueKobo: 0, unitsSold: 0, receiptCount: 0);
}

class ProductSales {
  const ProductSales({
    required this.productId,
    required this.name,
    required this.unitsSold,
    required this.revenueKobo,
  });

  final String productId;
  final String name;
  final int unitsSold;
  final int revenueKobo;
}

class StaffSales {
  const StaffSales({
    required this.staffRef,
    required this.name,
    required this.revenueKobo,
    required this.receiptCount,
  });

  final String staffRef;
  final String name;
  final int revenueKobo;
  final int receiptCount;
}

class LowStockItem {
  const LowStockItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.threshold,
  });

  final String productId;
  final String name;
  final int quantity;
  final int threshold;
}
