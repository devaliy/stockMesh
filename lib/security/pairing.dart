import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../data/db/daos/app_state_dao.dart';
import '../data/db/database.dart';
import '../sync/protocol/codec.dart';
import '../sync/protocol/messages.dart';
import '../sync/transport/transport.dart';
import '../sync/transport/ws_transport.dart';
import 'message_auth.dart';

/// What the pairing QR encodes (design.md §6.1).
class PairingQr {
  const PairingQr({required this.ip, required this.port, required this.token});

  final String ip;
  final int port;
  final String token;

  String encode() => jsonEncode({'ip': ip, 'port': port, 'token': token});

  static PairingQr? decode(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      final ip = map['ip'];
      final port = map['port'];
      final token = map['token'];
      if (ip is! String || port is! int || token is! String) return null;
      return PairingQr(ip: ip, port: port, token: token);
    } on FormatException {
      return null;
    }
  }
}

class _IssuedToken {
  _IssuedToken(this.token) : expiresAt = DateTime.now().add(tokenLifetime);

  static const tokenLifetime = Duration(minutes: 5);

  final String token;
  final DateTime expiresAt;
  bool used = false;

  bool get isValid => !used && DateTime.now().isBefore(expiresAt);
}

/// Hub-side pairing (design.md §6): single-use 5-minute tokens shown as QR;
/// consuming one registers the device and hands it its HMAC secret — the
/// only time that secret ever crosses the wire.
class PairingService {
  PairingService(this._db);

  final AppDatabase _db;
  final _tokens = <String, _IssuedToken>{};

  /// Mints a token and returns the QR content. Previous unused tokens stay
  /// valid until their own expiry (staff may open two pairing screens).
  /// Throws [NoLocalIpException] rather than issuing a QR that can never be
  /// reached — that failure is silent and confusing on the other end.
  Future<PairingQr> issueToken() async {
    _prune();
    final ip = await WsServer.localIpv4();
    if (ip == null) throw const NoLocalIpException();
    final token = MessageAuth.randomSecretHex();
    _tokens[token] = _IssuedToken(token);
    return PairingQr(ip: ip, port: kStockMeshPort, token: token);
  }

  void _prune() {
    _tokens.removeWhere((_, t) => !t.isValid);
  }

  /// HubServer.pairingHandler target: consumes a raw first-frame that looked
  /// like a PAIR_REQUEST. Always returns true (the connection is spent on
  /// pairing either way — reject closes it).
  Future<bool> handle(Transport transport, String raw) async {
    final frame = Codec.parse(raw);
    if (frame == null || frame.type != MsgType.pairRequest) {
      await transport.close();
      return true;
    }

    void reject(String reason) {
      transport.send(Codec.encode(
        type: MsgType.pairReject,
        deviceId: 'hub',
        payload: PairRejectPayload(reason: reason).toJson(),
      ));
      transport.close();
    }

    final PairRequestPayload request;
    try {
      request = PairRequestPayload.fromJson(frame.payload);
    } catch (_) {
      await transport.close();
      return true;
    }

    _prune();
    final issued = _tokens[request.token];
    if (issued == null || !issued.isValid) {
      reject('BAD_TOKEN'); // expired, unknown, or already used (§6.3 burn)
      return true;
    }
    final role = request.roleRequested;
    if (role != 'ATTENDANT' && role != 'STOCKTAKER') {
      reject('BAD_ROLE');
      return true;
    }
    final existing = await _db.devicesDao.getById(request.deviceId);
    if (existing != null && existing.isRevoked) {
      reject('REVOKED');
      return true;
    }

    issued.used = true; // burn before replying — a replay must fail

    final secret = MessageAuth.randomSecretHex();
    await _db.devicesDao.upsertDevice(DevicesCompanion.insert(
      deviceId: request.deviceId,
      displayName: request.deviceName,
      role: role,
      secretHash: secret,
      isRevoked: const Value(false),
    ));

    final state = await _db.appStateDao.getAll();
    transport.send(Codec.encode(
      type: MsgType.pairAccept,
      deviceId: 'hub',
      payload: PairAcceptPayload(
        deviceSecret: secret,
        businessName: state[StateKeys.businessName] ?? '',
        currency: state[StateKeys.currency] ?? '₦',
      ).toJson(),
    ));
    // Give the frame a beat to flush, then close — pairing connections are
    // single-purpose; the client reconnects as a normal session.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await transport.close();
    return true;
  }
}

/// Client-side pairing: dial the QR's address, trade the token for a device
/// secret, persist identity. The caller then starts the normal sync client.
class PairingClient {
  const PairingClient(this._db);

  final AppDatabase _db;

  Future<PairOutcome> pair({
    required PairingQr qr,
    required String deviceId,
    required String deviceName,
    String role = 'ATTENDANT',
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final Transport transport;
    try {
      transport = await WsTransport.connect(qr.ip, port: qr.port);
    } catch (_) {
      return const PairOutcome.failure(
          'Could not reach the main phone. Same Wi-Fi network?');
    }

    try {
      final reply = Completer<Frame>();
      final sub = transport.incoming.listen((raw) {
        final frame = Codec.parse(raw);
        if (frame != null && !reply.isCompleted) reply.complete(frame);
      }, onDone: () {
        if (!reply.isCompleted) {
          reply.completeError(const HubNotRespondingException());
        }
      });

      transport.send(Codec.encode(
        type: MsgType.pairRequest,
        deviceId: deviceId,
        payload: PairRequestPayload(
          token: qr.token,
          deviceId: deviceId,
          deviceName: deviceName,
          roleRequested: role,
        ).toJson(),
      ));

      final frame = await reply.future.timeout(timeout);
      await sub.cancel();

      if (frame.type == MsgType.pairAccept) {
        final accept = PairAcceptPayload.fromJson(frame.payload);
        final state = _db.appStateDao;
        await _db.transaction(() async {
          await state.set(StateKeys.role, role);
          await state.set(StateKeys.businessName, accept.businessName);
          await state.set(StateKeys.currency, accept.currency);
          await state.set(StateKeys.ownDeviceId, deviceId);
          await state.set(StateKeys.ownDeviceName, deviceName);
          await state.set(StateKeys.ownSecret, accept.deviceSecret);
          await state.set(StateKeys.hubLastKnownIp, qr.ip);
        });
        return PairOutcome.success(accept.businessName);
      }
      if (frame.type == MsgType.pairReject) {
        final reason = PairRejectPayload.fromJson(frame.payload).reason;
        return PairOutcome.failure(switch (reason) {
          'BAD_TOKEN' =>
            'That QR code has expired — generate a fresh one on the main phone.',
          'REVOKED' =>
            'This phone was removed from the business. Ask the owner to re-add it.',
          _ => 'Pairing was declined ($reason).',
        });
      }
      return const PairOutcome.failure('Unexpected reply from the main phone.');
    } on TimeoutException {
      return const PairOutcome.failure('The main phone did not respond.');
    } on HubNotRespondingException {
      return const PairOutcome.failure('The main phone closed the connection.');
    } finally {
      await transport.close();
    }
  }
}

class PairOutcome {
  const PairOutcome.success(this.businessName) : error = null;
  const PairOutcome.failure(this.error) : businessName = null;

  final String? businessName;
  final String? error;

  bool get ok => error == null;
}

class HubNotRespondingException implements Exception {
  const HubNotRespondingException();
}

/// Thrown by [PairingService.issueToken] when this phone has no discoverable
/// Wi-Fi/hotspot IPv4 address — issuing a QR would just fail silently on
/// the other end.
class NoLocalIpException implements Exception {
  const NoLocalIpException();
}
