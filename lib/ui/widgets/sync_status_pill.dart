import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../sync/sync_status.dart';
import '../../theme/app_theme.dart';

/// The persistent sync status pill (design §8.2): LIVE green, SYNCING amber,
/// OFFLINE gray with pending count ("OFFLINE · 12 unsynced"). On the Hub it
/// shows the connected-device count instead.
class SyncStatusPill extends ConsumerWidget {
  const SyncStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = StockMeshTokens.of(context);
    final bootstrap = ref.watch(bootstrapProvider).valueOrNull;
    final pending = ref.watch(pendingCountProvider).valueOrNull ?? 0;

    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    if (bootstrap?.isHub ?? false) {
      final connected = ref.watch(connectedDeviceCountProvider);
      bg = tokens.successContainer;
      fg = tokens.onSuccessContainer;
      icon = Icons.hub_outlined;
      label = connected == 0 ? 'HUB' : 'HUB · $connected';
    } else {
      final state = ref.watch(syncPillProvider);
      switch (state) {
        case SyncPillState.live:
          bg = tokens.successContainer;
          fg = tokens.onSuccessContainer;
          icon = Icons.check_circle_rounded;
          label = 'LIVE';
        case SyncPillState.syncing:
          bg = tokens.warningContainer;
          fg = tokens.onWarningContainer;
          icon = Icons.sync_rounded;
          label = 'SYNCING';
        case SyncPillState.offline:
          bg = tokens.offlineContainer;
          fg = tokens.onOfflineContainer;
          icon = Icons.cloud_off_rounded;
          label = pending > 0 ? 'OFFLINE · $pending unsynced' : 'OFFLINE';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                  fontFeatures: tabularFigures,
                ),
          ),
        ],
      ),
    );
  }
}
