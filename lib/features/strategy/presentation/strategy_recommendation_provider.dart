import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stock/data/stock_api_service.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../stock/domain/stock_models.dart';
import '../data/strategy_service.dart';
import '../domain/strategy_models.dart';
import '../domain/strategy_scoring_service.dart';
import '../../../shared/providers.dart';

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
  final bool hasEnabledStrategies;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const StrategyRecommendationState({
    this.groups = const [],
    this.isLoading = false,
    this.hasError = false,
    this.hasEnabledStrategies = true,
    this.errorMessage,
    this.lastUpdated,
  });

  StrategyRecommendationState copyWith({
    List<StrategyRecommendation>? groups,
    bool? isLoading,
    bool? hasError,
    bool? hasEnabledStrategies,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return StrategyRecommendationState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      hasEnabledStrategies: hasEnabledStrategies ?? this.hasEnabledStrategies,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class StrategyRecommendationNotifier
    extends StateNotifier<StrategyRecommendationState> {
  final StrategyService _strategyService;
  final StockApiService _apiService;
  final StrategyScoringService _scoringService;

  StrategyRecommendationNotifier(
    this._strategyService,
    this._apiService,
    this._scoringService,
  ) : super(const StrategyRecommendationState());

  Future<void> loadRecommendations() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      await _strategyService.init();
      final enabledStrategies = _strategyService.getEnabledStrategies();
      if (enabledStrategies.isEmpty) {
        state = state.copyWith(
          groups: [],
          isLoading: false,
          hasEnabledStrategies: false,
        );
        return;
      }

      final quotes = await _apiService.fetchRecommendationCandidates();
      if (quotes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          hasEnabledStrategies: true,
          errorMessage: '暂无行情数据',
        );
        return;
      }

      await _strategyService.backfillActualChanges({
        for (final quote in quotes) quote.code: quote.price,
      });

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
        hasEnabledStrategies: true,
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

      final scoreResult = _scoringService.scoreStock(
        quote: quote,
        klines: klines,
        strategy: strategy,
      );
      final score = scoreResult.score;
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
      final scoringService = ref.read(strategyScoringServiceProvider);
      return StrategyRecommendationNotifier(
        strategyService,
        apiService,
        scoringService,
      );
    });
