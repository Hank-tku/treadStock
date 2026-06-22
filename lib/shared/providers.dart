import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/stock/data/stock_api_service.dart';
import '../features/stock/data/kline_cache.dart';
import '../features/stock/data/cached_stock_api_service.dart';
import '../features/analysis/domain/analysis_engine.dart';
import '../features/strategy/data/database.dart';
import '../features/strategy/data/strategy_service.dart';
import '../features/strategy/domain/strategy_scoring_service.dart';
import '../features/watchlist/data/watchlist_service.dart';

/// Provider for the stock API service (singleton).
final stockApiServiceProvider = Provider<StockApiService>((ref) {
  return StockApiService();
});

/// Provider for the analysis engine (singleton).
final analysisEngineProvider = Provider<AnalysisEngine>((ref) {
  return AnalysisEngine();
});

/// Provider for the local Drift database shared by app services.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider for the watchlist service (singleton).
/// The service is initialized lazily on first access.
final watchlistServiceProvider = Provider<WatchlistService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = WatchlistService(db: db);
  // Kick off async initialization; callers can also call init() explicitly.
  service.init();
  return service;
});

/// Provider for the strategy service (singleton).
final strategyServiceProvider = Provider<StrategyService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final service = StrategyService(db: db);
  service.init();
  return service;
});

/// Provider for reusable strategy scoring across recommendation/watchlist.
final strategyScoringServiceProvider = Provider<StrategyScoringService>((ref) {
  final analysisEngine = ref.watch(analysisEngineProvider);
  return StrategyScoringService(analysisEngine);
});

/// Provider for the K-line cache database (singleton).
final klineCacheProvider = Provider<KlineCacheDatabase>((ref) {
  final db = KlineCacheDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Provider for the cached stock API service (singleton).
/// Wraps StockApiService with a K-line local cache layer.
final cachedStockApiServiceProvider = Provider<CachedStockApiService>((ref) {
  final api = ref.watch(stockApiServiceProvider);
  final cache = ref.watch(klineCacheProvider);
  return CachedStockApiService(api: api, cache: cache);
});
