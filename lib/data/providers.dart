import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/inventory_service.dart';
import '../domain/reporting_service.dart';
import '../domain/sales_service.dart';
import 'db/daos/app_state_dao.dart';
import 'db/database.dart';

/// Composition root for the data/domain layers. Overridden in tests with an
/// in-memory database.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final inventoryServiceProvider = Provider<InventoryService>(
    (ref) => InventoryService(ref.watch(databaseProvider)));

final salesServiceProvider = Provider<SalesService>((ref) => SalesService(
    ref.watch(databaseProvider), ref.watch(inventoryServiceProvider)));

final reportingServiceProvider = Provider<ReportingService>(
    (ref) => ReportingService(ref.watch(databaseProvider)));

/// Identity + bootstrap snapshot loaded once at startup and invalidated when
/// onboarding writes it.
class BootstrapState {
  const BootstrapState({
    required this.onboardingDone,
    required this.role,
    required this.businessName,
    required this.currency,
    required this.deviceId,
    required this.deviceName,
  });

  final bool onboardingDone;
  final String? role; // HUB | ATTENDANT | STOCKTAKER
  final String businessName;
  final String currency;
  final String? deviceId;
  final String deviceName;

  bool get isHub => role == 'HUB';
}

final bootstrapProvider = FutureProvider<BootstrapState>((ref) async {
  final dao = ref.watch(databaseProvider).appStateDao;
  final all = await dao.getAll();
  return BootstrapState(
    onboardingDone: all[StateKeys.onboardingDone] == '1',
    role: all[StateKeys.role],
    businessName: all[StateKeys.businessName] ?? '',
    currency: all[StateKeys.currency] ?? '₦',
    deviceId: all[StateKeys.ownDeviceId],
    deviceName: all[StateKeys.ownDeviceName] ?? 'This device',
  );
});

/// Currency symbol for formatting — reactive so settings changes propagate.
final currencyProvider = Provider<String>((ref) {
  return ref.watch(bootstrapProvider).valueOrNull?.currency ?? '₦';
});

/// The staff member who last passed a PIN check on this device. Cleared on
/// app restart; admin-gated screens re-verify.
final currentStaffProvider = StateProvider<StaffData?>((ref) => null);

/// Live count of unsynced local events — drives the OFFLINE pill badge.
final pendingCountProvider = StreamProvider<int>(
    (ref) => ref.watch(databaseProvider).eventsDao.watchPendingCount());
