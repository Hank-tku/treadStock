import 'package:flutter/material.dart';

/// StockPilot semantic color constants.
/// All colors follow A-stock standard: red = up, green = down.
/// Design: DESIGN.md v1.0 Color System
class StockColors {
  StockColors._();

  // Price colors (A-stock standard)
  static const Color up = Color(0xFFE6432D);
  static const Color upBg = Color(0x14E6432D); // rgba(230, 67, 45, 0.08)
  static const Color down = Color(0xFF1DB954);
  static const Color downBg = Color(0x141DB954); // rgba(29, 185, 84, 0.08)
  static const Color flat = Color(0xFF8C8C8C);

  // Score colors
  static const Color scoreHigh = Color(0xFFE6432D); // 8-10 strong buy
  static const Color scoreMid = Color(0xFFD4A017); // 5-7 neutral
  static const Color scoreLow = Color(0xFF1DB954); // 1-4 risk

  // Band low tag
  static const Color bandLow = Color(0xFFE69321);
  static const Color bandLowBg = Color(0x1FE69321); // rgba(230, 147, 33, 0.12)

  // Brand
  static const Color brand = Color(0xFF1A6AFF);
  static const Color brandHover = Color(0xFF1554D6);

  // Neutral grays (10 levels)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF8C8C8C);
  static const Color gray600 = Color(0xFF6B6B6B);
  static const Color gray700 = Color(0xFF4A4A4A);
  static const Color gray800 = Color(0xFF333333);
  static const Color gray900 = Color(0xFF1A1A1A);

  // Semantic
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF7F8FA);
  static const Color bgTertiary = Color(0xFFF0F1F3);
  static const Color bgWarning = Color(0xFFFFF8E1);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF8C8C8C);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFEEEEEE);
  static const Color borderFocus = Color(0xFFE0E0E0);
  static const Color borderActive = Color(0xFF1A6AFF);
  static const Color divider = Color(0xFFF0F1F3);

  // Functional
  static const Color error = Color(0xFFE6432D);
  static const Color warning = Color(0xFFD4A017);
  static const Color success = Color(0xFF1DB954);
  static const Color info = Color(0xFF1A6AFF);

  // Cache banner text (design spec: #8C6B00)
  static const Color cacheBannerText = Color(0xFF8C6B00);

  // Toast
  static const Color toastBg = Color(0xFF333333);

  // Alert
  static const Color danger = Color(0xFFE6432D);
  static const Color pin = Color(0xFF1A6AFF);
  static const Color alert = Color(0xFFE6432D);

  // Shadow
  static const Color shadow = Color(0x0D000000); // rgba(0,0,0,0.05)
  static const Color shadowMd = Color(0x14000000); // rgba(0,0,0,0.08)
}

/// Get score color based on score value.
Color getScoreColor(int? score) {
  if (score == null) return StockColors.gray200;
  if (score >= 8) return StockColors.scoreHigh;
  if (score >= 5) return StockColors.scoreMid;
  return StockColors.scoreLow;
}

/// Get score background color based on score value.
Color getScoreBgColor(int? score) {
  if (score == null) return StockColors.gray200;
  if (score >= 8) return StockColors.upBg;
  if (score >= 5) return Color(0x14D4A017); // rgba(212,160,23,0.08)
  return StockColors.downBg;
}

/// Get price change color based on change percentage.
Color getPriceColor(double changePct) {
  if (changePct > 0) return StockColors.up;
  if (changePct < 0) return StockColors.down;
  return StockColors.flat;
}

/// Get score semantic label.
String getScoreLabel(int? score) {
  if (score == null) return '';
  if (score >= 8) return '重点观察';
  if (score >= 5) return '中性观望';
  return '风险较高';
}
