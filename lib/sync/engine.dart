import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/daos/app_state_dao.dart';
import '../data/providers.dart';
import '../security/pairing.dart';
import 'client/sync_client.dart';
import 'discovery/advertiser.dart';
import 'discovery/browser.dart';
import 'hub/hub_foreground.dart';
import 'hub/hub_server.dart';
import 'sync_status.dart';
import 'transport/transport.dart';
import 'transport/ws_transport.dart';

/// Role-appropriate networking, started once after onboarding:
/// * HUB — WebSocket server on :47800 inside the foreground service,
///   mDNS advertiser, pairing handler.
/// * ATTENDANT/STOCKTAKER — discovery + reconnecting [SyncClient].
///
/// Owns nothing domain-level: all correctness lives in the sync layer; this
/// is wiring and status reporting for the UI pill.
class SyncEngine {
  SyncEngine(this._ref);

  final Ref _ref;

  bool _started = false;
  HubServer? hubServer;
  PairingService? pairingService;
  WsServer? _wsServer;
  HubAdvertiser? _advertiser;
  SyncClient? _client;

  Future<void> ensureStarted() async {
    if (_started) return;
    final bootstrap = await _ref.read(bootstrapProvider.future);
    if (!bootstrap.onboardingDone) return;
    _started = true;
    if (bootstrap.isHub) {
      await _startHub(bootstrap);
    } else {
      await _startClient(bootstrap);
    }
  }

  Future<void> _startHub(BootstrapState bootstrap) async {
    final db = _ref.read(databaseProvider);

    final server = HubServer(
      db: db,
      onClientCountChanged: (count) {
        _ref.read(connectedDeviceCountProvider.notifier).state = count;
        HubForeground.updateConnectedCount(count);
      },
      onOnlineDevicesChanged: (ids) {
        _ref.read(onlineDevicesProvider.notifier).state = ids;
      },
    );
    hubServer = server;
    pairingService = PairingService(db);
    server.pairingHandler = pairingService!.handle;
    server.start();

    _wsServer = WsServer(onConnection: server.attach);
    try {
      await _wsServer!.start();
    } catch (_) {
      // Port already bound (service restart race) — retry once after stop.
      await _wsServer!.stop();
      await _wsServer!.start();
    }

    _advertiser = HubAdvertiser();
    unawaited(_advertiser!
        .start(businessName: bootstrap.businessName)
        .catchError((Object _) {}));

    await HubForeground.requestNotificationPermission();
    await HubForeground.start();

    // The Hub is its own authority: always LIVE.
    _ref.read(syncPillProvider.notifier).state = SyncPillState.live;
  }

  Future<void> _startClient(BootstrapState bootstrap) async {
    final db = _ref.read(databaseProvider);
    final secret = await db.appStateDao.get(StateKeys.ownSecret);
    final deviceId = bootstrap.deviceId;
    if (secret == null || deviceId == null) return; // not paired yet

    final locator = HubLocator(db);
    final client = SyncClient(
      db: db,
      inventoryService: _ref.read(inventoryServiceProvider),
      deviceId: deviceId,
      secretHex: secret,
      connector: () async {
        final host = await locator.locate();
        final Transport transport = await WsTransport.connect(host);
        return transport;
      },
      onState: (state) {
        _ref.read(syncPillProvider.notifier).state = switch (state) {
          ClientState.live => SyncPillState.live,
          ClientState.syncing ||
          ClientState.connecting =>
            SyncPillState.syncing,
          ClientState.discovering ||
          ClientState.disconnected =>
            SyncPillState.offline,
        };
      },
      onRevoked: _wipeAndReonboard,
    );
    _client = client;
    client.start();
  }

  /// Revocation (§6.5): wipe the local replica and return to onboarding.
  Future<void> _wipeAndReonboard() async {
    final db = _ref.read(databaseProvider);
    await db.transaction(() async {
      await db.delete(db.stockEvents).go();
      await db.delete(db.stockLevels).go();
      await db.delete(db.products).go();
      await db.delete(db.staff).go();
      await db.delete(db.devices).go();
      await db.delete(db.appState).go();
    });
    _started = false;
    _client = null;
    _ref.invalidate(bootstrapProvider);
  }

  Future<void> shutdown() async {
    await _client?.stop();
    await _advertiser?.stop();
    await _wsServer?.stop();
    await hubServer?.shutdown();
    await HubForeground.stop();
    _started = false;
  }
}

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(ref);
  ref.onDispose(engine.shutdown);
  return engine;
});
