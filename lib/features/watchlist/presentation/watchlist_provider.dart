import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stock/domain/stock_models.dart';
import '../../analysis/domain/analysis_engine.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../stock/data/stock_api_service.dart';
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

  const WatchlistState({
    this.items = const [],
    this.searchResults = const [],
    this.isSearching = false,
    this.isAdding = false,
    this.addingCode,
    this.hasSearchError = false,
    this.searchError,
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
  }) {
    return WatchlistState(
      items: items ?? this.items,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      isAdding: isAdding ?? this.isAdding,
      addingCode: addingCode,
      hasSearchError: hasSearchError ?? this.hasSearchError,
      searchError: searchError,
    );
  }
}

class WatchlistNotifier extends StateNotifier<WatchlistState> {
  final WatchlistService _watchlistService;
  final StockApiService _apiService;
  final AnalysisEngine _analysisEngine;

  WatchlistNotifier(
    this._watchlistService,
    this._apiService,
    this._analysisEngine,
  ) : super(WatchlistState(items: _watchlistService.getWatchlist()));

  /// Reload watchlist from service.
  void reload() {
    state = WatchlistState(items: _watchlistService.getWatchlist());
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
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
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
    await _watchlistService.removeFromWatchlist(id);
    reload();
  }

  /// Toggle pin status.
  Future<void> togglePin(String id, bool isPinned) async {
    await _watchlistService.togglePin(id, isPinned);
    reload();
  }

  /// Toggle alert status.
  Future<void> toggleAlert(String id, bool enabled) async {
    await _watchlistService.toggleAlert(id, enabled);
    reload();
  }

  /// Check if a stock is watched.
  bool isWatched(String stockCode) {
    return _watchlistService.isWatched(stockCode);
  }

  /// Fetch latest data for a watchlist stock.
  Future<void> _fetchStockData(String code, String market) async {
    try {
      final klines = await _apiService.fetchStockKline(code, market: market);
      if (klines.isNotEmpty) {
        final score = _analysisEngine.calculateScore(klines);
        final lastKline = klines.last;
        _watchlistService.updateQuote(code, lastKline.close, lastKline.changePct);
        _watchlistService.updateScore(code, score);
      }
    } catch (_) {
      // Silent fail for background data fetch
    }
  }

  /// Refresh all watchlist stock data.
  Future<void> refreshAll() async {
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
  return WatchlistNotifier(watchlistService, apiService, analysisEngine);
});
