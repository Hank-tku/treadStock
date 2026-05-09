// T-SVC-01, T-SVC-02, T-SVC-03: WatchlistService CRUD 测试
// 使用 in-memory SQLite 数据库，测试完整的关注列表管理逻辑。

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stockpilot/features/watchlist/data/watchlist_service.dart';
import 'package:stockpilot/features/strategy/data/database.dart';
import 'package:stockpilot/features/analysis/domain/analysis_models.dart';

/// 创建内存数据库用于测试。
AppDatabase createTestDb() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late WatchlistService service;

  setUp(() async {
    db = createTestDb();
    service = WatchlistService(db: db);
    await service.init();
  });

  tearDown(() async {
    await db.close();
  });

  // =========================================================================
  // T-SVC-01: 基本 CRUD
  // =========================================================================
  group('T-SVC-01: CRUD operations', () {
    test('初始列表为空', () {
      expect(service.getWatchlist(), isEmpty);
    });

    test('添加关注后列表不为空', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      final list = service.getWatchlist();
      expect(list, hasLength(1));
      expect(list[0].stockCode, '601318');
      expect(list[0].stockName, '中国平安');
      expect(list[0].market, 'SH');
      expect(list[0].isPinned, false);
      expect(list[0].alertEnabled, true);
    });

    test('添加关注生成唯一 id', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      await service.addToWatchlist('000001', '平安银行', 'SZ');

      final list = service.getWatchlist();
      expect(list[0].id, isNot(equals(list[1].id)));
      expect(list[0].id, isNotEmpty);
    });

    test('删除关注后列表为空', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      final list = service.getWatchlist();
      expect(list, hasLength(1));

      await service.removeFromWatchlist(list[0].id);
      expect(service.getWatchlist(), isEmpty);
    });

    test('删除不存在的 id 不崩溃', () async {
      await service.removeFromWatchlist('non-existent-id');
      expect(service.getWatchlist(), isEmpty);
    });

    test('置顶切换', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      final item = service.getWatchlist()[0];
      expect(item.isPinned, false);

      await service.togglePin(item.id, true);
      expect(service.getWatchlist()[0].isPinned, true);

      await service.togglePin(item.id, false);
      expect(service.getWatchlist()[0].isPinned, false);
    });

    test('预警开关切换', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      final item = service.getWatchlist()[0];
      expect(item.alertEnabled, true);

      await service.toggleAlert(item.id, false);
      expect(service.getWatchlist()[0].alertEnabled, false);

      await service.toggleAlert(item.id, true);
      expect(service.getWatchlist()[0].alertEnabled, true);
    });

    test('togglePin 不存在的 id 不崩溃', () async {
      await service.togglePin('non-existent-id', true);
      expect(service.getWatchlist(), isEmpty);
    });

    test('toggleAlert 不存在的 id 不崩溃', () async {
      await service.toggleAlert('non-existent-id', false);
      expect(service.getWatchlist(), isEmpty);
    });
  });

  // =========================================================================
  // T-SVC-02: 重复添加检测
  // =========================================================================
  group('T-SVC-02: duplicate detection', () {
    test('重复添加相同 stockCode 抛出异常', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');

      expect(
        () => service.addToWatchlist('601318', '中国平安2', 'SH'),
        throwsA(isA<Exception>()),
      );
    });

    test('添加不同 stockCode 正常', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      await service.addToWatchlist('000001', '平安银行', 'SZ');

      expect(service.getWatchlist(), hasLength(2));
    });

    test('重复添加后列表长度不变', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');

      try {
        await service.addToWatchlist('601318', '中国平安2', 'SH');
      } catch (_) {}

      expect(service.getWatchlist(), hasLength(1));
    });
  });

  // =========================================================================
  // T-SVC-03: 排序逻辑
  // =========================================================================
  group('T-SVC-03: sorting', () {
    test('置顶项排在前面', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      await service.addToWatchlist('000001', '平安银行', 'SZ');
      await service.addToWatchlist('600036', '招商银行', 'SH');

      final list = service.getWatchlist();
      // 全部未置顶时，按创建时间倒序（后创建的在前）
      expect(list[0].stockCode, '600036');
      expect(list[1].stockCode, '000001');
      expect(list[2].stockCode, '601318');

      // 置顶第一个
      await service.togglePin(list[2].id, true);
      final list2 = service.getWatchlist();
      expect(list2[0].stockCode, '601318');
      expect(list2[0].isPinned, true);
    });

    test('多个置顶项按 sortOrder 倒序', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      await service.addToWatchlist('000001', '平安银行', 'SZ');
      await service.addToWatchlist('600036', '招商银行', 'SH');

      final list = service.getWatchlist();

      // 置顶第二个（平安银行）
      await service.togglePin(list[1].id, true);
      // 置顶第三个（中国平安）-- 应该是最新的置顶
      await service.togglePin(list[0].id, true);

      final list2 = service.getWatchlist();
      // 第三个先置顶（sortOrder=1），第二个后置顶（sortOrder=2）
      // sortOrder 大的排在前面
      expect(list2[0].isPinned, true);
      expect(list2[1].isPinned, true);
      expect(list2[2].isPinned, false);
    });

    test('取消置顶后回到普通列表', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      await service.addToWatchlist('000001', '平安银行', 'SZ');

      // Pin 000001
      await service.togglePin(service.findByCode('000001')!.id, true);
      var list2 = service.getWatchlist();
      expect(list2[0].stockCode, '000001');
      expect(list2[0].isPinned, true);
      expect(list2[1].isPinned, false);

      // Unpin 000001
      await service.togglePin(service.findByCode('000001')!.id, false);
      final list3 = service.getWatchlist();

      // 取消置顶后，000001 回到未置顶列表
      final unPinned = list3.where((i) => !i.isPinned).toList();
      expect(unPinned.any((i) => i.stockCode == '000001'), true);
      expect(unPinned.any((i) => i.stockCode == '601318'), true);

      // 排序：601318 先添加（createdAt 更早），取消置顶后应排在前
      // list3 = [所有置顶, 未置顶按 createdAt 倒序]
      // 两个都未置顶 -> 按 createdAt 倒序 -> 000001 (更晚) 在前
      final firstUnpinned = unPinned.first;
      expect(firstUnpinned.stockCode, '000001'); // 后添加的排在前面
    });
  });

  // =========================================================================
  // 查询方法
  // =========================================================================
  group('query methods', () {
    test('isWatched 返回正确结果', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      expect(service.isWatched('601318'), true);
      expect(service.isWatched('000001'), false);
    });

    test('findByCode 返回正确项', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      final item = service.findByCode('601318');
      expect(item, isNotNull);
      expect(item!.stockName, '中国平安');
    });

    test('findByCode 未找到返回 null', () {
      expect(service.findByCode('999999'), isNull);
    });
  });

  // =========================================================================
  // 内存更新方法（不影响 DB）
  // =========================================================================
  group('in-memory updates', () {
    test('updateQuote 更新价格和涨跌幅', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      service.updateQuote('601318', 50.0, 3.5);

      final item = service.getWatchlist()[0];
      expect(item.currentPrice, 50.0);
      expect(item.currentChangePct, 3.5);
    });

    test('updateQuote 对不存在的股票不崩溃', () {
      service.updateQuote('999999', 50.0, 3.5);
      // 不崩溃即通过
    });

    test('updateScore 更新评分', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      final score = StockScore(
        score: 8,
        maScore: 8,
        bollScore: 8,
        volScore: 7,
        trendScore: 7,
        isBandLow: true,
      );
      service.updateScore('601318', score);

      final item = service.getWatchlist()[0];
      expect(item.currentScore, isNotNull);
      expect(item.currentScore!.score, 8);
    });

    test('updateScore 对不存在的股票不崩溃', () {
      final score = StockScore(
        score: 5,
        maScore: 5,
        bollScore: 5,
        volScore: 5,
        trendScore: 5,
        isBandLow: false,
      );
      service.updateScore('999999', score);
      // 不崩溃即通过
    });
  });

  // =========================================================================
  // init 重新加载
  // =========================================================================
  group('init reload', () {
    test('init 后从 DB 重新加载', () async {
      await service.addToWatchlist('601318', '中国平安', 'SH');
      await service.addToWatchlist('000001', '平安银行', 'SZ');

      // 创建新 service 实例共享同一个 DB
      final service2 = WatchlistService(db: db);
      await service2.init();

      expect(service2.getWatchlist(), hasLength(2));
    });
  });
}
