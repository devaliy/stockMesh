import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../domain/models/event_type.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pin_pad.dart';

final _productProvider =
    StreamProvider.family<Product?, String>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.productsDao.watchSearch('').map((products) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  });
});

final _qtyProvider = StreamProvider.family<int, String>((ref, id) {
  return ref.watch(databaseProvider).projectionDao.watchQuantity(id);
});

final _historyProvider =
    FutureProvider.family<List<StockEvent>, String>((ref, id) async {
  final db = ref.watch(databaseProvider);
  final events = await db.customSelect(
    'SELECT * FROM stock_events WHERE product_id = ? '
    'ORDER BY created_at DESC LIMIT 50',
    variables: [Variable.withString(id)],
    readsFrom: {db.stockEvents},
  ).get();
  return events
      .map((row) => db.stockEvents.map(row.data))
      .toList(growable: false);
});

/// Product detail: identity card, live stock figure, movement history from
/// the event log (the log IS the audit trail — invariant §1.1).
class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final product = ref.watch(_productProvider(productId)).valueOrNull;
    final qty = ref.watch(_qtyProvider(productId)).valueOrNull ?? 0;
    final history = ref.watch(_historyProvider(productId));
    final currency = ref.watch(currencyProvider);
    final isHub = ref.watch(bootstrapProvider).valueOrNull?.isHub ?? false;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
            icon: Icons.inventory_2_outlined, title: 'Product not found'),
      );
    }

    final low = product.lowStockThreshold > 0 &&
        qty <= product.lowStockThreshold;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (isHub)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () async {
                final staff = await verifyStaffPin(context, ref,
                    title: 'Admin PIN required', requireAdmin: true);
                if (staff != null && context.mounted) {
                  context.go('/products/${product.id}/edit');
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Column(
                children: [
                  Text(
                    formatQty(qty),
                    style: theme.textTheme.displayLarge!.copyWith(
                      color: low ? tokens.warning : theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '${product.unit} in stock',
                    style: theme.textTheme.labelMedium!
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (low) ...[
                    const SizedBox(height: Insets.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.md, vertical: Insets.xs),
                      decoration: BoxDecoration(
                        color: tokens.warningContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'LOW STOCK — reorder at ${product.lowStockThreshold}',
                        style: theme.textTheme.labelSmall!
                            .copyWith(color: tokens.onWarningContainer),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Column(
                children: [
                  _InfoRow(
                      label: 'Selling price',
                      value:
                          formatKobo(product.sellingPrice, symbol: currency)),
                  _InfoRow(
                      label: 'Cost price',
                      value: formatKobo(product.costPrice, symbol: currency)),
                  if (product.sku != null)
                    _InfoRow(label: 'SKU', value: product.sku!),
                  if (product.barcode != null)
                    _InfoRow(label: 'Barcode', value: product.barcode!),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.xxl),
          Text('MOVEMENT',
              style: theme.textTheme.labelSmall!
                  .copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Insets.sm),
          history.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e'),
            data: (events) => events.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(Insets.xl),
                    child: Text(
                      'No stock movement yet.',
                      style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Card(
                    child: Column(
                      children: [
                        for (final e in events) _EventRow(event: e),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value,
              style: theme.textTheme.titleSmall!
                  .copyWith(fontFeatures: tabularFigures)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final StockEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final type = StockEventType.fromWire(event.eventType);
    final positive = event.quantityDelta > 0;
    final pending = event.hubSeq == null;
    final when = DateTime.fromMillisecondsSinceEpoch(event.createdAt);

    final (icon, label) = switch (type) {
      StockEventType.sale => (Icons.point_of_sale_rounded, 'Sale'),
      StockEventType.receive => (Icons.move_to_inbox_rounded, 'Received'),
      StockEventType.adjust => (Icons.tune_rounded, 'Adjustment'),
      StockEventType.countAdjust => (Icons.fact_check_rounded, 'Count'),
      StockEventType.saleReturn => (Icons.keyboard_return_rounded, 'Return'),
      StockEventType.transferOut => (Icons.outbox_rounded, 'Transfer out'),
      StockEventType.damage => (Icons.dangerous_outlined, 'Damage'),
      null => (Icons.help_outline_rounded, event.eventType),
    };

    return ListTile(
      dense: true,
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        '${when.day}/${when.month}/${when.year} '
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}'
        ' · ${event.staffRef}',
        style: theme.textTheme.bodySmall!
            .copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pending)
            Padding(
              padding: const EdgeInsets.only(right: Insets.xs),
              child: Icon(Icons.schedule_rounded,
                  size: 14,
                  color: theme.colorScheme.outline.withValues(alpha: 0.7)),
            ),
          Text(
            '${positive ? '+' : ''}${formatQty(event.quantityDelta)}',
            style: theme.textTheme.titleSmall!.copyWith(
              color: positive ? tokens.success : theme.colorScheme.error,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
