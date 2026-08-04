import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import 'devices/devices_screen.dart';
import 'devices/pairing_screen.dart';
import 'onboarding/hub_setup_screen.dart';
import 'onboarding/join_business_screen.dart';
import 'onboarding/role_choice_screen.dart';
import 'onboarding/splash_screen.dart';
import 'products/product_details_screen.dart';
import 'products/product_form_screen.dart';
import 'products/products_screen.dart';
import 'receive/receive_screen.dart';
import 'reports/reports_screen.dart';
import 'sell/sell_screen.dart';
import 'settings/backup_screen.dart';
import 'settings/connection_screen.dart';
import 'settings/more_screen.dart';
import 'settings/staff_screen.dart';
import 'shell/app_shell.dart';
import 'stock_count/stock_count_screen.dart';
import 'stock_count/stock_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Route table. Onboarding gates everything: until onboarding completes,
/// every navigation lands on the role-choice flow (invariant §1.6 — role is
/// chosen once in the first-run wizard).
final routerProvider = Provider<GoRouter>((ref) {
  final bootstrap = ref.watch(bootstrapProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (bootstrap.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }
      final done = bootstrap.valueOrNull?.onboardingDone ?? false;
      // Splash always hands off once loading finishes — it must never be
      // treated as "already in onboarding" or the app parks here forever.
      if (loc == '/splash') return done ? '/sell' : '/onboarding';
      final inOnboarding = loc.startsWith('/onboarding');
      if (!done && !inOnboarding) return '/onboarding';
      if (done && inOnboarding) return '/sell';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const RoleChoiceScreen()),
      GoRoute(
          path: '/onboarding/hub-setup',
          builder: (_, _) => const HubSetupScreen()),
      GoRoute(
          path: '/onboarding/join',
          builder: (_, _) => const JoinBusinessScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/sell', builder: (_, _) => const SellScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/stock',
              builder: (_, _) => const StockScreen(),
              routes: [
                GoRoute(
                    path: 'receive',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const ReceiveScreen()),
                GoRoute(
                    path: 'count',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const StockCountScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/products',
              builder: (_, _) => const ProductsScreen(),
              routes: [
                GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, _) => const ProductFormScreen()),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => ProductDetailsScreen(
                      productId: state.pathParameters['id']!),
                  routes: [
                    GoRoute(
                        path: 'edit',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (_, state) => ProductFormScreen(
                            productId: state.pathParameters['id'])),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              builder: (_, _) => const MoreScreen(),
              routes: [
                GoRoute(
                  path: 'devices',
                  builder: (_, _) => const DevicesScreen(),
                  routes: [
                    GoRoute(
                        path: 'pair',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (_, _) => const PairingScreen()),
                  ],
                ),
                GoRoute(
                    path: 'staff', builder: (_, _) => const StaffScreen()),
                GoRoute(
                    path: 'backup', builder: (_, _) => const BackupScreen()),
                GoRoute(
                    path: 'connection',
                    builder: (_, _) => const ConnectionScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
