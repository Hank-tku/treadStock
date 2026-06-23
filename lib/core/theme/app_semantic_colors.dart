import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-dependent semantic colors.
///
/// Colors here change between light and dark themes. A-stock fixed-semantic
/// colors (red=up, green=down, score colors, functional error/warning/success)
/// stay on [StockColors] as static constants and do NOT move here — they keep
/// the same hue in both themes (only their tinted backgrounds adapt).
///
/// Usage in widgets (inside build methods that have a [BuildContext]):
///   final bg = context.sc.bgPrimary;
///   final fg = context.sc.textPrimary;
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.bgCard,
    required this.bgWarning,
    required this.bgInfo,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textOnPrimary,
    required this.border,
    required this.borderLight,
    required this.borderFocus,
    required this.borderActive,
    required this.divider,
    required this.brandLight,
    required this.cacheBannerText,
    required this.toastBg,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray700,
  });

  // ── Surfaces (theme-dependent) ───────────────────────────────────
  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color bgCard;
  final Color bgWarning;
  final Color bgInfo;

  // ── Text (theme-dependent) ───────────────────────────────────────
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textOnPrimary;

  // ── Borders & dividers (theme-dependent) ─────────────────────────
  final Color border;
  final Color borderLight;
  final Color borderFocus;
  final Color borderActive;
  final Color divider;

  // ── Misc (theme-dependent) ───────────────────────────────────────
  final Color brandLight;
  final Color cacheBannerText;
  final Color toastBg;

  // ── Grays in semantic use (skeleton highlight, muted text, border)
  // These mirror StockColors gray scale on light, and are remapped to a
  // dark-friendly scale on dark (inverted lightness).
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray700;

  /// Light palette — mirrors the original StockColors values.
  static const SemanticColors light = SemanticColors(
    bgPrimary: Color(0xFFFFFFFF),
    bgSecondary: Color(0xFFF9FAFB),
    bgTertiary: Color(0xFFF3F4F6),
    bgCard: Color(0xFFFFFFFF),
    bgWarning: Color(0xFFFFFBEB),
    bgInfo: Color(0xFFEFF6FF),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textTertiary: Color(0xFF6B7280),
    textDisabled: Color(0xFF9CA3AF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    borderLight: Color(0xFFF3F4F6),
    borderFocus: Color(0xFFD1D5DB),
    borderActive: Color(0xFF2563EB),
    divider: Color(0xFFF3F4F6),
    brandLight: Color(0xFFEFF6FF),
    cacheBannerText: Color(0xFF92400E),
    toastBg: Color(0xFF1F2937),
    gray100: Color(0xFFF3F4F6),
    gray200: Color(0xFFE5E7EB),
    gray300: Color(0xFFD1D5DB),
    gray400: Color(0xFF9CA3AF),
    gray500: Color(0xFF6B7280),
    gray700: Color(0xFF374151),
  );

  /// Dark palette — surfaces invert to deep neutrals, text inverts to light,
  /// borders darken, grays are remapped to a dark-friendly lightness scale.
  /// A-stock red/green hues are NOT here; they stay on StockColors.
  static const SemanticColors dark = SemanticColors(
    bgPrimary: Color(0xFF0F1419),
    bgSecondary: Color(0xFF1A1F26),
    bgTertiary: Color(0xFF252B33),
    bgCard: Color(0xFF1A1F26),
    bgWarning: Color(0xFF2A2118),
    bgInfo: Color(0xFF16203A),
    textPrimary: Color(0xFFF0F0F0),
    textSecondary: Color(0xFFB4BCC8),
    textTertiary: Color(0xFF8A93A0),
    textDisabled: Color(0xFF5A6470),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFF2A313A),
    borderLight: Color(0xFF222831),
    borderFocus: Color(0xFF3A4452),
    borderActive: Color(0xFF3B82F6),
    divider: Color(0xFF222831),
    brandLight: Color(0xFF16203A),
    cacheBannerText: Color(0xFFFBBF24),
    toastBg: Color(0xFF374151),
    // Dark-friendly gray remap: keep the "muted/secondary/border" semantic
    // role by flipping lightness (light gray200 was a light border, so dark
    // gray200 is a dark border, etc.).
    gray100: Color(0xFF1A1F26),
    gray200: Color(0xFF2A313A),
    gray300: Color(0xFF3A4452),
    gray400: Color(0xFF6B7280),
    gray500: Color(0xFF8A93A0),
    gray700: Color(0xFFB4BCC8),
  );

  @override
  SemanticColors copyWith({
    Color? bgPrimary,
    Color? bgSecondary,
    Color? bgTertiary,
    Color? bgCard,
    Color? bgWarning,
    Color? bgInfo,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? textOnPrimary,
    Color? border,
    Color? borderLight,
    Color? borderFocus,
    Color? borderActive,
    Color? divider,
    Color? brandLight,
    Color? cacheBannerText,
    Color? toastBg,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray700,
  }) {
    return SemanticColors(
      bgPrimary: bgPrimary ?? this.bgPrimary,
      bgSecondary: bgSecondary ?? this.bgSecondary,
      bgTertiary: bgTertiary ?? this.bgTertiary,
      bgCard: bgCard ?? this.bgCard,
      bgWarning: bgWarning ?? this.bgWarning,
      bgInfo: bgInfo ?? this.bgInfo,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      textOnPrimary: textOnPrimary ?? this.textOnPrimary,
      border: border ?? this.border,
      borderLight: borderLight ?? this.borderLight,
      borderFocus: borderFocus ?? this.borderFocus,
      borderActive: borderActive ?? this.borderActive,
      divider: divider ?? this.divider,
      brandLight: brandLight ?? this.brandLight,
      cacheBannerText: cacheBannerText ?? this.cacheBannerText,
      toastBg: toastBg ?? this.toastBg,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray700: gray700 ?? this.gray700,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      bgPrimary: Color.lerp(bgPrimary, other.bgPrimary, t)!,
      bgSecondary: Color.lerp(bgSecondary, other.bgSecondary, t)!,
      bgTertiary: Color.lerp(bgTertiary, other.bgTertiary, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgWarning: Color.lerp(bgWarning, other.bgWarning, t)!,
      bgInfo: Color.lerp(bgInfo, other.bgInfo, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      textOnPrimary: Color.lerp(textOnPrimary, other.textOnPrimary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderActive: Color.lerp(borderActive, other.borderActive, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      brandLight: Color.lerp(brandLight, other.brandLight, t)!,
      cacheBannerText: Color.lerp(cacheBannerText, other.cacheBannerText, t)!,
      toastBg: Color.lerp(toastBg, other.toastBg, t)!,
      gray100: Color.lerp(gray100, other.gray100, t)!,
      gray200: Color.lerp(gray200, other.gray200, t)!,
      gray300: Color.lerp(gray300, other.gray300, t)!,
      gray400: Color.lerp(gray400, other.gray400, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      gray700: Color.lerp(gray700, other.gray700, t)!,
    );
  }
}

/// Convenience accessor for [SemanticColors] from a [BuildContext].
///
/// Widgets should use `context.sc.bgPrimary` etc. for theme-dependent colors,
/// and continue to use `StockColors.up` / `StockColors.down` for fixed
/// A-stock semantic colors that must not change with the theme.
extension SemanticColorsContext on BuildContext {
  /// Theme-dependent semantic colors. Falls back to the light palette if the
  /// extension is missing (e.g. in widget tests using a bare MaterialApp).
  SemanticColors get sc =>
      Theme.of(this).extension<SemanticColors>() ?? SemanticColors.light;
}
