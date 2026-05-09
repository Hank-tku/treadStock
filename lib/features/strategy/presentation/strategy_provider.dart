import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stock/data/stock_api_service.dart';
import '../../analysis/domain/analysis_engine.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../stock/domain/stock_models.dart';
import '../data/strategy_service.dart';
import '../domain/strategy_models.dart';
import '../../../shared/providers.dart';

/// State for strategy list tab.
class StrategyListState {
  final List<Strategy> strategies;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const StrategyListState({
    this.strategies = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  StrategyListState copyWith({
    List<Strategy>? strategies,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return StrategyListState(
      strategies: strategies ?? this.strategies,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class StrategyListNotifier extends StateNotifier<StrategyListState> {
  final StrategyService _strategyService;

  StrategyListNotifier(this._strategyService)
    : super(const StrategyListState(isLoading: true));

  Future<void> loadStrategies() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      await _strategyService.init();
      final strategies = _strategyService.getStrategies();
      state = state.copyWith(strategies: strategies, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: '策略数据加载失败',
      );
    }
  }

  Future<void> toggleEnabled(String id, bool isEnabled) async {
    await _strategyService.toggleEnabled(id, isEnabled);
    await loadStrategies();
  }

  Future<bool> deleteStrategy(String id) async {
    try {
      await _strategyService.deleteStrategy(id);
      await loadStrategies();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createStrategy(StrategyFormData form) async {
    try {
      await _strategyService.createStrategy(form);
      await loadStrategies();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStrategy(String id, StrategyFormData form) async {
    try {
      await _strategyService.updateStrategy(id, form);
      await loadStrategies();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Provider for strategy list state.
final strategyListProvider =
    StateNotifierProvider<StrategyListNotifier, StrategyListState>((ref) {
      final strategyService = ref.read(strategyServiceProvider);
      return StrategyListNotifier(strategyService);
    });

// ── Strategy Detail State ──────────────────────────────────────

class StrategyDetailState {
  final Strategy? strategy;
  final List<StrategyHitRecord> hitRecords;
  final List<StrategyReview> reviewHistory;
  final StrategyStats stats;
  final List<ChecklistItem> checklist;
  final List<StrategySuggestion> suggestions;
  final bool isLoading;
  final bool hasError;

  const StrategyDetailState({
    this.strategy,
    this.hitRecords = const [],
    this.reviewHistory = const [],
    this.stats = const StrategyStats(),
    this.checklist = const [],
    this.suggestions = const [],
    this.isLoading = true,
    this.hasError = false,
  });

  StrategyDetailState copyWith({
    Strategy? strategy,
    List<StrategyHitRecord>? hitRecords,
    List<StrategyReview>? reviewHistory,
    StrategyStats? stats,
    List<ChecklistItem>? checklist,
    List<StrategySuggestion>? suggestions,
    bool? isLoading,
    bool? hasError,
  }) {
    return StrategyDetailState(
      strategy: strategy ?? this.strategy,
      hitRecords: hitRecords ?? this.hitRecords,
      reviewHistory: reviewHistory ?? this.reviewHistory,
      stats: stats ?? this.stats,
      checklist: checklist ?? this.checklist,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

class StrategyDetailNotifier extends StateNotifier<StrategyDetailState> {
  final StrategyService _strategyService;

  StrategyDetailNotifier(this._strategyService)
    : super(const StrategyDetailState());

  Future<void> loadDetail(String strategyId) async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final strategy = _strategyService.getStrategy(strategyId);
      if (strategy == null) {
        state = state.copyWith(isLoading: false, hasError: true);
        return;
      }

      final stats = await _strategyService.computeStats(strategyId);
      final hitRecords = await _strategyService.getHitRecords(strategyId);
      final reviewHistory = await _strategyService.getReviewHistory(strategyId);
      final suggestions = _strategyService.generateSuggestions(strategy, stats);

      state = state.copyWith(
        strategy: strategy,
        stats: stats,
        hitRecords: hitRecords,
        reviewHistory: reviewHistory,
        suggestions: suggestions,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }

  Future<void> generateChecklist(String strategyId) async {
    final items = await _strategyService.generateChecklist(strategyId);
    state = state.copyWith(checklist: items);
  }

  Future<bool> submitReview(
    String strategyId,
    List<ChecklistItem> items, {
    String? note,
  }) async {
    try {
      await _strategyService.createReview(strategyId, items, note: note);
      await loadDetail(strategyId);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Provider for strategy detail state.
final strategyDetailProvider =
    StateNotifierProvider<StrategyDetailNotifier, StrategyDetailState>((ref) {
      final strategyService = ref.read(strategyServiceProvider);
      return StrategyDetailNotifier(strategyService);
    });

// ── Recommendation by Strategy ─────────────────────────────────

/// A recommendation result grouped by strategy.
class StrategyRecommendation {
  final Strategy strategy;
  final List<DailyRecommendation> recommendations;

  const StrategyRecommendation({
    required this.strategy,
    required this.recommendations,
  });
}

/// State for strategy-grouped recommendations.
class StrategyRecommendationState {
  final List<StrategyRecommendation> groups;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const StrategyRecommendationState({
    this.groups = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.lastUpdated,
  });

  StrategyRecommendationState copyWith({
    List<StrategyRecommendation>? groups,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return StrategyRecommendationState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class StrategyRecommendationNotifier
    extends StateNotifier<StrategyRecommendationState> {
  final StrategyService _strategyService;
  final StockApiService _apiService;
  final AnalysisEngine _analysisEngine;

  StrategyRecommendationNotifier(
    this._strategyService,
    this._apiService,
    this._analysisEngine,
  ) : super(const StrategyRecommendationState());

  Future<void> loadRecommendations() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      await _strategyService.init();
      final enabledStrategies = _strategyService.getEnabledStrategies();
      if (enabledStrategies.isEmpty) {
        state = state.copyWith(groups: [], isLoading: false);
        return;
      }

      final quotes = await _apiService.fetchAllMarketQuotes();
      if (quotes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: '暂无行情数据',
        );
        return;
      }

      final topStocks = quotes.take(50).toList();
      final groups = <StrategyRecommendation>[];

      for (final strategy in enabledStrategies) {
        final scored = await _fetchAndScoreForStrategy(topStocks, strategy);
        final recs =
            scored
                .where(
                  (item) =>
                      item.score != null &&
                      item.score!.score >= strategy.recommendThreshold,
                )
                .toList()
              ..sort(
                (a, b) => (b.score?.score ?? 0).compareTo(a.score?.score ?? 0),
              );

        groups.add(
          StrategyRecommendation(strategy: strategy, recommendations: recs),
        );

        // Record recommendations for hit tracking
        await _strategyService.recordRecommendations(
          strategy.id,
          recs
              .map(
                (r) => (
                  code: r.code,
                  name: r.name,
                  score: r.score?.score ?? 0,
                  price: r.closePrice,
                ),
              )
              .toList(),
        );
      }

      // Sort groups by strategy hit rate descending
      groups.sort((a, b) {
        final rateA = a.strategy.stats?.hitRate ?? 0;
        final rateB = b.strategy.stats?.hitRate ?? 0;
        return rateB.compareTo(rateA);
      });

      state = state.copyWith(
        groups: groups,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: '数据更新失败',
      );
    }
  }

  Future<List<DailyRecommendation>> _fetchAndScoreForStrategy(
    List<StockQuote> stocks,
    Strategy strategy,
  ) async {
    final results = <DailyRecommendation>[];
    const concurrency = 8;

    for (var i = 0; i < stocks.length; i += concurrency) {
      final batch = stocks.sublist(
        i,
        (i + concurrency).clamp(0, stocks.length),
      );
      final batchResults = await Future.wait(
        batch.map((q) => _scoreOne(q, strategy)),
      );
      for (final r in batchResults) {
        if (r != null) results.add(r);
      }
    }

    return results;
  }

  Future<DailyRecommendation?> _scoreOne(
    StockQuote quote,
    Strategy strategy,
  ) async {
    try {
      final klines = await _apiService.fetchStockKline(
        quote.code,
        market: quote.market,
      );
      if (klines.length < strategy.maLongPeriod) return null;

      final score = _analysisEngine.calculateScoreForStrategy(klines, strategy);
      if (score.score > 0) {
        return DailyRecommendation(
          code: quote.code,
          name: quote.name,
          market: quote.market,
          category: score.isBandLow && score.score >= 7
              ? 'short_term'
              : 'mid_term',
          closePrice: quote.price,
          changePct: quote.changePct,
          score: score,
          isBandLow: score.isBandLow,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    await loadRecommendations();
  }
}

/// Provider for strategy-grouped recommendations.
final strategyRecommendationProvider =
    StateNotifierProvider<
      StrategyRecommendationNotifier,
      StrategyRecommendationState
    >((ref) {
      final strategyService = ref.read(strategyServiceProvider);
      final apiService = ref.read(stockApiServiceProvider);
      final analysisEngine = ref.read(analysisEngineProvider);
      return StrategyRecommendationNotifier(
        strategyService,
        apiService,
        analysisEngine,
      );
    });
