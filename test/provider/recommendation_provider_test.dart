// T-PRV-02: StrategyRecommendationState error vs empty-data distinction.

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/presentation/strategy_recommendation_provider.dart';

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
}
