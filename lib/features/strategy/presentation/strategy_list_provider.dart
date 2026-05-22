import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    : super(const StrategyListState(isLoading: true)) {
    Future.microtask(loadStrategies);
  }

  Future<void> loadStrategies() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      await _strategyService.init();
      final strategies = _strategyService.getStrategies();
      if (!mounted) return;
      state = state.copyWith(strategies: strategies, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: '策略数据加载失败',
      );
    }
  }

  Future<void> toggleEnabled(String id, bool isEnabled) async {
    await _strategyService.init();
    await _strategyService.toggleEnabled(id, isEnabled);
    await loadStrategies();
  }

  Future<bool> deleteStrategy(String id) async {
    try {
      await _strategyService.init();
      await _strategyService.deleteStrategy(id);
      await loadStrategies();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createStrategy(StrategyFormData form) async {
    try {
      await _strategyService.init();
      await _strategyService.createStrategy(form);
      await loadStrategies();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateStrategy(String id, StrategyFormData form) async {
    try {
      await _strategyService.init();
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
