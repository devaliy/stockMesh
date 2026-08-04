import 'package:flutter_test/flutter_test.dart';
import 'package:stockmesh/theme/app_theme.dart';

void main() {
  test('theme is built from Stitch tokens', () {
    final theme = buildAppTheme();
    expect(theme.colorScheme.primary, StitchPalette.primary);
    expect(theme.colorScheme.surface, StitchPalette.background);
    expect(theme.extension<StockMeshTokens>(), isNotNull);
    expect(theme.textTheme.bodyLarge!.fontSize, 16);
  });
}
