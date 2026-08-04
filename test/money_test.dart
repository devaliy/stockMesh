import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stockmesh/core/money.dart';

void main() {
  group('formatKobo', () {
    test('formats with thousands separators and two decimals', () {
      expect(formatKobo(123456), '₦1,234.56');
      expect(formatKobo(0), '₦0.00');
      expect(formatKobo(5), '₦0.05');
      expect(formatKobo(100), '₦1.00');
      expect(formatKobo(100000000), '₦1,000,000.00');
    });

    test('handles negatives and custom symbols', () {
      expect(formatKobo(-123456), '-₦1,234.56');
      expect(formatKobo(250000, symbol: r'$'), r'$2,500.00');
      expect(formatKobo(123456, showDecimals: false), '₦1,234');
    });
  });

  group('parseToKobo', () {
    test('parses plain and formatted amounts', () {
      expect(parseToKobo('1234.56'), 123456);
      expect(parseToKobo('1,234.56'), 123456);
      expect(parseToKobo('₦1,234.56'), 123456);
      expect(parseToKobo('500'), 50000);
      expect(parseToKobo('0.5'), 50);
      expect(parseToKobo('.5'), 50);
      expect(parseToKobo('-12.34'), -1234);
    });

    test('rejects invalid input', () {
      expect(parseToKobo(''), isNull);
      expect(parseToKobo('abc'), isNull);
      expect(parseToKobo('1.2.3'), isNull);
      expect(parseToKobo('1.234'), isNull); // more than 2 decimal places
    });

    test('round-trips every kobo value across a wide range', () {
      for (var kobo = -100050; kobo <= 100050; kobo += 37) {
        final display = formatKobo(kobo, symbol: '');
        expect(parseToKobo(display), kobo, reason: 'round-trip of $kobo');
      }
    });
  });

  test('money.dart never touches floating point (M1 acceptance)', () {
    final source = File('lib/core/money.dart').readAsStringSync();
    expect(source.contains('double'), isFalse,
        reason: 'lib/core/money.dart must contain no `double`');
  });
}
