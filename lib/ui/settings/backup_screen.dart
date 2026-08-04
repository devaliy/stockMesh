import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup_service.dart';
import '../../data/db/daos/app_state_dao.dart';
import '../../data/providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/pin_pad.dart';

final _lastBackupProvider = StreamProvider<int?>((ref) => ref
    .watch(databaseProvider)
    .appStateDao
    .watch(StateKeys.lastBackupAt)
    .map((v) => v == null ? null : int.tryParse(v)));

/// Backup & restore (§7). Backup: PIN-encrypted zip via the share sheet.
/// Restore: replaces everything on this phone and re-seats it as the Hub.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<String?> _collectPin(String title) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Insets.lg, Insets.sm, Insets.lg, Insets.xl),
          child: PinPad(
            title: title,
            onCompleted: (pin) async {
              Navigator.pop(sheetContext, pin);
              return true;
            },
          ),
        ),
      ),
    );
  }

  Future<void> _backupNow() async {
    // The PIN both authorizes the export and becomes the encryption key.
    final admin = await verifyStaffPin(context, ref,
        title: 'Admin PIN — also encrypts the backup', requireAdmin: true);
    if (admin == null || !mounted) return;
    final pin = await _collectPin('Re-enter the PIN to encrypt with');
    if (pin == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final bytes = await BackupService(ref.read(databaseProvider))
          .createBackup(pin);
      final stamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: 'stockmesh-backup-$stamp.smbk',
            mimeType: 'application/octet-stream',
          )
        ],
        subject: 'StockMesh backup $stamp',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
            'Everything currently on this phone will be replaced by the '
            'backup, and this phone becomes the Hub. Attendant phones must '
            'be paired again afterwards.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Replace everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final picked = await FilePicker.platform
        .pickFiles(type: FileType.any, withData: true);
    final data = picked?.files.firstOrNull?.bytes;
    if (data == null || !mounted) return;

    final pin = await _collectPin('PIN this backup was encrypted with');
    if (pin == null || !mounted) return;

    setState(() => _busy = true);
    final result = await BackupService(ref.read(databaseProvider))
        .restoreBackup(Uint8List.fromList(data), pin);
    if (!mounted) return;
    setState(() => _busy = false);

    result.when(
      ok: (business) {
        ref.invalidate(bootstrapProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(business.isEmpty
                ? 'Backup restored'
                : '$business restored — this phone is now the Hub')));
      },
      err: (message) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = StockMeshTokens.of(context);
    final lastBackup = ref.watch(_lastBackupProvider).valueOrNull;
    final overdue = lastBackup == null ||
        DateTime.now().millisecondsSinceEpoch - lastBackup >
            const Duration(days: 7).inMilliseconds;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & restore')),
      body: ListView(
        padding: const EdgeInsets.all(Insets.lg),
        children: [
          if (overdue)
            Card(
              color: tokens.warningContainer,
              child: Padding(
                padding: const EdgeInsets.all(Insets.xl),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: tokens.onWarningContainer),
                    const SizedBox(width: Insets.md),
                    Expanded(
                      child: Text(
                        lastBackup == null
                            ? 'No backup yet. If this phone is lost, the '
                                'business records go with it.'
                            : 'Last backup was over a week ago.',
                        style: theme.textTheme.bodyMedium!
                            .copyWith(color: tokens.onWarningContainer),
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
                ListTile(
                  leading: Icon(Icons.cloud_download_outlined,
                      color: theme.colorScheme.primary),
                  title: const Text('Back up now'),
                  subtitle: Text(lastBackup == null
                      ? 'Encrypted with your admin PIN'
                      : 'Last backup ${DateFormat('d MMM, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(lastBackup))}'),
                  trailing: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _busy ? null : _backupNow,
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.settings_backup_restore_rounded,
                      color: theme.colorScheme.error),
                  title: const Text('Restore a backup'),
                  subtitle:
                      const Text('Replaces everything on this phone'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _busy ? null : _restore,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Insets.xl),
              child: Text(
                'Back up weekly. Send the file to WhatsApp (message '
                'yourself), Google Drive, or a computer — anywhere outside '
                'this phone. Without the admin PIN the file cannot be '
                'opened.',
                style: theme.textTheme.bodyMedium!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
