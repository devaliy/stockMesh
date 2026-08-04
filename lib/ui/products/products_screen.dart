import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pin_pad.dart';
import '../widgets/sync_status_pill.dart';

final _productSearchProvider = StateProvider<String>((ref) => '');

final _productListProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.productsDao.watchSearch(ref.watch(_productSearchProvider));
});

final _levelsProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(databaseProvider).projectionDao.watchAllLevels();
});

/// Screen 06 — inventory list. Reactive drift stream; low-stock rows get the
/// amber badge. Adding/editing products is Hub + admin only (invariant §1.5).
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final products = ref.watch(_productListProvider);
    final levels = ref.watch(_levelsProvider).valueOrNull ?? const {};
    final currency = ref.watch(currencyProvider);
    final isHub = ref.watch(bootstrapProvider).valueOrNull?.isHub ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: Insets.lg),
            child: Center(child: SyncStatusPill()),
          ),
        ],
      ),
      floatingActionButton: isHub
          ? FloatingActionButton.extended(
              onPressed: () async {
                final staff = await verifyStaffPin(context, ref,
                    title: 'Admin PIN required', requireAdmin: true);
                if (staff != null && context.mounted) {
                  context.go('/products/add');
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, Insets.sm, Insets.lg, Insets.md),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, SKU or barcode…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) =>
                  ref.read(_productSearchProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: products.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load products',
                message: '$e',
              ),
              data: (list) {
                if (list.isEmpty) {
                  final searching =
                      ref.watch(_productSearchProvider).isNotEmpty;
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title:
                        searching ? 'No products found' : 'No products yet',
                    message: searching
                        ? 'Check the spelling or scan the item instead.'
                        : isHub
                            ? 'Add your first product to start selling.'
                            : 'Products added on the main phone appear here automatically.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(indent: Insets.lg),
                  itemBuilder: (context, index) {
                    final product = list[index];
                    final qty = levels[product.id] ?? 0;
                    final low = product.lowStockThreshold > 0 &&
                        qty <= product.lowStockThreshold;
                    final tokens = StockMeshTokens.of(context);
                    return ListTile(
                      onTap: () => context.go('/products/${product.id}'),
                      title: Text(product.name,
                          style: theme.textTheme.bodyLarge),
                      subtitle: product.sku == null && product.barcode == null
                          ? null
                          : Text(
                              [
                                if (product.sku != null) 'SKU ${product.sku}',
                                if (product.barcode != null) product.barcode!,
                              ].join(' · '),
                              style: theme.textTheme.bodySmall!.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatKobo(product.sellingPrice, symbol: currency),
                            style: theme.textTheme.titleSmall!
                                .copyWith(fontFeatures: tabularFigures),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Insets.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: low
                                  ? tokens.warningContainer
                                  : theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (low) ...[
                                  Icon(Icons.warning_amber_rounded,
                                      size: 12,
                                      color: tokens.onWarningContainer),
                                  const SizedBox(width: 2),
                                ],
                                Text(
                                  '${formatQty(qty)} ${product.unit}',
                                  style:
                                      theme.textTheme.labelSmall!.copyWith(
                                    color: low
                                        ? tokens.onWarningContainer
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontFeatures: tabularFigures,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
