import '../../analysis/domain/analysis_engine.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../stock/domain/stock_models.dart';
import 'strategy_models.dart';

/// Unified scoring facade used by recommendation and watchlist surfaces.
class StrategyScoringService {
  final AnalysisEngine _analysisEngine;

  const StrategyScoringService(this._analysisEngine);

  StrategyScoreResult scoreStock({
    required StockQuote quote,
    required List<DailyKline> klines,
    required Strategy strategy,
  }) {
    final score = _analysisEngine.calculateScoreForStrategy(klines, strategy);
    return StrategyScoreResult(
      strategyId: strategy.id,
      strategyName: strategy.name,
      recommendThreshold: strategy.recommendThreshold,
      score: score,
      isMatched: score.score >= strategy.recommendThreshold,
    );
  }

  List<StrategyScoreResult> scoreAll({
    required StockQuote quote,
    required List<DailyKline> klines,
    required List<Strategy> strategies,
  }) {
    final results =
        strategies
            .map(
              (strategy) =>
                  scoreStock(quote: quote, klines: klines, strategy: strategy),
            )
            .toList()
          ..sort((a, b) => b.score.score.compareTo(a.score.score));
    return results;
  }

  StrategyScoreResult? bestScore({
    required StockQuote quote,
    required List<DailyKline> klines,
    required List<Strategy> strategies,
  }) {
    if (strategies.isEmpty) return null;
    final results = scoreAll(
      quote: quote,
      klines: klines,
      strategies: strategies,
    );
    return results.isEmpty ? null : results.first;
  }

  /// Generate next-session prediction from TA data.
  StockPrediction generatePrediction({
    required List<DailyKline> klines,
    required StockScore score,
    double? currentPrice,
  }) {
    return _analysisEngine.generatePrediction(
      klines: klines,
      score: score,
      currentPrice: currentPrice,
    );
  }
}

class StrategyScoreResult {
  final String strategyId;
  final String strategyName;
  final int recommendThreshold;
  final StockScore score;
  final bool isMatched;

  const StrategyScoreResult({
    required this.strategyId,
    required this.strategyName,
    required this.recommendThreshold,
    required this.score,
    required this.isMatched,
  });

  String get displayTitle => '匹配策略：$strategyName';

  String get displayReason {
    final reason = score.reason ?? '技术面评分已生成';
    final status = isMatched ? '达到观察阈值' : '未达观察阈值';
    return '$reason，$status ${score.score}/$recommendThreshold。$learningHint';
  }

  String get learningHint {
    // Rule-based strategies return all-zero sub-scores (see AnalysisEngine
    // _evaluateWithRules). Factor-based signal extraction does not apply, so
    // surface the rule signal description instead to avoid misleading
    // "均线结构较好/偏弱" output on a rule strategy.
    final isRuleBased =
        score.maScore == 0 &&
        score.bollScore == 0 &&
        score.volScore == 0 &&
        score.trendScore == 0;
    if (isRuleBased) {
      return '规则策略按入场/出场信号判定，不适用因子分解；下一步：$nextObservation';
    }
    final strongest = _strongestSignal;
    final weakest = _weakestSignal;
    return '匹配点：$strongest；风险点：$weakest；下一步：$nextObservation';
  }

  String get nextObservation {
    if (score.isBandLow || score.bollScore >= 7) {
      return '观察是否重新站上短期均线';
    }
    if (score.maScore >= 7 || score.trendScore >= 7) {
      return '观察趋势能否连续保持';
    }
    return '加入关注后看 3-5 日表现';
  }

  String get _strongestSignal {
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

  String get _weakestSignal {
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
}
