import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/analysis_models.dart';
import 'package:stockpilot/shared/widgets/decision_labels/decision_labels.dart';

StockScore _score({
  required int score,
  required double maScore,
  required double bollScore,
  required double volScore,
  required double trendScore,
  required bool isBandLow,
  String? reason,
}) {
  return StockScore(
    score: score,
    maScore: maScore,
    bollScore: bollScore,
    volScore: volScore,
    trendScore: trendScore,
    isBandLow: isBandLow,
    reason: reason,
  );
}

void main() {
  group('DecisionLabelEngine', () {
    test('returns data insufficient label when score is zero', () {
      final labels = DecisionLabelEngine.generate(
        _score(
          score: 0,
          maScore: 0,
          bollScore: 0,
          volScore: 0,
          trendScore: 0,
          isBandLow: false,
        ),
      );

      expect(labels, hasLength(1));
      expect(labels.first.displayName, '数据不足');
      expect(labels.first.sentiment, DecisionSentiment.unknown);
      expect(labels.first.detail, contains('K线数据不足'));
    });

    test('generates bullish labels for strong MA and band-low scores', () {
      final labels = DecisionLabelEngine.generate(
        _score(
          score: 9,
          maScore: 8.6,
          bollScore: 8.2,
          volScore: 7.4,
          trendScore: 6.1,
          isBandLow: true,
          reason: '技术面强势',
        ),
      );

      expect(labels.map((e) => e.displayName), contains('多头排列'));
      expect(labels.map((e) => e.displayName), contains('波段低位'));
      expect(labels.map((e) => e.displayName), contains('放量突破'));
      expect(labels.length, lessThanOrEqualTo(4));
      expect(labels.first.sentiment, DecisionSentiment.bullish);
    });

    test('generates bearish labels for weak trend and low scores', () {
      final labels = DecisionLabelEngine.generate(
        _score(
          score: 3,
          maScore: 2.8,
          bollScore: 2.5,
          volScore: 2.2,
          trendScore: 2.6,
          isBandLow: false,
          reason: '趋势走弱',
        ),
      );

      expect(labels.map((e) => e.displayName), contains('空头排列'));
      expect(labels.map((e) => e.displayName), contains('波段高位'));
      expect(labels.map((e) => e.displayName), contains('放量下跌'));
      expect(labels.map((e) => e.displayName), contains('回调风险'));
      expect(labels.first.sentiment, DecisionSentiment.bearish);
      expect(labels.any((e) => e.sentiment == DecisionSentiment.bearish), isTrue);
    });

    test('keeps output capped at four labels and ordered by sentiment', () {
      final labels = DecisionLabelEngine.generate(
        _score(
          score: 8,
          maScore: 8.5,
          bollScore: 8.1,
          volScore: 7.8,
          trendScore: 7.2,
          isBandLow: true,
        ),
      );

      expect(labels, hasLength(4));
      final sentiments = labels.map((e) => e.sentiment).toList();
      expect(sentiments.first, DecisionSentiment.bullish);
      expect(sentiments.where((s) => s == DecisionSentiment.bearish), isEmpty);
    });
  });
}
