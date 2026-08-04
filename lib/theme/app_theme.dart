import 'package:flutter/material.dart';

/// Design tokens extracted from the Google Stitch exports
/// (`design/stitch/tokens.md`). This file is the single place colors live —
/// screens must pull everything from [Theme.of] / [StockMeshTokens.of] and
/// never hardcode hex values (design.md §8).
abstract final class StitchPalette {
  static const primary = Color(0xFF006B2C);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF00873A);
  static const onPrimaryContainer = Color(0xFFF7FFF2);
  static const inversePrimary = Color(0xFF62DF7D);

  static const secondary = Color(0xFF0051D5);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF316BF3);
  static const onSecondaryContainer = Color(0xFFFEFCFF);
  // A soft blue chip surface used by the Stitch dashboard for info cards.
  static const secondaryFixed = Color(0xFFDBE1FF);
  static const onSecondaryFixed = Color(0xFF00174B);

  static const tertiary = Color(0xFF712AE2);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF8A4CFC);
  static const onTertiaryContainer = Color(0xFFFFFBFF);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const background = Color(0xFFF8F9FF);
  static const onBackground = Color(0xFF0B1C30);
  static const surfaceDim = Color(0xFFCBDBF5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFEFF4FF);
  static const surfaceContainer = Color(0xFFE5EEFF);
  static const surfaceContainerHigh = Color(0xFFDCE9FF);
  static const surfaceContainerHighest = Color(0xFFD3E4FE);
  static const onSurfaceVariant = Color(0xFF3E4A3D);
  static const outline = Color(0xFF6E7B6C);
  static const outlineVariant = Color(0xFFBDCABA);
  static const inverseSurface = Color(0xFF213145);
  static const inverseOnSurface = Color(0xFFEAF1FF);
  static const surfaceTint = Color(0xFF006E2D);

  // Semantic extras (tokens.md "StockMeshTokens" table).
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFEF3C7);
  static const onWarningContainer = Color(0xFF78350F);
  static const offline = Color(0xFF64748B);
  static const offlineContainer = Color(0xFFE2E8F0);
  static const onOfflineContainer = Color(0xFF334155);
}

/// Spacing / radius / sizing scale (tokens.md). 8px base grid.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16; // screen margin & gutter
  static const double xl = 20; // card internal padding
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double touchTarget = 48;
  static const double ctaHeight = 56;
}

abstract final class Corners {
  static const double sm = 4;
  static const double md = 8; // inputs, buttons
  static const double lg = 12;
  static const double xl = 16; // cards
  static const double xxl = 24; // sheets, big CTAs
}

/// Semantic colors that have no Material 3 role — amber warnings for low
/// stock / SYNCING, slate gray for OFFLINE (design direction §8.2).
@immutable
class StockMeshTokens extends ThemeExtension<StockMeshTokens> {
  const StockMeshTokens({
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.offline,
    required this.offlineContainer,
    required this.onOfflineContainer,
    required this.infoChip,
    required this.onInfoChip,
  });

  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color offline;
  final Color offlineContainer;
  final Color onOfflineContainer;
  final Color infoChip;
  final Color onInfoChip;

  static const light = StockMeshTokens(
    warning: StitchPalette.warning,
    warningContainer: StitchPalette.warningContainer,
    onWarningContainer: StitchPalette.onWarningContainer,
    success: StitchPalette.primary,
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF14532D),
    offline: StitchPalette.offline,
    offlineContainer: StitchPalette.offlineContainer,
    onOfflineContainer: StitchPalette.onOfflineContainer,
    infoChip: StitchPalette.secondaryFixed,
    onInfoChip: StitchPalette.onSecondaryFixed,
  );

  static StockMeshTokens of(BuildContext context) =>
      Theme.of(context).extension<StockMeshTokens>()!;

  @override
  StockMeshTokens copyWith({
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? offline,
    Color? offlineContainer,
    Color? onOfflineContainer,
    Color? infoChip,
    Color? onInfoChip,
  }) {
    return StockMeshTokens(
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      offline: offline ?? this.offline,
      offlineContainer: offlineContainer ?? this.offlineContainer,
      onOfflineContainer: onOfflineContainer ?? this.onOfflineContainer,
      infoChip: infoChip ?? this.infoChip,
      onInfoChip: onInfoChip ?? this.onInfoChip,
    );
  }

  @override
  StockMeshTokens lerp(StockMeshTokens? other, double t) {
    if (other == null) return this;
    return StockMeshTokens(
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      offlineContainer: Color.lerp(offlineContainer, other.offlineContainer, t)!,
      onOfflineContainer:
          Color.lerp(onOfflineContainer, other.onOfflineContainer, t)!,
      infoChip: Color.lerp(infoChip, other.infoChip, t)!,
      onInfoChip: Color.lerp(onInfoChip, other.onInfoChip, t)!,
    );
  }
}

