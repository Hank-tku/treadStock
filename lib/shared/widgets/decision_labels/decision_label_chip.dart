import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';

/// Sentiment-based color mapping for decision labels.
/// Colors reuse the global StockColors tokens so sentiment chips stay
/// consistent with A-stock convention (red = up/bullish, green = down/bearish)
/// and with the rest of the UI.
class _SentimentColors {
  final Color fg;
  final Color bg;
  final Color border;

  const _SentimentColors({
    required this.fg,
    required this.bg,
    required this.border,
  });

  // Bullish = A-stock up color (red).
  static const bullish = _SentimentColors(
    fg: StockColors.up,
    bg: StockColors.upBg,
    border: StockColors.up,
  );

  // Neutral = secondary text on tertiary surface.
  static const neutral = _SentimentColors(
    fg: StockColors.textSecondary,
    bg: StockColors.bgTertiary,
    border: StockColors.border,
  );

  // Bearish = A-stock down color (green).
  static const bearish = _SentimentColors(
    fg: StockColors.down,
    bg: StockColors.downBg,
    border: StockColors.down,
  );

  static const unknown = _SentimentColors(
    fg: StockColors.textDisabled,
    bg: StockColors.bgSecondary,
    border: StockColors.borderLight,
  );
}

/// A single decision label chip.
/// Follows DESIGN.md tag spec: 4px radius, compact height, semantic colors.
class DecisionLabelChip extends StatelessWidget {
  final String text;
  final String? detail;
  final DecisionSentiment sentiment;

  const DecisionLabelChip({
    super.key,
    required this.text,
    this.detail,
    required this.sentiment,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _sentimentColorsOf(sentiment);

    return Tooltip(
      message: detail ?? text,
      preferBelow: true,
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.fg,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Sentiment enum shared with DecisionLabel, but kept here for widget use.
enum DecisionSentiment { bullish, neutral, bearish, unknown }

_SentimentColors _sentimentColorsOf(DecisionSentiment s) {
  switch (s) {
    case DecisionSentiment.bullish:
      return _SentimentColors.bullish;
    case DecisionSentiment.neutral:
      return _SentimentColors.neutral;
    case DecisionSentiment.bearish:
      return _SentimentColors.bearish;
    case DecisionSentiment.unknown:
      return _SentimentColors.unknown;
  }
}
