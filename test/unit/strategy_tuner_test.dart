import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/strategy_tuner.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:stockpilot/features/strategy/domain/backtest_models.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';

/// Generate mock kline data for testing.
/// Prices follow a pattern with configurable trend and volatility.
List<DailyKline> _generateKlines({
  int count = 120,
  double startPrice = 10.0,
  double trendPct = 0.0,
  double volatility = 0.02,
}) {
  final klines = <DailyKline>[];
  var price = startPrice;

  for (var i = 0; i < count; i++) {
    final change = trendPct / 100 + (i % 7 - 3) * volatility / 100;
    price = price * (1 + change);
    if (price <= 0) price = 0.01;
    final high = price * (1 + volatility / 2);
    final low = price * (1 - volatility / 2);

    final date = DateTime(2025, 1, 2).add(Duration(days: i));

    klines.add(DailyKline(
      date: date,
      open: price * (1 - volatility / 4),
      close: price,
      high: high,
      low: low,
      volume: 100000 + (i % 10) * 10000,
      amount: price * 100000,
      preClose: i > 0 ? klines[i - 1].close : price,
    ));
  }
  return klines;
}

/// Create a test strategy with sensible defaults.
Strategy _testStrategy() {
  return Strategy(
    id: 'test-tuner-strategy',
    name: '调参测试策略',
    maShortPeriod: 20,
    maLongPeriod: 60,
    bollPeriod: 20,
    bollStdDev: 2.0,
    weightMA: 0.30,
    weightBoll: 0.30,
    weightVol: 0.20,
    weightTrend: 0.20,
    recommendThreshold: 7,
    isEnabled: true,
    isDefault: false,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  late StrategyTuner tuner;
  late AnalysisEngine analysisEngine;

  setUp(() {
    tuner = StrategyTuner();
    analysisEngine = AnalysisEngine();
  });

  group('StrategyTuner.tune', () {
    test('returns results including baseline', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      expect(results, isNotEmpty);
      final baselines = results.where((r) => r.isBaseline).toList();
      expect(baselines.length, 1, reason: 'Should have exactly one baseline');
    });

    test('baseline is marked with isBaseline=true', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      final baseline = results.firstWhere((r) => r.isBaseline);
      expect(baseline.isBaseline, isTrue);
      expect(baseline.label, contains('基线'));
      // Baseline strategy variant should match the original
      expect(baseline.strategyVariant.maShortPeriod, strategy.maShortPeriod);
      expect(baseline.strategyVariant.maLongPeriod, strategy.maLongPeriod);
    });

    test('non-baseline results have isBaseline=false', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      final nonBaselines = results.where((r) => !r.isBaseline).toList();
      for (final r in nonBaselines) {
        expect(r.isBaseline, isFalse);
      }
    });

    test('results are sorted by totalReturnPct descending (after baseline)', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      // Baseline is always first; the rest should be sorted descending.
      // The implementation returns [baseline, ...sortedNonBaseline].
      // Skip the baseline (index 0), check the rest are sorted.
      final nonBaseline = results.skip(1).toList();
      for (var i = 1; i < nonBaseline.length; i++) {
        expect(
          nonBaseline[i - 1].backtestResult.totalReturnPct,
          greaterThanOrEqualTo(nonBaseline[i].backtestResult.totalReturnPct),
          reason: 'Results after baseline should be sorted by totalReturnPct descending',
        );
      }
    });

    test('returns multiple parameter variants', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      // The grid has maShort ∈ {10,20,30} × maLong ∈ {40,60,80}
      // (skip short>=long), weightMA ∈ {0.1..0.5}, weightBoll ∈ {0.1..0.5}
      // (skip if remaining < 0.2). This should produce many variants.
      expect(results.length, greaterThan(1),
          reason: 'Should return baseline plus at least one variant');
      expect(results.length, lessThanOrEqualTo(StrategyTuner.maxResults));
    });

    test('each non-baseline variant has different parameters from baseline', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      final nonBaselines = results.where((r) => !r.isBaseline).toList();
      for (final variant in nonBaselines) {
        final vs = variant.strategyVariant;
        // At least one of the swept parameters should differ from original
        final paramsDiffer = vs.maShortPeriod != strategy.maShortPeriod ||
            vs.maLongPeriod != strategy.maLongPeriod ||
            vs.weightMA != strategy.weightMA ||
            vs.weightBoll != strategy.weightBoll;
        expect(paramsDiffer, isTrue,
            reason: 'Variant should differ in at least one swept parameter');
      }
    });

    test('variant labels describe parameter changes', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      final nonBaselines = results.where((r) => !r.isBaseline).toList();
      for (final variant in nonBaselines) {
        expect(variant.label, contains('MA'));
        expect(variant.label, isNotEmpty);
      }
    });

    test('handles empty klines gracefully', () {
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: [],
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      // Should still return the baseline result with zero trades
      expect(results, isNotEmpty);
      final baseline = results.firstWhere((r) => r.isBaseline);
      expect(baseline.backtestResult.totalTrades, 0);
      expect(baseline.backtestResult.totalReturnPct, 0.0);
    });

    test('handles insufficient klines (fewer than warmup) gracefully', () {
      final klines = _generateKlines(count: 30);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      // Should return results; with few klines the engine produces 0 trades
      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(1));
    });

    test('result count does not exceed maxResults', () {
      final klines = _generateKlines(count: 150);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      expect(results.length, lessThanOrEqualTo(StrategyTuner.maxResults));
    });

    test('each TunerResult has a valid BacktestResult', () {
      final klines = _generateKlines(count: 120);
      final strategy = _testStrategy();
      final config = BacktestConfig();

      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: config,
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      for (final r in results) {
        expect(r.backtestResult, isNotNull);
        expect(r.backtestResult.totalReturnPct, isA<double>());
        expect(r.backtestResult.winRate, isA<double>());
        expect(r.backtestResult.winRate, inInclusiveRange(0.0, 1.0));
        expect(r.label, isNotEmpty);
      }
    });
  });
}
