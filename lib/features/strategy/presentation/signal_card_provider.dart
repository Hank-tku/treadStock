import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../stock/data/stock_api_service.dart';
import '../../stock/domain/stock_models.dart';
import '../data/strategy_service.dart';
import '../domain/decision_signal_engine.dart';
import '../domain/signal_card.dart';
import '../domain/strategy_models.dart';
import '../../../shared/providers.dart';

/// State for signal card loading.
class SignalCardState {
  final List<SignalCard> cards;
  final bool isLoading;
  final String? error;

  const SignalCardState({
    this.cards = const [],
    this.isLoading = false,
    this.error,
  });

  SignalCardState copyWith({
    List<SignalCard>? cards,
    bool? isLoading,
    String? error,
  }) {
    return SignalCardState(
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier that computes signal cards for a given stock.
class SignalCardNotifier extends StateNotifier<SignalCardState> {
  final StrategyService _strategyService;
  final StockApiService _apiService;

  SignalCardNotifier(this._strategyService, this._apiService)
      : super(const SignalCardState());

  Future<void> _evaluateCards({
    required List<Strategy> strategies,
    required List<DailyKline> klines,
    required String stockCode,
    required String stockName,
    double? currentPrice,
    double? changePct,
    String? preferredStrategyId,
  }) async {
    if (strategies.isEmpty) {
      state = state.copyWith(isLoading: false, cards: []);
      return;
    }

    List<Strategy> targetStrategies;
    if (preferredStrategyId != null) {
      targetStrategies = strategies.where((s) => s.id == preferredStrategyId).toList();
      if (targetStrategies.isEmpty) {
        targetStrategies = strategies;
      }
    } else {
      targetStrategies = strategies;
    }

    final cards = DecisionSignalEngine.evaluateMultiple(
      klines: klines,
      strategies: targetStrategies,
      stockCode: stockCode,
      stockName: stockName,
      currentPrice: currentPrice,
      changePct: changePct,
    );

    cards.sort((a, b) {
      final aActive = a.isActionable ? 1 : 0;
      final bActive = b.isActionable ? 1 : 0;
      if (aActive != bActive) return bActive - aActive;
      return b.strength.level.compareTo(a.strength.level);
    });

    state = state.copyWith(isLoading: false, cards: cards);
  }

  /// Load and evaluate signal cards for the given stock using fresh API data.
  Future<void> loadSignalCards({
    required String stockCode,
    required String stockName,
    required String market,
    double? currentPrice,
    double? changePct,
    String? preferredStrategyId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final klines = await _apiService.fetchStockKline(stockCode, market: market);
      await _strategyService.init();
      final strategies = _strategyService.getEnabledStrategies();
      await _evaluateCards(
        strategies: strategies,
        klines: klines,
        stockCode: stockCode,
        stockName: stockName,
        currentPrice: currentPrice,
        changePct: changePct,
        preferredStrategyId: preferredStrategyId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Evaluate using pre-fetched K-line data.
  Future<void> loadSignalCardsFromKlines({
    required List<DailyKline> klines,
    required String stockCode,
    required String stockName,
    required List<Strategy> strategies,
    double? currentPrice,
    double? changePct,
    String? preferredStrategyId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _evaluateCards(
        strategies: strategies,
        klines: klines,
        stockCode: stockCode,
        stockName: stockName,
        currentPrice: currentPrice,
        changePct: changePct,
        preferredStrategyId: preferredStrategyId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider for signal card state.
final signalCardProvider =
    StateNotifierProvider<SignalCardNotifier, SignalCardState>((ref) {
  final strategyService = ref.watch(strategyServiceProvider);
  final apiService = ref.watch(stockApiServiceProvider);
  return SignalCardNotifier(strategyService, apiService);
});
