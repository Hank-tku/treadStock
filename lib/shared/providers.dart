import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/stock/data/stock_api_service.dart';
import '../features/stock/data/kline_cache.dart';
import '../features/stock/data/cached_stock_api_service.dart';
import '../features/analysis/domain/analysis_engine.dart';
import '../features/strategy/data/database.dart';
import '../features/strategy/data/strategy_service.dart';
import '../features/strategy/domain/strategy_scoring_service.dart';
import '../features/watchlist/data/watchlist_service.dart';
import '../features/alert/data/notification_service.dart';
import '../features/alert/data/alert_scheduler.dart';
import '../features/alert/data/review_scheduler.dart';
import '../features/settings/data/theme_prefs_service.dart';

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

/// Provider for the local notifications service (singleton).
/// The service is initialized lazily; callers should `await init()` once at
/// startup (see main.dart) but it also self-initializes on first use.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Provider for the alert scheduler (singleton). Ties watchlist, market data,
/// analysis engine and notifications together. The foreground timer in
/// app.dart and the background workmanager callback both call runScan().
final alertSchedulerProvider = Provider<AlertScheduler>((ref) {
  return AlertScheduler(
    watchlistService: ref.watch(watchlistServiceProvider),
    apiService: ref.watch(stockApiServiceProvider),
    analysisEngine: ref.watch(analysisEngineProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

/// Provider for the daily review scheduler (singleton). Runs automatic
/// strategy reviews once per day per enabled strategy.
final reviewSchedulerProvider = Provider<ReviewScheduler>((ref) {
  return ReviewScheduler(
    strategyService: ref.watch(strategyServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
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

// ── Theme ──────────────────────────────────────────────────────────

/// Singleton provider for the theme-mode persistence service.
final themePrefsServiceProvider = Provider<ThemePrefsService>((ref) {
  return ThemePrefsService();
});

/// Holds the app's [ThemeMode] and persists user changes.
///
/// Initialized from [ThemePrefsService] (defaults to [ThemeMode.system]).
/// Calling [ThemeModeNotifier.set] updates both the in-memory state and the
/// persisted preference so the choice survives app restarts.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(ThemeMode.system);

  final ThemePrefsService _prefs;

  /// Load the persisted theme mode into state. Called once at startup.
  Future<void> init() async {
    state = await _prefs.getThemeMode();
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(mode);
  }
}

/// App theme mode state. Watch this in MaterialApp's `themeMode`.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(themePrefsServiceProvider));
});
