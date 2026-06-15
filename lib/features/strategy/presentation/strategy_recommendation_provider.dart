import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stock/data/stock_api_service.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../stock/domain/stock_models.dart';
import '../data/strategy_service.dart';
import '../domain/strategy_models.dart';
import '../domain/strategy_scoring_service.dart';
import '../domain/stock_filter.dart';
import '../../analysis/domain/market_environment.dart';
import '../../../shared/providers.dart';

// ── Recommendation by Strategy ─────────────────────────────────

/// A recommendation result grouped by strategy.
class StrategyRecommendation {
  final Strategy strategy;
  final List<DailyRecommendation> recommendations;
  final EnvironmentMatchResult? environmentMatch;

  const StrategyRecommendation({
    required this.strategy,
    required this.recommendations,
    this.environmentMatch,
  });

  /// Whether the environment is unfavourable (matchScore < 50).
  bool get isEnvironmentUnfavourable =>
      environmentMatch != null && !environmentMatch!.isFavourable;
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

      // ── Fetch market environment for E502 ──────────────────────
      MarketEnvironment? env;
      try {
        final indexKlines = await _apiService.fetchStockKline(
          '000001',
          market: 'SH',
        );
        env = MarketEnvironmentCalculator.calculate(
          quotes: quotes,
          indexKlines: indexKlines,
        );
      } catch (_) {
        // Environment fetch failure should not block recommendations
        env = null;
      }

      await _strategyService.backfillActualChanges({
        for (final quote in quotes) quote.code: quote.price,
      });

      final topStocks = quotes.take(50).toList();
      final groups = <StrategyRecommendation>[];

      for (final strategy in enabledStrategies) {
        // Apply strategy-specific stock filter if configured
        final candidates = strategy.stockFilter != null &&
                strategy.stockFilter!.isActive
            ? _applyStockFilter(quotes, strategy.stockFilter!)
            : topStocks;

        // ── Compute environment match for this strategy ───────────
        final envMatch = env != null
            ? EnvironmentMatchResult.evaluate(
                env: env,
                weightMA: strategy.weightMA,
                weightBoll: strategy.weightBoll,
                weightVol: strategy.weightVol,
                weightTrend: strategy.weightTrend,
              )
            : null;

        // When environment is unfavourable, lower the effective threshold
        final effectiveThreshold = envMatch != null && !envMatch.isFavourable
            ? (strategy.recommendThreshold *
                    envMatch.weightMultiplier)
                .ceil()
            : strategy.recommendThreshold;

        final scored = await _fetchAndScoreForStrategy(candidates, strategy);
        final recs =
            scored
                .where(
                  (item) =>
                      item.score != null &&
                      item.score!.score >= effectiveThreshold,
                )
                .toList()
              ..sort(
                (a, b) => (b.score?.score ?? 0).compareTo(a.score?.score ?? 0),
              );

        // When environment is poor, apply weight multiplier to displayed scores
        List<DailyRecommendation> adjustedRecs = recs;
        if (envMatch != null &&
            envMatch.weightMultiplier < 1.0 &&
            recs.isNotEmpty) {
          adjustedRecs = recs
              .map((rec) {
                final adjusted =
                    (rec.score!.score * envMatch.weightMultiplier).round();
                return DailyRecommendation(
                  code: rec.code,
                  name: rec.name,
                  market: rec.market,
                  category: rec.category,
                  closePrice: rec.closePrice,
                  changePct: rec.changePct,
                  isBandLow: rec.isBandLow,
                  score: StockScore(
                    score: adjusted,
                    maScore: rec.score!.maScore,
                    bollScore: rec.score!.bollScore,
                    volScore: rec.score!.volScore,
                    trendScore: rec.score!.trendScore,
                    isBandLow: rec.score!.isBandLow,
                    reason: rec.score!.reason != null
                        ? '${rec.score!.reason}（环境降权 ×${envMatch.weightMultiplier.toStringAsFixed(2)}）'
                        : null,
                  ),
                );
              })
              .toList();
        }

        groups.add(
          StrategyRecommendation(
            strategy: strategy,
            recommendations: adjustedRecs,
            environmentMatch: envMatch,
          ),
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

  /// Apply a StockFilter to a list of quotes, returning filtered candidates.
  /// Filters by price, change %, turnover, and board (based on code prefix).
  List<StockQuote> _applyStockFilter(
    List<StockQuote> quotes,
    StockFilter filter,
  ) {
    var result = quotes;

    // Price range
    if (filter.minPrice != null || filter.maxPrice != null) {
      result = result.where((q) {
        if (filter.minPrice != null && q.price < filter.minPrice!) return false;
        if (filter.maxPrice != null && q.price > filter.maxPrice!) return false;
        return true;
      }).toList();
    }

    // Change % range
    if (filter.changeRange != null) {
      final (lo, hi) = filter.changeRange!;
      result = result.where((q) => q.changePct >= lo && q.changePct <= hi).toList();
    }

    // Turnover range
    if (filter.turnoverRange != null) {
      final (lo, hi) = filter.turnoverRange!;
      result = result.where((q) => q.turnover >= lo && q.turnover <= hi).toList();
    }

    // Board filter based on stock code prefix
    if (filter.boards != null && filter.boards!.isNotEmpty) {
      result = result.where((q) {
        final code = q.code;
        for (final board in filter.boards!) {
          switch (board) {
            case 'main': // 沪深主板: SH 60xxxx, SZ 00xxxx
              if (code.startsWith('6') || code.startsWith('00')) return true;
            case 'gem': // 创业板: SZ 30xxxx
              if (code.startsWith('30')) return true;
            case 'star': // 科创板: SH 688xxx
              if (code.startsWith('688')) return true;
            case 'bse': // 北交所: 8xxxxx
              if (code.startsWith('8') || code.startsWith('4')) return true;
          }
        }
        return false;
      }).toList();
    }

    // Cap at 50 candidates max to keep scoring time reasonable
    return result.take(50).toList();
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
