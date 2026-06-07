import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/strategy_presets.dart';

void main() {
  group('StrategyPresets', () {
    final now = DateTime(2026, 6, 7);
    var idCounter = 0;
    String genId() => 'preset-${++idCounter}';

    test('rsiOversoldBounce has correct entry and exit rules', () {
      final s = StrategyPresets.rsiOversoldBounce(id: genId(), now: now);
      expect(s.isRuleBased, isTrue);
      expect(s.entryRules!.length, 1);
      expect(s.entryRules!.first.indicator, 'rsi');
      expect(s.entryRules!.first.condition, 'lt');
      expect(s.entryRules!.first.value, 30);
      expect(s.exitRules!.length, 1);
      expect(s.exitRules!.first.indicator, 'rsi');
      expect(s.exitRules!.first.condition, 'gt');
      expect(s.exitRules!.first.value, 70);
    });

    test('macdGoldenCross has MACD cross rules', () {
      final s = StrategyPresets.macdGoldenCross(id: genId(), now: now);
      expect(s.isRuleBased, isTrue);
      expect(s.entryRules!.first.indicator, 'macd');
      expect(s.entryRules!.first.condition, 'cross_up');
      expect(s.exitRules!.first.indicator, 'macd');
      expect(s.exitRules!.first.condition, 'cross_down');
    });

    test('kdjLowGoldenCross has K cross and K < 40 entry rules', () {
      final s = StrategyPresets.kdjLowGoldenCross(id: genId(), now: now);
      expect(s.isRuleBased, isTrue);
      expect(s.entryRules!.length, 2); // cross_up + lt
      expect(s.exitRules!.first.indicator, 'k');
      expect(s.exitRules!.first.condition, 'gt');
      expect(s.exitRules!.first.value, 80);
    });

    test('all() returns exactly 6 presets', () {
      var counter = 100;
      final presets = StrategyPresets.all(
        idGenerator: () => 'p-${++counter}',
        now: now,
      );
      expect(presets.length, 6);
      expect(presets.every((s) => s.isRuleBased), isTrue);
    });
  });
}
