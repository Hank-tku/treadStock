import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/decision_engine.dart';

/// 首页决策看板 —— 一行显示四档信号的数量统计。
class DecisionSummaryBar extends StatelessWidget {
  final int strongWatchCount;
  final int watchCount;
  final int observeCount;
  final int notRecommendedCount;

  const DecisionSummaryBar({
    super.key,
    required this.strongWatchCount,
    required this.watchCount,
    required this.observeCount,
    required this.notRecommendedCount,
  });

  /// 从一组决策结果列表直接统计并构建。
  factory DecisionSummaryBar.fromResults(
    List<DecisionResult> results, {
    Key? key,
  }) {
    var strong = 0;
    var watch = 0;
    var observe = 0;
    var notRec = 0;
    for (final r in results) {
      switch (r.signal) {
        case DecisionSignal.strongWatch:
          strong++;
        case DecisionSignal.watch:
          watch++;
        case DecisionSignal.observe:
          observe++;
        case DecisionSignal.notRecommended:
          notRec++;
      }
    }
    return DecisionSummaryBar(
      key: key,
      strongWatchCount: strong,
      watchCount: watch,
      observeCount: observe,
      notRecommendedCount: notRec,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          _buildCount(context, 
            color: DecisionEngine.signalColor(DecisionSignal.strongWatch),
            bg: DecisionEngine.signalBgColor(DecisionSignal.strongWatch),
            label: '强烈关注',
            count: strongWatchCount,
          ),
          _buildDivider(context),
          _buildCount(context, 
            color: DecisionEngine.signalColor(DecisionSignal.watch),
            bg: DecisionEngine.signalBgColor(DecisionSignal.watch),
            label: '可以关注',
            count: watchCount,
          ),
          _buildDivider(context),
          _buildCount(context, 
            color: DecisionEngine.signalColor(DecisionSignal.observe),
            bg: DecisionEngine.signalBgColor(DecisionSignal.observe),
            label: '继续观望',
            count: observeCount,
          ),
          _buildDivider(context),
          _buildCount(context, 
            color: DecisionEngine.signalColor(DecisionSignal.notRecommended),
            bg: DecisionEngine.signalBgColor(DecisionSignal.notRecommended),
            label: '暂不建议',
            count: notRecommendedCount,
          ),
        ],
      ),
    );
  }

  Widget _buildCount(BuildContext context, {
    required Color color,
    required Color bg,
    required String label,
    required int count,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.numberSm.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTextStyles.micro.copyWith(
              color: context.sc.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 0.5,
      height: 16,
      color: context.sc.border,
    );
  }
}
