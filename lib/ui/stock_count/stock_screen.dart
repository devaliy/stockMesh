import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/reporting_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/sync_status_pill.dart';

final _lowStockProvider = StreamProvider<List<LowStockItem>>(
    (ref) => ref.watch(reportingServiceProvider).watchLowStock());

/// The Stock tab — entry points for receiving, counting, and a live
/// low-stock watchlist.
class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final lowStock = ref.watch(_lowStockProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: Insets.lg),
            child: Center(child: SyncStatusPill()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.move_to_inbox_rounded,
                  label: 'Receive stock',
                  color: theme.colorScheme.primary,
                  onTap: () => context.go('/stock/receive'),
                ),
              ),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: _ActionCard(
                  icon: Icons.fact_check_rounded,
                  label: 'Stock count',
                  color: theme.colorScheme.secondary,
                  onTap: () => context.go('/stock/count'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xxl),
          Text('LOW STOCK',
              style: theme.textTheme.labelSmall!
                  .copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Insets.sm),
          lowStock.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Insets.xxl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('$e'),
            data: (items) => items.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(Insets.xl),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              color: tokens.success),
                          const SizedBox(width: Insets.md),
                          Expanded(
                            child: Text(
                              'Nothing is running low. Thresholds are set per product.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Card(
                    child: Column(
                      children: [
                        for (final item in items)
                          ListTile(
                            onTap: () =>
                                context.go('/products/${item.productId}'),
                            leading: Icon(Icons.warning_amber_rounded,
                                color: tokens.warning),
                            title: Text(item.name),
                            subtitle: Text(
                                'Reorder point: ${formatQty(item.threshold)}'),
                            trailing: Text(
                              formatQty(item.quantity),
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: tokens.warning,
                                fontFeatures: tabularFigures,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Corners.lg),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: Insets.md),
              Text(label,
                  style: theme.textTheme.titleSmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
