import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Staff PIN hashing (design.md §6.4): 4 digits, salted SHA-256, verified
/// locally on every device — no network needed to confirm who is selling.
/// Stored as `salt:hash` hex in staff.pin_hash.
abstract final class PinHasher {
  static final _random = Random.secure();

  static String hash(String pin) {
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final digest = sha256.convert([...salt, ...utf8.encode(pin)]);
    return '${_hex(salt)}:$digest';
  }

  static bool verify(String pin, String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final salt = _unhex(parts[0]);
    if (salt == null) return false;
    final digest = sha256.convert([...salt, ...utf8.encode(pin)]);
    return _constantTimeEquals(digest.toString(), parts[1]);
  }

  static String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static List<int>? _unhex(String s) {
    if (s.length.isOdd) return null;
    final out = <int>[];
    for (var i = 0; i < s.length; i += 2) {
      final b = int.tryParse(s.substring(i, i + 2), radix: 16);
      if (b == null) return null;
      out.add(b);
    }
    return out;
  }

  /// Compares hex strings without short-circuiting on the first mismatch.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
