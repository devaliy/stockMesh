import 'dart:convert';

import '../../security/message_auth.dart';
import 'messages.dart';

/// Protocol version. Bump on breaking wire changes; HELLO_REJECT{VERSION}
/// bounces mismatched peers.
const int kProtocolVersion = 1;

/// A decoded, MAC-verified frame.
class Frame {
  const Frame({
    required this.v,
    required this.type,
    required this.deviceId,
    required this.nonce,
    required this.payload,
  });

  final int v;
  final String type;
  final String deviceId;
  final String nonce;
  final Map<String, dynamic> payload;
}

/// JSON envelope encode/decode + HMAC (design.md §5).
///
/// The MAC is computed over the exact serialized payload string that ships
/// inside the frame, so there is no canonicalization step to get wrong:
/// both sides re-encode the decoded payload map with Dart's [jsonEncode],
/// which preserves key order through a decode/encode round trip.
abstract final class Codec {
  /// Builds an authenticated frame. [secretHex] is the sender's device
  /// secret; pairing messages pass null and carry an empty MAC (§6.2 — the
  /// pairing token is the authorization).
  static String encode({
    required String type,
    required String deviceId,
    required Map<String, dynamic> payload,
    String? secretHex,
    String? nonce,
  }) {
    final n = nonce ?? MessageAuth.nonce();
    final payloadJson = jsonEncode(payload);
    final mac = secretHex == null
        ? ''
        : MessageAuth.envelopeMac(
            secretHex: secretHex,
            v: kProtocolVersion,
            type: type,
            deviceId: deviceId,
            nonce: n,
            payloadJson: payloadJson,
          );
    return jsonEncode({
      'v': kProtocolVersion,
      'type': type,
      'device_id': deviceId,
      'nonce': n,
      'payload': payload,
      'mac': mac,
    });
  }

  /// Parses a frame WITHOUT verifying its MAC. Returns null on malformed
  /// input. Callers must follow up with [verify] (except for PAIR_REQUEST,
  /// which is unauthenticated by design).
  static Frame? parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final v = decoded['v'];
    final type = decoded['type'];
    final deviceId = decoded['device_id'];
    final nonce = decoded['nonce'];
    final payload = decoded['payload'];
    if (v is! int ||
        type is! String ||
        deviceId is! String ||
        nonce is! String ||
        payload is! Map<String, dynamic>) {
      return null;
    }
    return Frame(
        v: v, type: type, deviceId: deviceId, nonce: nonce, payload: payload);
  }

  /// True when [raw]'s MAC verifies under [secretHex]. Uses the re-encoded
  /// payload (see class docs) and constant-time comparison.
  static bool verify(String raw, Frame frame, String secretHex) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return false;
    }
    if (decoded is! Map<String, dynamic>) return false;
    final mac = decoded['mac'];
    if (mac is! String || mac.isEmpty) return false;
    final expected = MessageAuth.envelopeMac(
      secretHex: secretHex,
      v: frame.v,
      type: frame.type,
      deviceId: frame.deviceId,
      nonce: frame.nonce,
      payloadJson: jsonEncode(frame.payload),
    );
    return MessageAuth.verifyHex(expected, mac);
  }

  /// True for the message types allowed to arrive without a MAC.
  static bool isPairingType(String type) =>
      type == MsgType.pairRequest ||
      type == MsgType.pairAccept ||
      type == MsgType.pairReject;
}
