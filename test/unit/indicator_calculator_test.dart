import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/indicator_calculator.dart';

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
}
