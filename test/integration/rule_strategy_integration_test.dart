import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';
import 'package:stockpilot/features/strategy/domain/strategy_presets.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';

void main() {
  group('Rule-based strategy integration', () {
    final engine = AnalysisEngine();
    final now = DateTime(2026, 6, 7);

    /// Generate strongly declining klines to trigger RSI oversold
    List<DailyKline> generateDecliningKlines({
      int days = 60,
      double startPrice = 50.0,
    }) {
      final klines = <DailyKline>[];
      var price = startPrice;
      for (var i = 0; i < days; i++) {
        final prevClose = i > 0 ? klines[i - 1].close : price * 1.05;
        price *= 0.96; // 4% daily drop
        klines.add(DailyKline(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          open: price * 1.005,
          close: price,
          high: price * 1.01,
          low: price * 0.99,
          volume: 100000 + i * 1000,
          amount: price * 5000000000,
          preClose: prevClose,
        ));
      }
      return klines;
    }

    /// Generate strongly rising klines
    List<DailyKline> generateRisingKlines({
      int days = 60,
      double startPrice = 10.0,
    }) {
      final klines = <DailyKline>[];
      var price = startPrice;
      for (var i = 0; i < days; i++) {
        final prevClose = i > 0 ? klines[i - 1].close : price * 0.95;
        price *= 1.04; // 4% daily rise
        klines.add(DailyKline(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          open: price * 0.995,
          close: price,
          high: price * 1.01,
          low: price * 0.99,
          volume: 100000 + i * 1000,
          amount: price * 5000000000,
          preClose: prevClose,
        ));
      }
      return klines;
    }

    test('RSI oversold preset triggers on declining market', () {
      final strategy =
          StrategyPresets.rsiOversoldBounce(id: 'int-test-1', now: now);
      final klines = generateDecliningKlines();
      final score = engine.calculateScoreForStrategy(klines, strategy);
      expect(score.score, greaterThanOrEqualTo(7));
      expect(strategy.isRuleBased, isTrue);
    });

    test('RSI oversold preset does NOT trigger on rising market', () {
      final strategy =
          StrategyPresets.rsiOversoldBounce(id: 'int-test-2', now: now);
      final klines = generateRisingKlines();
      final score = engine.calculateScoreForStrategy(klines, strategy);
      expect(score.score, lessThan(7));
    });

    test('Traditional strategy still works alongside rule-based ones', () {
      final decliningKlines = generateDecliningKlines();

      // Old-style strategy (no rules)
      final oldStrategy = Strategy(
        id: 'old-1',
        name: '传统加权',
        description: '',
        maShortPeriod: 20,
        maLongPeriod: 60,
        bollPeriod: 20,
        bollStdDev: 2.0,
        weightMA: 0.3,
        weightBoll: 0.3,
        weightVol: 0.2,
        weightTrend: 0.2,
        recommendThreshold: 7,
        isEnabled: true,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );
      final oldScore =
          engine.calculateScoreForStrategy(decliningKlines, oldStrategy);
      expect(oldScore.score, greaterThanOrEqualTo(1));
      expect(oldScore.score, lessThanOrEqualTo(10));

      // New rule-based strategy
      final newStrategy =
          StrategyPresets.rsiOversoldBounce(id: 'new-1', now: now);
      final newScore =
          engine.calculateScoreForStrategy(decliningKlines, newStrategy);
      expect(newScore.score, greaterThanOrEqualTo(1));
      expect(newScore.score, lessThanOrEqualTo(10));
    });

    test('Strategy.toJson and fromJson round-trip preserves rules', () {
      final original =
          StrategyPresets.macdGoldenCross(id: 'json-1', now: now);
      final json = original.toJson();
      final restored = Strategy.fromJson(json);
      expect(restored.isRuleBased, isTrue);
      expect(restored.entryRules!.length, original.entryRules!.length);
      expect(restored.exitRules!.length, original.exitRules!.length);
      expect(restored.entryRules!.first.indicator, 'macd');
    });

    test('All presets produce valid scores on various market conditions', () {
      var counter = 0;
      final presets = StrategyPresets.all(
        idGenerator: () => 'verify-${++counter}',
        now: now,
      );

      final marketConditions = {
        'declining': generateDecliningKlines(),
        'rising': generateRisingKlines(),
      };

      for (final preset in presets) {
        for (final entry in marketConditions.entries) {
          final score =
              engine.calculateScoreForStrategy(entry.value, preset);
          expect(score.score, greaterThanOrEqualTo(1),
              reason: '${preset.name} on ${entry.key}');
          expect(score.score, lessThanOrEqualTo(10),
              reason: '${preset.name} on ${entry.key}');
          expect(score.reason, isNotEmpty,
              reason: '${preset.name} on ${entry.key}');
        }
      }
    });
  });
}
