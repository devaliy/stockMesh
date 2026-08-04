import 'package:flutter_test/flutter_test.dart';
import 'package:stockmesh/data/db/daos/app_state_dao.dart';
import 'package:stockmesh/data/db/database.dart';
import 'package:stockmesh/security/pairing.dart';
import 'package:stockmesh/security/pin_hasher.dart';
import 'package:stockmesh/sync/protocol/codec.dart';
import 'package:stockmesh/sync/protocol/messages.dart';
import 'package:stockmesh/sync/transport/memory_transport.dart';

import 'helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late PairingService service;

  setUp(() async {
    db = testDb();
    await db.appStateDao.set(StateKeys.businessName, 'Test Shop');
    await db.appStateDao.set(StateKeys.currency, '₦');
    service = PairingService(db);
  });

  tearDown(() => db.close());

  String pairRequestFrame(String token, {String deviceId = 'device-x'}) =>
      Codec.encode(
        type: MsgType.pairRequest,
        deviceId: deviceId,
        payload: PairRequestPayload(
          token: token,
          deviceId: deviceId,
          deviceName: 'Test phone',
          roleRequested: 'ATTENDANT',
        ).toJson(),
      );

  Future<Frame?> handleAndReply(String frameJson) async {
    final pair = MemoryTransportPair();
    Frame? reply;
    final sub = pair.client.incoming.listen((raw) {
      reply ??= Codec.parse(raw);
    });
    await service.handle(pair.server, frameJson);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel();
    return reply;
  }

  test('valid token pairs the device and hands out a secret', () async {
    final qr = await service.issueToken();
    final reply = await handleAndReply(pairRequestFrame(qr.token));

    expect(reply, isNotNull);
    expect(reply!.type, MsgType.pairAccept);
    final accept = PairAcceptPayload.fromJson(reply.payload);
    expect(accept.businessName, 'Test Shop');
    expect(accept.deviceSecret, hasLength(64)); // 32 bytes hex

    final device = await db.devicesDao.getById('device-x');
    expect(device, isNotNull);
    expect(device!.secretHash, accept.deviceSecret);
    expect(device.role, 'ATTENDANT');
  });

  test('M5: a used token is burned — replay gets BAD_TOKEN', () async {
    final qr = await service.issueToken();
    final first = await handleAndReply(pairRequestFrame(qr.token));
    expect(first!.type, MsgType.pairAccept);

    final replay = await handleAndReply(
        pairRequestFrame(qr.token, deviceId: 'device-y'));
    expect(replay!.type, MsgType.pairReject);
    expect(PairRejectPayload.fromJson(replay.payload).reason, 'BAD_TOKEN');
    expect(await db.devicesDao.getById('device-y'), isNull);
  });

  test('M5: unknown token is rejected', () async {
    final reply = await handleAndReply(pairRequestFrame('not-a-real-token'));
    expect(reply!.type, MsgType.pairReject);
  });

  test('revoked device cannot re-pair even with a fresh token', () async {
    final qr1 = await service.issueToken();
    final first = await handleAndReply(pairRequestFrame(qr1.token));
    expect(first!.type, MsgType.pairAccept);

    await db.devicesDao.revoke('device-x');

    final qr2 = await service.issueToken();
    final again = await handleAndReply(pairRequestFrame(qr2.token));
    expect(again!.type, MsgType.pairReject);
    expect(PairRejectPayload.fromJson(again.payload).reason, 'REVOKED');
  });

  test('QR payload round-trips', () async {
    const qr = PairingQr(ip: '192.168.1.7', port: 47800, token: 'abc123');
    final decoded = PairingQr.decode(qr.encode());
    expect(decoded!.ip, '192.168.1.7');
    expect(decoded.port, 47800);
    expect(decoded.token, 'abc123');
    expect(PairingQr.decode('random text'), isNull);
    expect(PairingQr.decode('{"ip": 5}'), isNull);
  });

  test('PIN hashing verifies correct PINs and rejects wrong ones', () {
    final stored = PinHasher.hash('4821');
    expect(PinHasher.verify('4821', stored), isTrue);
    expect(PinHasher.verify('4822', stored), isFalse);
    expect(PinHasher.verify('4821', 'malformed'), isFalse);
    // Same PIN, new salt → different hash.
    expect(PinHasher.hash('4821'), isNot(stored));
  });
}
