import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/strategy/domain/signal_rule.dart';
import 'package:stockpilot/features/strategy/domain/rule_engine.dart';

/// Helper: build a list of DailyKline with monotonically declining closes.
List<DailyKline> _decliningKlines(int count, {double startPrice = 50.0, double drop = 0.5}) {
  return List.generate(count, (i) {
    final price = startPrice - i * drop;
    return DailyKline(
      date: DateTime(2026, 1, 1).add(Duration(days: i)),
      open: price + 0.1,
      close: price,
      high: price + 0.3,
      low: price - 0.2,
      volume: 100000,
      amount: price * 100000,
    );
  });
}

/// Helper: build klines with a V-shaped recovery so MACD crosses up.
List<DailyKline> _vShapedKlines() {
  final klines = <DailyKline>[];
  // 25 days declining
  for (var i = 0; i < 25; i++) {
    final price = 100.0 - i * 1.5;
    klines.add(DailyKline(
      date: DateTime(2026, 1, 1).add(Duration(days: i)),
      open: price + 0.2,
      close: price,
      high: price + 0.5,
      low: price - 0.3,
      volume: 100000,
      amount: price * 100000,
    ));
  }
  // 25 days recovering — creates MACD cross-up
  for (var i = 0; i < 25; i++) {
    final price = 62.5 + i * 1.5;
    klines.add(DailyKline(
      date: DateTime(2026, 1, 26).add(Duration(days: i)),
      open: price - 0.2,
      close: price,
      high: price + 0.5,
      low: price - 0.3,
      volume: 120000,
      amount: price * 120000,
    ));
  }
  return klines;
}

/// Helper: build klines with steady prices so RSI stays moderate.
List<DailyKline> _steadyKlines(int count, {double price = 50.0}) {
  return List.generate(count, (i) {
    return DailyKline(
      date: DateTime(2026, 1, 1).add(Duration(days: i)),
      open: price,
      close: price,
      high: price + 0.1,
      low: price - 0.1,
      volume: 100000,
      amount: price * 100000,
    );
  });
}

void main() {
  group('RuleEngine', () {
    test('empty klines → entry not triggered, RSI/MACD/KDJ absent', () {
      final result = RuleEngine.evaluate(
        klines: [],
        entryRules: [SignalRule(indicator: 'rsi', condition: 'lt', value: 30)],
      );

      expect(result.entryTriggered, isFalse);
      expect(result.exitTriggered, isFalse);
      // RSI/MACD/KDJ/Boll require sufficient data so should be absent
      expect(result.indicatorValues.containsKey('rsi'), isFalse);
      expect(result.indicatorValues.containsKey('macd'), isFalse);
      expect(result.indicatorValues.containsKey('k'), isFalse);
      expect(result.indicatorValues.containsKey('boll_position'), isFalse);
      // ma_alignment, vol_price_divergence, vol_ratio have defaults
      expect(result.indicatorValues['ma_alignment'], 5.0);
      expect(result.indicatorValues['vol_price_divergence'], 0.0);
      expect(result.indicatorValues['vol_ratio'], 1.0);
      expect(result.prevIndicatorValues, isEmpty);
      expect(result.entryResults, [false]);
    });

    test('RSI < 30 rule with declining prices → entry triggered', () {
      // 30 declining klines: RSI should be very low
      final klines = _decliningKlines(30, startPrice: 50.0, drop: 1.0);
      final rule = SignalRule(indicator: 'rsi', condition: 'lt', value: 30);

      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [rule],
      );

      expect(result.indicatorValues, contains('rsi'));
      expect(result.indicatorValues['rsi']!, lessThan(30));
      expect(result.entryResults, [true]);
      expect(result.entryTriggered, isTrue);
    });

    test('multiple entry rules use AND logic — all must pass', () {
      // Declining prices: RSI low, MACD negative
      final klines = _decliningKlines(40, startPrice: 50.0, drop: 1.0);
      final rule1 = SignalRule(indicator: 'rsi', condition: 'lt', value: 30);
      final rule2 = SignalRule(indicator: 'macd', condition: 'lt', value: 0);

      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [rule1, rule2],
      );

      // Both should pass: declining prices → low RSI and negative MACD
      expect(result.entryResults.length, 2);
      expect(result.entryResults[0], isTrue, reason: 'RSI should be < 30');
      expect(result.entryResults[1], isTrue, reason: 'MACD should be < 0');
      expect(result.entryTriggered, isTrue);

      // Now add a rule that will fail: RSI > 70 should be false
      final rule3 = SignalRule(indicator: 'rsi', condition: 'gt', value: 70);
      final result2 = RuleEngine.evaluate(
        klines: klines,
        entryRules: [rule1, rule3],
      );

      expect(result2.entryResults[0], isTrue);
      expect(result2.entryResults[1], isFalse);
      expect(result2.entryTriggered, isFalse, reason: 'AND logic: not all rules pass');
    });

    test('exit rules use OR logic — any one triggers exit', () {
      // Steady prices: RSI moderate, MACD near zero
      final klines = _steadyKlines(40);
      final exitRule1 = SignalRule(indicator: 'rsi', condition: 'gt', value: 70);
      final exitRule2 = SignalRule(indicator: 'macd_hist', condition: 'gt', value: 0);

      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [],
        exitRules: [exitRule1, exitRule2],
      );

      expect(result.exitTriggered, isTrue, reason: 'OR logic: at least one exit rule should pass');
      // At least one exit result should be true
      expect(result.exitResults.any((r) => r), isTrue);
    });

    test('cross_up rule with MACD — uses prev/current comparison', () {
      // V-shaped: MACD should cross up from negative to positive
      final klines = _vShapedKlines();
      final crossRule = SignalRule(indicator: 'macd', condition: 'cross_up', value: 0);

      final result = RuleEngine.evaluate(
        klines: klines,
        entryRules: [crossRule],
      );

      // With V-shaped recovery, MACD should cross up above 0
      expect(result.indicatorValues, contains('macd'));
      expect(result.prevIndicatorValues, contains('macd'));

      // Verify cross_up logic: prev < 0 and current >= 0
      if (result.prevIndicatorValues['macd'] != null && result.indicatorValues['macd'] != null) {
        final prevMacd = result.prevIndicatorValues['macd']!;
        final curMacd = result.indicatorValues['macd']!;
        // The cross_up should detect prev < 0 and current >= 0
        expect(result.entryResults[0], equals(prevMacd < 0 && curMacd >= 0));
      }
    });
  });
}
