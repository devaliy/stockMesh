import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ids.dart';
import '../../data/db/daos/app_state_dao.dart';
import '../../data/providers.dart';
import '../../security/pairing.dart';
import '../../sync/discovery/browser.dart';
import '../../theme/app_theme.dart';
import '../widgets/scanner_page.dart';

/// Screen 03 — join an existing business: Wi-Fi instruction, QR scan,
/// pairing (§6), success state; CATCH_UP then streams in the shell.
class JoinBusinessScreen extends ConsumerStatefulWidget {
  const JoinBusinessScreen({super.key});

  @override
  ConsumerState<JoinBusinessScreen> createState() =>
      _JoinBusinessScreenState();
}

enum _JoinPhase { idle, pairing, success }

class _JoinBusinessScreenState extends ConsumerState<JoinBusinessScreen> {
  _JoinPhase _phase = _JoinPhase.idle;
  String? _error;
  String _businessName = '';
  String _role = 'ATTENDANT';

  // Discovery only ever informs the UI — pairing still requires scanning
  // the found shop's QR, so it never bypasses the token/secret exchange.
  final _browser = HubBrowser();

  @override
  void initState() {
    super.initState();
    _browser.start();
  }

  @override
  void dispose() {
    _browser.dispose();
    super.dispose();
  }

  Future<void> _scanAndPair() async {
    final raw = await ScannerPage.scan(context, title: 'Scan pairing QR');
    if (raw == null || !mounted) return;

    final qr = PairingQr.decode(raw);
    if (qr == null) {
      setState(() =>
          _error = 'That is not a StockMesh pairing code. Scan the QR from '
              'More → Devices → Add device on the main phone.');
      return;
    }

    setState(() {
      _phase = _JoinPhase.pairing;
      _error = null;
    });

    final db = ref.read(databaseProvider);
    final deviceId = newId();
    final outcome = await PairingClient(db).pair(
      qr: qr,
      deviceId: deviceId,
      deviceName:
          _role == 'STOCKTAKER' ? 'Stock-taker phone' : 'Attendant phone',
      role: _role,
    );
    if (!mounted) return;

    if (!outcome.ok) {
      setState(() {
        _phase = _JoinPhase.idle;
        _error = outcome.error;
      });
      return;
    }

    setState(() {
      _phase = _JoinPhase.success;
      _businessName = outcome.businessName ?? '';
    });
  }

  Future<void> _enter() async {
    final db = ref.read(databaseProvider);
    await db.appStateDao.set(StateKeys.onboardingDone, '1');
    ref.invalidate(bootstrapProvider);
    if (mounted) context.go('/sell');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a business'),
        leading: _phase == _JoinPhase.idle
            ? BackButton(onPressed: () => context.go('/onboarding'))
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xxl),
          child: switch (_phase) {
            _JoinPhase.idle => _idleView(theme),
            _JoinPhase.pairing => _pairingView(theme),
            _JoinPhase.success => _successView(theme),
          },
        ),
      ),
    );
  }

  Widget _idleView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Insets.xl),
            child: Row(
              children: [
                Icon(Icons.wifi_rounded,
                    color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: Insets.lg),
                Expanded(
                  child: Text(
                    'Step 1 — connect this phone to the same Wi-Fi (or the '
                    'hotspot) as the main business phone.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Insets.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 2 — what will this phone do?',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Insets.md),
                Wrap(
                  spacing: Insets.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('Sell (attendant)'),
                      selected: _role == 'ATTENDANT',
                      onSelected: (_) =>
                          setState(() => _role = 'ATTENDANT'),
                    ),
                    ChoiceChip(
                      label: const Text('Count stock'),
                      selected: _role == 'STOCKTAKER',
                      onSelected: (_) =>
                          setState(() => _role = 'STOCKTAKER'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: Insets.lg),
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: Insets.lg),
        Expanded(child: _nearbyShopsSection(theme)),
        const SizedBox(height: Insets.lg),
        FilledButton.icon(
          onPressed: _scanAndPair,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Scan pairing QR'),
        ),
      ],
    );
  }

  Widget _nearbyShopsSection(ThemeData theme) {
    return StreamBuilder<List<DiscoveredHub>>(
      stream: _browser.hubs,
      builder: (context, snapshot) {
        final hubs = snapshot.data ?? const <DiscoveredHub>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NEARBY SHOPS',
                style: theme.textTheme.labelSmall!
                    .copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: Insets.sm),
            if (hubs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Text(
                          'Searching… if a shop appears here, tap Connect '
                          'instead of scanning.',
                          style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: hubs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Insets.sm),
                  itemBuilder: (context, index) {
                    final hub = hubs[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.storefront_rounded,
                            color: theme.colorScheme.primary),
                        title: Text(hub.businessName),
                        subtitle: const Text('Found on this Wi-Fi network'),
                        trailing: FilledButton.tonal(
                          onPressed: _scanAndPair,
                          child: const Text('Connect'),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _pairingView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: Insets.xxl),
        Text('Connecting to the main phone…',
            style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: Insets.sm),
        Text(
          'Keep both phones on and close together.',
          style: theme.textTheme.bodyMedium!
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _successView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(Icons.check_circle_rounded,
            size: 96, color: theme.colorScheme.primary),
        const SizedBox(height: Insets.xxl),
        Text(
          _businessName.isEmpty
              ? 'Connected!'
              : 'Welcome to $_businessName',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.sm),
        Text(
          'This phone is paired. Products and prices download '
          'automatically the moment you enter — and selling works even '
          'when the connection drops.',
          style: theme.textTheme.bodyMedium!
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: _enter,
          icon: const Icon(Icons.storefront_rounded),
          label: const Text('Start selling'),
        ),
      ],
    );
  }
}
