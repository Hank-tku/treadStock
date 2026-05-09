// T-PRV-01, T-F001-3: RecommendationProvider 状态管理测试

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/recommendation/presentation/recommendation_provider.dart';

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
}
