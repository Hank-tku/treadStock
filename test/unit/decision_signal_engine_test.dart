import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/strategy/domain/decision_signal_engine.dart';
import 'package:stockpilot/features/strategy/domain/signal_card.dart';
import 'package:stockpilot/features/strategy/domain/signal_rule.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';

List<DailyKline> _buildTrendingKlines({
  int count = 60,
  double start = 10,
  double step = 0.2,
}) {
  return List.generate(count, (i) {
    final close = start + i * step;
    return DailyKline(
      date: DateTime(2026, 1, 1).add(Duration(days: i)),
      open: close - 0.1,
      close: close,
      high: close + 0.2,
      low: close - 0.2,
      volume: 1000000 + i * 1000,
      amount: close * 1000000,
    );
  });
}

Strategy _entryStrategy() {
  return Strategy(
    id: 's-entry',
    name: 'Entry Strategy',
    description: 'rule-based entry',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    entryRules: const [
      SignalRule(indicator: 'rsi', condition: 'gt', value: 0),
    ],
    exitRules: const [],
  );
}

Strategy _exitStrategy() {
  return Strategy(
    id: 's-exit',
    name: 'Exit Strategy',
    description: 'rule-based exit',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    entryRules: const [],
    exitRules: const [
      SignalRule(indicator: 'rsi', condition: 'gt', value: 0),
    ],
  );
}

Strategy _nonRuleStrategy() {
  return Strategy(
    id: 's-non-rule',
    name: 'Weighted Strategy',
    description: 'non rule based',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('DecisionSignalEngine', () {
    test('returns neutral card when strategy is not rule-based', () {
      final card = DecisionSignalEngine.evaluate(
        klines: _buildTrendingKlines(),
        strategy: _nonRuleStrategy(),
        stockCode: '600000',
        stockName: '浦发银行',
      );

      expect(card.type, SignalType.neutral);
      expect(card.strength, SignalStrength.none);
      expect(card.isActionable, isFalse);
      expect(card.headline, contains('未配置信号规则'));
    });

    test('builds an actionable entry signal card', () {
      final card = DecisionSignalEngine.evaluate(
        klines: _buildTrendingKlines(),
        strategy: _entryStrategy(),
        stockCode: '600000',
        stockName: '浦发银行',
        currentPrice: 22.3,
        changePct: 1.5,
      );

      expect(card.type, SignalType.entry);
      expect(card.strength, SignalStrength.strong);
      expect(card.isActionable, isTrue);
      expect(card.ruleResults.length, 1);
      expect(card.ruleResults.values.single, isTrue);
      expect(card.highlights, isNotEmpty);
      expect(card.suggestion, isNotEmpty);
    });

    test('builds an actionable exit signal card', () {
      final card = DecisionSignalEngine.evaluate(
        klines: _buildTrendingKlines(),
        strategy: _exitStrategy(),
        stockCode: '600000',
        stockName: '浦发银行',
      );

      expect(card.type, SignalType.exit);
      expect(card.strength, SignalStrength.strong);
      expect(card.isActionable, isTrue);
      expect(card.ruleResults.values.single, isTrue);
      expect(card.headline, contains('离场'));
    });
  });
}
