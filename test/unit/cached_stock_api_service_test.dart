// CachedStockApiService 装饰器测试
// 验证缓存命中跳过 API、缓存未命中调 API 并存储、clearCache 清除。
// 使用手动 fake 代替 mock 框架（项目不依赖 mocktail）。

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:stockpilot/features/stock/data/cached_stock_api_service.dart';
import 'package:stockpilot/features/stock/data/stock_api_service.dart';
import 'package:stockpilot/features/stock/data/kline_cache.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';

// ---------------------------------------------------------------------------
// Fake StockApiService — 记录调用次数和返回值
// ---------------------------------------------------------------------------
class FakeStockApiService implements StockApiService {
  int fetchStockKlineCallCount = 0;
  List<DailyKline>? _response;
  String? lastCode;
  String? lastMarket;
  int? lastDays;

  void setResponse(List<DailyKline> klines) {
    _response = klines;
  }

  @override
  Future<List<DailyKline>> fetchStockKline(
    String stockCode, {
    String market = 'SH',
    int days = 120,
  }) async {
    fetchStockKlineCallCount++;
    lastCode = stockCode;
    lastMarket = market;
    lastDays = days;
    return _response ?? [];
  }

  // Unused stubs — not needed for these tests.
  @override
  Future<List<StockQuote>> fetchAllMarketQuotes() async => [];
  @override
  Future<List<StockQuote>> fetchRecommendationCandidates({
    int limit = 50,
  }) async => [];
  @override
  Future<StockQuote?> fetchStockQuote(
    String stockCode, {
    String market = 'SH',
  }) async => null;
  @override
  Future<List<StockSearchResult>> searchStock(String keyword) async => [];
  @override
  Future<List<StockNews>> fetchStockNews(
    String stockCode, {
    int page = 1,
    int pageSize = 10,
  }) async => [];
  @override
  String getSecid(String code, String market) =>
      '${market == "SH" ? 1 : 0}.$code';
}

