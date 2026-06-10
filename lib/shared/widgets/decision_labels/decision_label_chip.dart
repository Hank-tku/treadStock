import 'package:flutter/material.dart';

/// Sentiment-based color mapping for decision labels.
class _SentimentColors {
  final Color fg;
  final Color bg;
  final Color border;

  const _SentimentColors({
    required this.fg,
    required this.bg,
    required this.border,
  });

  static const bullish = _SentimentColors(
    fg: Color(0xFFB45309), // amber-700
    bg: Color(0xFFFEF3C7), // amber-100
    border: Color(0xFFF59E0B), // amber-500
  );

  static const neutral = _SentimentColors(
    fg: Color(0xFF4B5563), // gray-600
    bg: Color(0xFFF3F4F6), // gray-100
    border: Color(0xFFD1D5DB), // gray-300
  );

  static const bearish = _SentimentColors(
    fg: Color(0xFF059669), // emerald-600
    bg: Color(0xFFECFDF5), // emerald-50
    border: Color(0xFF34D399), // emerald-400
  );

  static const unknown = _SentimentColors(
    fg: Color(0xFF9CA3AF), // gray-400
    bg: Color(0xFFF9FAFB), // gray-50
    border: Color(0xFFE5E7EB), // gray-200
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
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border, width: 0.5),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
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
