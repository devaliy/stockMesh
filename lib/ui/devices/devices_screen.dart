import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../sync/engine.dart';
import '../../sync/sync_status.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pin_pad.dart';
import '../widgets/sync_status_pill.dart';

final _devicesProvider = StreamProvider<List<Device>>(
    (ref) => ref.watch(databaseProvider).devicesDao.watchAll());

/// Screen 11 — connected devices (Hub only): registry with online dots,
/// pairing entry point, revoke with confirm (§6.5).
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  Future<void> _revoke(
      BuildContext context, WidgetRef ref, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${device.displayName}?'),
        content: const Text(
            'The phone will be disconnected and wiped of business data the '
            'next time it tries to sync. Sales it recorded remain in the '
            'books. To bring it back, pair it again with a new QR code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove device'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final staff = await verifyStaffPin(context, ref,
        title: 'Admin PIN to remove device', requireAdmin: true);
    if (staff == null) return;

    await ref.read(databaseProvider).devicesDao.revoke(device.deviceId);
    // Kick the live session so the revocation bites immediately.
    ref.read(syncEngineProvider).hubServer?.kick(device.deviceId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${device.displayName} removed')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final devices = ref.watch(_devicesProvider);
    final online = ref.watch(onlineDevicesProvider);
    final ownId = ref.watch(bootstrapProvider).valueOrNull?.deviceId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: Insets.lg),
            child: Center(child: SyncStatusPill()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final staff = await verifyStaffPin(context, ref,
              title: 'Admin PIN to add a device', requireAdmin: true);
          if (staff != null && context.mounted) {
            context.go('/more/devices/pair');
          }
        },
        icon: const Icon(Icons.qr_code_rounded),
        label: const Text('Add device'),
      ),
      body: devices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load devices',
            message: '$e'),
        data: (list) {
          final others =
              list.where((d) => d.deviceId != ownId).toList(growable: false);
          if (others.isEmpty) {
            return const EmptyState(
              icon: Icons.devices_other_rounded,
              title: 'No paired devices yet',
              message:
                  'Tap "Add device" and scan the QR code with the attendant\'s phone.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96, top: Insets.sm),
            itemCount: others.length,
            separatorBuilder: (_, _) => const Divider(indent: Insets.lg),
            itemBuilder: (context, index) {
              final device = others[index];
              final isOnline = online.contains(device.deviceId);
              final lastSeen = device.lastSeenAt == null
                  ? 'never'
                  : _relative(device.lastSeenAt!);
              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        device.role == 'STOCKTAKER'
                            ? Icons.fact_check_outlined
                            : Icons.smartphone_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: device.isRevoked
                              ? theme.colorScheme.error
                              : isOnline
                                  ? tokens.success
                                  : tokens.offline,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: theme.colorScheme.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(device.displayName),
                subtitle: Text(device.isRevoked
                    ? 'Removed'
                    : '${device.role == 'STOCKTAKER' ? 'Stock-taker' : 'Attendant'}'
                        ' · ${isOnline ? 'online' : 'last seen $lastSeen'}'),
                trailing: device.isRevoked
                    ? null
                    : IconButton(
                        icon: Icon(Icons.link_off_rounded,
                            color: theme.colorScheme.error),
                        tooltip: 'Remove device',
                        onPressed: () => _revoke(context, ref, device),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  String _relative(int ms) {
    final delta = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inHours < 1) return '${delta.inMinutes} min ago';
    if (delta.inDays < 1) return '${delta.inHours} h ago';
    return '${delta.inDays} d ago';
  }
}
