import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../security/pin_hasher.dart';
import '../../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/pin_pad.dart';

final _staffProvider = StreamProvider<List<StaffData>>(
    (ref) => ref.watch(databaseProvider).staffDao.watchActive());

/// Staff & PINs (Hub, admin-gated). Staff rows sync to attendants via
/// REF_UPDATE so PINs verify locally on every device (§6.4).
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  Future<void> _addStaff(BuildContext context, WidgetRef ref) async {
    final admin = await verifyStaffPin(context, ref,
        title: 'Admin PIN to add staff', requireAdmin: true);
    if (admin == null || !context.mounted) return;

    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New staff member'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, nameController.text.trim()),
            child: const Text('Next — set PIN'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;

    final pin = await _collectPin(context, 'Set a 4-digit PIN for $name');
    if (pin == null || !context.mounted) return;

    await ref.read(databaseProvider).staffDao.upsertStaff(
          StaffCompanion.insert(
            staffRef: newId(),
            displayName: name,
            pinHash: PinHasher.hash(pin),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$name can now sell')));
    }
  }

  Future<String?> _collectPin(BuildContext context, String title) {
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

  Future<void> _resetPin(
      BuildContext context, WidgetRef ref, StaffData staff) async {
    final admin = await verifyStaffPin(context, ref,
        title: 'Admin PIN to reset', requireAdmin: true);
    if (admin == null || !context.mounted) return;
    final pin =
        await _collectPin(context, 'New PIN for ${staff.displayName}');
    if (pin == null || !context.mounted) return;
    await ref.read(databaseProvider).staffDao.upsertStaff(StaffCompanion(
          staffRef: Value(staff.staffRef),
          displayName: Value(staff.displayName),
          pinHash: Value(PinHasher.hash(pin)),
          isAdmin: Value(staff.isAdmin),
          isActive: const Value(true),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN updated for ${staff.displayName}')));
    }
  }

  Future<void> _deactivate(
      BuildContext context, WidgetRef ref, StaffData staff) async {
    if (staff.isAdmin) return;
    final admin = await verifyStaffPin(context, ref,
        title: 'Admin PIN to remove staff', requireAdmin: true);
    if (admin == null || !context.mounted) return;
    await ref.read(databaseProvider).staffDao.upsertStaff(StaffCompanion(
          staffRef: Value(staff.staffRef),
          displayName: Value(staff.displayName),
          pinHash: Value(staff.pinHash),
          isAdmin: Value(staff.isAdmin),
          isActive: const Value(false),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${staff.displayName} can no longer sell (history kept)')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final staff = ref.watch(_staffProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Staff & PINs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addStaff(context, ref),
        icon: const Icon(Icons.person_add_alt_rounded),
        label: const Text('Add staff'),
      ),
      body: staff.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Could not load staff',
            message: '$e'),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.only(top: Insets.sm, bottom: 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(indent: Insets.lg),
          itemBuilder: (context, index) {
            final member = list[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  member.displayName.isEmpty
                      ? '?'
                      : member.displayName[0].toUpperCase(),
                  style: theme.textTheme.titleSmall!
                      .copyWith(color: theme.colorScheme.primary),
                ),
              ),
              title: Text(member.displayName),
              subtitle:
                  Text(member.isAdmin ? 'Admin' : 'Sales attendant'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) => switch (action) {
                  'pin' => _resetPin(context, ref, member),
                  'remove' => _deactivate(context, ref, member),
                  _ => null,
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'pin', child: Text('Reset PIN')),
                  if (!member.isAdmin)
                    const PopupMenuItem(
                        value: 'remove', child: Text('Remove')),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
