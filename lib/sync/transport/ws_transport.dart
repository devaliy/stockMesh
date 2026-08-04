import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

import 'transport.dart';

/// StockMesh speaks WebSocket over TCP on this port (design.md §2).
const int kStockMeshPort = 47800;

/// Production [Transport] over a `dart:io` WebSocket.
class WsTransport implements Transport {
  WsTransport(this._socket) {
    _socket.listen(
      (data) {
        if (data is String && !_incoming.isClosed) _incoming.add(data);
      },
      onDone: _handleDone,
      onError: (Object _) => _handleDone(),
      cancelOnError: true,
    );
  }

  final WebSocket _socket;
  final _incoming = StreamController<String>.broadcast();
  bool _open = true;

  /// Dials the Hub. [timeout] keeps the last-known-IP probe snappy.
  static Future<WsTransport> connect(
    String host, {
    int port = kStockMeshPort,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final socket = await WebSocket.connect('ws://$host:$port')
        .timeout(timeout);
    socket.pingInterval = const Duration(seconds: 10);
    return WsTransport(socket);
  }

  @override
  Stream<String> get incoming => _incoming.stream;

  @override
  bool get isOpen => _open;

  @override
  void send(String frame) {
    if (!_open) return;
    try {
      _socket.add(frame);
    } catch (_) {
      _handleDone();
    }
  }

  void _handleDone() {
    if (!_open) return;
    _open = false;
    _incoming.close();
  }

  @override
  Future<void> close() async {
    if (_open) {
      _open = false;
      await _incoming.close();
    }
    await _socket.close();
  }
}

/// The Hub's listening socket: accepts TCP connections on port 47800 and
/// upgrades them to WebSocket, handing each to [onConnection] (which feeds
/// `HubServer.attach`). Rebind-safe: `stop` then `start` after the
/// foreground service restarts (§9).
class WsServer {
  WsServer({required this.onConnection});

  final void Function(Transport transport) onConnection;

  HttpServer? _server;

  bool get isRunning => _server != null;

  Future<void> start({int port = kStockMeshPort}) async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port,
        shared: true);
    _server = server;
    server.listen((request) async {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response
          ..statusCode = HttpStatus.upgradeRequired
          ..close();
        return;
      }
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.pingInterval = const Duration(seconds: 10);
        onConnection(WsTransport(socket));
      } catch (_) {
        // Malformed upgrade — drop.
      }
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// This device's Wi-Fi/hotspot IPv4 — what the pairing QR embeds.
  ///
  /// Ask the OS for the Wi-Fi station IP first. Prefix-matching alone
  /// (`192.168.*`/`10.*`) cannot tell a Wi-Fi interface apart from a
  /// simultaneously-active mobile data interface — many carriers hand out
  /// private 10.x.x.x addresses under CGNAT, so a phone with mobile data
  /// left on can end up advertising an address the other phone, sitting on
  /// Wi-Fi, can never reach.
  static Future<String?> localIpv4() async {
    try {
      final wifiIp = await NetworkInfo().getWifiIP();
      if (wifiIp != null && wifiIp.isNotEmpty && wifiIp != '0.0.0.0') {
        return wifiIp;
      }
    } catch (_) {
      // Plugin unavailable — fall through to the interface scan below.
    }

    // Not connected to Wi-Fi as a station (e.g. this phone is running its
    // own hotspot): scan interfaces, preferring ones that look like
    // Wi-Fi/hotspot and skipping ones that look like mobile data.
    final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4, includeLinkLocal: false);
    String? wifiLike;
    String? fallback;
    for (final iface in interfaces) {
      final name = iface.name.toLowerCase();
      final looksCellular = name.contains('rmnet') ||
          name.contains('ccmni') ||
          name.contains('cellular') ||
          name.contains('data');
      if (looksCellular) continue;
      final looksWifi = name.contains('wlan') || name.contains('ap');
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        if (looksWifi &&
            (addr.address.startsWith('192.168.') ||
                addr.address.startsWith('10.'))) {
          return addr.address;
        }
        if (looksWifi) wifiLike ??= addr.address;
        fallback ??= addr.address;
      }
    }
    if (wifiLike != null) return wifiLike;
    return fallback;
  }
}
