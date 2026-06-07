// KlineCache Drift 表 + DAO 测试
// 测试 K-line 数据的缓存命中、过期返回 null、清除过期、清除全部。

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stockpilot/features/stock/data/kline_cache.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';

void main() {
  late KlineCacheDatabase db;

  setUp(() async {
    db = KlineCacheDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // 测试辅助方法
  // ---------------------------------------------------------------------------
  DailyKline makeKline({
    DateTime? date,
    double open = 10.0,
    double close = 10.5,
    double high = 11.0,
    double low = 9.5,
    double volume = 100000,
    double amount = 1000000,
    double preClose = 10.0,
  }) {
    return DailyKline(
      date: date ?? DateTime(2026, 1, 1),
      open: open,
      close: close,
      high: high,
      low: low,
      volume: volume,
      amount: amount,
      preClose: preClose,
    );
  }

  // ---------------------------------------------------------------------------
  // 缓存命中测试
  // ---------------------------------------------------------------------------
  test('save + get: 缓存命中返回正确的 K 线数据', () async {
    final klines = [
      makeKline(date: DateTime(2026, 1, 1), close: 10.5),
      makeKline(date: DateTime(2026, 1, 2), close: 11.0),
      makeKline(date: DateTime(2026, 1, 3), close: 11.5),
    ];

    await db.saveKlines('600519', 'SH', klines, ttl: const Duration(minutes: 5));
    final result = await db.getCachedKlines('600519');

    expect(result, isNotNull);
    expect(result!, hasLength(3));
    expect(result[0].close, 10.5);
    expect(result[1].close, 11.0);
    expect(result[2].close, 11.5);
    expect(result[0].date, DateTime(2026, 1, 1));
  });

  test('save + get: 缓存未命中返回 null', () async {
    final klines = [makeKline()];
    await db.saveKlines('600519', 'SH', klines);
    final result = await db.getCachedKlines('000001');
    expect(result, isNull);
  });

  // ---------------------------------------------------------------------------
  // 过期缓存测试
  // ---------------------------------------------------------------------------
  test('过期缓存返回 null', () async {
    final klines = [makeKline()];
    // TTL 为 0 毫秒，立即过期
    await db.saveKlines('600519', 'SH', klines, ttl: Duration.zero);

    // 给过期留一点时间余量
    await Future<void>.delayed(const Duration(milliseconds: 10));

    final result = await db.getCachedKlines('600519');
    expect(result, isNull);
  });

  // ---------------------------------------------------------------------------
  // 覆盖缓存测试
  // ---------------------------------------------------------------------------
  test('重复 save 覆盖旧缓存', () async {
    final klines1 = [makeKline(close: 10.0)];
    final klines2 = [makeKline(close: 20.0)];

    await db.saveKlines('600519', 'SH', klines1, ttl: const Duration(minutes: 5));
    await db.saveKlines('600519', 'SH', klines2, ttl: const Duration(minutes: 5));

    final result = await db.getCachedKlines('600519');
    expect(result, isNotNull);
    expect(result!.first.close, 20.0);
  });

  // ---------------------------------------------------------------------------
  // clearExpired 测试
  // ---------------------------------------------------------------------------
  test('clearExpired 只清除过期条目', () async {
    final klines = [makeKline()];

    // 过期条目
    await db.saveKlines('000001', 'SZ', klines, ttl: Duration.zero);
    // 有效条目
    await db.saveKlines('600519', 'SH', klines, ttl: const Duration(hours: 1));

    await Future<void>.delayed(const Duration(milliseconds: 10));
    await db.clearExpired();

    expect(await db.getCachedKlines('000001'), isNull);
    expect(await db.getCachedKlines('600519'), isNotNull);
  });

  // ---------------------------------------------------------------------------
  // clearAll 测试
  // ---------------------------------------------------------------------------
  test('clearAll 清除所有缓存', () async {
    final klines = [makeKline()];

    await db.saveKlines('600519', 'SH', klines, ttl: const Duration(hours: 1));
    await db.saveKlines('000001', 'SZ', klines, ttl: const Duration(hours: 1));

    await db.clearAll();

    expect(await db.getCachedKlines('600519'), isNull);
    expect(await db.getCachedKlines('000001'), isNull);
  });

  // ---------------------------------------------------------------------------
  // 序列化完整性测试
  // ---------------------------------------------------------------------------
  test('序列化保留所有 DailyKline 字段', () async {
    final kline = DailyKline(
      date: DateTime(2026, 6, 1),
      open: 44.80,
      close: 45.20,
      high: 45.80,
      low: 44.50,
      volume: 125400,
      amount: 5678000000,
      preClose: 44.00,
    );

    await db.saveKlines('601318', 'SH', [kline], ttl: const Duration(minutes: 5));
    final result = await db.getCachedKlines('601318');

    expect(result, isNotNull);
    final restored = result!.first;
    expect(restored.date, DateTime(2026, 6, 1));
    expect(restored.open, 44.80);
    expect(restored.close, 45.20);
    expect(restored.high, 45.80);
    expect(restored.low, 44.50);
    expect(restored.volume, 125400);
    expect(restored.amount, 5678000000);
    expect(restored.preClose, 44.00);
  });
}
