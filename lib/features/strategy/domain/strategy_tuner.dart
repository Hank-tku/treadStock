import '../../analysis/domain/analysis_engine.dart';
import '../../stock/domain/stock_models.dart';
import 'backtest_engine.dart';
import 'backtest_models.dart';
import 'strategy_models.dart';

/// Result of a single tuning combination.
class TunerResult {
  /// Strategy variant with modified parameters.
  final Strategy strategyVariant;

  /// Backtest result for this variant.
  final BacktestResult backtestResult;

  /// Human-readable label describing the parameter changes,
  /// e.g. 'MA10/40, MA权重0.20, 布林权重0.40'
  final String label;

  /// Whether this is the baseline (original strategy, no parameter changes).
  final bool isBaseline;

  const TunerResult({
    required this.strategyVariant,
    required this.backtestResult,
    required this.label,
    this.isBaseline = false,
  });
}

/// Auto-tuner that tries different parameter combinations and finds the best
/// one based on backtest total return percentage.
///
/// Parameter grid:
/// - maShortPeriod: [10, 20, 30]
/// - maLongPeriod: [40, 60, 80]
/// - weightMA: [0.1, 0.2, 0.3, 0.4, 0.5]
/// - weightBoll: [0.1, 0.2, 0.3, 0.4, 0.5]
///
/// Only combinations where weightMA + weightBoll <= 0.9 are tested so that
/// weightVol + weightTrend can fill the remaining budget.
class StrategyTuner {
  final BacktestEngine _engine = BacktestEngine();

  /// Parameter sweep values.
  static const List<int> _maShortValues = [10, 20, 30];
  static const List<int> _maLongValues = [40, 60, 80];
  static const List<double> _weightMAValues = [0.1, 0.2, 0.3, 0.4, 0.5];
  static const List<double> _weightBollValues = [0.1, 0.2, 0.3, 0.4, 0.5];

  /// Maximum results to return (sorted by totalReturnPct descending).
  static const int maxResults = 20;

  /// Run the parameter sweep.
  ///
  /// [strategy] - Original strategy to use as baseline and template.
  /// [klines] - Historical kline data for backtesting.
  /// [config] - Backtest configuration (capital, commission, etc.).
  /// [stockCode] - Stock code for labeling.
  /// [analysisEngine] - Analysis engine for scoring.
  List<TunerResult> tune({
    required Strategy strategy,
    required List<DailyKline> klines,
    required BacktestConfig config,
    required String stockCode,
    required AnalysisEngine analysisEngine,
  }) {
    final results = <TunerResult>[];

    // ── Baseline: original strategy unchanged ──
    final baselineResult = _engine.run(
      klines: klines,
      strategy: strategy,
      config: config,
      stockCode: stockCode,
      analysisEngine: analysisEngine,
    );
    results.add(TunerResult(
      strategyVariant: strategy,
      backtestResult: baselineResult,
      label: '原始参数 (基线)',
      isBaseline: true,
    ));

    // ── Sweep parameter grid ──
    for (final maShort in _maShortValues) {
      for (final maLong in _maLongValues) {
        // Skip invalid combinations where short >= long
        if (maShort >= maLong) continue;

        for (final wMA in _weightMAValues) {
          for (final wBoll in _weightBollValues) {
            // Ensure remaining budget for weightVol + weightTrend (>= 0.1 each)
            final remaining = 1.0 - wMA - wBoll;
            if (remaining < 0.2) continue; // need at least 0.2 total for Vol+Trend

            // Distribute remaining weight proportionally to original ratios
            final origVolTrendSum =
                strategy.weightVol + strategy.weightTrend;
            final wVol = origVolTrendSum > 0
                ? (remaining * strategy.weightVol / origVolTrendSum)
                : remaining / 2;
            final wTrend = remaining - wVol;

            final variant = strategy.copyWith(
              maShortPeriod: maShort,
              maLongPeriod: maLong,
              weightMA: wMA,
              weightBoll: wBoll,
              weightVol: wVol,
              weightTrend: wTrend,
            );

            final btResult = _engine.run(
              klines: klines,
              strategy: variant,
              config: config,
              stockCode: stockCode,
              analysisEngine: analysisEngine,
            );

            // Build descriptive label
            final label =
                'MA$maShort/$maLong, '
                'MA权重${wMA.toStringAsFixed(2)}, '
                '布林权重${wBoll.toStringAsFixed(2)}';

            results.add(TunerResult(
              strategyVariant: variant,
              backtestResult: btResult,
              label: label,
            ));
          }
        }
      }
    }

    // ── Sort by totalReturnPct descending ──
    results.sort((a, b) =>
        b.backtestResult.totalReturnPct
            .compareTo(a.backtestResult.totalReturnPct));

    // ── Keep baseline + top variants, limit to maxResults ──
    final baseline = results.firstWhere((r) => r.isBaseline);
    final nonBaseline =
        results.where((r) => !r.isBaseline).take(maxResults - 1).toList();
    return [baseline, ...nonBaseline];
  }
}
