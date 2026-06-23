import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'score_badge.dart';
import 'band_low_tag.dart';
import '../../features/analysis/domain/analysis_models.dart';
import 'decision_labels/decision_labels.dart';
import 'decision_labels/decision_label_chip.dart' as chip;
import '../../features/strategy/domain/decision_engine.dart';
import '../../features/strategy/presentation/widgets/decision_signal_badge.dart';

/// Stock list item widget used in both recommendation and watchlist tabs.
/// Design: DESIGN.md StockListItem component spec.
class StockListItem extends StatelessWidget {
  final String name;
  final String code;
  final String market;
  final double price;
  final double changePct;
  final int? score;
  final bool isBandLow;
  final bool isPinned;
  final bool isAlertTriggered;
  final String? expectedRange;
  final StockPrediction? prediction;
  final String? strategyName;
  final String? scoreReason;
  final String? riskText;
  final StockScore? stockScore;
  final DecisionResult? decisionResult;
  final VoidCallback? onTap;
  final bool isWatched;
  final VoidCallback? onWatchToggle;

  const StockListItem({
    super.key,
    required this.name,
    required this.code,
    required this.market,
    required this.price,
    required this.changePct,
    this.score,
    this.isBandLow = false,
    this.isPinned = false,
    this.isAlertTriggered = false,
    this.expectedRange,
    this.prediction,
    this.strategyName,
    this.scoreReason,
    this.riskText,
    this.stockScore,
    this.decisionResult,
    this.onTap,
    this.isWatched = false,
    this.onWatchToggle,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = getPriceColor(changePct);
    final changePrefix = changePct > 0 ? '+' : '';
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.listItemPaddingH,
          vertical: AppTheme.listItemPaddingV,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.sc.border, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name + price
            Row(
              children: [
                // Pin icon
                if (isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: StockColors.pin,
                    ),
                  ),

                // Stock name
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Alert bell
                if (isAlertTriggered)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.notifications_active,
                      size: 16,
                      color: StockColors.alert,
                    ),
                  ),

                // Price (right-aligned, number font)
                Text(
                  price > 0 ? '¥${price.toStringAsFixed(2)}' : '--',
                  style: AppTextStyles.numberSm.copyWith(
                    color: context.sc.textPrimary,
                  ),
                ),

                // Watch/follow button (only if callback provided)
                if (onWatchToggle != null || isWatched) ...[
                  const SizedBox(width: 8),
                  _AnimatedWatchButton(
                    isWatched: isWatched,
                    onTap: onWatchToggle,
                  ),
                ],
              ],
            ),

            // Row 2: code + strategy score + tags + change%
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '$code ${market == "SH" ? 'SH' : 'SZ'}',
                        style: AppTextStyles.caption,
                      ),
                      if (score != null) ScoreBadge(score: score),
                      if (decisionResult != null)
                        DecisionSignalBadge(signal: decisionResult!.signal, isSmall: true),
                      if (isBandLow) const BandLowTag(),
                      _buildDecisionLabelWidget(stockScore),
                      if (prediction != null) _PredictionTag(prediction: prediction!),
                      if (expectedRange != null)
                        Text(
                          expectedRange!,
                          style: AppTextStyles.caption.copyWith(
                            color: context.sc.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Change percentage (right-aligned)
                Text(
                  price > 0
                      ? '$changePrefix${changePct.toStringAsFixed(2)}%'
                      : '--',
                  style: AppTextStyles.number.copyWith(color: priceColor),
                ),
              ],
            ),
            if (strategyName != null ||
                scoreReason != null ||
                riskText != null) ...[
              const SizedBox(height: 6),
              _StrategySummaryLine(
                strategyName: strategyName,
                scoreReason: scoreReason,
                riskText: riskText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Animated watch/follow toggle button.
/// Shows "关注" → "✓ 已关注" with a scale+color transition.
class _AnimatedWatchButton extends StatefulWidget {
  final bool isWatched;
  final VoidCallback? onTap;

  const _AnimatedWatchButton({
    required this.isWatched,
    this.onTap,
  });

  @override
  State<_AnimatedWatchButton> createState() => _AnimatedWatchButtonState();
}

class _AnimatedWatchButtonState extends State<_AnimatedWatchButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.fastDuration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

  }

  @override
  void didUpdateWidget(covariant _AnimatedWatchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWatched && !oldWidget.isWatched) {
      _controller.forward().then((_) {
        if (mounted) _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isWatched
        ? StockColors.success.withValues(alpha: 0.12)
        : StockColors.brand.withValues(alpha: 0.1);
    final textColor =
        widget.isWatched ? StockColors.success : StockColors.brand;
    final label = widget.isWatched ? '✓ 已关注' : '关注';

    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppTheme.fastDuration,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppTheme.fastDuration,
            curve: Curves.easeOut,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _StrategySummaryLine extends StatelessWidget {
  final String? strategyName;
  final String? scoreReason;
  final String? riskText;

  const _StrategySummaryLine({
    this.strategyName,
    this.scoreReason,
    this.riskText,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String?>[
      strategyName != null ? '策略 $strategyName' : null,
      scoreReason,
      riskText,
    ].whereType<String>().toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(
        parts.join(' · '),
        style: AppTextStyles.caption.copyWith(color: context.sc.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}



Widget _buildDecisionLabelWidget(StockScore? stockScore) {
  if (stockScore == null || stockScore.score <= 0) {
    return const SizedBox.shrink();
  }

  final labels = DecisionLabelEngine.generate(stockScore);
  if (labels.isEmpty) return const SizedBox.shrink();

  final label = labels.first;
  return chip.DecisionLabelChip(
    text: label.displayName,
    detail: label.detail,
    sentiment: _toChipSentiment(label.sentiment),
  );
}
/// Convert model sentiment to widget sentiment.
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

/// Prediction direction chip.
/// Shows "看涨 68%" / "看跌 55%" / "震荡" with corresponding color.
class _PredictionTag extends StatelessWidget {
  final StockPrediction prediction;
  const _PredictionTag({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final tag = prediction.tag;
    Color bgColor;
    Color textColor;

    switch (prediction.direction) {
      case PredictionDirection.up:
        // A-stock convention: red = up. Reuse global tokens so the prediction
        // tag stays visually consistent with the inline changePct color.
        bgColor = StockColors.upBg;
        textColor = StockColors.up;
      case PredictionDirection.down:
        // A-stock convention: green = down.
        bgColor = StockColors.downBg;
        textColor = StockColors.down;
      case PredictionDirection.flat:
        bgColor = context.sc.bgTertiary;
        textColor = context.sc.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        '${prediction.targetDateLabel} $tag',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
