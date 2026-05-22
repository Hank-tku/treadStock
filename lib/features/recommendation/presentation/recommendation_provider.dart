import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../analysis/domain/analysis_engine.dart';
import '../../stock/data/stock_api_service.dart';
import '../../stock/domain/stock_models.dart';
import '../../../shared/providers.dart';

/// State for recommendation list.
class RecommendationState {
  final List<DailyRecommendation> shortTerm;
  final List<DailyRecommendation> midTerm;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool isOffline;
  final DateTime? lastUpdated;

  const RecommendationState({
    this.shortTerm = const [],
    this.midTerm = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.isOffline = false,
    this.lastUpdated,
  });

  RecommendationState copyWith({
    List<DailyRecommendation>? shortTerm,
    List<DailyRecommendation>? midTerm,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? isOffline,
    DateTime? lastUpdated,
  }) {
    return RecommendationState(
      shortTerm: shortTerm ?? this.shortTerm,
      midTerm: midTerm ?? this.midTerm,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final StockApiService _apiService;
  final AnalysisEngine _analysisEngine;

  RecommendationNotifier(this._apiService, this._analysisEngine)
    : super(const RecommendationState());

  Future<void> loadRecommendations() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      // Fetch only the candidate pool needed for recommendation scoring.
      final quotes = await _apiService.fetchRecommendationCandidates();
      if (quotes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: '暂无推荐数据',
        );
        return;
      }

      // Score top stocks (limit to ~50 for performance)
      final scoredStocks = <DailyRecommendation>[];
      final topStocks = quotes.take(50).toList();

      // Fetch klines in parallel with concurrency limit of 8.
      scoredStocks.addAll(
        await _fetchAndScoreInParallel(topStocks, concurrency: 8),
      );

      // Sort by score descending
      scoredStocks.sort(
        (a, b) => (b.score?.score ?? 0).compareTo(a.score?.score ?? 0),
      );

      final shortTerm = scoredStocks
          .where((r) => r.category == 'short_term')
          .toList();
      final midTerm = scoredStocks
          .where((r) => r.category == 'mid_term')
          .toList();

      state = state.copyWith(
        shortTerm: shortTerm,
        midTerm: midTerm,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        isOffline: true,
        errorMessage: '数据更新失败，显示缓存数据',
      );
    }
  }

  /// Fetch klines and score stocks in parallel with a concurrency limit.
  Future<List<DailyRecommendation>> _fetchAndScoreInParallel(
    List<StockQuote> stocks, {
    required int concurrency,
  }) async {
    final results = <DailyRecommendation>[];

    // Process in batches of [concurrency] to limit parallel requests.
    for (var i = 0; i < stocks.length; i += concurrency) {
      final batch = stocks.sublist(
        i,
        (i + concurrency).clamp(0, stocks.length),
      );
      final batchResults = await Future.wait(batch.map((q) => _scoreOne(q)));
      for (final r in batchResults) {
        if (r != null) results.add(r);
      }
    }

    return results;
  }

  /// Score a single stock. Returns null on failure.
  Future<DailyRecommendation?> _scoreOne(StockQuote quote) async {
    try {
      final klines = await _apiService.fetchStockKline(
        quote.code,
        market: quote.market,
      );
      if (klines.length < 20) return null;

      final score = _analysisEngine.calculateScore(klines);
      if (score.score > 0) {
        return DailyRecommendation(
          code: quote.code,
          name: quote.name,
          market: quote.market,
          category: score.category,
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

/// Provider for recommendation state.
final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
      final apiService = ref.read(stockApiServiceProvider);
      final analysisEngine = ref.read(analysisEngineProvider);
      return RecommendationNotifier(apiService, analysisEngine);
    });
