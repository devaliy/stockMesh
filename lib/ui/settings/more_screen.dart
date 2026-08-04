import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/sync_status_pill.dart';

/// Screen 12 — More/Settings hub. Devices, staff, backup and hub controls
/// are wired in M5/M6; this screen is the stable entry point.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bootstrap = ref.watch(bootstrapProvider).valueOrNull;
    final isHub = bootstrap?.isHub ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(Corners.lg),
                    ),
                    child: Icon(Icons.storefront_rounded,
                        color: theme.colorScheme.onPrimary),
                  ),
                  const SizedBox(width: Insets.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bootstrap?.businessName.isNotEmpty == true
                              ? bootstrap!.businessName
                              : 'StockMesh',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          isHub
                              ? 'Main business phone (Hub)'
                              : 'Attendant phone',
                          style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          Card(
            child: Column(
              children: [
                if (isHub) ...[
                  _MoreTile(
                    icon: Icons.devices_rounded,
                    title: 'Connected devices',
                    subtitle: 'Pair attendant phones, revoke access',
                    onTap: () => context.go('/more/devices'),
                  ),
                  const Divider(),
                  _MoreTile(
                    icon: Icons.badge_outlined,
                    title: 'Staff & PINs',
                    subtitle: 'Who can sell on this business',
                    onTap: () => context.go('/more/staff'),
                  ),
                  const Divider(),
                ],
                _MoreTile(
                  icon: Icons.cloud_download_outlined,
                  title: 'Backup & restore',
                  subtitle: 'Encrypted backup of all records',
                  onTap: () => context.go('/more/backup'),
                ),
                const Divider(),
                _MoreTile(
                  icon: Icons.lan_outlined,
                  title: 'Connection',
                  subtitle: isHub
                      ? 'Hub status and network details'
                      : 'Hub address and troubleshooting',
                  onTap: () => context.go('/more/connection'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          Card(
            child: _MoreTile(
              icon: Icons.info_outline_rounded,
              title: 'About StockMesh',
              subtitle: 'Works fully offline — your data never leaves the shop',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'StockMesh',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(Icons.inventory_2_rounded,
                    color: theme.colorScheme.primary),
                children: [
                  const Text(
                      'Offline-first inventory for small shops. One phone is the Hub; other phones sync to it over local Wi-Fi. No internet, no cloud, no accounts.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing:
          Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
    );
  }
}
