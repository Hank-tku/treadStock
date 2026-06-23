import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/stock_models.dart';
import '../../../core/constants/api_constants.dart';

/// HTTP client service for fetching stock data from East Money and Sina Finance APIs.
class StockApiService {
  static const int _marketQuotePageSize = 500;
  static const int _recommendationQuoteLimit = 50;

  late final Dio _dio;

  StockApiService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
          'Referer': 'https://www.eastmoney.com/',
        },
      ),
    );

    // Only enable request/response logging in debug builds to avoid leaking
    // sensitive data (URLs, tokens) in production logs.
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: false),
      );
    }

    // Automatic retry for network errors and server-side failures.
    _dio.interceptors.add(_RetryInterceptor(
      maxRetries: ApiConstants.maxRetries,
      retryDelay: ApiConstants.retryDelay,
    ));
  }

  /// Fetch all A-stock market quotes (price, change%, volume).
  Future<List<StockQuote>> fetchAllMarketQuotes() async {
    try {
      return await _fetchMarketQuotes(pageSize: _marketQuotePageSize);
    } catch (_) {
      return _fetchSinaMarketQuotes(limit: _marketQuotePageSize);
    }
  }

  /// Fetch only the highest-ranked market quotes needed by recommendation pages.
  ///
  /// East Money can be slow when requesting thousands of rows in one response.
  /// Recommendation only scores a small candidate pool, so this keeps the
  /// first-screen path fast and avoids whole-market receive timeouts.
  Future<List<StockQuote>> fetchRecommendationCandidates({
    int limit = _recommendationQuoteLimit,
  }) async {
    try {
      return await _fetchMarketQuotes(pageSize: limit, maxItems: limit);
    } catch (_) {
      return _fetchSinaMarketQuotes(limit: limit);
    }
  }

  Future<List<StockQuote>> _fetchMarketQuotes({
    required int pageSize,
    int? maxItems,
  }) async {
    final quotes = <StockQuote>[];
    var page = 1;
    int? total;

    while (true) {
      final pageQuotes = await _fetchMarketQuotePage(page, pageSize);
      quotes.addAll(pageQuotes.quotes);

      total ??= pageQuotes.total;
      if (maxItems != null && quotes.length >= maxItems) {
        return quotes.take(maxItems).toList();
      }
      if (pageQuotes.quotes.isEmpty) return quotes;
      if (total != null && quotes.length >= total) return quotes;

      page++;
    }
  }

  Future<({List<StockQuote> quotes, int? total})> _fetchMarketQuotePage(
    int page,
    int pageSize,
  ) async {
    final quotes = <StockQuote>[];

    final response = await _dio.get(
      '${ApiConstants.eastmoneyPush}/clist/get',
      queryParameters: {
        'pn': page,
        'pz': pageSize,
        'po': 1,
        'np': 1,
        'fltt': 2,
        'invt': 2,
        'fid': 'f3',
        'fs':
            'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23,m:1+t:23,b:MK0021,m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23',
        'fields': 'f2,f3,f4,f5,f6,f7,f8,f12,f14,f15,f16,f17,f18,f20,f100',
      },
    );

    final data = response.data;
    if (data == null) return (quotes: quotes, total: null);

    final quoteData = data['data'];
    final total = quoteData?['total'] is int ? quoteData['total'] as int : null;
    final diff = quoteData?['diff'];
    if (diff is! List) return (quotes: quotes, total: total);

    for (final item in diff) {
      try {
        quotes.add(StockQuote.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries
      }
    }

    return (quotes: quotes, total: total);
  }

  Future<List<StockQuote>> _fetchSinaMarketQuotes({required int limit}) async {
    final perMarketLimit = (limit / 2).ceil();
    final results = <StockQuote>[
      ...await _fetchSinaMarketQuotePage('sz_a', perMarketLimit),
      ...await _fetchSinaMarketQuotePage('sh_a', perMarketLimit),
    ]..sort((a, b) => b.changePct.compareTo(a.changePct));

    return results.take(limit).toList();
  }

  Future<List<StockQuote>> _fetchSinaMarketQuotePage(
    String node,
    int limit,
  ) async {
    final response = await _dio.get(
      'https://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/'
      'Market_Center.getHQNodeData',
      queryParameters: {
        'page': 1,
        'num': limit,
        'sort': 'changepercent',
        'asc': 0,
        'node': node,
        'symbol': '',
        '_s_r_a': 'page',
      },
      options: Options(responseType: ResponseType.plain),
    );

    final rows = json.decode(response.data?.toString() ?? '[]');
    if (rows is! List) return [];

    final quotes = <StockQuote>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final symbol = row['symbol']?.toString() ?? '';
      final market = symbol.startsWith('sh')
          ? 'SH'
          : symbol.startsWith('sz')
          ? 'SZ'
          : null;
      if (market == null) continue;

      final code = row['code']?.toString() ?? '';
      final price = _parseDouble(row['trade']?.toString());
      final preClose = _parseDouble(row['settlement']?.toString());
      final changeAmt = _parseDouble(row['pricechange']?.toString()) ?? 0;
      final changePct = _parseDouble(row['changepercent']?.toString()) ?? 0;
      if (code.isEmpty || price == null) continue;

      quotes.add(
        StockQuote(
          code: code,
          name: row['name']?.toString() ?? code,
          market: market,
          price: price,
          changePct: changePct,
          changeAmt: changeAmt,
          openPrice: _parseDouble(row['open']?.toString()) ?? price,
          highPrice: _parseDouble(row['high']?.toString()) ?? price,
          lowPrice: _parseDouble(row['low']?.toString()) ?? price,
          preClose: preClose ?? price - changeAmt,
          volume: _parseDouble(row['volume']?.toString()) ?? 0,
          turnover: _parseDouble(row['turnoverratio']?.toString()) ?? 0,
        ),
      );
    }

    return quotes;
  }

  /// Fetch stock K-line data (daily).
  Future<List<DailyKline>> fetchStockKline(
    String stockCode, {
    String market = 'SH',
    int days = ApiConstants.defaultKlineDays,
  }) async {
    try {
      final klines = await _fetchEastMoneyKline(
        stockCode,
        market: market,
        days: days,
      );
      if (klines.isNotEmpty) return klines;
    } catch (_) {
      // Fall back below. East Money occasionally closes Dart HTTP connections
      // before sending headers on macOS.
    }

    return _fetchSinaKline(stockCode, market: market, days: days);
  }

  Future<List<DailyKline>> _fetchEastMoneyKline(
    String stockCode, {
    required String market,
    required int days,
  }) async {
    final secid = '${market == "SH" ? 1 : 0}.$stockCode';
    final now = DateTime.now();
    final beg = DateTime(now.year - 1, now.month, now.day);
    final end = now;

    final response = await _dio.get(
      '${ApiConstants.eastmoneyPushHis}/stock/kline/get',
      queryParameters: {
        'secid': secid,
        'fields1': 'f1,f2,f3,f4,f5,f6',
        'fields2': 'f51,f52,f53,f54,f55,f56,f57',
        'klt': ApiConstants.klineTypeDaily,
        'fqt': ApiConstants.fqTypeForward,
        'beg':
            '${beg.year}${beg.month.toString().padLeft(2, '0')}${beg.day.toString().padLeft(2, '0')}',
        'end':
            '${end.year}${end.month.toString().padLeft(2, '0')}${end.day.toString().padLeft(2, '0')}',
        'lmt': days,
      },
    );

    final data = response.data;
    final klinesStr = data?['data']?['klines'] as List<dynamic>?;
    if (klinesStr == null) return [];

    return DailyKline.parseKlines(klinesStr.cast<String>());
  }

  /// Fetch latest quote for one stock.
  ///
  /// This endpoint is more stable than the historical K-line endpoint and is
  /// used by watchlist surfaces so price data can still render when K-lines
  /// are temporarily unavailable.
  Future<StockQuote?> fetchStockQuote(
    String stockCode, {
    String market = 'SH',
  }) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.eastmoneyPush}/stock/get',
        queryParameters: {
          'secid': getSecid(stockCode, market),
          'fields': 'f43,f44,f45,f46,f47,f48,f57,f58,f60,f168,f169,f170',
        },
      );

      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return StockQuote.fromRealtimeJson(
          data,
          fallbackCode: stockCode,
          fallbackMarket: market,
        );
      }
    } catch (_) {
      // Fall back below.
    }

    return _fetchSinaStockQuote(stockCode, market: market);
  }

  Future<StockQuote?> _fetchSinaStockQuote(
    String stockCode, {
    required String market,
  }) async {
    final symbol = '${market.toLowerCase()}$stockCode';
    final response = await _dio.get(
      'https://hq.sinajs.cn/list=$symbol',
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Referer': 'https://finance.sina.com.cn/'},
      ),
    );
    final body = response.data?.toString() ?? '';
    final start = body.indexOf('"');
    final end = body.lastIndexOf('"');
    if (start < 0 || end <= start) return null;

    final fields = body.substring(start + 1, end).split(',');
    if (fields.length < 10) return null;

    final open = _parseDouble(fields[1]);
    final preClose = _parseDouble(fields[2]);
    final price = _parseDouble(fields[3]);
    final high = _parseDouble(fields[4]);
    final low = _parseDouble(fields[5]);
    final volume = _parseDouble(fields[8]);
    final amount = _parseDouble(fields[9]);
    if (price == null || preClose == null) return null;

    final changeAmt = price - preClose;
    final changePct = preClose == 0 ? 0.0 : changeAmt / preClose * 100;
    return StockQuote(
      code: stockCode,
      name: stockCode,
      market: market,
      price: price,
      changePct: changePct,
      changeAmt: changeAmt,
      openPrice: open ?? price,
      highPrice: high ?? price,
      lowPrice: low ?? price,
      preClose: preClose,
      volume: volume ?? 0,
      turnover: amount ?? 0,
    );
  }

  Future<List<DailyKline>> _fetchSinaKline(
    String stockCode, {
    required String market,
    required int days,
  }) async {
    final symbol = '${market.toLowerCase()}$stockCode';
    final now = DateTime.now();
    final callback = 'var _${symbol}_${now.year}_${now.month}_${now.day}=';
    final response = await _dio.get(
      'https://quotes.sina.cn/cn/api/jsonp_v2.php/$callback/'
      'CN_MarketDataService.getKLineData',
      queryParameters: {
        'symbol': symbol,
        'scale': 240,
        'ma': 'no',
        'datalen': days,
      },
      options: Options(responseType: ResponseType.plain),
    );

    final body = response.data?.toString() ?? '';
    final start = body.indexOf('[');
    final end = body.lastIndexOf(']');
    if (start < 0 || end <= start) return [];

    final rows = json.decode(body.substring(start, end + 1));
    if (rows is! List) return [];

    final klines = <DailyKline>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final date = DateTime.tryParse(row['day']?.toString() ?? '');
      final open = _parseDouble(row['open']?.toString());
      final high = _parseDouble(row['high']?.toString());
      final low = _parseDouble(row['low']?.toString());
      final close = _parseDouble(row['close']?.toString());
      final volume = _parseDouble(row['volume']?.toString());
      if (date == null ||
          open == null ||
          high == null ||
          low == null ||
          close == null) {
        continue;
      }
      klines.add(
        DailyKline(
          date: date,
          open: open,
          close: close,
          high: high,
          low: low,
          volume: volume ?? 0,
          amount: 0,
          preClose: klines.isEmpty ? open : klines.last.close,
        ),
      );
    }

    return klines;
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  /// Search stocks by code or name.
  Future<List<StockSearchResult>> searchStock(String keyword) async {
    if (keyword.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        ApiConstants.eastmoneySearch,
        queryParameters: {
          'input': keyword.trim(),
          'type': '14',
          'token': ApiConstants.searchToken,
        },
      );

      final data = response.data;
      if (data == null) return [];

      final quoter = data['QuotationCodeTable']?['Data'] as List<dynamic>?;
      if (quoter == null) return [];

      return quoter
          .take(AppConstants.maxSearchResults)
          .map(
            (item) => StockSearchResult.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch stock news from East Money.
  Future<List<StockNews>> fetchStockNews(
    String stockCode, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.eastmoneySearchApi,
        queryParameters: {
          'cb': 'jQuery',
          'param':
              '{"uid":"","keyword":"$stockCode","type":["cmsArticleWebOld"],"pi":$page,"ps":$pageSize,"np":1}',
        },
        options: Options(responseType: ResponseType.plain),
      );

      // Parse JSONP response: extract JSON from callback wrapper.
      final body = response.data as String;
      final Map<String, dynamic> data;
      try {
        final startIndex = body.indexOf('(');
        if (startIndex >= 0) {
          final jsonPart = body.substring(
            startIndex + 1,
            body.lastIndexOf(')'),
          );
          data = json.decode(jsonPart) as Map<String, dynamic>;
        } else {
          data = json.decode(body) as Map<String, dynamic>;
        }
      } catch (e, st) {
        // JSONP/JSON decode failure — log so a future API change is visible
        // in debug instead of silently returning an empty news list.
        debugPrint('[StockApiService] news JSONP decode failed: $e\n$st');
        return [];
      }

      // The Eastmoney search-api wraps results under a top-level "result" key
      // (NOT "Data" — that was a stale assumption that always returned null).
      final result = data['result'] as Map<String, dynamic>?;
      final articles = result?['cmsArticleWebOld'] as List<dynamic>?;
      if (articles == null) return [];

      return articles.map((item) {
        final map = item as Map<String, dynamic>;
        // "date" is a string like "2026-06-21 18:05:00", not a millis int.
        // Parse defensively: fall back to now on unexpected formats.
        DateTime parseDate() {
          final raw = map['date'];
          if (raw is String) {
            return DateTime.tryParse(raw) ?? DateTime.now();
          }
          if (raw is int) {
            return DateTime.fromMillisecondsSinceEpoch(raw);
          }
          return DateTime.now();
        }

        return StockNews(
          id: (map['id'] ?? map['url'] ?? '').toString(),
          stockCode: stockCode,
          title: map['title'] as String? ?? '',
          source: map['mediaName'] as String? ?? '',
          sourceUrl: map['url'] as String? ?? '',
          publishedAt: parseDate(),
          fetchedAt: DateTime.now(),
        );
      }).toList();
    } catch (e, st) {
      // Network/parse errors: log instead of silently swallowing so a future
      // API change shows up in debug rather than an inexplicable empty list.
      debugPrint('[StockApiService] fetchStockNews failed: $e\n$st');
      return [];
    }
  }

  /// Get secid for a stock code.
  String getSecid(String code, String market) {
    return '${market == "SH" ? 1 : 0}.$code';
  }
}

