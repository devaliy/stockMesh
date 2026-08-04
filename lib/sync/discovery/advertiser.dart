import 'package:bonsoir/bonsoir.dart';

import '../transport/ws_transport.dart';

/// Hub-side mDNS broadcast: advertises `_stockmesh._tcp` on port 47800 so
/// clients on the same Wi-Fi find the Hub without typing an IP (§2, §9).
class HubAdvertiser {
  BonsoirBroadcast? _broadcast;

  bool get isRunning => _broadcast != null;

  Future<void> start({required String businessName}) async {
    if (_broadcast != null) return;
    final service = BonsoirService(
      name: 'StockMesh — $businessName',
      type: '_stockmesh._tcp',
      port: kStockMeshPort,
      attributes: {'business': businessName},
    );
    final broadcast = BonsoirBroadcast(service: service);
    _broadcast = broadcast;
    await broadcast.ready;
    await broadcast.start();
  }

  Future<void> stop() async {
    await _broadcast?.stop();
    _broadcast = null;
  }
}
