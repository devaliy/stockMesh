import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../domain/sales_service.dart';

/// One product in the cart, at the price captured when it was added
/// (price edits mid-sale don't retro-change a cart).
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get lineTotal => product.sellingPrice * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  void add(Product product) {
    final index = state.indexWhere((i) => i.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      changeQty(product.id, 1);
    }
  }

  void changeQty(String productId, int delta) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          if (item.quantity + delta > 0)
            item.copyWith(quantity: item.quantity + delta)
          else
            item // steppers never drop below 1; use remove()
        else
          item
    ];
  }

  void remove(String productId) {
    state = state.where((i) => i.product.id != productId).toList();
  }

  void clear() => state = const [];

  List<CartLine> toLines() => [
        for (final item in state)
          CartLine(
            productId: item.product.id,
            quantity: item.quantity,
            unitPrice: item.product.sellingPrice,
          )
      ];
}

final cartProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

final cartTotalProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.lineTotal);
});

final cartCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});
