import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/strategy_models.dart';
import '../../domain/strategy_trust_engine.dart';

/// 回测可视化摘要卡片
/// 展示命中率进度条、统计数字、交易天数
class BacktestSummaryCard extends StatelessWidget {
  final StrategyStats stats;

  const BacktestSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final trustResult = StrategyTrustEngine.evaluate(stats);
    final hitRatePct = stats.hitRate;
    final barColor = _hitRateBarColor(hitRatePct);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              const Text('策略验证', style: AppTextStyles.h3),
              const Spacer(),
              Text(
                trustResult.label,
                style: AppTextStyles.caption.copyWith(
                  color: StrategyTrustEngine.trustColor(trustResult.level),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 命中率大字 + 进度条
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stats.hitRateDisplay,
                style: AppTextStyles.numberLg.copyWith(
                  color: barColor,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '命中率',
                      style: AppTextStyles.caption.copyWith(
                        color: StockColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 进度条
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: stats.evaluatedCount > 0 ? hitRatePct : 0,
                          backgroundColor: StockColors.gray200,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3个统计数字横排
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '总信号数',
                  '${stats.totalRecommendations}',
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: StockColors.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  '命中数',
                  '${stats.hitCount}',
                ),
              ),
              Container(
                width: 1,
                height: 24,
                color: StockColors.divider,
              ),
              Expanded(
                child: _buildStatItem(
                  '平均涨幅',
                  stats.avgChangeDisplay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 底部说明
          Text(
            '基于近 ${stats.tradingDaysRun} 个交易日的数据',
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.numberSm.copyWith(
            color: StockColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.micro.copyWith(
            color: StockColors.textTertiary,
          ),
        ),
      ],
    );
  }

  /// 命中率进度条颜色：灰→绿随命中率变化
  Color _hitRateBarColor(double hitRate) {
    if (hitRate >= 0.6) return StockColors.success;
    if (hitRate >= 0.4) return StockColors.brand;
    if (hitRate >= 0.2) return StockColors.warning;
    return StockColors.flat;
  }
}
