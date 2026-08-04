import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/daos/app_state_dao.dart';
import '../../data/providers.dart';
import '../../sync/sync_status.dart';
import '../../sync/transport/ws_transport.dart';
import '../../theme/app_theme.dart';
import '../widgets/sync_status_pill.dart';

final _localIpProvider = FutureProvider<String?>((ref) => WsServer.localIpv4());

final _hubIpProvider = StreamProvider<String?>((ref) =>
    ref.watch(databaseProvider).appStateDao.watch(StateKeys.hubLastKnownIp));

/// Settings → Connection. Hub: server status + this phone's address.
/// Client: where the Hub was last seen, manual IP entry (discovery
/// fallback §5), and the OEM task-killer troubleshooting text (§9).
class ConnectionScreen extends ConsumerWidget {
  const ConnectionScreen({super.key});

  Future<void> _editIp(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
        text: ref.read(_hubIpProvider).valueOrNull ?? '');
    final entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hub IP address'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 192.168.43.1'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (entered != null && entered.isNotEmpty) {
      await ref
          .read(databaseProvider)
          .appStateDao
          .set(StateKeys.hubLastKnownIp, entered);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Saved — the app will try this address on reconnect')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final bootstrap = ref.watch(bootstrapProvider).valueOrNull;
    final isHub = bootstrap?.isHub ?? false;
    final pill = ref.watch(syncPillProvider);
    final pending = ref.watch(pendingCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection'),
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
          if (isHub) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.dns_rounded,
                        color: theme.colorScheme.primary),
                    title: const Text('Hub server'),
                    subtitle: const Text('Listening on port 47800'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.md, vertical: Insets.xs),
                      decoration: BoxDecoration(
                        color: tokens.successContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('RUNNING',
                          style: theme.textTheme.labelSmall!
                              .copyWith(color: tokens.onSuccessContainer)),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.wifi_rounded,
                        color: theme.colorScheme.primary),
                    title: const Text('This phone\'s address'),
                    subtitle: Text(
                      ref.watch(_localIpProvider).valueOrNull ??
                          'No Wi-Fi address found',
                      style:
                          const TextStyle(fontFeatures: tabularFigures),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.devices_rounded,
                        color: theme.colorScheme.primary),
                    title: const Text('Connected devices'),
                    trailing: Text(
                      '${ref.watch(connectedDeviceCountProvider)}',
                      style: theme.textTheme.titleMedium!
                          .copyWith(fontFeatures: tabularFigures),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      switch (pill) {
                        SyncPillState.live => Icons.check_circle_rounded,
                        SyncPillState.syncing => Icons.sync_rounded,
                        SyncPillState.offline => Icons.cloud_off_rounded,
                      },
                      color: switch (pill) {
                        SyncPillState.live => tokens.success,
                        SyncPillState.syncing => tokens.warning,
                        SyncPillState.offline => tokens.offline,
                      },
                    ),
                    title: Text(switch (pill) {
                      SyncPillState.live => 'Connected to the Hub',
                      SyncPillState.syncing => 'Syncing…',
                      SyncPillState.offline => 'Hub unreachable',
                    }),
                    subtitle: Text(pending > 0
                        ? '$pending change${pending == 1 ? '' : 's'} waiting to sync — selling still works'
                        : 'Everything is synced'),
                  ),
                  const Divider(),
                  ListTile(
                    onTap: () => _editIp(context, ref),
                    leading: Icon(Icons.edit_location_alt_outlined,
                        color: theme.colorScheme.primary),
                    title: const Text('Hub IP address'),
                    subtitle: Text(
                        ref.watch(_hubIpProvider).valueOrNull ??
                            'Not set — tap to enter manually'),
                    trailing: const Icon(Icons.chevron_right_rounded),
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
                    Row(
                      children: [
                        Icon(Icons.help_outline_rounded,
                            color: theme.colorScheme.secondary),
                        const SizedBox(width: Insets.sm),
                        Text('Hub unreachable?',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: Insets.md),
                    Text(
                      '1. Make sure both phones are on the same Wi-Fi or the '
                      'Hub\'s hotspot.\n'
                      '2. Open StockMesh on the main phone — its screen can '
                      'be off, but the app must not be force-closed.\n'
                      '3. Some phones (Xiaomi, Oppo, Vivo, Huawei, Tecno, '
                      'Infinix) aggressively kill background apps. On the '
                      'main phone, open its battery settings and set '
                      'StockMesh to "No restrictions" / "Don\'t optimize", '
                      'and lock the app in the recent-apps list.\n'
                      '4. As a last resort, read the Wi-Fi IP on the main '
                      'phone (More → Connection) and type it in above.',
                      style: theme.textTheme.bodyMedium!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: Insets.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      'All data stays inside your shop\'s network. StockMesh '
                      'never uses the internet.',
                      style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
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
