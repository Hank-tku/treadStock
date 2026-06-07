import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/signal_rule.dart';

void main() {
  group('SignalRule', () {
    test('evaluate gt condition returns true when value > threshold', () {
      final rule = SignalRule(indicator: 'rsi', condition: 'gt', value: 70);
      expect(rule.evaluate(75), isTrue);
      expect(rule.evaluate(65), isFalse);
    });

    test('evaluate lt condition returns true when value < threshold', () {
      final rule = SignalRule(indicator: 'rsi', condition: 'lt', value: 30);
      expect(rule.evaluate(25), isTrue);
      expect(rule.evaluate(35), isFalse);
    });

    test('evaluate in_range condition checks inclusive bounds', () {
      final rule = SignalRule(indicator: 'rsi', condition: 'in_range', value: 30, value2: 70);
      expect(rule.evaluate(30), isTrue);
      expect(rule.evaluate(50), isTrue);
      expect(rule.evaluate(70), isTrue);
      expect(rule.evaluate(29), isFalse);
      expect(rule.evaluate(71), isFalse);
    });

    test('evaluate cross_up detects previous < threshold and current >= threshold', () {
      final rule = SignalRule(indicator: 'macd', condition: 'cross_up', value: 0);
      expect(rule.evaluateWithPrev(-0.5, 0.3), isTrue);
      expect(rule.evaluateWithPrev(0.1, 0.3), isFalse);
      expect(rule.evaluateWithPrev(-0.5, -0.1), isFalse);
    });

    test('evaluate cross_down detects previous > threshold and current <= threshold', () {
      final rule = SignalRule(indicator: 'macd', condition: 'cross_down', value: 0);
      expect(rule.evaluateWithPrev(0.5, -0.3), isTrue);
      expect(rule.evaluateWithPrev(-0.1, -0.3), isFalse);
    });

    test('fromJson / toJson roundtrip preserves all fields', () {
      final rule = SignalRule(
        indicator: 'boll_position',
        condition: 'lt',
        value: 0.3,
        value2: null,
      );
      final json = rule.toJson();
      final restored = SignalRule.fromJson(json);
      expect(restored.indicator, rule.indicator);
      expect(restored.condition, rule.condition);
      expect(restored.value, rule.value);
    });
  });

  group('RuleGroup', () {
    test('toJson/fromJson roundtrip', () {
      final group = RuleGroup(rules: [
        SignalRule(indicator: 'rsi', condition: 'lt', value: 30),
        SignalRule(indicator: 'macd', condition: 'gt', value: 0),
      ]);
      final json = group.toJson();
      final restored = RuleGroup.fromJson(json);
      expect(restored.rules.length, 2);
      expect(restored.rules[0].indicator, 'rsi');
      expect(restored.rules[1].indicator, 'macd');
    });

    test('isEmpty/isNotEmpty', () {
      final empty = RuleGroup(rules: []);
      final nonEmpty = RuleGroup(rules: [
        SignalRule(indicator: 'rsi', condition: 'gt', value: 50),
      ]);
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
      expect(nonEmpty.isEmpty, isFalse);
      expect(nonEmpty.isNotEmpty, isTrue);
    });
  });
}
