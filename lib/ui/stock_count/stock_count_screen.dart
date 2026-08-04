import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../data/db/daos/app_state_dao.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pin_pad.dart';

/// Screen 09 — stock take. Walk the checklist entering counted quantities,
/// then review variances; approving emits COUNT_ADJUST deltas (the raw count
/// lives in the event note — §4 projector rules).
class StockCountScreen extends ConsumerStatefulWidget {
  const StockCountScreen({super.key});

  @override
  ConsumerState<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends ConsumerState<StockCountScreen> {
  /// productId → counted quantity entered this session.
  final Map<String, int> _counts = {};
  bool _reviewing = false;
  bool _submitting = false;

  Future<void> _enterCount(Product product, int expected) async {
    final counted = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CountKeypadSheet(
          product: product, initial: _counts[product.id]),
    );
    if (counted != null) {
      setState(() => _counts[product.id] = counted);
    }
  }

  Future<void> _approve(List<Product> products,
      Map<String, int> levels) async {
    final staff = await verifyStaffPin(context, ref,
        title: 'Admin PIN to approve variances', requireAdmin: true);
    if (staff == null || !mounted) return;

    setState(() => _submitting = true);
    final db = ref.read(databaseProvider);
    final deviceId =
        await db.appStateDao.get(StateKeys.ownDeviceId) ?? 'unknown-device';
    final inventory = ref.read(inventoryServiceProvider);

    var adjustments = 0;
    for (final entry in _counts.entries) {
      final result = await inventory.recordCount(
        productId: entry.key,
        countedQty: entry.value,
        deviceId: deviceId,
        staffRef: staff.staffRef,
      );
      result.when(
        ok: (event) {
          if (event != null) adjustments++;
        },
        err: (_) {},
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(adjustments == 0
            ? 'Count complete — no variances'
            : 'Count complete — $adjustments adjustment${adjustments == 1 ? '' : 's'} recorded')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_reviewing ? 'Review variances' : 'Stock count'),
        leading: _reviewing
            ? BackButton(onPressed: () => setState(() => _reviewing = false))
            : null,
      ),
      body: StreamBuilder<List<Product>>(
        stream: db.productsDao.watchActive(),
        builder: (context, productsSnap) {
          final products = productsSnap.data ?? const <Product>[];
          return StreamBuilder<Map<String, int>>(
            stream: db.projectionDao.watchAllLevels(),
            builder: (context, levelsSnap) {
              final levels = levelsSnap.data ?? const <String, int>{};
              if (products.isEmpty) {
                return const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Nothing to count',
                  message: 'Add products first, then run a stock take.',
                );
              }
              return _reviewing
                  ? _buildReview(theme, tokens, products, levels)
                  : _buildChecklist(theme, tokens, products, levels);
            },
          );
        },
      ),
    );
  }

  Widget _buildChecklist(ThemeData theme, StockMeshTokens tokens,
      List<Product> products, Map<String, int> levels) {
    final done = _counts.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$done of ${products.length} counted',
                      style: theme.textTheme.titleSmall!
                          .copyWith(fontFeatures: tabularFigures)),
                  TextButton(
                    onPressed:
                        done == 0 ? null : () => setState(() => _counts.clear()),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: products.isEmpty ? 0 : done / products.length,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(indent: Insets.lg),
            itemBuilder: (context, index) {
              final product = products[index];
              final expected = levels[product.id] ?? 0;
              final counted = _counts[product.id];
              return ListTile(
                onTap: () => _enterCount(product, expected),
                leading: Icon(
                  counted == null
                      ? Icons.radio_button_unchecked_rounded
                      : Icons.check_circle_rounded,
                  color: counted == null
                      ? theme.colorScheme.outlineVariant
                      : tokens.success,
                ),
                title: Text(product.name),
                subtitle: Text('Expected ${formatQty(expected)}'),
                trailing: counted == null
                    ? null
                    : Text(
                        formatQty(counted),
                        style: theme.textTheme.titleMedium!.copyWith(
                          fontFeatures: tabularFigures,
                          color: counted == expected
                              ? tokens.success
                              : tokens.warning,
                        ),
                      ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: FilledButton(
              onPressed:
                  done == 0 ? null : () => setState(() => _reviewing = true),
              child: Text('Review $done count${done == 1 ? '' : 's'}'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview(ThemeData theme, StockMeshTokens tokens,
      List<Product> products, Map<String, int> levels) {
    final byId = {for (final p in products) p.id: p};
    final entries = _counts.entries
        .where((e) => byId.containsKey(e.key))
        .toList(growable: false);
    final variances = entries
        .where((e) => e.value != (levels[e.key] ?? 0))
        .length;

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(top: Insets.sm),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(indent: Insets.lg),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final product = byId[entry.key]!;
              final expected = levels[entry.key] ?? 0;
              final diff = entry.value - expected;
              return ListTile(
                title: Text(product.name),
                subtitle: Text(
                    'Expected ${formatQty(expected)} · Counted ${formatQty(entry.value)}'),
                trailing: diff == 0
                    ? Icon(Icons.check_rounded, color: tokens.success)
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Insets.md, vertical: Insets.xs),
                        decoration: BoxDecoration(
                          color: diff < 0
                              ? theme.colorScheme.errorContainer
                              : tokens.successContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${diff > 0 ? '+' : ''}${formatQty(diff)}',
                          style: theme.textTheme.titleSmall!.copyWith(
                            fontFeatures: tabularFigures,
                            color: diff < 0
                                ? theme.colorScheme.onErrorContainer
                                : tokens.onSuccessContainer,
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: FilledButton.icon(
              onPressed: _submitting
                  ? null
                  : () => _approve(products, levels),
              icon: const Icon(Icons.verified_rounded),
              label: Text(_submitting
                  ? 'Recording…'
                  : variances == 0
                      ? 'Finish count'
                      : 'Approve $variances adjustment${variances == 1 ? '' : 's'}'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountKeypadSheet extends StatefulWidget {
  const _CountKeypadSheet({required this.product, this.initial});

  final Product product;
  final int? initial;

  @override
  State<_CountKeypadSheet> createState() => _CountKeypadSheetState();
}

class _CountKeypadSheetState extends State<_CountKeypadSheet> {
  late String _value = widget.initial?.toString() ?? '';

  void _tap(String key) {
    setState(() {
      if (key == '⌫') {
        if (_value.isNotEmpty) _value = _value.substring(0, _value.length - 1);
      } else if (_value.length < 6) {
        if (_value.isEmpty && key == '0') {
          _value = '0';
        } else {
          _value += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counted = int.tryParse(_value);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, 0, Insets.lg, Insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.product.name,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: Insets.md),
            Text(
              _value.isEmpty ? '—' : formatQty(counted ?? 0),
              textAlign: TextAlign.center,
              style: theme.textTheme.displayLarge!.copyWith(
                color: _value.isEmpty
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Insets.lg),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        child: key.isEmpty
                            ? const SizedBox(height: 52)
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Insets.xs),
                                child: Material(
                                  color:
                                      theme.colorScheme.surfaceContainerLow,
                                  borderRadius:
                                      BorderRadius.circular(Corners.lg),
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(Corners.lg),
                                    onTap: () => _tap(key),
                                    child: SizedBox(
                                      height: 52,
                                      child: Center(
                                        child: key == '⌫'
                                            ? const Icon(
                                                Icons.backspace_outlined)
                                            : Text(key,
                                                style: theme.textTheme
                                                    .headlineSmall),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            FilledButton(
              onPressed: counted == null
                  ? null
                  : () => Navigator.pop(context, counted),
              child: const Text('Save count'),
            ),
          ],
        ),
      ),
    );
  }
}
