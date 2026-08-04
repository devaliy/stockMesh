import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ids.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/scanner_page.dart';

/// Screen 07 — add/edit product. Hub only (invariant §1.5). Saving bumps
/// updated_at, which is what REF sync uses to push the row to clients.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _costPrice = TextEditingController();
  final _sellingPrice = TextEditingController();
  final _threshold = TextEditingController(text: '0');
  String _unit = 'pcs';
  bool _loading = false;
  bool _loaded = false;

  static const _units = ['pcs', 'carton', 'kg', 'litre'];

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    final product = await ref
        .read(databaseProvider)
        .productsDao
        .getById(widget.productId!);
    if (product == null || !mounted) return;
    _name.text = product.name;
    _sku.text = product.sku ?? '';
    _barcode.text = product.barcode ?? '';
    _costPrice.text = product.costPrice == 0
        ? ''
        : formatKobo(product.costPrice, symbol: '');
    _sellingPrice.text = product.sellingPrice == 0
        ? ''
        : formatKobo(product.sellingPrice, symbol: '');
    _threshold.text = product.lowStockThreshold.toString();
    setState(() {
      _unit = product.unit;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _barcode.dispose();
    _costPrice.dispose();
    _sellingPrice.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final barcode = _barcode.text.trim();
    final sku = _sku.text.trim();

    await db.productsDao.upsertProduct(ProductsCompanion(
      id: Value(widget.productId ?? newId()),
      name: Value(_name.text.trim()),
      sku: Value(sku.isEmpty ? null : sku),
      barcode: Value(barcode.isEmpty ? null : barcode),
      unit: Value(_unit),
      costPrice: Value(parseToKobo(_costPrice.text) ?? 0),
      sellingPrice: Value(parseToKobo(_sellingPrice.text) ?? 0),
      lowStockThreshold: Value(int.tryParse(_threshold.text.trim()) ?? 0),
      isActive: const Value(true),
      updatedAt: Value(now),
    ));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(_isEdit ? 'Product updated' : '${_name.text.trim()} added')));
    context.pop();
  }

  String? _priceValidator(String? v, {required bool required}) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return required ? 'Required' : null;
    if (parseToKobo(text) == null) return 'Enter a valid amount';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isEdit && !_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit product')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit product' : 'Add product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Insets.lg),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Product name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: Insets.lg),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Unit'),
              items: [
                for (final u in _units)
                  DropdownMenuItem(value: u, child: Text(u)),
              ],
              onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
            ),
            const SizedBox(height: Insets.lg),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Cost price'),
                    validator: (v) => _priceValidator(v, required: false),
                  ),
                ),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: TextFormField(
                    controller: _sellingPrice,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Selling price'),
                    validator: (v) => _priceValidator(v, required: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            TextFormField(
              controller: _threshold,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Low stock threshold',
                helperText: 'Warn when stock falls to this level (0 = off)',
              ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 0) return 'Enter a whole number';
                return null;
              },
            ),
            const SizedBox(height: Insets.lg),
            TextFormField(
              controller: _barcode,
              decoration: InputDecoration(
                labelText: 'Barcode',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.barcode_reader),
                  onPressed: () async {
                    final code = await ScannerPage.scan(context);
                    if (code != null) _barcode.text = code;
                  },
                ),
              ),
            ),
            const SizedBox(height: Insets.lg),
            TextFormField(
              controller: _sku,
              decoration: const InputDecoration(labelText: 'SKU (optional)'),
            ),
            const SizedBox(height: Insets.xxl),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: Text(_loading
                  ? 'Saving…'
                  : _isEdit
                      ? 'Save changes'
                      : 'Add product'),
            ),
            const SizedBox(height: Insets.sm),
            Text(
              'Product changes sync to attendant phones automatically.',
              style: theme.textTheme.bodySmall!
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
