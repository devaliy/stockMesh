import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../security/pin_hasher.dart';
import '../../theme/app_theme.dart';

/// Big-target 4-digit PIN pad (design screen 05). Fires [onCompleted] when
/// the fourth digit lands; the caller decides what "correct" means.
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onCompleted, this.title});

  final Future<bool> Function(String pin) onCompleted;
  final String? title;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _entered = '';
  bool _error = false;
  bool _busy = false;

  Future<void> _append(String digit) async {
    if (_busy || _entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = false;
    });
    if (_entered.length == 4) {
      setState(() => _busy = true);
      final ok = await widget.onCompleted(_entered);
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _entered = '';
          _error = true;
          _busy = false;
        });
      }
    }
  }

  void _backspace() {
    if (_entered.isEmpty || _busy) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!, style: theme.textTheme.titleMedium),
          const SizedBox(height: Insets.lg),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < _entered.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: Insets.sm),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (_error ? theme.colorScheme.error : theme.colorScheme.primary)
                    : theme.colorScheme.surfaceContainerHighest,
                border: _error
                    ? Border.all(color: theme.colorScheme.error)
                    : null,
              ),
            );
          }),
        ),
        SizedBox(
          height: Insets.xl,
          child: _error
              ? Center(
                  child: Text(
                    'Wrong PIN — try again',
                    style: theme.textTheme.labelMedium!
                        .copyWith(color: theme.colorScheme.error),
                  ),
                )
              : null,
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in row) _key(context, d)],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 76, height: 64),
            _key(context, '0'),
            SizedBox(
              width: 76,
              height: 64,
              child: IconButton(
                onPressed: _backspace,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(BuildContext context, String digit) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xs),
      child: SizedBox(
        width: 68,
        height: 64,
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Corners.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(Corners.lg),
            onTap: () => _append(digit),
            child: Center(
              child: Text(digit,
                  style: theme.textTheme.headlineMedium!
                      .copyWith(fontFeatures: tabularFigures)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that resolves to the staff member whose PIN was entered, or
/// null if dismissed. Every stock event carries this staff_ref (§6.4).
Future<StaffData?> verifyStaffPin(BuildContext context, WidgetRef ref,
    {String title = 'Enter staff PIN', bool requireAdmin = false}) {
  final db = ref.read(databaseProvider);
  return showModalBottomSheet<StaffData>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, Insets.sm, Insets.lg, Insets.xl),
        child: PinPad(
          title: title,
          onCompleted: (pin) async {
            final staff = await db.staffDao.getActive();
            for (final s in staff) {
              if (requireAdmin && !s.isAdmin) continue;
              if (PinHasher.verify(pin, s.pinHash)) {
                if (sheetContext.mounted) Navigator.pop(sheetContext, s);
                return true;
              }
            }
            return false;
          },
        ),
      ),
    ),
  );
}
