import '../core/ids.dart';
import '../core/result.dart';
import '../data/db/database.dart';
import 'inventory_service.dart';
import 'models/event_type.dart';

/// One line of a cart about to be checked out.
class CartLine {
  const CartLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final int quantity; // positive count of units sold
  final int unitPrice; // kobo per unit at time of sale

  int get lineTotal => quantity * unitPrice;
}

/// Turns a cart into SALE events: one shared receipt_id, one event per line
/// (design.md §8.3 screen 04). All lines commit atomically; each line's
/// delta is negative-quantity by construction.
class SalesService {
  SalesService(this._db, this._inventory);

  final AppDatabase _db;
  final InventoryService _inventory;

  /// Returns the receipt_id on success. Fails as one unit — a bad line rolls
  /// back the whole receipt.
  Future<Result<String>> checkout({
    required List<CartLine> lines,
    required String deviceId,
    required String staffRef,
  }) async {
    if (lines.isEmpty) return const Err('Cart is empty');
    for (final line in lines) {
      if (line.quantity <= 0) return const Err('Quantities must be positive');
    }
    final receiptId = newId();
    try {
      await _db.transaction(() async {
        for (final line in lines) {
          final result = await _inventory.recordLocalEvent(
            productId: line.productId,
            type: StockEventType.sale,
            quantityDelta: -line.quantity,
            unitPrice: line.unitPrice,
            receiptId: receiptId,
            deviceId: deviceId,
            staffRef: staffRef,
          );
          if (!result.isOk) {
            throw _CheckoutAbort((result as Err).message);
          }
        }
      });
    } on _CheckoutAbort catch (abort) {
      return Err(abort.message);
    }
    return Ok(receiptId);
  }
}

class _CheckoutAbort implements Exception {
  _CheckoutAbort(this.message);
  final String message;
}
