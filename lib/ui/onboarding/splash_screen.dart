import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Boot splash while bootstrapProvider loads (router redirects away as soon
/// as app_state is read — this is visible for milliseconds).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(Corners.xxl),
              ),
              child: Icon(Icons.inventory_2_rounded,
                  size: 48, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(height: Insets.xxl),
            Text('StockMesh',
                style: theme.textTheme.headlineLarge!
                    .copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: Insets.sm),
            Text(
              'Offline inventory for your shop',
              style: theme.textTheme.bodyMedium!
                  .copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
