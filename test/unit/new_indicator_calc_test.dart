import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/indicator_calculator.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';

DailyKline _k(double close, {double volume = 1000, double open = 0, double high = 0, double low = 0, double prevClose = 0}) {
  return DailyKline(
    date: DateTime(2026, 1, 1),
    open: open > 0 ? open : close,
    close: close,
    high: high > 0 ? high : close * 1.02,
    low: low > 0 ? low : close * 0.98,
    volume: volume,
    amount: close * volume,
    preClose: prevClose > 0 ? prevClose : close,
  );
}

void main() {
  group('calculateEMA', () {
    test('returns empty for insufficient data', () {
      expect(IndicatorCalculator.calculateEMA([1, 2, 3], period: 5), isEmpty);
    });

    test('returns correct length', () {
      final closes = List.generate(30, (i) => 100.0 + i);
      final ema = IndicatorCalculator.calculateEMA(closes, period: 10);
      expect(ema.length, 21); // 30 - 10 + 1
    });

    test('EMA values are in reasonable range for monotonic data', () {
      final closes = List.generate(30, (i) => 100.0 + i);
      final ema = IndicatorCalculator.calculateEMA(closes, period: 10);
      // EMA should be within data range
      for (final v in ema) {
        expect(v, greaterThanOrEqualTo(100.0));
        expect(v, lessThanOrEqualTo(129.0));
      }
    });

    test('EMA lags behind price for rising data', () {
      final closes = List.generate(50, (i) => 100.0 + i * 2);
      final ema = IndicatorCalculator.calculateEMA(closes, period: 20);
      // EMA should be less than the current price for rising data
      expect(ema.last, lessThan(closes.last));
    });
  });

  group('calculateATR', () {
    test('returns empty for insufficient data', () {
      final klines = List.generate(10, (i) => _k(100.0 + i));
      expect(IndicatorCalculator.calculateATR(klines, period: 14), isEmpty);
    });

    test('returns correct length for sufficient data', () {
      final klines = List.generate(30, (i) => _k(100.0 + i));
      final atr = IndicatorCalculator.calculateATR(klines, period: 14);
      // 29 true ranges - 14 period + 1 (first ATR) = 16 ATR values
      expect(atr.length, 16);
    });

    test('ATR values are positive', () {
      final klines = List.generate(30, (i) => _k(100.0 + i, high: 102.0 + i, low: 98.0 + i));
      final atr = IndicatorCalculator.calculateATR(klines, period: 14);
      for (final v in atr) {
        expect(v, greaterThan(0));
      }
    });

    test('ATR increases with higher volatility', () {
      // Low volatility
      final lowVolKlines = List.generate(30, (i) => _k(100.0, high: 101.0, low: 99.0));
      // High volatility
      final highVolKlines = List.generate(30, (i) => _k(100.0, high: 110.0, low: 90.0));

      final lowAtr = IndicatorCalculator.calculateATR(lowVolKlines, period: 14);
      final highAtr = IndicatorCalculator.calculateATR(highVolKlines, period: 14);

      expect(highAtr.last, greaterThan(lowAtr.last));
    });
  });

  group('calculateOBV', () {
    test('returns empty for empty klines', () {
      expect(IndicatorCalculator.calculateOBV([]), isEmpty);
    });

    test('returns correct length matching klines', () {
      final klines = List.generate(20, (i) => _k(100.0 + i));
      final obv = IndicatorCalculator.calculateOBV(klines);
      expect(obv.length, 20);
    });

    test('OBV rises when prices rise on high volume', () {
      final klines = [
        _k(10.0, volume: 1000),
        _k(11.0, volume: 2000),
        _k(12.0, volume: 3000),
        _k(13.0, volume: 4000),
      ];
      final obv = IndicatorCalculator.calculateOBV(klines);
      // OBV should be monotonically increasing
      for (var i = 1; i < obv.length; i++) {
        expect(obv[i], greaterThan(obv[i - 1]));
      }
    });

    test('OBV falls when prices fall on high volume', () {
      final klines = [
        _k(13.0, volume: 1000),
        _k(12.0, volume: 2000),
        _k(11.0, volume: 3000),
        _k(10.0, volume: 4000),
      ];
      final obv = IndicatorCalculator.calculateOBV(klines);
      // OBV should be monotonically decreasing after first
      for (var i = 2; i < obv.length; i++) {
        expect(obv[i], lessThan(obv[i - 1]));
      }
    });

    test('OBV unchanged when price unchanged', () {
      final klines = [
        _k(10.0, volume: 1000),
        _k(10.0, volume: 2000),
        _k(10.0, volume: 3000),
      ];
      final obv = IndicatorCalculator.calculateOBV(klines);
      expect(obv[0], 1000.0);
      expect(obv[1], 1000.0);
      expect(obv[2], 1000.0);
    });
  });
}
