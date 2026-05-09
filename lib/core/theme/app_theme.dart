import 'package:flutter/material.dart';
import 'app_colors.dart';

/// StockPilot app theme.
/// Design: DESIGN.md v1.0 Typography + Spacing + Border Radius + Shadow
class AppTheme {
  AppTheme._();

  // Font families
  static const String textFont = 'PingFang SC';
  static const String numberFont = 'DIN Alternate';

  // Border radius levels
  static const double radiusNone = 0;
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusFull = 999;

  // Spacing (4px base)
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

  // Animation durations
  static const Duration instantDuration = Duration(milliseconds: 100);
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);

  // Animation curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;

  // Layout
  static const double pagePadding = 16;
  static const double listItemPaddingH = 16;
  static const double listItemPaddingV = 12;
  static const double bottomTabHeight = 48;
  static const double searchBarHeight = 40;
  static const double sectionSpacing = 24;

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: StockColors.brand,
        onPrimary: Colors.white,
        surface: StockColors.bgPrimary,
        onSurface: StockColors.textPrimary,
        error: StockColors.error,
        onError: Colors.white,
        secondary: StockColors.brand,
        onSecondary: Colors.white,
        outline: StockColors.border,
        outlineVariant: StockColors.divider,
      ),
      scaffoldBackgroundColor: StockColors.bgPrimary,
      appBarTheme: const AppBarTheme(
        backgroundColor: StockColors.bgPrimary,
        foregroundColor: StockColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: textFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: StockColors.textPrimary,
          height: 1.3,
        ),
      ),
      textTheme: const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontFamily: numberFont,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: StockColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: numberFont,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: StockColors.textPrimary,
        ),
        // Headings
        headlineMedium: TextStyle(
          fontFamily: textFont,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: StockColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontFamily: textFont,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: StockColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: textFont,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: StockColors.textPrimary,
        ),
        // Body
        bodyLarge: TextStyle(
          fontFamily: textFont,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: StockColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: textFont,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: StockColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: textFont,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: StockColors.textTertiary,
        ),
        // Label
        labelLarge: TextStyle(
          fontFamily: textFont,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: StockColors.brand,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: StockColors.bgPrimary,
        selectedItemColor: StockColors.brand,
        unselectedItemColor: StockColors.gray500,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: textFont,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: textFont,
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: StockColors.border,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: StockColors.bgPrimary,
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
          return StockColors.gray400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return StockColors.brand;
          }
          return StockColors.gray200;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: StockColors.toastBg,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: textFont,
          fontSize: 13,
          color: Colors.white,
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
