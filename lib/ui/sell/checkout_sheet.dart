import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/db/daos/app_state_dao.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/pin_pad.dart';
import 'cart_controller.dart';

/// Screen 05 — slide-up cart sheet: line items with steppers, big total,
/// staff-PIN-confirmed checkout. The PIN resolves which staff_ref every SALE
/// event in the receipt carries.
Future<void> showCheckoutSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _CheckoutSheet(),
  );
}

class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet();

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  bool _submitting = false;

  Future<void> _confirm() async {
    final staff = await verifyStaffPin(context, ref,
        title: 'Confirm sale with your PIN');
    if (staff == null || !mounted) return;

    setState(() => _submitting = true);
    final db = ref.read(databaseProvider);
    final deviceId =
        await db.appStateDao.get(StateKeys.ownDeviceId) ?? 'unknown-device';
    final lines = ref.read(cartProvider.notifier).toLines();
    final result = await ref.read(salesServiceProvider).checkout(
          lines: lines,
          deviceId: deviceId,
          staffRef: staff.staffRef,
        );
    if (!mounted) return;

    result.when(
      ok: (_) {
        final total = ref.read(cartTotalProvider);
        final currency = ref.read(currencyProvider);
        ref.read(cartProvider.notifier).clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: Insets.sm),
              Text('Sale recorded — ${formatKobo(total, symbol: currency)}'),
            ],
          ),
        ));
      },
      err: (message) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final currency = ref.watch(currencyProvider);

    if (items.isEmpty) {
      // Cart emptied while the sheet was open (e.g. last line removed).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
      return const SizedBox(height: 120);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, Insets.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cart', style: theme.textTheme.titleMedium),
          const SizedBox(height: Insets.md),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name,
                                style: theme.textTheme.bodyLarge),
                            Text(
                              '${formatKobo(item.product.sellingPrice, symbol: currency)} each',
                              style: theme.textTheme.bodySmall!.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFeatures: tabularFigures),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (item.quantity <= 1) {
                            ref
                                .read(cartProvider.notifier)
                                .remove(item.product.id);
                          } else {
                            ref
                                .read(cartProvider.notifier)
                                .changeQty(item.product.id, -1);
                          }
                        },
                        icon: Icon(item.quantity <= 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_rounded),
                      ),
                      SizedBox(
                        width: 32,
                        child: Center(
                          child: Text('${item.quantity}',
                              style: theme.textTheme.titleSmall!.copyWith(
                                  fontFeatures: tabularFigures)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .changeQty(item.product.id, 1),
                        icon: const Icon(Icons.add_rounded),
                      ),
                      SizedBox(
                        width: 88,
                        child: Text(
                          formatKobo(item.lineTotal, symbol: currency),
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleSmall!
                              .copyWith(fontFeatures: tabularFigures),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Insets.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: theme.textTheme.titleMedium),
                Text(
                  formatKobo(total, symbol: currency),
                  style: theme.textTheme.headlineLarge!.copyWith(
                    color: theme.colorScheme.primary,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _submitting ? null : _confirm,
            icon: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.pin_rounded),
            label: Text(_submitting ? 'Recording…' : 'Confirm with PIN'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
          ),
        ],
      ),
    );
  }
}
