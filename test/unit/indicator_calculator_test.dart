import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/indicator_calculator.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';

void main() {
  group('IndicatorCalculator.calculateRSI', () {
    test('returns empty list when closes length < period + 1', () {
      final rsi = IndicatorCalculator.calculateRSI([10, 20, 30], period: 14);
      expect(rsi, isEmpty);
    });

    test('returns RSI values with correct length', () {
      final closes = List.generate(20, (i) => 100.0 + i);
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      // 20 closes - 14 period = 6 RSI values
      expect(rsi.length, 6);
    });

    test('all gains no losses gives RSI = 100', () {
      final closes = List.generate(30, (i) => (i + 1).toDouble());
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      expect(rsi.last, closeTo(100.0, 0.01));
    });

    test('all losses no gains gives RSI = 0', () {
      final closes = List.generate(30, (i) => (30 - i).toDouble());
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      expect(rsi.last, closeTo(0.0, 0.01));
    });

    test('mixed price changes gives RSI between 0 and 100', () {
      final closes = <double>[100];
      for (var i = 1; i < 30; i++) {
        closes.add(closes.last + (i.isEven ? 2 : -1));
      }
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      for (final value in rsi) {
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(100));
      }
    });

    test('uses Wilder smoothing (exponential)', () {
      final closes = <double>[50];
      for (var i = 1; i < 30; i++) {
        closes.add(closes.last * 1.02);
      }
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      expect(rsi.last, greaterThan(90));
    });
  });

  group('IndicatorCalculator.calculateMACD', () {
    test('returns empty result when closes length < slowPeriod + signalPeriod', () {
      final result = IndicatorCalculator.calculateMACD([10, 20, 30, 40]);
      expect(result.macdLine, isEmpty);
      expect(result.signalLine, isEmpty);
      expect(result.histogram, isEmpty);
    });

    test('MACD line crosses zero when price trend reverses from up to down', () {
      final closes = <double>[];
      for (var i = 0; i < 30; i++) {
        closes.add(100 + i * 2.0);
      }
      for (var i = 0; i < 30; i++) {
        closes.add(158 - i * 2.0);
      }
      final result = IndicatorCalculator.calculateMACD(closes);
      expect(result.macdLine.first, greaterThan(0));
      expect(result.macdLine.last, lessThan(0));
    });

    test('histogram equals macdLine minus signalLine', () {
      final closes = List.generate(80, (i) => 100.0 + i * 0.5);
      final result = IndicatorCalculator.calculateMACD(closes);
      for (var i = 0; i < result.histogram.length; i++) {
        expect(result.histogram[i],
            closeTo(result.macdLine[i + (result.macdLine.length - result.histogram.length)] - result.signalLine[i], 0.001));
      }
    });

    test('signal line length <= MACD line length', () {
      final closes = List.generate(80, (i) => 100.0 + i * 0.5);
      final result = IndicatorCalculator.calculateMACD(closes);
      expect(result.signalLine.length, lessThanOrEqualTo(result.macdLine.length));
      expect(result.histogram.length, equals(result.signalLine.length));
    });
  });

  group('IndicatorCalculator.calculateKDJ', () {
    test('returns empty result when klines length < period', () {
      final klines = List.generate(5, (i) => DailyKline(
        date: DateTime(2026, 1, i + 1), open: 100, close: 101, high: 102, low: 99,
        volume: 100000, amount: 10000000, preClose: 100,
      ));
      final result = IndicatorCalculator.calculateKDJ(klines, period: 9);
      expect(result.kValues, isEmpty);
      expect(result.dValues, isEmpty);
      expect(result.jValues, isEmpty);
    });

    test('K and D values between 0-100 for normal data', () {
      final klines = List.generate(30, (i) => DailyKline(
        date: DateTime(2026, 1, i + 1),
        open: 100 + i * 0.5,
        close: 101 + i * 0.5,
        high: 102 + i * 0.5,
        low: 99 + i * 0.5,
        volume: 100000, amount: 10000000, preClose: 100 + (i > 0 ? (i-1) * 0.5 : 0),
      ));
      final result = IndicatorCalculator.calculateKDJ(klines, period: 9);
      for (var i = 0; i < result.kValues.length; i++) {
        expect(result.kValues[i], greaterThanOrEqualTo(0));
        expect(result.kValues[i], lessThanOrEqualTo(100));
        expect(result.dValues[i], greaterThanOrEqualTo(0));
        expect(result.dValues[i], lessThanOrEqualTo(100));
      }
    });

    test('J value can exceed 0-100 range', () {
      // Strong uptrend should push J above 100
      final klines = List.generate(30, (i) => DailyKline(
        date: DateTime(2026, 1, i + 1),
        open: 100 + i * 3.0,
        close: 102 + i * 3.0,
        high: 103 + i * 3.0,
        low: 99 + i * 3.0,
        volume: 100000, amount: 10000000, preClose: 100 + (i > 0 ? (i-1) * 3.0 : 0),
      ));
      final result = IndicatorCalculator.calculateKDJ(klines, period: 9);
      expect(result.jValues.any((j) => j > 100), isTrue);
    });

    test('output length = klines.length - period + 1', () {
      final klines = List.generate(20, (i) => DailyKline(
        date: DateTime(2026, 1, i + 1),
        open: 100.0, close: 100.0 + i, high: 101.0 + i, low: 99.0,
        volume: 100000, amount: 10000000, preClose: i > 0 ? 99.0 + i : 100.0,
      ));
      final result = IndicatorCalculator.calculateKDJ(klines, period: 9);
      expect(result.kValues.length, 12); // 20 - 9 + 1
      expect(result.dValues.length, 12);
      expect(result.jValues.length, 12);
    });
  });
}