/// Numbers in lists must line up — always pair with a money/quantity Text.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: StitchPalette.primary,
    onPrimary: StitchPalette.onPrimary,
    primaryContainer: StitchPalette.primaryContainer,
    onPrimaryContainer: StitchPalette.onPrimaryContainer,
    inversePrimary: StitchPalette.inversePrimary,
    secondary: StitchPalette.secondary,
    onSecondary: StitchPalette.onSecondary,
    secondaryContainer: StitchPalette.secondaryContainer,
    onSecondaryContainer: StitchPalette.onSecondaryContainer,
    tertiary: StitchPalette.tertiary,
    onTertiary: StitchPalette.onTertiary,
    tertiaryContainer: StitchPalette.tertiaryContainer,
    onTertiaryContainer: StitchPalette.onTertiaryContainer,
    error: StitchPalette.error,
    onError: StitchPalette.onError,
    errorContainer: StitchPalette.errorContainer,
    onErrorContainer: StitchPalette.onErrorContainer,
    surface: StitchPalette.background,
    onSurface: StitchPalette.onBackground,
    surfaceDim: StitchPalette.surfaceDim,
    surfaceBright: StitchPalette.background,
    surfaceContainerLowest: StitchPalette.surfaceContainerLowest,
    surfaceContainerLow: StitchPalette.surfaceContainerLow,
    surfaceContainer: StitchPalette.surfaceContainer,
    surfaceContainerHigh: StitchPalette.surfaceContainerHigh,
    surfaceContainerHighest: StitchPalette.surfaceContainerHighest,
    onSurfaceVariant: StitchPalette.onSurfaceVariant,
    outline: StitchPalette.outline,
    outlineVariant: StitchPalette.outlineVariant,
    inverseSurface: StitchPalette.inverseSurface,
    onInverseSurface: StitchPalette.inverseOnSurface,
    surfaceTint: StitchPalette.surfaceTint,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // Type scale from tokens.md (Inter, bundled in assets/fonts).
  const textTheme = TextTheme(
    displayLarge: TextStyle(
        fontSize: 48, height: 56 / 48, fontWeight: FontWeight.w700,
        letterSpacing: -0.96, fontFeatures: tabularFigures),
    displaySmall: TextStyle(
        fontSize: 36, height: 44 / 36, fontWeight: FontWeight.w700,
        letterSpacing: -0.72, fontFeatures: tabularFigures),
    headlineLarge: TextStyle(
        fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w600,
        letterSpacing: -0.32),
    headlineMedium: TextStyle(
        fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(
        fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600),
    titleLarge: TextStyle(
        fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(
        fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(
        fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(
        fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(
        fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(
        fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(
        fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(
        fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w500,
        letterSpacing: 0.5),
    labelSmall: TextStyle(
        fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500,
        letterSpacing: 0.6),
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: const [StockMeshTokens.light],
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: textTheme.headlineMedium!.copyWith(
        color: scheme.onSurface,
        fontFamily: 'Inter',
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.xl),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Insets.ctaHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.lg),
        ),
        textStyle: textTheme.titleMedium!.copyWith(fontFamily: 'Inter'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(Insets.ctaHeight),
        side: BorderSide(color: scheme.outlineVariant),
        foregroundColor: scheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corners.lg),
        ),
        textStyle: textTheme.titleMedium!.copyWith(fontFamily: 'Inter'),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: textTheme.labelLarge!.copyWith(fontFamily: 'Inter'),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg, vertical: Insets.lg),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.md),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Corners.md),
        borderSide: BorderSide(color: scheme.error),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primary.withValues(alpha: 0.12),
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(
        textTheme.labelSmall!.copyWith(fontFamily: 'Inter'),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyLarge!.copyWith(
        color: scheme.onInverseSurface,
        fontFamily: 'Inter',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.lg),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.4),
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: Insets.lg),
      minVerticalPadding: Insets.md,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      labelStyle: textTheme.labelMedium!.copyWith(fontFamily: 'Inter'),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Corners.xxl),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Corners.xxl)),
      ),
      showDragHandle: true,
    ),
  );
}
