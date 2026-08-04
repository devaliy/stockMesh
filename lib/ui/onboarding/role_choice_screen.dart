import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/backup_service.dart';
import '../../data/db/daos/app_state_dao.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/pin_pad.dart';

/// Screen 01 — role choice. One codebase, one APK, two roles (invariant
/// §1.6): the chosen role is written to app_state by the flow it opens.
/// Also carries the "Restore a business" escape hatch (§7).
class RoleChoiceScreen extends ConsumerWidget {
  const RoleChoiceScreen({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform
        .pickFiles(type: FileType.any, withData: true);
    final data = picked?.files.firstOrNull?.bytes;
    if (data == null || !context.mounted) return;

    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Insets.lg, Insets.sm, Insets.lg, Insets.xl),
          child: PinPad(
            title: 'PIN this backup was encrypted with',
            onCompleted: (entered) async {
              Navigator.pop(sheetContext, entered);
              return true;
            },
          ),
        ),
      ),
    );
    if (pin == null || !context.mounted) return;

    final db = ref.read(databaseProvider);
    final result = await BackupService(db)
        .restoreBackup(Uint8List.fromList(data), pin);
    if (!context.mounted) return;
    await result.when(
      ok: (business) async {
        await db.appStateDao.set(StateKeys.onboardingDone, '1');
        ref.invalidate(bootstrapProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(business.isEmpty
                  ? 'Business restored — this phone is the Hub'
                  : '$business restored — this phone is the Hub')));
          context.go('/products');
        }
      },
      err: (message) async {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Insets.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(Corners.xl),
                  ),
                  child: Icon(Icons.inventory_2_rounded,
                      size: 40, color: theme.colorScheme.onPrimary),
                ),
              ),
              const SizedBox(height: Insets.xl),
              Text('Welcome to StockMesh',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: Insets.sm),
              Text(
                'Inventory that works with no internet.\nPhones sync over your shop Wi-Fi.',
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _RoleCard(
                icon: Icons.storefront_rounded,
                title: 'Set up main business phone',
                subtitle:
                    'This phone becomes the Hub — it keeps the master records and other phones connect to it.',
                onTap: () => context.go('/onboarding/hub-setup'),
              ),
              const SizedBox(height: Insets.lg),
              _RoleCard(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Join an existing business',
                subtitle:
                    'Scan the QR code on the main phone to connect as an attendant.',
                onTap: () => context.go('/onboarding/join'),
              ),
              const SizedBox(height: Insets.lg),
              TextButton.icon(
                onPressed: () => _restore(context, ref),
                icon: const Icon(Icons.settings_backup_restore_rounded),
                label: const Text('Restore a business from backup'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Corners.xl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Insets.xl),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Corners.lg),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: Insets.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: Insets.xs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
