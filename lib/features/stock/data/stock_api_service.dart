import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/stock_models.dart';
import '../../../core/constants/api_constants.dart';

/// HTTP client service for fetching stock data from East Money and Sina Finance APIs.
class StockApiService {
  late final Dio _dio;

  StockApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
        'Referer': 'https://www.eastmoney.com/',
      },
    ));

    // Only enable request/response logging in debug builds to avoid leaking
    // sensitive data (URLs, tokens) in production logs.
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
      ));
    }
  }

  /// Fetch all A-stock market quotes (price, change%, volume).
  Future<List<StockQuote>> fetchAllMarketQuotes() async {
    // Fetch in pages for reliability
    final allQuotes = <StockQuote>[];
    final pageSize = 5000;

    final response = await _dio.get(
      '${ApiConstants.eastmoneyPush}/clist/get',
      queryParameters: {
        'pn': 1,
        'pz': pageSize,
        'po': 1,
        'np': 1,
        'fltt': 2,
        'invt': 2,
        'fid': 'f3',
        'fs': 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23,m:1+t:23,b:MK0021,m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23',
        'fields': 'f2,f3,f4,f5,f6,f7,f8,f12,f14,f15,f16,f17,f18',
      },
    );

    final data = response.data;
    if (data == null) return allQuotes;

    final diff = data['data']?['diff'];
    if (diff == null) return allQuotes;

    for (final item in diff) {
      try {
        allQuotes.add(StockQuote.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip malformed entries
      }
    }

    return allQuotes;
  }

  /// Fetch stock K-line data (daily).
  Future<List<DailyKline>> fetchStockKline(
    String stockCode, {
    String market = 'SH',
    int days = ApiConstants.defaultKlineDays,
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
        'beg': '${beg.year}${beg.month.toString().padLeft(2, '0')}${beg.day.toString().padLeft(2, '0')}',
        'end': '${end.year}${end.month.toString().padLeft(2, '0')}${end.day.toString().padLeft(2, '0')}',
        'lmt': days,
      },
    );

    final data = response.data;
    final klinesStr = data?['data']?['klines'] as List<dynamic>?;
    if (klinesStr == null) return [];

    return DailyKline.parseKlines(klinesStr.cast<String>());
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
          .map((item) => StockSearchResult.fromJson(item as Map<String, dynamic>))
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
          'param': '{"uid":"","keyword":"$stockCode","type":["cmsArticleWebOld"],"pi":$page,"ps":$pageSize,"np":1}',
        },
        options: Options(responseType: ResponseType.plain),
      );

      // Parse JSONP response: extract JSON from callback wrapper.
      final body = response.data as String;
      final Map<String, dynamic> data;
      try {
        final startIndex = body.indexOf('(');
        if (startIndex >= 0) {
          final jsonPart = body.substring(startIndex + 1, body.lastIndexOf(')'));
          data = json.decode(jsonPart) as Map<String, dynamic>;
        } else {
          data = json.decode(body) as Map<String, dynamic>;
        }
      } catch (_) {
        return [];
      }

      final articles = data['Data']?['cmsArticleWebOld'] as List<dynamic>?;
      if (articles == null) return [];

      return articles.map((item) {
        final map = item as Map<String, dynamic>;
        return StockNews(
          id: (map['id'] ?? map['url'] ?? '').toString(),
          stockCode: stockCode,
          title: map['title'] as String? ?? '',
          source: map['mediaName'] as String? ?? '',
          sourceUrl: map['url'] as String? ?? '',
          publishedAt: map['date'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['date'] as int)
              : DateTime.now(),
          fetchedAt: DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get secid for a stock code.
  String getSecid(String code, String market) {
    return '${market == "SH" ? 1 : 0}.$code';
  }
}
