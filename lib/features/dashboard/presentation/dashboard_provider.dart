import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../strategy/data/strategy_service.dart';
import '../../strategy/domain/strategy_models.dart';
import '../../strategy/presentation/strategy_recommendation_provider.dart';
import '../../watchlist/data/watchlist_service.dart';
import '../../../shared/providers.dart';

// ── Dashboard Decision Board ─────────────────────────────────

/// Summary stats for the decision dashboard.
class DashboardData {
  /// Total number of strategies (enabled / total).
  final int enabledStrategies;
  final int totalStrategies;

  /// Best-performing strategy (by health score), null if no stats.
  final Strategy? bestStrategy;
  final double? bestHealthScore;

  /// Total recommendations today across all strategies.
  final int totalRecommendations;

  /// Top recommendations across all strategies (best score first).
  final List<DailyRecommendation> topRecommendations;

  /// Average hit rate across enabled strategies with stats.
  final double avgHitRate;
  final int strategiesWithStats;

  /// Overall market sentiment based on top recommendations.
  final MarketSentiment sentiment;

  /// Strategies that need review (30+ days).
  final List<Strategy> strategiesNeedingReview;

  /// Watchlist count.
  final int watchlistCount;

  const DashboardData({
    this.enabledStrategies = 0,
    this.totalStrategies = 0,
    this.bestStrategy,
    this.bestHealthScore,
    this.totalRecommendations = 0,
    this.topRecommendations = const [],
    this.avgHitRate = 0.0,
    this.strategiesWithStats = 0,
    this.sentiment = MarketSentiment.neutral,
    this.strategiesNeedingReview = const [],
    this.watchlistCount = 0,
  });
}

/// Market sentiment derived from recommendation data.
enum MarketSentiment {
  /// Many high-score recommendations — bullish.
  strong,

  /// Some recommendations, moderate scores — neutral.
  neutral,

  /// Few or low-score recommendations — cautious.
  cautious,

  /// No data available.
  unknown,
}

/// State for the dashboard.
class DashboardState {
  final DashboardData data;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const DashboardState({
    DashboardData? data,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  }) : data = data ?? const DashboardData();

  DashboardState copyWith({
    DashboardData? data,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return DashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final StrategyService _strategyService;
  final WatchlistService _watchlistService;

  DashboardNotifier(this._strategyService, this._watchlistService)
      : super(const DashboardState());

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      await _strategyService.init();
      await _watchlistService.init();

      final allStrategies = _strategyService.getStrategies();
      final enabled = allStrategies.where((s) => s.isEnabled).toList();
      final needingReview = allStrategies.where((s) => s.needsReview).toList();
      final watchlistCount = _watchlistService.getWatchlist().length;

      // Find best strategy by health score
      Strategy? best;
      double? bestScore;
      for (final s in enabled) {
        final score = s.stats?.healthScore;
        if (score != null && (bestScore == null || score > bestScore)) {
          best = s;
          bestScore = score;
        }
      }

      // Average hit rate
      final withStats =
          enabled.where((s) => s.stats != null && s.stats!.evaluatedCount > 0);
      final avgHitRate = withStats.isEmpty
          ? 0.0
          : withStats
                  .map((s) => s.stats!.hitRate)
                  .reduce((a, b) => a + b) /
              withStats.length;

      state = state.copyWith(
        isLoading: false,
        data: DashboardData(
          enabledStrategies: enabled.length,
          totalStrategies: allStrategies.length,
          bestStrategy: best,
          bestHealthScore: bestScore,
          avgHitRate: avgHitRate,
          strategiesWithStats: withStats.length,
          strategiesNeedingReview: needingReview,
          watchlistCount: watchlistCount,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: '看板数据加载失败',
      );
    }
  }

  /// Enrich dashboard with recommendation data from the recommendation provider.
  DashboardData enrichWithRecommendations(
    DashboardData base,
    StrategyRecommendationState recState,
  ) {
    if (recState.groups.isEmpty) {
      return base;
    }

    int totalRecs = 0;
    final allRecs = <DailyRecommendation>[];

    for (final group in recState.groups) {
      totalRecs += group.recommendations.length;
      allRecs.addAll(group.recommendations);
    }

    // Sort by score descending, take top 5
    allRecs.sort(
        (a, b) => (b.score?.score ?? 0).compareTo(a.score?.score ?? 0));
    final topRecs = allRecs.take(5).toList();

    // Determine sentiment
    MarketSentiment sentiment;
    if (totalRecs == 0) {
      sentiment = recState.hasEnabledStrategies
          ? MarketSentiment.cautious
          : MarketSentiment.unknown;
    } else if (totalRecs >= 10) {
      final highScoreCount =
          allRecs.where((r) => (r.score?.score ?? 0) >= 8).length;
      sentiment = highScoreCount >= 3
          ? MarketSentiment.strong
          : MarketSentiment.neutral;
    } else {
      sentiment = MarketSentiment.neutral;
    }

    return DashboardData(
      enabledStrategies: base.enabledStrategies,
      totalStrategies: base.totalStrategies,
      bestStrategy: base.bestStrategy,
      bestHealthScore: base.bestHealthScore,
      totalRecommendations: totalRecs,
      topRecommendations: topRecs,
      avgHitRate: base.avgHitRate,
      strategiesWithStats: base.strategiesWithStats,
      sentiment: sentiment,
      strategiesNeedingReview: base.strategiesNeedingReview,
      watchlistCount: base.watchlistCount,
    );
  }
}

/// Provider for the dashboard state.
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final strategyService = ref.read(strategyServiceProvider);
  final watchlistService = ref.read(watchlistServiceProvider);
  return DashboardNotifier(strategyService, watchlistService);
});
