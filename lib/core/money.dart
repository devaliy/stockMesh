/// Money helpers. All amounts are `int` kobo (1/100 of the major unit).
///
/// Invariant: floating point NEVER touches money. Formatting and parsing are
/// pure integer/string operations — no binary floating type appears anywhere
/// in this file (enforced by a test, per the M1 acceptance criteria).
library;

/// Default currency symbol (design direction §8.2 shows ₦).
const String kNaira = '₦';

/// Formats [kobo] as a display string: `123456` → `₦1,234.56`.
///
/// [symbol] comes from app_state's `currency` key. Set [showDecimals] false
/// for compact dashboard figures (`₦1,234`; rounds toward zero).
String formatKobo(int kobo, {String symbol = kNaira, bool showDecimals = true}) {
  final negative = kobo < 0;
  final abs = kobo.abs();
  final major = abs ~/ 100;
  final minor = abs % 100;
  final buffer = StringBuffer();
  if (negative) buffer.write('-');
  buffer.write(symbol);
  buffer.write(_groupThousands(major.toString()));
  if (showDecimals) {
    buffer.write('.');
    buffer.write(minor.toString().padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Formats a bare quantity with thousands separators: `12345` → `12,345`.
String formatQty(int qty) {
  final negative = qty < 0;
  final grouped = _groupThousands(qty.abs().toString());
  return negative ? '-$grouped' : grouped;
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  final len = digits.length;
  for (var i = 0; i < len; i++) {
    if (i != 0 && (len - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Parses user input (`"1,234.5"`, `"₦1,234.56"`, `"500"`) into kobo.
/// Returns null for empty/invalid input or more than 2 decimal places.
/// Pure string→int; no floating point.
int? parseToKobo(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  var negative = false;
  if (s.startsWith('-')) {
    negative = true;
    s = s.substring(1);
  }
  // Strip currency symbols and grouping commas.
  s = s.replaceAll(RegExp(r'[₦$,\s]'), '');
  if (s.isEmpty) return null;
  final parts = s.split('.');
  if (parts.length > 2) return null;
  final majorStr = parts[0].isEmpty ? '0' : parts[0];
  var minorStr = parts.length == 2 ? parts[1] : '';
  if (minorStr.length > 2) return null;
  minorStr = minorStr.padRight(2, '0');
  final major = int.tryParse(majorStr);
  final minor = minorStr.isEmpty ? 0 : int.tryParse(minorStr);
  if (major == null || minor == null) return null;
  final kobo = major * 100 + minor;
  return negative ? -kobo : kobo;
}