/// Simple retry interceptor that retries on network-level errors (connection
/// closed, timeout, etc.) and HTTP 5xx responses.
///
/// This avoids adding an external dependency while addressing the frequent
/// `HttpException: Connection closed before full header was received` errors
/// seen when calling East Money APIs from macOS desktop.
class _RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;

  _RetryInterceptor({
    required this.maxRetries,
    required this.retryDelay,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['_retryAttempt'] as int?) ?? 0;
    if (attempt >= maxRetries || !_isRetriable(err)) {
      return handler.next(err);
    }

    // Wait before retrying; use exponential-ish backoff: base * (attempt + 1)
    await Future<void>.delayed(retryDelay * (attempt + 1));

    final options = err.requestOptions.copyWith(
      extra: {...err.requestOptions.extra, '_retryAttempt': attempt + 1},
    );

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: options.connectTimeout ?? ApiConstants.connectTimeout,
        receiveTimeout: options.receiveTimeout ?? ApiConstants.receiveTimeout,
        headers: options.headers,
      ));
      final response = await dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } catch (e) {
      handler.next(DioException(
        requestOptions: options,
        error: e,
        type: DioExceptionType.unknown,
      ));
    }
  }

  /// Whether the error deserves a retry.
  bool _isRetriable(DioException err) {
    switch (err.type) {
      // Network-level errors where the server dropped the connection or
      // responded too slowly.
      case DioExceptionType.connectionError:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.unknown:
        return true;

      // Server returned a response — retry only on 5xx.
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        return statusCode != null && statusCode >= 500;

      // Request was cancelled or bad — don't retry.
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
        return false;
    }
  }
}
