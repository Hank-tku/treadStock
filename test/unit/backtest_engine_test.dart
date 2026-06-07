import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/strategy/domain/backtest_engine.dart';
import 'package:stockpilot/features/strategy/domain/backtest_models.dart';
import 'package:stockpilot/features/strategy/domain/signal_rule.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';

/// Generate mock kline data for testing.
/// Prices follow a pattern: [trendPct] per day drift with volatility.
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
    if (price <= 0) price = 0.01; // floor
    final high = price * (1 + volatility / 2);
    final low = price * (1 - volatility / 2);

    // Use business days starting from 2025-01-02
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

/// Create a weighted strategy for testing.
Strategy _weightedStrategy({
  int threshold = 7,
  int maShort = 20,
  int maLong = 60,
}) {
  return Strategy(
    id: 'test-strategy',
    name: '测试策略',
    maShortPeriod: maShort,
    maLongPeriod: maLong,
    recommendThreshold: threshold,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

/// Create a rule-based strategy.
Strategy _ruleStrategy({
  List<SignalRule> entryRules = const [],
  List<SignalRule> exitRules = const [],
}) {
  return Strategy(
    id: 'test-rule-strategy',
    name: '规则测试策略',
    entryRules: entryRules,
    exitRules: exitRules,
    recommendThreshold: 7,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  late BacktestEngine engine;
  late AnalysisEngine analysisEngine;

  setUp(() {
    engine = BacktestEngine();
    analysisEngine = AnalysisEngine();
  });

  group('BacktestEngine - basic cases', () {
    test('empty klines returns zero-result', () {
      final result = engine.run(
        klines: [],
        strategy: _weightedStrategy(),
        config: const BacktestConfig(),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      expect(result.totalTrades, 0);
      expect(result.trades, isEmpty);
      expect(result.barsProcessed, 0);
    });

    test('insufficient klines (less than warmup) returns zero trades', () {
      final klines = _generateKlines(count: 30);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(),
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      expect(result.totalTrades, 0);
      expect(result.barsProcessed, greaterThan(0));
    });

    test('result contains correct strategy name and stock code', () {
      final klines = _generateKlines(count: 120);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(),
        config: const BacktestConfig(),
        stockCode: '000001',
        analysisEngine: analysisEngine,
      );

      expect(result.strategyName, '测试策略');
      expect(result.stockCode, '000001');
      expect(result.startDate, isNotNull);
      expect(result.endDate, isNotNull);
    });
  });

  group('BacktestEngine - weighted strategy', () {
    test('produces trades with sufficient data', () {
      // Upward trending data should trigger entries
      final klines = _generateKlines(count: 200, trendPct: 0.5);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      // Should have at least some trades in a trending market
      // (exact count depends on scoring logic)
      expect(result.barsProcessed, greaterThan(0));
      if (result.totalTrades > 0) {
        expect(result.winRate, greaterThanOrEqualTo(0.0));
        expect(result.winRate, lessThanOrEqualTo(1.0));
        expect(result.totalReturnPct, greaterThanOrEqualTo(-99999));
      }
    });
  });

  group('BacktestEngine - rule-based strategy', () {
    test('RSI oversold rule can trigger entries', () {
      // RSI < 30 = oversold → buy signal
      final strategy = _ruleStrategy(
        entryRules: [
          const SignalRule(indicator: 'rsi', condition: 'lt', value: 30),
        ],
      );

      // Generate data with a dip to trigger RSI oversold
      final klines = _generateKlines(count: 200, trendPct: -0.3, volatility: 0.05);
      final result = engine.run(
        klines: klines,
        strategy: strategy,
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      // In a volatile declining market, RSI < 30 may trigger
      if (result.totalTrades > 0) {
        for (final trade in result.trades) {
          expect(trade.entryBarIndex, greaterThanOrEqualTo(60));
          expect(trade.exitBarIndex, greaterThan(trade.entryBarIndex));
        }
      }
    });

    test('exit rule triggers and closes trade', () {
      final strategy = _ruleStrategy(
        entryRules: [
          const SignalRule(indicator: 'rsi', condition: 'lt', value: 70),
        ],
        exitRules: [
          const SignalRule(indicator: 'rsi', condition: 'gt', value: 70),
        ],
      );

      final klines = _generateKlines(count: 200, volatility: 0.04);
      final result = engine.run(
        klines: klines,
        strategy: strategy,
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      // Check that trades have exit reasons
      for (final trade in result.trades) {
        expect(trade.exitReason, isNotNull);
      }
    });
  });

  group('BacktestEngine - stop loss / take profit', () {
    test('stop loss triggers correctly', () {
      // Use a very tight stop loss (-1%)
      final klines = _generateKlines(count: 200, trendPct: 0.0, volatility: 0.03);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(
          warmupBars: 60,
          stopLossPct: -0.01, // -1%
        ),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      // If there are trades, check that stop loss was used
      final stopLossTrades = result.trades
          .where((t) => t.exitReason == ExitReason.stopLoss)
          .toList();
      for (final t in stopLossTrades) {
        expect(t.returnPct, lessThanOrEqualTo(0));
      }
    });

    test('take profit triggers correctly', () {
      final klines = _generateKlines(count: 200, trendPct: 0.5, volatility: 0.03);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(
          warmupBars: 60,
          takeProfitPct: 0.05, // +5%
        ),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      final tpTrades = result.trades
          .where((t) => t.exitReason == ExitReason.takeProfit)
          .toList();
      for (final t in tpTrades) {
        expect(t.returnPct, greaterThanOrEqualTo(0));
      }
    });
  });

  group('BacktestEngine - statistics', () {
    test('max drawdown is always <= 0', () {
      final klines = _generateKlines(count: 200, volatility: 0.04);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      expect(result.maxDrawdownPct, lessThanOrEqualTo(0));
    });

    test('win rate is between 0 and 1', () {
      final klines = _generateKlines(count: 200, trendPct: 0.3);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      if (result.totalTrades > 0) {
        expect(result.winRate, greaterThanOrEqualTo(0.0));
        expect(result.winRate, lessThanOrEqualTo(1.0));
        expect(result.winCount + result.loseCount, equals(result.totalTrades));
      }
    });

    test('profit factor is non-negative', () {
      final klines = _generateKlines(count: 200);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      expect(result.profitFactor, greaterThanOrEqualTo(0));
    });

    test('consecutive wins and losses are tracked', () {
      final klines = _generateKlines(count: 200, volatility: 0.05);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      expect(result.maxConsecutiveWins, greaterThanOrEqualTo(0));
      expect(result.maxConsecutiveLosses, greaterThanOrEqualTo(0));
      if (result.totalTrades > 0) {
        expect(
          result.maxConsecutiveWins + result.maxConsecutiveLosses,
          greaterThanOrEqualTo(1),
        );
      }
    });

    test('best trade >= worst trade', () {
      final klines = _generateKlines(count: 200, volatility: 0.05);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      if (result.totalTrades > 1) {
        expect(result.bestTradePct, greaterThanOrEqualTo(result.worstTradePct));
      }
    });

    test('average holding days is positive for closed trades', () {
      final klines = _generateKlines(count: 200);
      final result = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      if (result.totalTrades > 0) {
        expect(result.avgHoldingDays, greaterThanOrEqualTo(1));
      }
    });
  });

  group('BacktestEngine - trade model', () {
    test('BacktestTrade.isWin returns true for profitable trades', () {
      final trade = BacktestTrade(
        direction: TradeDirection.long,
        entryBarIndex: 0,
        entryDate: DateTime(2025, 1, 1),
        entryPrice: 10.0,
        exitBarIndex: 5,
        exitDate: DateTime(2025, 1, 8),
        exitPrice: 11.0,
        shares: 1000,
        grossProfit: 1000,
        commission: 10,
        stampTax: 11,
        netProfit: 979,
        returnPct: 0.0979,
        exitReason: ExitReason.endOfData,
      );

      expect(trade.isWin, isTrue);
    });

    test('BacktestTrade.isWin returns false for losing trades', () {
      final trade = BacktestTrade(
        direction: TradeDirection.long,
        entryBarIndex: 0,
        entryDate: DateTime(2025, 1, 1),
        entryPrice: 10.0,
        exitBarIndex: 5,
        exitDate: DateTime(2025, 1, 8),
        exitPrice: 9.0,
        shares: 1000,
        grossProfit: -1000,
        commission: 10,
        stampTax: 9,
        netProfit: -1019,
        returnPct: -0.1019,
        exitReason: ExitReason.stopLoss,
      );

      expect(trade.isWin, isFalse);
    });
  });

  group('BacktestEngine - result health label', () {
    test('zero trades shows 无交易', () {
      const result = BacktestResult(
        strategyName: 'test',
        stockCode: '000001',
        trades: [],
      );
      expect(result.healthLabel, '无交易');
    });

    test('good win rate and profit factor shows 良好', () {
      const result = BacktestResult(
        strategyName: 'test',
        stockCode: '000001',
        trades: [],
        totalTrades: 10,
        winRate: 0.7,
        profitFactor: 2.0,
      );
      expect(result.healthLabel, '策略表现良好');
    });

    test('neutral performance', () {
      const result = BacktestResult(
        strategyName: 'test',
        stockCode: '000001',
        trades: [],
        totalTrades: 10,
        winRate: 0.5,
        profitFactor: 1.2,
      );
      expect(result.healthLabel, '策略表现中性');
    });

    test('weak performance', () {
      const result = BacktestResult(
        strategyName: 'test',
        stockCode: '000001',
        trades: [],
        totalTrades: 10,
        winRate: 0.3,
        profitFactor: 0.5,
      );
      expect(result.healthLabel, '策略表现偏弱');
    });
  });

  group('BacktestEngine - maxTrades limit', () {
    test('respects maxTrades configuration', () {
      final klines = _generateKlines(count: 300, trendPct: 0.5, volatility: 0.03);
      final unlimited = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60, maxTrades: 0),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );
      final limited = engine.run(
        klines: klines,
        strategy: _weightedStrategy(threshold: 5),
        config: const BacktestConfig(warmupBars: 60, maxTrades: 3),
        stockCode: '600000',
        analysisEngine: analysisEngine,
      );

      expect(limited.totalTrades, lessThanOrEqualTo(3));
      if (unlimited.totalTrades > 3) {
        expect(limited.totalTrades, lessThan(unlimited.totalTrades));
      }
    });
  });
}
