import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../data/db/daos/app_state_dao.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../domain/models/event_type.dart';
import '../../theme/app_theme.dart';
import '../widgets/pin_pad.dart';
import '../widgets/scanner_page.dart';

/// Screen 08 — receive stock: pick/scan a product, enter quantity on a big
/// keypad, optional cost per unit, one green button → RECEIVE event.
class ReceiveScreen extends ConsumerStatefulWidget {
  const ReceiveScreen({super.key});

  @override
  ConsumerState<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends ConsumerState<ReceiveScreen> {
  Product? _product;
  String _qty = '';
  final _cost = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ProductPickerSheet(),
    );
    if (product != null) {
      setState(() {
        _product = product;
        if (_cost.text.isEmpty && product.costPrice > 0) {
          _cost.text = formatKobo(product.costPrice, symbol: '');
        }
      });
    }
  }

  Future<void> _scan() async {
    final code = await ScannerPage.scan(context);
    if (code == null || !mounted) return;
    final product =
        await ref.read(databaseProvider).productsDao.getByBarcode(code);
    if (product != null) {
      setState(() => _product = product);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No product with that barcode')));
    }
  }

  void _tapKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_qty.isNotEmpty) _qty = _qty.substring(0, _qty.length - 1);
      } else if (_qty.length < 6) {
        if (_qty.isEmpty && key == '0') return;
        _qty += key;
      }
    });
  }

  int get _quantity => int.tryParse(_qty) ?? 0;

  Future<void> _receive() async {
    final product = _product;
    if (product == null || _quantity <= 0 || _saving) return;
    final staff = await verifyStaffPin(context, ref,
        title: 'Confirm receive with your PIN');
    if (staff == null || !mounted) return;

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final deviceId =
        await db.appStateDao.get(StateKeys.ownDeviceId) ?? 'unknown-device';
    final costKobo = parseToKobo(_cost.text);

    final result = await ref.read(inventoryServiceProvider).recordLocalEvent(
          productId: product.id,
          type: StockEventType.receive,
          quantityDelta: _quantity,
          unitPrice: costKobo,
          deviceId: deviceId,
          staffRef: staff.staffRef,
        );
    if (!mounted) return;

    result.when(
      ok: (_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Received ${formatQty(_quantity)} × ${product.name}')));
        context.pop();
      },
      err: (message) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Receive stock')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  onTap: _pickProduct,
                  leading: Icon(Icons.inventory_2_outlined,
                      color: theme.colorScheme.primary),
                  title: Text(
                    _product?.name ?? 'Choose product',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: _product == null
                      ? const Text('Tap to search the product list')
                      : Text('Unit: ${_product!.unit}'),
                  trailing: IconButton(
                    onPressed: _scan,
                    icon: const Icon(Icons.barcode_reader),
                    tooltip: 'Scan',
                  ),
                ),
              ),
              const SizedBox(height: Insets.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _qty.isEmpty ? '0' : formatQty(_quantity),
                      style: theme.textTheme.displayLarge!.copyWith(
                        color: _qty.isEmpty
                            ? theme.colorScheme.outlineVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _product == null ? 'quantity' : _product!.unit,
                      style: theme.textTheme.labelMedium!
                          .copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _cost,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost per unit (optional)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: Insets.lg),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
                ['00', '0', '⌫'],
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: Row(
                    children: [
                      for (final key in row)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Insets.xs),
                            child: Material(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius:
                                  BorderRadius.circular(Corners.lg),
                              child: InkWell(
                                borderRadius:
                                    BorderRadius.circular(Corners.lg),
                                onTap: () {
                                  if (key == '00') {
                                    _tapKey('0');
                                    _tapKey('0');
                                  } else {
                                    _tapKey(key);
                                  }
                                },
                                child: SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: key == '⌫'
                                        ? const Icon(
                                            Icons.backspace_outlined)
                                        : Text(key,
                                            style: theme
                                                .textTheme.headlineSmall!
                                                .copyWith(
                                                    fontFeatures:
                                                        tabularFigures)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: Insets.sm),
              FilledButton.icon(
                onPressed:
                    _product != null && _quantity > 0 && !_saving
                        ? _receive
                        : null,
                icon: const Icon(Icons.move_to_inbox_rounded),
                label: Text(_saving ? 'Recording…' : 'Receive'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(64)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  const _ProductPickerSheet();

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, 0, Insets.lg, Insets.md),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search products…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: db.productsDao.watchSearch(_query),
              builder: (context, snapshot) {
                final products = snapshot.data ?? const <Product>[];
                return ListView.builder(
                  controller: scrollController,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final p = products[index];
                    return ListTile(
                      title: Text(p.name),
                      subtitle: p.sku == null ? null : Text('SKU ${p.sku}'),
                      onTap: () => Navigator.pop(context, p),
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
