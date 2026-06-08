import 'package:flutter/material.dart';

/// StockPilot semantic color constants.
/// All colors follow A-stock standard: red = up, green = down.
/// Design: DESIGN.md v2.0 Color System
class StockColors {
  StockColors._();

  // ── Price colors (A-stock standard: red=up, green=down) ──────────
  static const Color up = Color(0xFFD93025);
  static const Color upLight = Color(0xFFFEF2F2);
  static const Color upBg = Color(0xFFFEE2E2);
  static const Color down = Color(0xFF0F9D58);
  static const Color downLight = Color(0xFFECFDF5);
  static const Color downBg = Color(0xFFDCFCE7);
  static const Color flat = Color(0xFF6B7280);

  // ── Score colors ─────────────────────────────────────────────────
  static const Color scoreHigh = Color(0xFFD93025); // 8-10 strong buy
  static const Color scoreMid = Color(0xFFD97706); // 5-7 neutral
  static const Color scoreLow = Color(0xFF0F9D58); // 1-4 risk

  // ── Band low tag ─────────────────────────────────────────────────
  static const Color bandLow = Color(0xFFD97706);
  static const Color bandLowBg = Color(0xFFFEF3C7);

  // ── Brand ────────────────────────────────────────────────────────
  static const Color brand = Color(0xFF2563EB);
  static const Color brandLight = Color(0xFFEFF6FF);
  static const Color brandDark = Color(0xFF1D4ED8);
  static const Color brandHover = Color(0xFF1E40AF);

  // ── Neutral grays (Tailwind Gray, 10 levels) ────────────────────
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ── Semantic surfaces ────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF9FAFB);
  static const Color bgTertiary = Color(0xFFF3F4F6);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgWarning = Color(0xFFFFFBEB);
  static const Color bgInfo = Color(0xFFEFF6FF);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & dividers ───────────────────────────────────────────
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderFocus = Color(0xFFD1D5DB);
  static const Color borderActive = Color(0xFF2563EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ── Functional ───────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color success = Color(0xFF0F9D58);
  static const Color info = Color(0xFF2563EB);

  // ── Cache banner text (warm dark amber) ──────────────────────────
  static const Color cacheBannerText = Color(0xFF92400E);

  // ── Toast ────────────────────────────────────────────────────────
  static const Color toastBg = Color(0xFF1F2937);

  // ── Alert / danger ───────────────────────────────────────────────
  static const Color danger = Color(0xFFDC2626);
  static const Color pin = Color(0xFF2563EB);
  static const Color alert = Color(0xFFDC2626);

  // ── Shadows ──────────────────────────────────────────────────────
  static const Color shadow = Color(0x0A000000); // rgba(0,0,0,0.04)
  static const Color shadowMd = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color shadowLg = Color(0x1F000000); // rgba(0,0,0,0.12)
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
  if (score >= 5) return Color(0x14D97706); // rgba(217,119,6,0.08)
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
