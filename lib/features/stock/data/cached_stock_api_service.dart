import 'stock_api_service.dart';
import 'kline_cache.dart';
import '../domain/stock_models.dart';

/// Decorator that wraps [StockApiService] with a local K-line cache layer.
///
/// - [fetchStockKline] checks the cache first; on miss it calls the API,
///   stores the result in the cache, then returns it.
/// - [clearCache] removes all cached entries.
class CachedStockApiService {
  final StockApiService _api;
  final KlineCacheDatabase _cache;

  CachedStockApiService({
    required StockApiService api,
    required KlineCacheDatabase cache,
  })  : _api = api,
        _cache = cache;

  /// Fetch K-line data with caching.
  /// On cache hit (non-expired), returns cached data immediately.
  /// On cache miss, calls the API, stores the result, then returns it.
  Future<List<DailyKline>> fetchStockKline(
    String code, {
    String market = 'SH',
    int days = 120,
    Duration ttl = const Duration(minutes: 5),
  }) async {
    // Check cache first
    final cached = await _cache.getCachedKlines(code);
    if (cached != null) return cached;

    // Cache miss → call API
    final klines = await _api.fetchStockKline(code, market: market, days: days);

    // Store in cache (even if empty, to avoid repeated API calls)
    await _cache.saveKlines(code, market, klines, ttl: ttl);

    return klines;
  }

  /// Clear all cached K-line data.
  Future<void> clearCache() async {
    await _cache.clearAll();
  }
}
