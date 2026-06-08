import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/indicator_calculator.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/strategy/domain/rule_engine.dart';
import 'package:stockpilot/features/strategy/domain/signal_rule.dart';
import 'package:stockpilot/features/strategy/domain/strategy_presets.dart';

DailyKline _k(double close, {double volume = 1000, double open = 0, double high = 0, double low = 0}) {
  return DailyKline(
    date: DateTime(2026, 1, 1),
    open: open > 0 ? open : close,
    close: close,
    high: high > 0 ? high : close * 1.02,
    low: low > 0 ? low : close * 0.98,
    volume: volume,
    amount: close * volume,
  );
}

List<DailyKline> _makeKlines(List<double> closes, {List<double>? volumes}) {
  return List.generate(closes.length, (i) {
    final c = closes[i];
    final v = volumes != null ? volumes[i] : 1000.0;
    return _k(c, volume: v);
  });
}

void main() {
  group('calculateBollPosition', () {
    test('returns 0.5 when price is at midpoint', () {
      expect(
        IndicatorCalculator.calculateBollPosition(50.0, 60.0, 40.0),
        closeTo(0.5, 0.001),
      );
    });

    test('returns ~0 when price is at lower band', () {
      expect(
        IndicatorCalculator.calculateBollPosition(40.0, 60.0, 40.0),
        closeTo(0.0, 0.001),
      );
    });

    test('returns ~1 when price is at upper band', () {
      expect(
        IndicatorCalculator.calculateBollPosition(60.0, 60.0, 40.0),
        closeTo(1.0, 0.001),
      );
    });

    test('returns 0.5 when upper == lower', () {
      expect(
        IndicatorCalculator.calculateBollPosition(50.0, 50.0, 50.0),
        0.5,
      );
    });

    test('clamps values below 0', () {
      expect(
        IndicatorCalculator.calculateBollPosition(30.0, 60.0, 40.0),
        closeTo(0.0, 0.001),
      );
    });

    test('clamps values above 1', () {
      expect(
        IndicatorCalculator.calculateBollPosition(70.0, 60.0, 40.0),
        closeTo(1.0, 0.001),
      );
    });
  });

  group('calculateMAAlignment', () {
    test('returns 10.0 for perfect bullish alignment', () {
      // Generate closes where MA5 > MA10 > MA20 > MA60
      // Ascending trend: recent values high, older values low
      final closes = <double>[];
      for (var i = 0; i < 60; i++) {
        closes.add((i + 1).toDouble());
      }
      final result = IndicatorCalculator.calculateMAAlignment(closes);
      expect(result, equals(10.0));
    });

    test('returns 0.0 for perfect bearish alignment', () {
      // Descending trend
      final closes = <double>[];
      for (var i = 60; i >= 1; i--) {
        closes.add(i.toDouble());
      }
      final result = IndicatorCalculator.calculateMAAlignment(closes);
      expect(result, equals(0.0));
    });

    test('returns 5.0 when insufficient data', () {
      expect(
        IndicatorCalculator.calculateMAAlignment([1.0, 2.0, 3.0]),
        5.0,
      );
    });

    test('returns partial score for partial alignment', () {
      // Flat then slight rise: should have some alignment
      final closes = <double>[];
      for (var i = 0; i < 30; i++) {
        closes.add(10.0); // flat for 30 days
      }
      for (var i = 0; i < 30; i++) {
        closes.add(10.0 + i * 0.5); // rising for 30 days
      }
      final result = IndicatorCalculator.calculateMAAlignment(closes);
      // Should be between 0 and 10, not extreme
      expect(result, greaterThanOrEqualTo(0.0));
      expect(result, lessThanOrEqualTo(10.0));
    });
  });

  group('calculateVolumePriceDivergence', () {
    test('returns 1 for top divergence (price up + volume down)', () {
      // 5 days: price consistently up, volume consistently down
      final klines = _makeKlines(
        [10.0, 11.0, 12.0, 13.0, 14.0, 15.0],
        volumes: [5000, 4000, 3000, 2500, 2000, 1500],
      );
      // lookback=5: take last 5 days, compare day-over-day:
      // days 1-2: price up, vol down; 2-3: up, down; 3-4: up, down; 4-5: up, down
      // priceUpDays=4, volDownDays=4 → both >= 3 → return 1
      expect(
        IndicatorCalculator.calculateVolumePriceDivergence(klines, lookback: 5),
        equals(1.0),
      );
    });

    test('returns 1 for bottom divergence (price down + volume up)', () {
      final klines = _makeKlines(
        [15.0, 14.0, 13.0, 12.0, 11.0, 10.0],
        volumes: [1000, 2000, 3000, 4000, 5000, 6000],
      );
      expect(
        IndicatorCalculator.calculateVolumePriceDivergence(klines, lookback: 5),
        equals(1.0),
      );
    });

    test('returns 0 for normal correlated price-volume', () {
      // Price up and volume up — no divergence
      final klines = _makeKlines(
        [10.0, 11.0, 12.0, 13.0, 14.0, 15.0],
        volumes: [1000, 2000, 3000, 4000, 5000, 6000],
      );
      expect(
        IndicatorCalculator.calculateVolumePriceDivergence(klines, lookback: 5),
        equals(0.0),
      );
    });

    test('returns 0 for insufficient data', () {
      final klines = _makeKlines([10.0, 11.0]);
      expect(
        IndicatorCalculator.calculateVolumePriceDivergence(klines, lookback: 5),
        equals(0.0),
      );
    });
  });

  group('calculateVolumeRatio', () {
    test('returns ~1.0 for normal volume', () {
      final klines = _makeKlines(
        List.generate(6, (_) => 10.0),
        volumes: [1000, 1000, 1000, 1000, 1000, 1000],
      );
      final ratio = IndicatorCalculator.calculateVolumeRatio(klines);
      expect(ratio, closeTo(1.0, 0.01));
    });

    test('returns >1.5 for high volume day', () {
      final klines = _makeKlines(
        List.generate(6, (_) => 10.0),
        volumes: [1000, 1000, 1000, 1000, 1000, 3000],
      );
      final ratio = IndicatorCalculator.calculateVolumeRatio(klines);
      expect(ratio, greaterThan(2.5));
    });

    test('returns <0.5 for low volume day', () {
      final klines = _makeKlines(
        List.generate(6, (_) => 10.0),
        volumes: [1000, 1000, 1000, 1000, 1000, 200],
      );
      final ratio = IndicatorCalculator.calculateVolumeRatio(klines);
      expect(ratio, lessThan(0.5));
    });

    test('returns 1.0 for insufficient data', () {
      expect(
        IndicatorCalculator.calculateVolumeRatio([_k(10.0)]),
        1.0,
      );
    });
  });

  group('RuleEngine new indicators', () {
    List<DailyKline> makeTrendingKlines(int count) {
      final klines = <DailyKline>[];
      for (var i = 0; i < count; i++) {
        final price = 10.0 + i * 0.5;
        klines.add(DailyKline(
          date: DateTime(2026, 1, 1 + i),
          open: price,
          close: price + 0.1,
          high: price + 0.5,
          low: price - 0.5,
          volume: 1000 + (i % 3) * 100,
          amount: price * 1000,
        ));
      }
      return klines;
    }

    test('boll_position is populated in indicatorValues', () {
      final klines = makeTrendingKlines(80);
      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [SignalRule(indicator: 'boll_position', condition: 'gt', value: -1)],
        exitRules: [],
      );
      expect(result.indicatorValues, contains('boll_position'));
      expect(result.indicatorValues['boll_position'], greaterThanOrEqualTo(0.0));
      expect(result.indicatorValues['boll_position'], lessThanOrEqualTo(1.0));
    });

    test('ma_alignment is populated in indicatorValues', () {
      final klines = makeTrendingKlines(80);
      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [SignalRule(indicator: 'ma_alignment', condition: 'gt', value: -1)],
        exitRules: [],
      );
      expect(result.indicatorValues, contains('ma_alignment'));
      expect(result.indicatorValues['ma_alignment'], greaterThanOrEqualTo(0.0));
      expect(result.indicatorValues['ma_alignment'], lessThanOrEqualTo(10.0));
    });

    test('vol_price_divergence is populated in indicatorValues', () {
      final klines = makeTrendingKlines(80);
      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [SignalRule(indicator: 'vol_price_divergence', condition: 'gt', value: -1)],
        exitRules: [],
      );
      expect(result.indicatorValues, contains('vol_price_divergence'));
    });

    test('vol_ratio is populated in indicatorValues', () {
      final klines = makeTrendingKlines(80);
      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [SignalRule(indicator: 'vol_ratio', condition: 'gt', value: 0)],
        exitRules: [],
      );
      expect(result.indicatorValues, contains('vol_ratio'));
      expect(result.indicatorValues['vol_ratio'], greaterThan(0));
    });
  });

  group('StrategyPresets new templates', () {
    test('all() returns 8 presets', () {
      final presets = StrategyPresets.all(
        idGenerator: () => 'test-id',
        now: DateTime(2026, 1, 1),
      );
      expect(presets.length, 8);
    });

    test('bollBandBounce has correct entry/exit rules', () {
      final s = StrategyPresets.bollBandBounce(
        id: 'test',
        now: DateTime(2026, 1, 1),
      );
      expect(s.name, '布林带下轨反弹');
      expect(s.entryRules!.length, 2);
      expect(s.entryRules![0].indicator, 'boll_position');
      expect(s.entryRules![0].condition, 'lt');
      expect(s.entryRules![1].indicator, 'rsi');
      expect(s.exitRules!.length, 1);
      expect(s.exitRules![0].indicator, 'boll_position');
    });

    test('maBullAlignment has correct entry/exit rules', () {
      final s = StrategyPresets.maBullAlignment(
        id: 'test',
        now: DateTime(2026, 1, 1),
      );
      expect(s.name, '均线多头排列');
      expect(s.entryRules!.length, 2);
      expect(s.entryRules![0].indicator, 'ma_alignment');
      expect(s.entryRules![1].indicator, 'vol_ratio');
      expect(s.exitRules![0].indicator, 'ma_alignment');
    });

    test('volPriceDivergenceBottom has correct entry/exit rules', () {
      final s = StrategyPresets.volPriceDivergenceBottom(
        id: 'test',
        now: DateTime(2026, 1, 1),
      );
      expect(s.name, '量价背离抄底');
      expect(s.entryRules!.length, 2);
      expect(s.entryRules![0].indicator, 'vol_price_divergence');
      expect(s.entryRules![1].indicator, 'rsi');
      expect(s.exitRules![0].indicator, 'rsi');
    });
  });
}
