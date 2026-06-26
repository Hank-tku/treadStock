// T-PRV-02: StrategyRecommendationState error vs empty-data distinction.

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';
import 'package:stockpilot/features/stock/data/stock_api_service.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/strategy/data/database.dart';
import 'package:stockpilot/features/strategy/data/strategy_service.dart';
import 'package:stockpilot/features/strategy/domain/strategy_scoring_service.dart';
import 'package:stockpilot/features/strategy/presentation/strategy_recommendation_provider.dart';

class CountingStockApiService extends StockApiService {
  int klineCalls = 0;

  @override
  Future<List<StockQuote>> fetchRecommendationCandidates({
    int limit = 50,
  }) async {
    return List.generate(30, (i) {
      final code = (600000 + i).toString();
      return StockQuote(
        code: code,
        name: '测试$code',
        market: 'SH',
        price: 10 + i.toDouble(),
        changePct: 1,
        changeAmt: 0.1,
        openPrice: 10,
        highPrice: 11,
        lowPrice: 9,
        preClose: 9.9,
        volume: 100000,
        turnover: 1,
      );
    });
  }

  @override
  Future<List<DailyKline>> fetchStockKline(
    String stockCode, {
    String market = 'SH',
    int days = 120,
  }) async {
    klineCalls++;
    return List.generate(80, (i) {
      final close = 10 + i * 0.1;
      return DailyKline(
        date: DateTime(2026, 1, 1).add(Duration(days: i)),
        open: close - 0.1,
        close: close,
        high: close + 0.2,
        low: close - 0.2,
        volume: 100000 + i.toDouble(),
        amount: 1000000,
        preClose: i == 0 ? close - 0.1 : 10 + (i - 1) * 0.1,
      );
    });
  }
}

void main() {
  // T-PRV-02 (A3): StrategyRecommendationState must distinguish a hard load
  // error from a quote-source-empty condition so the UI can show the right
  // message instead of always blaming the network.
  group('T-PRV-02: StrategyRecommendationState error vs empty-data', () {
    test('初始状态不显示错误态', () {
      const state = StrategyRecommendationState();
      expect(state.hasError, false);
      expect(state.isEmptyData, false);
      expect(state.showErrorState, false);
    });

    test('行情源返回空 (isEmptyData) 不等于加载错误 (hasError)', () {
      final emptyData = const StrategyRecommendationState().copyWith(
        isEmptyData: true,
        errorMessage: '暂无行情数据',
      );
      expect(emptyData.isEmptyData, true);
      expect(emptyData.hasError, false);
      expect(emptyData.showErrorState, true);

      final hardError = const StrategyRecommendationState().copyWith(
        hasError: true,
        errorMessage: '数据更新失败',
      );
      expect(hardError.hasError, true);
      expect(hardError.isEmptyData, false);
      expect(hardError.showErrorState, true);

      // The two states are distinct even though both surface an error UI.
      expect(emptyData.hasError, isNot(hardError.hasError));
      expect(hardError.isEmptyData, isNot(emptyData.isEmptyData));
    });
  });

  group('recommendation loading priority', () {
    test('首屏只拉取有限数量的候选 K 线，避免 loading 等完整候选池', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final strategyService = StrategyService(db: db);
      final api = CountingStockApiService();
      final notifier = StrategyRecommendationNotifier(
        strategyService,
        api,
        StrategyScoringService(AnalysisEngine()),
      );

      await notifier.loadRecommendations();

      expect(notifier.state.isLoading, false);
      expect(
        api.klineCalls,
        lessThanOrEqualTo(initialRecommendationCandidateLimit + 1),
      );

      notifier.dispose();
      await db.close();
    });
  });
}