void main() {
  late FakeStockApiService fakeApi;
  late KlineCacheDatabase cacheDb;
  late CachedStockApiService service;

  setUp(() async {
    fakeApi = FakeStockApiService();
    cacheDb = KlineCacheDatabase.forTesting(NativeDatabase.memory());
    service = CachedStockApiService(api: fakeApi, cache: cacheDb);
  });

  tearDown(() async {
    await cacheDb.close();
  });

  // ---------------------------------------------------------------------------
  // 测试辅助方法
  // ---------------------------------------------------------------------------
  final testKlines = [
    DailyKline(
      date: DateTime(2026, 1, 1),
      open: 10.0,
      close: 10.5,
      high: 11.0,
      low: 9.5,
      volume: 100000,
      amount: 1000000,
      preClose: 10.0,
    ),
    DailyKline(
      date: DateTime(2026, 1, 2),
      open: 10.5,
      close: 11.0,
      high: 11.5,
      low: 10.0,
      volume: 200000,
      amount: 2000000,
      preClose: 10.5,
    ),
  ];

  // ---------------------------------------------------------------------------
  // 缓存命中：不调用 API
  // ---------------------------------------------------------------------------
  test('缓存命中时直接返回缓存数据，不调 API', () async {
    fakeApi.setResponse(testKlines);

    // 第一次调用：缓存未命中，调 API
    final result1 = await service.fetchStockKline(
      '600519',
      market: 'SH',
      days: 120,
    );
    _expectKlinesEqual(result1, testKlines);
    expect(fakeApi.fetchStockKlineCallCount, 1);

    // 第二次调用：缓存命中，不调 API
    final result2 = await service.fetchStockKline(
      '600519',
      market: 'SH',
      days: 120,
    );
    _expectKlinesEqual(result2, testKlines);
    expect(fakeApi.fetchStockKlineCallCount, 1); // 仍然为 1
  });

  // ---------------------------------------------------------------------------
  // 缓存未命中：调用 API 并存储
  // ---------------------------------------------------------------------------
  test('缓存未命中时调 API 并返回结果', () async {
    fakeApi.setResponse(testKlines);

    final result = await service.fetchStockKline(
      '600519',
      market: 'SH',
      days: 120,
    );

    _expectKlinesEqual(result, testKlines);
    expect(fakeApi.fetchStockKlineCallCount, 1);
    expect(fakeApi.lastCode, '600519');
    expect(fakeApi.lastMarket, 'SH');
    expect(fakeApi.lastDays, 120);
  });

  // ---------------------------------------------------------------------------
  // 缓存未命中：API 返回空列表也存储
  // ---------------------------------------------------------------------------
  test('缓存未命中且 API 返回空列表时也缓存', () async {
    fakeApi.setResponse([]);

    final result = await service.fetchStockKline(
      '000001',
      market: 'SZ',
      days: 60,
    );

    expect(result, isEmpty);
    expect(fakeApi.fetchStockKlineCallCount, 1);

    // 第二次调用不应调 API
    final result2 = await service.fetchStockKline(
      '000001',
      market: 'SZ',
      days: 60,
    );
    expect(result2, isEmpty);
    expect(fakeApi.fetchStockKlineCallCount, 1);
  });

  // ---------------------------------------------------------------------------
  // clearCache
  // ---------------------------------------------------------------------------
  test('clearCache 后重新调 API', () async {
    fakeApi.setResponse(testKlines);

    // 首次调 API
    await service.fetchStockKline('600519');
    expect(fakeApi.fetchStockKlineCallCount, 1);

    // 清除缓存
    await service.clearCache();

    // 应再次调 API
    await service.fetchStockKline('600519');
    expect(fakeApi.fetchStockKlineCallCount, 2);
  });

  // ---------------------------------------------------------------------------
  // 不同 stockCode 独立缓存
  // ---------------------------------------------------------------------------
  test('不同股票代码独立缓存', () async {
    fakeApi.setResponse(testKlines);

    await service.fetchStockKline('600519', market: 'SH');
    expect(fakeApi.fetchStockKlineCallCount, 1);

    await service.fetchStockKline('000001', market: 'SZ');
    expect(fakeApi.fetchStockKlineCallCount, 2);

    // 两个都应该有缓存了
    await service.fetchStockKline('600519', market: 'SH');
    await service.fetchStockKline('000001', market: 'SZ');
    expect(fakeApi.fetchStockKlineCallCount, 2); // 不增加
  });

  test('同一股票不同周期独立缓存', () async {
    fakeApi.setResponse(testKlines);

    await service.fetchStockKline('600519', market: 'SH', days: 60);
    expect(fakeApi.fetchStockKlineCallCount, 1);

    await service.fetchStockKline('600519', market: 'SH', days: 120);
    expect(fakeApi.fetchStockKlineCallCount, 2);

    await service.fetchStockKline('600519', market: 'SH', days: 60);
    await service.fetchStockKline('600519', market: 'SH', days: 120);
    expect(fakeApi.fetchStockKlineCallCount, 2);
  });

  // ---------------------------------------------------------------------------
  // 自定义 TTL 传递
  // ---------------------------------------------------------------------------
  test('自定义 TTL 过期后重新调 API', () async {
    fakeApi.setResponse(testKlines);

    // 使用极短 TTL
    await service.fetchStockKline('600519', ttl: Duration.zero);

    // 等待过期
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // 应再次调 API
    await service.fetchStockKline('600519');
    expect(fakeApi.fetchStockKlineCallCount, 2);
  });
}

/// Helper to compare two DailyKline lists field-by-field.
void _expectKlinesEqual(List<DailyKline> actual, List<DailyKline> expected) {
  expect(actual.length, expected.length, reason: 'kline list length mismatch');
  for (var i = 0; i < actual.length; i++) {
    final a = actual[i];
    final e = expected[i];
    expect(a.date, e.date, reason: 'kline[$i].date mismatch');
    expect(a.open, e.open, reason: 'kline[$i].open mismatch');
    expect(a.close, e.close, reason: 'kline[$i].close mismatch');
    expect(a.high, e.high, reason: 'kline[$i].high mismatch');
    expect(a.low, e.low, reason: 'kline[$i].low mismatch');
    expect(a.volume, e.volume, reason: 'kline[$i].volume mismatch');
    expect(a.amount, e.amount, reason: 'kline[$i].amount mismatch');
    expect(a.preClose, e.preClose, reason: 'kline[$i].preClose mismatch');
  }
}
