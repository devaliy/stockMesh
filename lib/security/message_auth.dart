import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// HMAC building blocks for the wire protocol (design.md §5, §6).
///
/// Every authenticated frame carries
/// `mac = HMAC-SHA256(device_secret, "v|type|device_id|nonce|payload_json")`.
/// The Hub knows each device's secret from pairing; a frame whose MAC does
/// not verify is dropped silently (M5 acceptance: tampered payloads vanish).
abstract final class MessageAuth {
  static final _random = Random.secure();

  /// 32 random bytes, hex — used for device secrets and pairing tokens.
  static String randomSecretHex() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Random per-message nonce (16 bytes hex).
  static String nonce() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// The envelope MAC (design.md §5).
  static String envelopeMac({
    required String secretHex,
    required int v,
    required String type,
    required String deviceId,
    required String nonce,
    required String payloadJson,
  }) {
    return hmacHex(secretHex, '$v|$type|$deviceId|$nonce|$payloadJson');
  }

  /// HELLO challenge-response (§6.3): proof of secret possession bound to
  /// this device id and this message's nonce.
  static String challengeResponse({
    required String secretHex,
    required String deviceId,
    required String nonce,
  }) {
    return hmacHex(secretHex, 'hello|$deviceId|$nonce');
  }

  static String hmacHex(String secretHex, String message) {
    final key = _hexToBytes(secretHex) ?? utf8.encode(secretHex);
    return Hmac(sha256, key).convert(utf8.encode(message)).toString();
  }

  /// Constant-time hex comparison — MAC checks must not leak length of the
  /// matching prefix through timing.
  static bool verifyHex(String expected, String actual) {
    if (expected.length != actual.length) return false;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected.codeUnitAt(i) ^ actual.codeUnitAt(i);
    }
    return diff == 0;
  }

  static List<int>? _hexToBytes(String s) {
    if (s.isEmpty || s.length.isOdd) return null;
    final out = <int>[];
    for (var i = 0; i < s.length; i += 2) {
      final b = int.tryParse(s.substring(i, i + 2), radix: 16);
      if (b == null) return null;
      out.add(b);
    }
    return out;
  }
}
