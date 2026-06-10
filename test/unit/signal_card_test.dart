import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/signal_card.dart';

void main() {
  group('SignalCard', () {
    test('calculates pass rate and tag correctly', () {
      final card = SignalCard(
        stockCode: '600000',
        stockName: '浦发银行',
        strategyId: 's1',
        strategyName: '突破策略',
        type: SignalType.entry,
        strength: SignalStrength.strong,
        headline: 'headline',
        detail: 'detail',
        highlights: const [
          IndicatorHighlight(
            name: 'RSI',
            value: '35.0',
            status: '偏低',
            isPositive: true,
          ),
        ],
        suggestion: 'suggestion',
        ruleResults: const {
          'RSI < 30': true,
          'MACD > 0': false,
        },
        indicatorValues: const {'rsi': 35.0},
        evaluatedAt: DateTime(2026, 1, 1),
        currentPrice: 12.3,
        changePct: 1.2,
      );

      expect(card.passedRuleCount, 1);
      expect(card.totalRuleCount, 2);
      expect(card.passRate, 0.5);
      expect(card.isActionable, isTrue);
      expect(card.tag, '入场信号 强');
    });

    test('neutral cards are not actionable', () {
      final card = SignalCard(
        stockCode: '600000',
        stockName: '浦发银行',
        strategyId: 's1',
        strategyName: '突破策略',
        type: SignalType.neutral,
        strength: SignalStrength.none,
        headline: '暂无信号',
        detail: 'detail',
        highlights: const [],
        suggestion: 'suggestion',
        ruleResults: const {},
        indicatorValues: const {},
        evaluatedAt: DateTime(2026, 1, 1),
      );

      expect(card.isActionable, isFalse);
      expect(card.tag, '无信号');
    });
  });
}
