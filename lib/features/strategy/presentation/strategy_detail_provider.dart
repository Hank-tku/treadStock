import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/strategy_service.dart';
import '../domain/strategy_models.dart';
import '../../../shared/providers.dart';

// ── Strategy Detail State ──────────────────────────────────────

class StrategyDetailState {
  final Strategy? strategy;
  final List<StrategyHitRecord> hitRecords;
  final List<StrategyReview> reviewHistory;
  final StrategyStats stats;
  final List<ChecklistItem> checklist;
  final ReviewPeriodInfo? reviewPeriod;
  final List<StrategySuggestion> suggestions;
  final bool isLoading;
  final bool hasError;

  const StrategyDetailState({
    this.strategy,
    this.hitRecords = const [],
    this.reviewHistory = const [],
    this.stats = const StrategyStats(),
    this.checklist = const [],
    this.reviewPeriod,
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
    ReviewPeriodInfo? reviewPeriod,
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
      reviewPeriod: reviewPeriod ?? this.reviewPeriod,
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
      await _strategyService.init();
      final strategy = _strategyService.getStrategy(strategyId);
      if (strategy == null) {
        if (!mounted) return;
        state = state.copyWith(isLoading: false, hasError: true);
        return;
      }

      final stats = await _strategyService.computeStats(strategyId);
      final hitRecords = await _strategyService.getHitRecords(strategyId);
      final reviewHistory = await _strategyService.getReviewHistory(strategyId);
      final suggestions = _strategyService.generateSuggestions(strategy, stats);

      if (!mounted) return;
      state = state.copyWith(
        strategy: strategy,
        stats: stats,
        hitRecords: hitRecords,
        reviewHistory: reviewHistory,
        suggestions: suggestions,
        isLoading: false,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, hasError: true);
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
