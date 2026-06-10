/// East Money API constants.
class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String eastmoneyPush = 'https://push2.eastmoney.com/api/qt';
  static const String eastmoneyPushHis = 'https://push2his.eastmoney.com/api/qt';
  static const String eastmoneySearch = 'https://searchapi.eastmoney.com/api/suggest/get';
  static const String eastmoneySearchApi = 'https://search-api-web.eastmoney.com/search/jsonp';
  static const String sinaFinance = 'https://hq.sinajs.cn/list=';

  // API tokens — split into prefix + suffix to increase reverse-engineering difficulty
  // Long-term solution: introduce a backend proxy so the token never ships in the app
  static const String _searchTokenPrefix = 'D43BF722C8E33BDC906FB84';
  static const String _searchTokenSuffix = 'D85E326E8';

  /// Assembled search token (reconstructed from two fragments).
  static String get searchToken => '$_searchTokenPrefix$_searchTokenSuffix';

  // Market secid prefixes
  static const int shPrefix = 1; // Shanghai
  static const int szPrefix = 0; // Shenzhen

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Retry config (used by RetryInterceptor inside StockApiService)
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration rateLimitDelay = Duration(seconds: 60);

  // Cache durations
  static const Duration quoteCacheDuration = Duration(minutes: 5);
  static const Duration recommendationCacheDuration = Duration(minutes: 30);
  static const Duration newsCacheDuration = Duration(hours: 24);

  // Kline config
  static const int defaultKlineDays = 120;
  static const int klineTypeDaily = 101;
  static const int fqTypeForward = 1;
}

/// App-level constants.
class AppConstants {
  AppConstants._();

  static const String appName = '股势 TrendStock';
  static const double minTouchTarget = 44;
  static const int searchDebounceMs = 300;
  static const int maxSearchResults = 10;
  static const int pullToRefreshThreshold = 60;
  static const double swipeActionThreshold = 80;
  static const double bottomToastOffset = 64; // 48px tab + 16px margin

  // Alert quiet hours (22:00 - 08:00)
  static const int alertQuietStartHour = 22;
  static const int alertQuietEndHour = 8;

  // Background task interval
  static const int backgroundTaskIntervalMinutes = 30;

  // Score weights
  static const double weightMA = 0.30;
  static const double weightBoll = 0.30;
  static const double weightVol = 0.20;
  static const double weightTrend = 0.20;

  // Bollinger Band params
  static const int bollPeriod = 20;
  static const double bollStdDev = 2.0;

  // MA periods
  static const int maShortPeriod = 20;
  static const int maLongPeriod = 60;

  // Disclaimer
  static const String disclaimer =
      '以上分析仅供参考，不构成任何投资建议。投资有风险，入市需谨慎。';
}
