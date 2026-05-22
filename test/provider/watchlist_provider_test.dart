// T-PRV-02, T-F002-2, T-F002-3, T-F002-4, T-F002-6, T-F002-7: WatchlistProvider 状态管理测试

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';
import 'package:stockpilot/features/stock/data/stock_api_service.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/strategy/data/database.dart';
import 'package:stockpilot/features/strategy/data/strategy_service.dart';
import 'package:stockpilot/features/strategy/domain/strategy_scoring_service.dart';
import 'package:stockpilot/features/watchlist/data/watchlist_service.dart';
import 'package:stockpilot/features/watchlist/presentation/watchlist_provider.dart';

class FakeKlineApiService extends StockApiService {
  @override
  Future<List<DailyKline>> fetchStockKline(
    String stockCode, {
    String market = 'SH',
    int days = 120,
  }) async {
    final klines = <DailyKline>[];
    var price = 20.0;
    for (var i = 0; i < 80; i++) {
      final open = price;
      price *= 1.002;
      klines.add(
        DailyKline(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          open: open,
          close: price,
          high: price * 1.01,
          low: open * 0.99,
          volume: 100000,
          amount: 2000000000,
          preClose: i > 0 ? klines[i - 1].close : open,
        ),
      );
    }
    return klines;
  }
}

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

  group('WatchlistNotifier initialization', () {
    test('initialize loads persisted watchlist items into state', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final service = WatchlistService(db: db, seedDefaults: false);
      await service.init();
      await service.addToWatchlist('601318', '中国平安', 'SH');

      final reloadedService = WatchlistService(db: db, seedDefaults: false);
      final notifier = WatchlistNotifier(
        reloadedService,
        StockApiService(),
        AnalysisEngine(),
        StrategyService(db: db),
        StrategyScoringService(AnalysisEngine()),
      );

      await notifier.initialize();

      expect(notifier.state.items, hasLength(1));
      expect(notifier.state.items.single.stockCode, '601318');

      notifier.dispose();
      await db.close();
    });
  });

  group('WatchlistNotifier best strategy scoring', () {
    test('refreshAll stores best strategy for each watched stock', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final watchlistService = WatchlistService(db: db, seedDefaults: false);
      await watchlistService.init();
      await watchlistService.addToWatchlist('601318', '中国平安', 'SH');
      final strategyService = StrategyService(db: db);
      final analysisEngine = AnalysisEngine();
      final notifier = WatchlistNotifier(
        watchlistService,
        FakeKlineApiService(),
        analysisEngine,
        strategyService,
        StrategyScoringService(analysisEngine),
      );

      await notifier.initialize();
      await notifier.refreshAll();

      expect(notifier.state.bestStrategies['601318'], isNotNull);
      expect(notifier.state.items.single.currentScore, isNotNull);

      notifier.dispose();
      await db.close();
    });
  });
}
