import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../data/providers.dart';
import '../../domain/reporting_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/sync_status_pill.dart';

/// Selected report range as [fromMs, toMs).
class ReportRange {
  const ReportRange(this.fromMs, this.toMs, this.label);

  final int fromMs;
  final int toMs;
  final String label;

  static ReportRange today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return ReportRange(start.millisecondsSinceEpoch,
        start.add(const Duration(days: 1)).millisecondsSinceEpoch, 'Today');
  }

  static ReportRange days(int n, String label) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    final start = end.subtract(Duration(days: n));
    return ReportRange(
        start.millisecondsSinceEpoch, end.millisecondsSinceEpoch, label);
  }
}

final reportRangeProvider =
    StateProvider<ReportRange>((ref) => ReportRange.today());

final _summaryProvider = StreamProvider<SalesSummary>((ref) {
  final range = ref.watch(reportRangeProvider);
  return ref
      .watch(reportingServiceProvider)
      .watchSalesSummary(range.fromMs, range.toMs);
});

final _topProductsProvider = StreamProvider<List<ProductSales>>((ref) {
  final range = ref.watch(reportRangeProvider);
  return ref
      .watch(reportingServiceProvider)
      .watchTopProducts(range.fromMs, range.toMs);
});

final _staffSalesProvider = StreamProvider<List<StaffSales>>((ref) {
  final range = ref.watch(reportRangeProvider);
  return ref
      .watch(reportingServiceProvider)
      .watchStaffSales(range.fromMs, range.toMs);
});

final _lowStockProvider = StreamProvider<List<LowStockItem>>(
    (ref) => ref.watch(reportingServiceProvider).watchLowStock());

/// Screen 10 — reports dashboard: sales total, top products, low stock,
/// per-staff sales, range picker, CSV export.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final range = ref.read(reportRangeProvider);
    final csv = await ref
        .read(reportingServiceProvider)
        .salesCsv(range.fromMs, range.toMs);
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(csv.codeUnits),
          name: 'stockmesh-sales-$stamp.csv',
          mimeType: 'text/csv',
        )
      ],
      subject: 'StockMesh sales export (${range.label})',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final currency = ref.watch(currencyProvider);
    final range = ref.watch(reportRangeProvider);
    final summary =
        ref.watch(_summaryProvider).valueOrNull ?? SalesSummary.empty;
    final topProducts = ref.watch(_topProductsProvider).valueOrNull ?? const [];
    final staffSales = ref.watch(_staffSalesProvider).valueOrNull ?? const [];
    final lowStock = ref.watch(_lowStockProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            onPressed: () => _exportCsv(context, ref),
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export CSV',
          ),
          const Padding(
            padding: EdgeInsets.only(right: Insets.lg),
            child: Center(child: SyncStatusPill()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in [
                  ReportRange.today(),
                  ReportRange.days(7, 'Last 7 days'),
                  ReportRange.days(30, 'Last 30 days'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: Insets.sm),
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: range.label == option.label,
                      onSelected: (_) => ref
                          .read(reportRangeProvider.notifier)
                          .state = option,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${range.label.toUpperCase()} SALES',
                      style: theme.textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: Insets.sm),
                  Text(
                    formatKobo(summary.revenueKobo, symbol: currency),
                    style: theme.textTheme.displaySmall!
                        .copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: Insets.sm),
                  Text(
                    '${formatQty(summary.receiptCount)} sales · ${formatQty(summary.unitsSold)} items',
                    style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: tabularFigures),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.xxl),
          _SectionHeader(title: 'TOP PRODUCTS'),
          topProducts.isEmpty
              ? const _NoData(message: 'No sales in this period yet.')
              : Card(
                  child: Column(
                    children: [
                      for (final (index, item) in topProducts.indexed)
                        ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHigh,
                            child: Text('${index + 1}',
                                style: theme.textTheme.labelMedium),
                          ),
                          title: Text(item.name),
                          subtitle:
                              Text('${formatQty(item.unitsSold)} sold'),
                          trailing: Text(
                            formatKobo(item.revenueKobo, symbol: currency),
                            style: theme.textTheme.titleSmall!
                                .copyWith(fontFeatures: tabularFigures),
                          ),
                        ),
                    ],
                  ),
                ),
          const SizedBox(height: Insets.xxl),
          _SectionHeader(title: 'SALES BY STAFF'),
          staffSales.isEmpty
              ? const _NoData(message: 'No staff sales in this period.')
              : Card(
                  child: Column(
                    children: [
                      for (final s in staffSales)
                        ListTile(
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              s.name.isEmpty
                                  ? '?'
                                  : s.name[0].toUpperCase(),
                              style: theme.textTheme.labelLarge!.copyWith(
                                  color: theme.colorScheme.primary),
                            ),
                          ),
                          title: Text(s.name),
                          subtitle: Text(
                              '${formatQty(s.receiptCount)} sale${s.receiptCount == 1 ? '' : 's'}'),
                          trailing: Text(
                            formatKobo(s.revenueKobo, symbol: currency),
                            style: theme.textTheme.titleSmall!
                                .copyWith(fontFeatures: tabularFigures),
                          ),
                        ),
                    ],
                  ),
                ),
          const SizedBox(height: Insets.xxl),
          _SectionHeader(title: 'LOW STOCK'),
          lowStock.isEmpty
              ? const _NoData(message: 'Nothing is below its threshold.')
              : Card(
                  child: Column(
                    children: [
                      for (final item in lowStock)
                        ListTile(
                          onTap: () =>
                              context.go('/products/${item.productId}'),
                          leading: Icon(Icons.warning_amber_rounded,
                              color: tokens.warning),
                          title: Text(item.name),
                          trailing: Text(
                            '${formatQty(item.quantity)} left',
                            style: theme.textTheme.titleSmall!.copyWith(
                              color: tokens.warning,
                              fontFeatures: tabularFigures,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          const SizedBox(height: Insets.xxl),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Text(title,
          style: theme.textTheme.labelSmall!
              .copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium!
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
