import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:stockpilot/features/strategy/domain/strategy_scoring_service.dart';

List<DailyKline> _bandLowKlines() {
  final klines = <DailyKline>[];
  var price = 40.0;

  for (var i = 0; i < 40; i++) {
    final open = price;
    price *= 1.015;
    klines.add(
      DailyKline(
        date: DateTime(2026, 1, 1).add(Duration(days: i)),
        open: open,
        close: price,
        high: price * 1.01,
        low: open * 0.99,
        volume: 120000,
        amount: 5000000000,
        preClose: i > 0 ? klines[i - 1].close : open,
      ),
    );
  }

  for (var i = 0; i < 30; i++) {
    final open = price;
    price *= 0.985;
    klines.add(
      DailyKline(
        date: DateTime(2026, 2, 10).add(Duration(days: i)),
        open: open,
        close: price,
        high: open,
        low: price * 0.995,
        volume: 80000,
        amount: 4000000000,
        preClose: klines.last.close,
      ),
    );
  }

  return klines;
}

void main() {
  group('StrategyScoringService', () {
    test('scores the same stock with each strategy and selects best score', () {
      final service = StrategyScoringService(AnalysisEngine());
      final klines = _bandLowKlines();
      final quote = StockQuote(
        code: '300750',
        name: '宁德时代',
        market: 'SZ',
        price: klines.last.close,
        changePct: klines.last.changePct,
        changeAmt: klines.last.close - klines.last.preClose,
        openPrice: klines.last.open,
        highPrice: klines.last.high,
        lowPrice: klines.last.low,
        preClose: klines.last.preClose,
        volume: klines.last.volume,
        turnover: 0,
      );
      final now = DateTime(2026, 5, 1);
      final maStrategy = Strategy(
        id: 'ma',
        name: '均线优先',
        weightMA: 0.70,
        weightBoll: 0.10,
        weightVol: 0.10,
        weightTrend: 0.10,
        recommendThreshold: 6,
        createdAt: now,
        updatedAt: now,
      );
      final bollStrategy = Strategy(
        id: 'boll',
        name: '低位优先',
        weightMA: 0.10,
        weightBoll: 0.70,
        weightVol: 0.10,
        weightTrend: 0.10,
        recommendThreshold: 6,
        createdAt: now,
        updatedAt: now,
      );

      final results = service.scoreAll(
        quote: quote,
        klines: klines,
        strategies: [maStrategy, bollStrategy],
      );
      final best = service.bestScore(
        quote: quote,
        klines: klines,
        strategies: [maStrategy, bollStrategy],
      );

      expect(results, hasLength(2));
      expect(
        results.first.score.score,
        greaterThanOrEqualTo(results.last.score.score),
      );
      expect(best, isNotNull);
      expect(best!.strategyId, results.first.strategyId);
      expect(results.map((r) => r.strategyId), containsAll(['ma', 'boll']));
    });
  });
}
