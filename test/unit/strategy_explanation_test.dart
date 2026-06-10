import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/analysis_models.dart';
import 'package:stockpilot/features/strategy/domain/strategy_explanation.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';

void main() {
  group('StrategyExplanation', () {
    test('recommendationInsight explains match, risk, and next step', () {
      final strategy = _strategy(weightBoll: 0.40);
      const score = StockScore(
        score: 8,
        maScore: 7,
        bollScore: 9,
        volScore: 5,
        trendScore: 6,
        isBandLow: true,
        reason: '处于波段低位',
      );

      final insight = StrategyExplanation.recommendationInsight(
        strategy: strategy,
        score: score,
      );

      expect(insight.matchPoint, contains('低位'));
      expect(insight.riskPoint, contains('风险点'));
      expect(insight.nextStep, contains('短期均线'));
      expect(insight.compact, contains('下一步'));
    });

    test('emptyDiagnosis guides strict threshold users to adjust', () {
      final diagnosis = StrategyExplanation.emptyDiagnosis(
        _strategy(recommendThreshold: 8),
      );

      expect(diagnosis.title, contains('阈值较高'));
      expect(diagnosis.actionLabel, contains('降低阈值'));
    });

    test('reviewSummary asks for more data when sample is insufficient', () {
      final summary = StrategyExplanation.reviewSummary(
        stats: const StrategyStats(totalRecommendations: 10, evaluatedCount: 5, tradingDaysRun: 10),
        suggestions: const [],
      );

      expect(summary.title, contains('样本不足'));
      expect(summary.nextStep, contains('20 条'));
      expect(summary.needsAttention, isFalse);
    });

    test(
      'reviewSummary surfaces first suggestion when attention is needed',
      () {
        final summary = StrategyExplanation.reviewSummary(
          stats: const StrategyStats(tradingDaysRun: 30,
            hitRate: 0.35,
            avgChange: -1.2,
            totalRecommendations: 30,
            evaluatedCount: 25,
          ),
          suggestions: const [
            StrategySuggestion(
              condition: '命中率偏低',
              suggestion: '建议提高推荐阈值',
              parameterKey: 'recommendThreshold',
              suggestedValue: 8,
            ),
          ],
        );

        expect(summary.title, '需要复盘调整');
        expect(summary.conclusion, '命中率偏低');
        expect(summary.nextStep, '建议提高推荐阈值');
        expect(summary.needsAttention, isTrue);
      },
    );
  });
}

Strategy _strategy({double weightBoll = 0.30, int recommendThreshold = 7}) {
  final now = DateTime(2026, 1, 1);
  return Strategy(
    id: 's1',
    name: '测试策略',
    weightBoll: weightBoll,
    weightMA: weightBoll >= 0.35 ? 0.25 : 0.30,
    weightVol: 0.20,
    weightTrend: weightBoll >= 0.35 ? 0.15 : 0.20,
    recommendThreshold: recommendThreshold,
    createdAt: now,
    updatedAt: now,
  );
}
