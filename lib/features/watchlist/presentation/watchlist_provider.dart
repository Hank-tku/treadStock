import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analysis/domain/analysis_engine.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../stock/data/stock_api_service.dart';
import '../../stock/domain/stock_models.dart';
import '../../strategy/data/strategy_service.dart';
import '../../strategy/domain/strategy_scoring_service.dart';
import '../../watchlist/data/watchlist_service.dart';
import '../../../shared/providers.dart';

/// State for watchlist.
class WatchlistState {
  final List<WatchlistItem> items;
  final List<StockSearchResult> searchResults;
  final bool isSearching;
  final bool isAdding;
  final String? addingCode;
  final bool hasSearchError;
  final String? searchError;
  final Map<String, StrategyScoreResult> bestStrategies;

  const WatchlistState({
    this.items = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.isAdding = false,
    this.addingCode,
    this.hasSearchError = false,
    this.searchError,
    this.bestStrategies = const {},
  });

  bool get isEmpty => items.isEmpty;

  WatchlistState copyWith({
    List<WatchlistItem>? items,
    List<StockSearchResult>? searchResults,
    bool? isSearching,
    bool? isAdding,
    String? addingCode,
    bool? hasSearchError,
    String? searchError,
    Map<String, StrategyScoreResult>? bestStrategies,
  }) {
    return WatchlistState(
      items: items ?? this.items,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      isAdding: isAdding ?? this.isAdding,
      addingCode: addingCode,
      hasSearchError: hasSearchError ?? this.hasSearchError,
      searchError: searchError,
      bestStrategies: bestStrategies ?? this.bestStrategies,
    );
  }
}

class WatchlistNotifier extends StateNotifier<WatchlistState> {
  final WatchlistService _watchlistService;
  final StockApiService _apiService;
  final AnalysisEngine _analysisEngine;
  final StrategyService _strategyService;
  final StrategyScoringService _scoringService;
  Future<void>? _initializeFuture;

  WatchlistNotifier(
    this._watchlistService,
    this._apiService,
    this._analysisEngine,
    this._strategyService,
    this._scoringService,
  ) : super(const WatchlistState()) {
    Future.microtask(initialize);
  }

  /// Load persisted watchlist items into state.
  Future<void> initialize() async {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    await _watchlistService.init();
    if (!mounted) return;
    reload();
    await refreshAll();
  }

  /// Reload watchlist from service.
  void reload() {
    if (!mounted) return;
    state = state.copyWith(items: _watchlistService.getWatchlist());
  }

  void _syncWatchlistState({Map<String, StrategyScoreResult>? bestStrategies}) {
    if (!mounted) return;
    state = state.copyWith(
      items: _watchlistService.getWatchlist(),
      bestStrategies: bestStrategies ?? state.bestStrategies,
    );
  }

  /// Search stocks by keyword.
  Future<void> searchStock(String keyword) async {
    if (keyword.trim().isEmpty) {
      state = state.copyWith(
        searchResults: [],
        isSearching: false,
        hasSearchError: false,
      );
      return;
    }

    state = state.copyWith(isSearching: true, hasSearchError: false);
    try {
      final results = await _apiService.searchStock(keyword);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (_) {
      state = state.copyWith(
        isSearching: false,
        hasSearchError: true,
        searchError: '搜索服务暂不可用',
      );
    }
  }

  /// Add stock to watchlist.
  Future<bool> addToWatchlist(
    String stockCode,
    String stockName,
    String market,
  ) async {
    state = state.copyWith(isAdding: true, addingCode: stockCode);
    try {
      await _watchlistService.init();
      await _watchlistService.addToWatchlist(stockCode, stockName, market);
      reload();
      // Fetch initial data for the new stock
      _fetchStockData(stockCode, market);
      state = state.copyWith(isAdding: false, addingCode: null);
      return true;
    } catch (e) {
      state = state.copyWith(isAdding: false, addingCode: null);
      return false;
    }
  }

  /// Remove stock from watchlist.
  Future<void> removeFromWatchlist(String id) async {
    await _watchlistService.init();
    await _watchlistService.removeFromWatchlist(id);
    reload();
  }

  /// Toggle pin status.
  Future<void> togglePin(String id, bool isPinned) async {
    await _watchlistService.init();
    await _watchlistService.togglePin(id, isPinned);
    reload();
  }

  /// Toggle alert status.
  Future<void> toggleAlert(String id, bool enabled) async {
    await _watchlistService.init();
    await _watchlistService.toggleAlert(id, enabled);
    reload();
  }

  /// Check if a stock is watched.
  bool isWatched(String stockCode) {
    return _watchlistService.isWatched(stockCode);
  }

  /// Fetch latest data for a watchlist stock.
  Future<void> _fetchStockData(String code, String market) async {
    StockQuote? latestQuote;
    try {
      latestQuote = await _apiService.fetchStockQuote(code, market: market);
      if (latestQuote != null) {
        _watchlistService.updateQuote(
          code,
          latestQuote.price,
          latestQuote.changePct,
        );
        _syncWatchlistState();
      }
    } catch (_) {
      // Keep K-line scoring attempt below even if real-time quote fails.
    }

    try {
      final klines = await _apiService.fetchStockKline(code, market: market);
      if (klines.isNotEmpty) {
        final lastKline = klines.last;
        await _strategyService.init();
        final strategies = _strategyService.getEnabledStrategies();
        final quote =
            latestQuote ??
            StockQuote(
              code: code,
              name: _watchlistService.findByCode(code)?.stockName ?? code,
              market: market,
              price: lastKline.close,
              changePct: lastKline.changePct,
              changeAmt: lastKline.close - lastKline.preClose,
              openPrice: lastKline.open,
              highPrice: lastKline.high,
              lowPrice: lastKline.low,
              preClose: lastKline.preClose,
              volume: lastKline.volume,
              turnover: 0,
            );
        final bestStrategy = _scoringService.bestScore(
          quote: quote,
          klines: klines,
          strategies: strategies,
        );
        final score =
            bestStrategy?.score ?? _analysisEngine.calculateScore(klines);
        _watchlistService.updateQuote(code, quote.price, quote.changePct);
        _watchlistService.updateScore(code, score);
        final updated = Map<String, StrategyScoreResult>.from(
          state.bestStrategies,
        );
        if (bestStrategy != null) {
          updated[code] = bestStrategy;
        } else {
          updated.remove(code);
        }
        _syncWatchlistState(bestStrategies: updated);
      }
    } catch (_) {
      // Silent fail for background data fetch
    }
  }

  /// Refresh all watchlist stock data.
  Future<void> refreshAll() async {
    await _watchlistService.init();
    for (final item in _watchlistService.getWatchlist()) {
      await _fetchStockData(item.stockCode, item.market);
    }
    reload();
  }
}

/// Provider for watchlist state.
final watchlistProvider =
    StateNotifierProvider<WatchlistNotifier, WatchlistState>((ref) {
      final watchlistService = ref.read(watchlistServiceProvider);
      final apiService = ref.read(stockApiServiceProvider);
      final analysisEngine = ref.read(analysisEngineProvider);
      final strategyService = ref.read(strategyServiceProvider);
      final scoringService = ref.read(strategyScoringServiceProvider);
      return WatchlistNotifier(
        watchlistService,
        apiService,
        analysisEngine,
        strategyService,
        scoringService,
      );
    });
