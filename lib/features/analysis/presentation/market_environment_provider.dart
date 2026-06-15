import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../stock/data/stock_api_service.dart';
import '../../stock/domain/stock_models.dart';
import '../domain/market_environment.dart';
import '../../../shared/providers.dart';

/// State holding the current [MarketEnvironment].
class MarketEnvironmentState {
  final MarketEnvironment? environment;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const MarketEnvironmentState({
    this.environment,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.lastUpdated,
  });

  MarketEnvironmentState copyWith({
    MarketEnvironment? environment,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return MarketEnvironmentState(
      environment: environment ?? this.environment,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class MarketEnvironmentNotifier
    extends StateNotifier<MarketEnvironmentState> {
  final StockApiService _apiService;

  MarketEnvironmentNotifier(this._apiService)
      : super(const MarketEnvironmentState());

  /// Fetch market data and compute the environment.
  Future<void> loadEnvironment() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final results = await Future.wait([
        _apiService.fetchAllMarketQuotes(),
        _apiService.fetchStockKline('000001', market: 'SH'),
      ]);

      final quotes = results[0] as List<StockQuote>;
      final indexKlines = results[1] as List<DailyKline>;

      if (quotes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: '暂无行情数据',
        );
        return;
      }

      final env = MarketEnvironmentCalculator.calculate(
        quotes: quotes,
        indexKlines: indexKlines,
      );

      state = state.copyWith(
        environment: env,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: '市场环境数据获取失败',
      );
    }
  }
}

/// Provider for the market environment.
final marketEnvironmentProvider = StateNotifierProvider<
    MarketEnvironmentNotifier, MarketEnvironmentState>((ref) {
  final apiService = ref.read(stockApiServiceProvider);
  return MarketEnvironmentNotifier(apiService);
});
