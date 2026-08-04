import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Standard empty/error state (design §8.4: every list has one; offline is a
/// normal state, not an error state).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: Insets.xxl),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: Insets.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Insets.xxl),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
