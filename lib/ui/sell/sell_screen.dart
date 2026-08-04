import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/scanner_page.dart';
import '../widgets/sync_status_pill.dart';
import 'cart_controller.dart';
import 'checkout_sheet.dart';

final _sellSearchProvider = StateProvider<String>((ref) => '');

final _sellResultsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = ref.watch(_sellSearchProvider);
  return db.productsDao.watchSearch(query);
});

final _levelsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).projectionDao.watchAllLevels();
});

/// Screen 04 — point of sale. Search or scan, tap to add to cart, cart bar
/// pinned above the bottom nav. Works fully offline; every sale applies
/// locally first (optimistic, §8.4).
class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await ScannerPage.scan(context);
    if (code == null || !mounted) return;
    final db = ref.read(databaseProvider);
    final product = await db.productsDao.getByBarcode(code);
    if (product != null) {
      ref.read(cartProvider.notifier).add(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(seconds: 1),
        ));
      }
    } else {
      _searchController.text = code;
      ref.read(_sellSearchProvider.notifier).state = code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final results = ref.watch(_sellResultsProvider);
    final levels = ref.watch(_levelsProvider).valueOrNull ?? const {};
    final cart = ref.watch(cartProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: Insets.lg),
            child: Center(child: SyncStatusPill()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, Insets.sm, Insets.lg, Insets.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: _scan,
                  icon: const Icon(Icons.barcode_reader),
                  tooltip: 'Scan barcode',
                ),
              ),
              onChanged: (v) =>
                  ref.read(_sellSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load products',
                message: '$e',
              ),
              data: (products) {
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: ref.watch(_sellSearchProvider).isEmpty
                        ? 'No products yet'
                        : 'No products found',
                    message: ref.watch(_sellSearchProvider).isEmpty
                        ? 'Products added on the main phone appear here.'
                        : 'Try a different name, or scan the barcode.',
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.only(
                      bottom: cart.isEmpty ? Insets.lg : 120),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(indent: Insets.lg),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final qty = levels[product.id] ?? 0;
                    final inCart = cart
                        .where((i) => i.product.id == product.id)
                        .fold(0, (s, i) => s + i.quantity);
                    return _ProductRow(
                      product: product,
                      stock: qty,
                      inCart: inCart,
                      currency: currency,
                      onTap: () =>
                          ref.read(cartProvider.notifier).add(product),
                      onIncrement: () => ref
                          .read(cartProvider.notifier)
                          .changeQty(product.id, 1),
                      onDecrement: () {
                        if (inCart <= 1) {
                          ref.read(cartProvider.notifier).remove(product.id);
                        } else {
                          ref
                              .read(cartProvider.notifier)
                              .changeQty(product.id, -1);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: cart.isEmpty
          ? null
          : _CartBar(
              theme: theme,
              currency: currency,
              onCheckout: () => showCheckoutSheet(context),
            ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({
    required this.product,
    required this.stock,
    required this.inCart,
    required this.currency,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int stock;
  final int inCart;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final low = product.lowStockThreshold > 0 &&
        stock <= product.lowStockThreshold;

    return ListTile(
      onTap: inCart == 0 ? onTap : null,
      title: Text(product.name, style: theme.textTheme.bodyLarge),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          children: [
            Text(
              formatKobo(product.sellingPrice, symbol: currency),
              style: theme.textTheme.titleSmall!.copyWith(
                color: theme.colorScheme.primary,
                fontFeatures: tabularFigures,
              ),
            ),
            const SizedBox(width: Insets.md),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Insets.sm, vertical: 2),
              decoration: BoxDecoration(
                color: low
                    ? tokens.warningContainer
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${formatQty(stock)} left',
                style: theme.textTheme.labelSmall!.copyWith(
                  color: low
                      ? tokens.onWarningContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: inCart == 0
          ? IconButton.filledTonal(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded),
            )
          : _QtyStepper(
              quantity: inCart,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$quantity',
            style: theme.textTheme.titleSmall!
                .copyWith(fontFeatures: tabularFigures),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_rounded, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _CartBar extends ConsumerWidget {
  const _CartBar({
    required this.theme,
    required this.currency,
    required this.onCheckout,
  });

  final ThemeData theme;
  final String currency;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: FilledButton(
          onPressed: onCheckout,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Corners.xl),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.md, vertical: Insets.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count ${count == 1 ? 'item' : 'items'}',
                  style: theme.textTheme.labelMedium!
                      .copyWith(color: theme.colorScheme.onPrimary),
                ),
              ),
              const Spacer(),
              Text(
                formatKobo(total, symbol: currency),
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontFeatures: tabularFigures,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Icon(Icons.arrow_forward_rounded,
                  color: theme.colorScheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
