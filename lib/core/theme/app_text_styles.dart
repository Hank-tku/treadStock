import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Predefined text styles for consistent typography.
class AppTextStyles {
  AppTextStyles._();

  static const String _textFont = AppTheme.textFont;
  static const String _numFont = AppTheme.numberFont;

  // Display - for large price numbers
  static const TextStyle displayLg = TextStyle(
    fontFamily: _numFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle display = TextStyle(
    fontFamily: _numFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Headings
  static const TextStyle h1 = TextStyle(
    fontFamily: _textFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _textFont,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _textFont,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _textFont,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _textFont,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _textFont,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Number styles (monospace)
  static const TextStyle numberLg = TextStyle(
    fontFamily: _numFont,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle number = TextStyle(
    fontFamily: _numFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle numberSm = TextStyle(
    fontFamily: _numFont,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
