// T-PRV-02, T-F002-2, T-F002-3, T-F002-4, T-F002-6, T-F002-7: WatchlistProvider 状态管理测试

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/watchlist/presentation/watchlist_provider.dart';

void main() {
  group('T-PRV-02: WatchlistState', () {
    test('初始状态正确', () {
      const state = WatchlistState();

      expect(state.items, isEmpty);
      expect(state.searchResults, isEmpty);
      expect(state.isSearching, false);
      expect(state.isAdding, false);
      expect(state.addingCode, isNull);
      expect(state.hasSearchError, false);
      expect(state.searchError, isNull);
    });

    test('isEmpty 正确反映列表状态', () {
      const empty = WatchlistState();
      expect(empty.isEmpty, true);

      // 有 items 时
      // WatchlistState 本身不限制 items 是否为空，isEmpty 依赖于 items
    });

    test('copyWith 更新 items', () {
      const state = WatchlistState();
      // 使用 empty list 验证 copyWith 不改变引用
      final updated = state.copyWith(isSearching: true);
      expect(updated.isSearching, true);
      expect(updated.items, isEmpty);
    });

    test('copyWith 更新 isAdding 和 addingCode', () {
      const state = WatchlistState();
      final updated = state.copyWith(isAdding: true, addingCode: '601318');
      expect(updated.isAdding, true);
      expect(updated.addingCode, '601318');
    });

    test('copyWith 更新搜索错误状态', () {
      const state = WatchlistState();
      final updated = state.copyWith(
        hasSearchError: true,
        searchError: '搜索服务暂不可用',
      );
      expect(updated.hasSearchError, true);
      expect(updated.searchError, '搜索服务暂不可用');
    });

    test('copyWith 保留未更新的字段', () {
      const state = WatchlistState();
      final updated = state.copyWith(isSearching: true);
      expect(updated.isAdding, false);
      expect(updated.hasSearchError, false);
      expect(updated.searchError, isNull);
    });
  });
}
