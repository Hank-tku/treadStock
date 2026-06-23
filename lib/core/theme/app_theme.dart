import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_semantic_colors.dart';

/// StockPilot app theme.
/// Design: DESIGN.md v2.0 Typography + Spacing + Border Radius + Shadow
class AppTheme {
  AppTheme._();

  // ── Font families ────────────────────────────────────────────────
  static const String textFont = 'PingFang SC';
  static const String numberFont = 'DIN Alternate';

  // ── Border radius levels ─────────────────────────────────────────
  static const double radiusNone = 0;
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ── Spacing (4px base) ───────────────────────────────────────────
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space10 = 48;
  static const double space12 = 64;
  static const double space16 = 96;

  // ── Animation durations ──────────────────────────────────────────
  static const Duration instantDuration = Duration(milliseconds: 100);
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);

  // ── Animation curves ─────────────────────────────────────────────
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;

  // ── Layout constants ─────────────────────────────────────────────
  static const double pagePadding = 16;
  static const double listItemPaddingH = 16;
  static const double listItemPaddingV = 12;
  static const double bottomTabHeight = 48;
  static const double searchBarHeight = 40;
  static const double sectionSpacing = 24;

  // ── Light theme ──────────────────────────────────────────────────
  static ThemeData get light =>
      _buildTheme(SemanticColors.light, Brightness.light);

  // ── Dark theme ───────────────────────────────────────────────────
  static ThemeData get dark =>
      _buildTheme(SemanticColors.dark, Brightness.dark);

  static ThemeData _buildTheme(SemanticColors sc, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      extensions: <ThemeExtension<dynamic>>[sc],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: StockColors.brand,
        onPrimary: Colors.white,
        surface: sc.bgPrimary,
        onSurface: sc.textPrimary,
        error: StockColors.error,
        onError: Colors.white,
        secondary: StockColors.brand,
        onSecondary: Colors.white,
        outline: sc.border,
        outlineVariant: sc.divider,
      ),
      scaffoldBackgroundColor: sc.bgPrimary,
      appBarTheme: AppBarTheme(
        backgroundColor: sc.bgPrimary,
        foregroundColor: sc.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: textFont,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: sc.textPrimary,
          height: 1.3,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: TextTheme(
        // Display
        displayLarge: TextStyle(
          fontFamily: numberFont,
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.15,
          color: sc.textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontFamily: numberFont,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: sc.textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontFamily: numberFont,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: sc.textPrimary,
        ),
        // Headings
        headlineMedium: TextStyle(
          fontFamily: textFont,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: sc.textPrimary,
          letterSpacing: -0.2,
        ),
        headlineSmall: TextStyle(
          fontFamily: textFont,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: sc.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: textFont,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: sc.textPrimary,
        ),
        // Body
        bodyLarge: TextStyle(
          fontFamily: textFont,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: sc.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: textFont,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: sc.textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: textFont,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: sc.textTertiary,
        ),
        // Label
        labelLarge: TextStyle(
          fontFamily: textFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: StockColors.brand,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: sc.bgPrimary,
        selectedItemColor: StockColors.brand,
        unselectedItemColor: sc.gray500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontFamily: textFont,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: textFont,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: sc.border,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: sc.bgPrimary,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return sc.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StockColors.brand;
          }
          return sc.gray200;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: sc.toastBg,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
        contentTextStyle: TextStyle(
          fontFamily: textFont,
          fontSize: 14,
          color: sc.textOnPrimary,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
