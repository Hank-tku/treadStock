import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/signal_card.dart';

/// Signal card widget — displays a decision signal evaluation result.
///
/// Shows signal type, strength, headline, indicator highlights,
/// and actionable suggestion in a compact card layout.
class SignalCardWidget extends StatelessWidget {
  final SignalCard card;
  final VoidCallback? onTap;

  const SignalCardWidget({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!card.isActionable) {
      return _buildNeutralCard();
    }

    return _buildSignalCard();
  }

  /// Active signal card — colored border + indicator highlights.
  Widget _buildSignalCard() {
    final color = _signalColor;
    final bgColor = _signalBgColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: type tag + strength + strategy name
                _buildHeader(color),
                const SizedBox(height: 8),
                // Headline
                Text(card.headline, style: AppTextStyles.bodyLg),
                const SizedBox(height: 6),
                // Indicator highlights row
                if (card.highlights.isNotEmpty) ...[
                  _buildHighlights(),
                  const SizedBox(height: 8),
                ],
                // Rule pass rate bar
                if (card.totalRuleCount > 0) ...[
                  _buildPassRateBar(color),
                  const SizedBox(height: 8),
                ],
                // Suggestion
                _buildSuggestion(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Neutral / no-signal card — minimal display.
  Widget _buildNeutralCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: StockColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                card.headline,
                style: AppTextStyles.body.copyWith(
                  color: StockColors.textSecondary,
                ),
              ),
            ],
          ),
          if (card.detail.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.detail,
              style: AppTextStyles.caption.copyWith(
                color: StockColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      children: [
        // Signal type tag
        Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
          ),
          alignment: Alignment.center,
          child: Text(
            card.tag,
            style: AppTextStyles.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Strategy name
        Expanded(
          child: Text(
            card.strategyName,
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Arrow icon
        if (onTap != null)
          Icon(
            Icons.chevron_right,
            size: 18,
            color: StockColors.textTertiary,
          ),
      ],
    );
  }

  Widget _buildHighlights() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: card.highlights.map((h) {
        final hColor = h.isPositive ? StockColors.up : StockColors.down;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            border: Border.all(color: hColor.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                h.name,
                style: AppTextStyles.micro.copyWith(
                  color: hColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '${h.value} ${h.status}',
                style: AppTextStyles.micro.copyWith(
                  color: StockColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPassRateBar(Color color) {
    final rate = card.passRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '规则匹配',
              style: AppTextStyles.caption.copyWith(
                color: StockColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${card.passedRuleCount}/${card.totalRuleCount}',
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: rate,
              backgroundColor: StockColors.gray200,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestion() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_outline,
          size: 14,
          color: StockColors.textTertiary,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            card.suggestion,
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Color helpers ──────────────────────────────────────────────────

  Color get _signalColor {
    return switch (card.type) {
      SignalType.entry => StockColors.up,
      SignalType.exit => StockColors.down,
      SignalType.watch => StockColors.warning,
      SignalType.neutral => StockColors.gray400,
    };
  }

  Color get _signalBgColor {
    return switch (card.type) {
      SignalType.entry => StockColors.upLight,
      SignalType.exit => StockColors.downLight,
      SignalType.watch => StockColors.bgWarning,
      SignalType.neutral => StockColors.bgSecondary,
    };
  }
}

/// Loading skeleton for signal card.
class SignalCardLoading extends StatelessWidget {
  const SignalCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag placeholder
          Row(
            children: [
              Container(
                width: 60,
                height: 18,
                decoration: BoxDecoration(
                  color: StockColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: StockColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Headline placeholder
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: StockColors.gray200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Highlights placeholder
          Row(
            children: [
              Container(
                width: 70,
                height: 24,
                decoration: BoxDecoration(
                  color: StockColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 70,
                height: 24,
                decoration: BoxDecoration(
                  color: StockColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 70,
                height: 24,
                decoration: BoxDecoration(
                  color: StockColors.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bar placeholder
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: StockColors.gray200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
