import '../../analysis/domain/analysis_models.dart';
import 'strategy_models.dart';

/// Plain-language explanation helpers for ordinary-user strategy learning.
class StrategyRecommendationInsight {
  final String matchPoint;
  final String riskPoint;
  final String nextStep;

  const StrategyRecommendationInsight({
    required this.matchPoint,
    required this.riskPoint,
    required this.nextStep,
  });

  String get compact => '$matchPoint · $riskPoint · $nextStep';
}

class StrategyReviewSummary {
  final String title;
  final String conclusion;
  final String nextStep;
  final bool needsAttention;

  const StrategyReviewSummary({
    required this.title,
    required this.conclusion,
    required this.nextStep,
    this.needsAttention = false,
  });
}

class StrategyEmptyDiagnosis {
  final String title;
  final String body;
  final String actionLabel;

  const StrategyEmptyDiagnosis({
    required this.title,
    required this.body,
    required this.actionLabel,
  });
}

class StrategyExplanation {
  StrategyExplanation._();

  static StrategyRecommendationInsight recommendationInsight({
    required Strategy strategy,
    required StockScore score,
  }) {
    final strongestSignal = _strongestSignal(score);
    final weakestSignal = _weakestSignal(score);

    return StrategyRecommendationInsight(
      matchPoint:
          '匹配点：$strongestSignal，对应 ${score.score}/${strategy.recommendThreshold} 分',
      riskPoint: '风险点：$weakestSignal，避免只看单一分数',
      nextStep: _nextStepFor(strategy, score),
    );
  }

  static StrategyEmptyDiagnosis emptyDiagnosis(Strategy strategy) {
    if (strategy.recommendThreshold >= 8) {
      return const StrategyEmptyDiagnosis(
        title: '阈值较高，今天没有筛出标的',
        body: '这通常表示策略偏严格。可以先保持观察，或把阈值降低 1 分后再比较结果数量。',
        actionLabel: '降低阈值或换目标',
      );
    }

    if (strategy.weightBoll >= 0.35) {
      return const StrategyEmptyDiagnosis(
        title: '低位条件暂未出现',
        body: '这类策略主要等待价格靠近低位区。没有结果时不要硬找机会，可以稍后刷新或切换趋势目标。',
        actionLabel: '查看趋势策略',
      );
    }

    if (strategy.weightMA >= 0.40 || strategy.weightTrend >= 0.30) {
      return const StrategyEmptyDiagnosis(
        title: '趋势条件暂不匹配',
        body: '当前候选池里没有明显满足均线或趋势延续的标的。可以继续等待，或使用低位修复目标观察不同市场状态。',
        actionLabel: '换低位修复',
      );
    }

    return const StrategyEmptyDiagnosis(
      title: '当前策略暂无匹配标的',
      body: '可能是行情不配合、K 线样本不足，或策略条件较窄。先下拉刷新，再考虑微调阈值。',
      actionLabel: '刷新或微调',
    );
  }

  static StrategyReviewSummary reviewSummary({
    required StrategyStats stats,
    required List<StrategySuggestion> suggestions,
  }) {
    if (stats.totalRecommendations == 0) {
      return const StrategyReviewSummary(
        title: '还没有可复盘记录',
        conclusion: '这条策略尚未产生推荐，暂时不能判断好坏。',
        nextStep: '先运行几天；如果一直没有结果，再降低阈值或换一个新手目标。',
      );
    }

    if (stats.evaluatedCount < 20) {
      return StrategyReviewSummary(
        title: '样本不足，先看趋势',
        conclusion: '已评估 ${stats.evaluatedCount} 条，当前数据只适合观察，不适合给策略下结论。',
        nextStep: '继续积累到 20 条以上，再根据命中率和极限跌幅做调整。',
      );
    }

    if (suggestions.isNotEmpty) {
      return StrategyReviewSummary(
        title: '需要复盘调整',
        conclusion: suggestions.first.condition,
        nextStep: suggestions.first.suggestion,
        needsAttention: true,
      );
    }

    if (stats.hitRate >= 0.55 && stats.avgChange >= 0) {
      return StrategyReviewSummary(
        title: '可以继续观察',
        conclusion:
            '命中率 ${stats.hitRateDisplay}，平均差 ${stats.avgChangeDisplay}，当前表现相对稳定。',
        nextStep: '保持参数不变，继续记录下一轮样本，避免因为单日波动频繁调参。',
      );
    }

    return StrategyReviewSummary(
      title: '表现一般，谨慎观察',
      conclusion:
          '命中率 ${stats.hitRateDisplay}，平均差 ${stats.avgChangeDisplay}，暂未形成清晰优势。',
      nextStep: '先不要扩大观察数量；优先复盘极限跌幅和推荐频率。',
      needsAttention: true,
    );
  }

  static String _strongestSignal(StockScore score) {
    final entries = <({String label, double value})>[
      (label: '均线结构', value: score.maScore),
      (label: '低位区间', value: score.bollScore),
      (label: '量价配合', value: score.volScore),
      (label: '近期节奏', value: score.trendScore),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final top = entries.first;
    if (top.label == '低位区间' && score.isBandLow) {
      return '价格接近低位观察区';
    }
    return '${top.label}较好';
  }

  static String _weakestSignal(StockScore score) {
    final entries = <({String label, double value})>[
      (label: '均线结构', value: score.maScore),
      (label: '低位位置', value: score.bollScore),
      (label: '量价配合', value: score.volScore),
      (label: '近期节奏', value: score.trendScore),
    ]..sort((a, b) => a.value.compareTo(b.value));

    final weakest = entries.first;
    if (weakest.value >= 5) {
      return '暂无明显短板，但仍需复盘';
    }
    return '${weakest.label}偏弱';
  }

  static String _nextStepFor(Strategy strategy, StockScore score) {
    if (score.isBandLow || strategy.weightBoll >= 0.35) {
      return '下一步：观察是否重新站上短期均线';
    }
    if (strategy.weightMA >= 0.40 || strategy.weightTrend >= 0.30) {
      return '下一步：观察趋势能否连续保持';
    }
    return '下一步：加入关注后看 3-5 日表现';
  }
}
