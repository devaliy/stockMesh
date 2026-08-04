import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ids.dart';
import '../../data/db/daos/app_state_dao.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../security/pin_hasher.dart';
import '../../sync/hub/hub_foreground.dart';
import '../../theme/app_theme.dart';
import '../widgets/pin_pad.dart';

/// Screen 02 — Hub business setup wizard (3 steps). Completing it creates
/// the admin staff row, this device's HUB registry row, and flips
/// onboarding_done; the router then drops the user into the shell.
class HubSetupScreen extends ConsumerStatefulWidget {
  const HubSetupScreen({super.key});

  @override
  ConsumerState<HubSetupScreen> createState() => _HubSetupScreenState();
}

class _HubSetupScreenState extends ConsumerState<HubSetupScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  String _currency = '₦';
  String? _firstPin;
  bool _confirmingPin = false;
  bool _saving = false;

  static const _currencies = ['₦', 'GH₵', 'KSh', 'R', r'$'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish(String pin) async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final deviceId = newId();

    await db.transaction(() async {
      await db.staffDao.upsertStaff(StaffCompanion.insert(
        staffRef: 'admin',
        displayName: 'Admin',
        pinHash: PinHasher.hash(pin),
        isAdmin: const Value(true),
        updatedAt: now,
      ));
      await db.devicesDao.upsertDevice(DevicesCompanion.insert(
        deviceId: deviceId,
        displayName: 'Hub — ${_nameController.text.trim()}',
        role: 'HUB',
        secretHash: '', // the Hub authenticates clients, never itself
      ));
      final state = db.appStateDao;
      await state.set(StateKeys.role, 'HUB');
      await state.set(StateKeys.businessName, _nameController.text.trim());
      await state.set(StateKeys.currency, _currency);
      await state.set(StateKeys.ownDeviceId, deviceId);
      await state.set(StateKeys.ownDeviceName, 'Hub phone');
    });

    if (!mounted) return;
    setState(() {
      _saving = false;
      _step = 2;
    });
  }

  Future<void> _enterApp() async {
    // §9: the Hub must survive the screen turning off — explain, then ask
    // for the battery-optimization exemption.
    if (mounted) {
      final agreed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Keep the Hub running'),
          content: const Text(
              'Other phones sync through this one, so Android must not put '
              'StockMesh to sleep. On the next screen, allow StockMesh to '
              'run without battery restrictions.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (agreed ?? false) {
        await HubForeground.requestBatteryExemption();
      }
    }

    final db = ref.read(databaseProvider);
    await db.appStateDao.set(StateKeys.onboardingDone, '1');
    ref.invalidate(bootstrapProvider);
    if (mounted) context.go('/products');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_step) {
          0 => 'Business details',
          1 => _confirmingPin ? 'Confirm admin PIN' : 'Create admin PIN',
          _ => 'All set',
        }),
        leading: _step == 0
            ? BackButton(onPressed: () => context.go('/onboarding'))
            : _step == 1
                ? BackButton(onPressed: () => setState(() {
                      _step = 0;
                      _firstPin = null;
                      _confirmingPin = false;
                    }))
                : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_step) {
            0 => _businessStep(theme),
            1 => _pinStep(theme),
            _ => _doneStep(theme),
          },
        ),
      ),
    );
  }

  Widget _businessStep(ThemeData theme) {
    return Padding(
      key: const ValueKey('business'),
      padding: const EdgeInsets.all(Insets.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepDots(step: 0),
          const SizedBox(height: Insets.xxl),
          Text('What is your business called?',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: Insets.xxl),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Business name',
              hintText: 'e.g. Mama Nkechi Provisions',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Insets.xxl),
          Text('CURRENCY',
              style: theme.textTheme.labelSmall!
                  .copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: Insets.md),
          Wrap(
            spacing: Insets.sm,
            children: [
              for (final c in _currencies)
                ChoiceChip(
                  label: Text(c,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  selected: _currency == c,
                  onSelected: (_) => setState(() => _currency = c),
                ),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: _nameController.text.trim().isEmpty
                ? null
                : () => setState(() => _step = 1),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _pinStep(ThemeData theme) {
    return SingleChildScrollView(
      key: ValueKey('pin-$_confirmingPin'),
      padding: const EdgeInsets.all(Insets.xxl),
      child: Column(
        children: [
          _StepDots(step: 1),
          const SizedBox(height: Insets.xxl),
          Text(
            _confirmingPin
                ? 'Enter the same PIN again'
                : 'This PIN protects prices, adjustments and backups.',
            style: theme.textTheme.bodyMedium!
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Insets.xl),
          PinPad(
            key: ValueKey('pad-$_confirmingPin'),
            onCompleted: (pin) async {
              if (!_confirmingPin) {
                setState(() {
                  _firstPin = pin;
                  _confirmingPin = true;
                });
                return true;
              }
              if (pin == _firstPin) {
                await _finish(pin);
                return true;
              }
              setState(() {
                _firstPin = null;
                _confirmingPin = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('PINs did not match — start again')));
              }
              return false;
            },
          ),
        ],
      ),
    );
  }

  Widget _doneStep(ThemeData theme) {
    return Padding(
      key: const ValueKey('done'),
      padding: const EdgeInsets.all(Insets.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.check_circle_rounded,
              size: 96, color: theme.colorScheme.primary),
          const SizedBox(height: Insets.xxl),
          Text('${_nameController.text.trim()} is ready',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: Insets.sm),
          Text(
            'This phone is now the Hub. Add your products, then pair attendant phones from the Devices screen.',
            style: theme.textTheme.bodyMedium!
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _enterApp,
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('Start adding products'),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: Insets.xs),
          width: i == step ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i <= step ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
