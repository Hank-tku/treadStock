import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Score Badge widget.
/// Displays a colored score indicator (1-10) with semantic mapping.
/// Design: DESIGN.md ScoreBadge component spec.
class ScoreBadge extends StatelessWidget {
  final int? score;
  final double? width;

  const ScoreBadge({
    super.key,
    required this.score,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return _buildContainer(
        width: 76,
        child: const Text(
          'N/A',
          style: TextStyle(
            fontFamily: AppTheme.numberFont,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: StockColors.textTertiary,
          ),
        ),
      );
    }

    return _buildContainer(
      width: 28,
      child: Text(
        '$score',
        style: const TextStyle(
          fontFamily: AppTheme.numberFont,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: StockColors.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildContainer({required double width, required Widget child}) {
    final bgColor = score == null
        ? StockColors.gray200
        : getScoreBgColor(score);
    final textColor = score == null
        ? StockColors.textTertiary
        : StockColors.textOnPrimary;

    return Container(
      width: this.width ?? width,
      height: 20,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: DefaultTextStyle(
        style: TextStyle(color: textColor),
        child: child,
      ),
    );
  }
}

/// Loading state for ScoreBadge.
class ScoreBadgeLoading extends StatelessWidget {
  const ScoreBadgeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 20,
      decoration: BoxDecoration(
        color: StockColors.gray200,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        '...',
        style: TextStyle(
          fontFamily: AppTheme.numberFont,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: StockColors.textTertiary,
        ),
      ),
    );
  }
}
