import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

/// Score Badge widget.
/// Displays a colored score indicator (1-10) with semantic mapping.
/// Design: DESIGN.md ScoreBadge component spec.
class ScoreBadge extends StatelessWidget {
  final int? score;
  final double? width;

  const ScoreBadge({super.key, required this.score, this.width});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return _buildContainer(
        context,
        width: 76,
        child: const Text('暂无评分', style: AppTextStyles.caption),
      );
    }

    return _buildContainer(
      context,
      width: 96,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '观察分',
            style: AppTextStyles.caption.copyWith(
              color: getScoreColor(score),
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$score/10',
            style: TextStyle(
              fontFamily: AppTheme.numberFont,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: getScoreColor(score),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer(BuildContext context, {required double width, required Widget child}) {
    final bgColor = score == null
        ? context.sc.gray200
        : getScoreBgColor(score);
    final textColor = score == null
        ? context.sc.textTertiary
        : context.sc.textOnPrimary;

    return Container(
      width: this.width ?? width,
      height: 20,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: score == null
              ? context.sc.gray300
              : getScoreColor(score).withValues(alpha: 0.18),
        ),
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
        color: context.sc.gray200,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        '...',
        style: TextStyle(
          fontFamily: AppTheme.numberFont,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.sc.textTertiary,
        ),
      ),
    );
  }
}
