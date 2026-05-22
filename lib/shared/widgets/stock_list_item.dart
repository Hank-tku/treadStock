import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import 'score_badge.dart';
import 'band_low_tag.dart';

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
  final String? strategyName;
  final String? scoreReason;
  final String? riskText;
  final VoidCallback? onTap;

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
    this.strategyName,
    this.scoreReason,
    this.riskText,
    this.onTap,
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
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: StockColors.border, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: badges + name + price
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

                // Score badge
                score != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ScoreBadge(score: score),
                      )
                    : const SizedBox(
                        width: 34,
                        height: 20,
                      ), // placeholder alignment
                // Band low tag
                if (isBandLow)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: BandLowTag(),
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
                    color: StockColors.textPrimary,
                  ),
                ),
              ],
            ),

            // Row 2: code + market + change%
            const SizedBox(height: 4),
            Row(
              children: [
                // Code and market
                Text(
                  '$code ${market == "SH" ? 'SH' : 'SZ'}',
                  style: AppTextStyles.caption,
                ),

                // Expected range (for pinned items)
                if (expectedRange != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    expectedRange!,
                    style: AppTextStyles.caption.copyWith(
                      color: StockColors.textSecondary,
                    ),
                  ),
                ],

                const Spacer(),

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
    final parts = [
      ?strategyName == null ? null : '策略 $strategyName',
      ?scoreReason,
      ?riskText,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        parts.join(' · '),
        style: AppTextStyles.caption.copyWith(color: StockColors.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
