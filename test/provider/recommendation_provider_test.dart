// T-PRV-01, T-F001-3: RecommendationProvider 状态管理测试

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/recommendation/presentation/recommendation_provider.dart';
import 'package:stockpilot/features/strategy/presentation/strategy_recommendation_provider.dart';

void main() {
  group('T-PRV-01: RecommendationState', () {
    test('初始状态正确', () {
      const state = RecommendationState();

      expect(state.shortTerm, isEmpty);
      expect(state.midTerm, isEmpty);
      expect(state.isLoading, false);
      expect(state.hasError, false);
      expect(state.errorMessage, isNull);
      expect(state.isOffline, false);
      expect(state.lastUpdated, isNull);
    });

    test('copyWith 正确更新各字段', () {
      const state = RecommendationState();
      final updated = state.copyWith(isLoading: true, hasError: false);
      expect(updated.isLoading, true);
      expect(updated.hasError, false);

      // shortTerm 和 midTerm 不变
      expect(updated.shortTerm, isEmpty);
      expect(updated.midTerm, isEmpty);
    });

    test('多次 copyWith 链式更新', () {
      const state = RecommendationState();
      final updated = state
          .copyWith(isLoading: true)
          .copyWith(hasError: true, errorMessage: 'test error')
          .copyWith(isLoading: false);

      expect(updated.isLoading, false);
      expect(updated.hasError, true);
      expect(updated.errorMessage, 'test error');
    });
  });

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
}
