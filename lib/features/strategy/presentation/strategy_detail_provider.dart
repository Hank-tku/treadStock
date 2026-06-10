import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/strategy_service.dart';
import '../domain/strategy_models.dart';
import '../../../shared/providers.dart';

// ── Strategy Detail State ──────────────────────────────────────

enum StrategyDetailErrorType { none, notFound, statsFailed }

class StrategyDetailState {
  final Strategy? strategy;
  final List<StrategyHitRecord> hitRecords;
  final List<StrategyReview> reviewHistory;
  final StrategyStats stats;
  final List<ChecklistItem> checklist;
  final ReviewPeriodInfo? reviewPeriod;
  final List<StrategySuggestion> suggestions;
  final bool isLoading;
  final StrategyDetailErrorType errorType;

  const StrategyDetailState({
    this.strategy,
    this.hitRecords = const [],
    this.reviewHistory = const [],
    this.stats = const StrategyStats(),
    this.checklist = const [],
    this.reviewPeriod,
    this.suggestions = const [],
    this.isLoading = true,
    this.errorType = StrategyDetailErrorType.none,
  });

  bool get hasError => errorType != StrategyDetailErrorType.none;
  bool get hasInsufficientSample =>
      !hasError && !isLoading && stats.evaluatedCount < 20;

  bool get isAccumulatingData =>
      strategy?.isEnabled == true &&
      !hasError &&
      !isLoading &&
      stats.tradingDaysRun < 5;

  StrategyDetailState copyWith({
    Object? strategy = _unset,
    List<StrategyHitRecord>? hitRecords,
    List<StrategyReview>? reviewHistory,
    StrategyStats? stats,
    List<ChecklistItem>? checklist,
    ReviewPeriodInfo? reviewPeriod,
    List<StrategySuggestion>? suggestions,
    bool? isLoading,
    StrategyDetailErrorType? errorType,
  }) {
    return StrategyDetailState(
      strategy: identical(strategy, _unset)
          ? this.strategy
          : strategy as Strategy?,
      hitRecords: hitRecords ?? this.hitRecords,
      reviewHistory: reviewHistory ?? this.reviewHistory,
      stats: stats ?? this.stats,
      checklist: checklist ?? this.checklist,
      reviewPeriod: reviewPeriod ?? this.reviewPeriod,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      errorType: errorType ?? this.errorType,
    );
  }
}

const Object _unset = Object();

class StrategyDetailNotifier extends StateNotifier<StrategyDetailState> {
  final StrategyService _strategyService;

  StrategyDetailNotifier(this._strategyService)
    : super(const StrategyDetailState());

  Future<void> loadDetail(String strategyId) async {
    state = state.copyWith(
      isLoading: true,
      errorType: StrategyDetailErrorType.none,
    );
    try {
      await _strategyService.init();
      final strategy = _strategyService.getStrategy(strategyId);
      if (strategy == null) {
        if (!mounted) return;
        state = state.copyWith(
          strategy: null,
          hitRecords: const [],
          reviewHistory: const [],
          stats: const StrategyStats(),
          suggestions: const [],
          isLoading: false,
          errorType: StrategyDetailErrorType.notFound,
        );
        return;
      }

      StrategyStats stats;
      List<StrategyHitRecord> hitRecords;
      List<StrategyReview> reviewHistory;
      List<StrategySuggestion> suggestions;
      try {
        stats = await _strategyService.computeStats(strategyId);
        hitRecords = await _strategyService.getHitRecords(strategyId);
        reviewHistory = await _strategyService.getReviewHistory(strategyId);
        suggestions = _strategyService.generateSuggestions(strategy, stats);
      } catch (_) {
        if (!mounted) return;
        state = state.copyWith(
          strategy: strategy,
          isLoading: false,
          errorType: StrategyDetailErrorType.statsFailed,
        );
        return;
      }

      if (!mounted) return;
      state = state.copyWith(
        strategy: strategy,
        stats: stats,
        hitRecords: hitRecords,
        reviewHistory: reviewHistory,
        suggestions: suggestions,
        isLoading: false,
        errorType: StrategyDetailErrorType.none,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorType: StrategyDetailErrorType.statsFailed,
      );
    }
  }

  Future<void> generateChecklist(String strategyId) async {
    final result = await _strategyService.generateChecklistResult(strategyId);
    state = state.copyWith(
      checklist: result.items,
      reviewPeriod: result.period,
    );
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
