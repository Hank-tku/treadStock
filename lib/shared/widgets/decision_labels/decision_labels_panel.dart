import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/analysis/domain/analysis_models.dart';

import 'decision_labels.dart';
import 'decision_label_chip.dart' as chip;

/// Converts DecisionSentiment from the model to the widget's enum.
chip.DecisionSentiment _toChipSentiment(DecisionSentiment s) {
  switch (s) {
    case DecisionSentiment.bullish:
      return chip.DecisionSentiment.bullish;
    case DecisionSentiment.neutral:
      return chip.DecisionSentiment.neutral;
    case DecisionSentiment.bearish:
      return chip.DecisionSentiment.bearish;
    case DecisionSentiment.unknown:
      return chip.DecisionSentiment.unknown;
  }
}

/// Panel showing decision labels for a stock.
/// Used in the stock detail page below the score section.
class DecisionLabelsPanel extends StatelessWidget {
  final StockScore? score;

  const DecisionLabelsPanel({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    if (score == null || score!.score == 0) {
      return const SizedBox.shrink();
    }

    final labels = DecisionLabelEngine.generate(score!);
    if (labels.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('决策标签', style: AppTextStyles.h3),
              const SizedBox(width: 6),
              Text(
                _summaryText(labels),
                style: AppTextStyles.caption.copyWith(
                  color: StockColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: labels
                .map(
                  (label) => chip.DecisionLabelChip(
                    text: label.displayName,
                    detail: label.detail,
                    sentiment: _toChipSentiment(label.sentiment),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _summaryText(List<DecisionLabel> labels) {
    final bullish = labels.where((l) => l.sentiment == DecisionSentiment.bullish).length;
    final bearish = labels.where((l) => l.sentiment == DecisionSentiment.bearish).length;

    if (bullish > bearish) return '偏多信号';
    if (bearish > bullish) return '偏空信号';
    return '信号中性';
  }
}
