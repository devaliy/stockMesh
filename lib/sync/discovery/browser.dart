import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

import '../../data/db/daos/app_state_dao.dart';
import '../../data/db/database.dart';
import '../transport/ws_transport.dart';

/// Client-side Hub discovery (design.md §5 discovery order):
/// 1. last-known IP, direct TCP probe with a 2 s timeout;
/// 2. mDNS browse for `_stockmesh._tcp`;
/// 3. manual IP entry (Settings → Connection) feeds hub_last_known_ip, so
///    it becomes step 1 on the next attempt.
class HubLocator {
  HubLocator(this._db);

  final AppDatabase _db;

  /// Finds the Hub's address or throws. Successful discovery updates the
  /// last-known IP for the fast path next time.
  Future<String> locate({Duration browseTimeout = const Duration(seconds: 8)}) async {
    final lastKnown = await _db.appStateDao.get(StateKeys.hubLastKnownIp);
    if (lastKnown != null && lastKnown.isNotEmpty) {
      if (await _probe(lastKnown)) return lastKnown;
    }

    final discovered = await _browse(browseTimeout);
    if (discovered != null) {
      await _db.appStateDao.set(StateKeys.hubLastKnownIp, discovered);
      return discovered;
    }

    throw const HubNotFoundException();
  }

  /// Cheap TCP reachability check against the StockMesh port.
  Future<bool> _probe(String host,
      {Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final socket =
          await Socket.connect(host, kStockMeshPort, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _browse(Duration timeout) async {
    final discovery = BonsoirDiscovery(type: '_stockmesh._tcp');
    final completer = Completer<String?>();
    StreamSubscription<BonsoirDiscoveryEvent>? sub;
    Timer? timer;

    Future<void> finish(String? result) async {
      if (completer.isCompleted) return;
      completer.complete(result);
      timer?.cancel();
      await sub?.cancel();
      await discovery.stop();
    }

    try {
      await discovery.ready;
      sub = discovery.eventStream?.listen((event) {
        if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceFound) {
          // Found → ask bonsoir to resolve the host/IP.
          event.service?.resolve(discovery.serviceResolver);
        } else if (event.type ==
            BonsoirDiscoveryEventType.discoveryServiceResolved) {
          final service = event.service;
          if (service is ResolvedBonsoirService) {
            final host = service.host;
            if (host != null && host.isNotEmpty) {
              finish(host);
            }
          }
        }
      });
      await discovery.start();
      timer = Timer(timeout, () => finish(null));
      return await completer.future;
    } catch (_) {
      await finish(null);
      return null;
    }
  }
}

class HubNotFoundException implements Exception {
  const HubNotFoundException();

  @override
  String toString() =>
      'Hub not found — check that both phones share one Wi-Fi network';
}

/// One Hub found on the network — the business name (from the advertiser's
/// `business` TXT attribute) plus its resolved host, for display on the
/// Join screen before the user scans a QR.
class DiscoveredHub {
  const DiscoveredHub({required this.businessName, required this.host});

  final String businessName;
  final String host;
}

/// Live listing of Hubs on the network — used only to show "shops found
/// nearby" on the Join screen (design.md discovery order §5 still applies
/// to the actual connection; this is a UX confidence signal, not a trust
/// boundary). Pairing still requires scanning that Hub's QR: discovery
/// alone never grants a device secret.
class HubBrowser {
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _sub;
  final _controller = StreamController<List<DiscoveredHub>>.broadcast();
  final _found = <String, DiscoveredHub>{}; // keyed by resolved host

  Stream<List<DiscoveredHub>> get hubs => _controller.stream;

  Future<void> start() async {
    if (_discovery != null) return;
    final discovery = BonsoirDiscovery(type: '_stockmesh._tcp');
    _discovery = discovery;
    try {
      await discovery.ready;
      _sub = discovery.eventStream?.listen((event) {
        switch (event.type) {
          case BonsoirDiscoveryEventType.discoveryServiceFound:
            event.service?.resolve(discovery.serviceResolver);
          case BonsoirDiscoveryEventType.discoveryServiceResolved:
            final service = event.service;
            if (service is ResolvedBonsoirService && service.host != null) {
              _found[service.host!] = DiscoveredHub(
                businessName: service.attributes['business'] ??
                    service.name.replaceFirst('StockMesh — ', ''),
                host: service.host!,
              );
              if (!_controller.isClosed) {
                _controller.add(_found.values.toList(growable: false));
              }
            }
          case BonsoirDiscoveryEventType.discoveryServiceLost:
            final host = event.service is ResolvedBonsoirService
                ? (event.service as ResolvedBonsoirService).host
                : null;
            if (host != null) {
              _found.remove(host);
              if (!_controller.isClosed) {
                _controller.add(_found.values.toList(growable: false));
              }
            }
          default:
            break;
        }
      });
      await discovery.start();
    } catch (_) {
      // No mDNS on this network/OS — the list just stays empty; scanning
      // the QR directly still works.
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _discovery?.stop();
    _discovery = null;
    _found.clear();
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
