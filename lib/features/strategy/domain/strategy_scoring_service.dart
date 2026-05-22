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
    return '$reason，$status ${score.score}/$recommendThreshold';
  }
}
