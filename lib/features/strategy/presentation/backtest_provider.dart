import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers.dart';
import '../../stock/data/cached_stock_api_service.dart';
import '../../analysis/domain/analysis_engine.dart';
import '../data/strategy_service.dart';
import '../domain/backtest_engine.dart';
import '../domain/backtest_models.dart';

// ── Backtest State ──────────────────────────────────────

enum BacktestStatus { idle, loading, done, error }

class BacktestState {
  final BacktestStatus status;
  final BacktestResult? result;
  final String? errorMessage;

  const BacktestState({
    this.status = BacktestStatus.idle,
    this.result,
    this.errorMessage,
  });

  BacktestState copyWith({
    BacktestStatus? status,
    BacktestResult? result,
    String? errorMessage,
  }) {
    return BacktestState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ── Backtest Notifier ───────────────────────────────────

class BacktestNotifier extends StateNotifier<BacktestState> {
  final StrategyService _strategyService;
  final CachedStockApiService _apiService;
  final AnalysisEngine _analysisEngine;

  BacktestNotifier({
    required StrategyService strategyService,
    required CachedStockApiService apiService,
    required AnalysisEngine analysisEngine,
  })  : _strategyService = strategyService,
        _apiService = apiService,
        _analysisEngine = analysisEngine,
        super(const BacktestState());

  Future<void> runBacktest({
    required String strategyId,
    required String stockCode,
    required String stockName,
    required String market,
    BacktestConfig config = const BacktestConfig(),
  }) async {
    state = state.copyWith(status: BacktestStatus.loading);

    try {
      await _strategyService.init();
      final strategy = _strategyService.getStrategy(strategyId);
      if (strategy == null) {
        state = state.copyWith(
          status: BacktestStatus.error,
          errorMessage: '策略不存在',
        );
        return;
      }

      // Fetch kline data (up to 500 bars for backtest)
      final klines = await _apiService.fetchStockKline(
        stockCode,
        market: market,
        days: 500,
      );

      if (klines.length < 60) {
        state = state.copyWith(
          status: BacktestStatus.error,
          errorMessage: 'K线数据不足（需要至少60根）',
        );
        return;
      }

      final engine = BacktestEngine();
      final result = engine.run(
        klines: klines,
        strategy: strategy,
        config: config,
        stockCode: stockCode,
        analysisEngine: _analysisEngine,
      );

      if (!mounted) return;
      state = state.copyWith(status: BacktestStatus.done, result: result);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: BacktestStatus.error,
        errorMessage: '回测失败：$e',
      );
    }
  }

  void reset() {
    state = const BacktestState();
  }
}

// ── Import for cached API ──
// (CachedStockApiService is already imported via providers)

// ── Providers ───────────────────────────────────────────

final backtestProvider =
    StateNotifierProvider<BacktestNotifier, BacktestState>((ref) {
  return BacktestNotifier(
    strategyService: ref.read(strategyServiceProvider),
    apiService: ref.read(cachedStockApiServiceProvider),
    analysisEngine: ref.read(analysisEngineProvider),
  );
});
