// Data models for stock quotes, klines, and search results.

class StockQuote {
  final String code;
  final String name;
  final String market; // SH or SZ
  final double price;
  final double changePct; // percentage
  final double changeAmt;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double preClose;
  final double volume; // in lots (手)
  final double turnover; // percentage
  // Total market cap in 亿元 (hundred-million CNY). Null when the quote source
  // does not provide it (e.g. Sina fallback). Used by StockFilter.marketCapRange.
  final double? marketCap;
  // Eastmoney industry classification string (e.g. '电子', '银行'). Null on
  // fallback sources. Used by StockFilter.industries.
  final String? industry;

  const StockQuote({
    required this.code,
    required this.name,
    required this.market,
    required this.price,
    required this.changePct,
    required this.changeAmt,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.preClose,
    required this.volume,
    required this.turnover,
    this.marketCap,
    this.industry,
  });

  String get fullCode => '$code.$market';

  factory StockQuote.fromJson(Map<String, dynamic> json) {
    return StockQuote(
      code: json['f12'] as String? ?? '',
      name: json['f14'] as String? ?? '',
      market: _detectMarket(json['f12'] as String? ?? ''),
      price: _toDouble(json['f2']),
      changePct: _toDouble(json['f3']),
      changeAmt: _toDouble(json['f4']),
      volume: _toDouble(json['f5']),
      openPrice: _toDouble(json['f17']),
      highPrice: _toDouble(json['f15']),
      lowPrice: _toDouble(json['f16']),
      preClose: _toDouble(json['f18']),
      turnover: _toDouble(json['f8']),
      // f20 is total market cap in CNY (元); convert to 亿元 (÷1e8).
      marketCap: (json['f20'] as num?)?.toDouble() == null
          ? null
          : (json['f20'] as num).toDouble() / 1e8,
      industry: json['f100'] as String?,
    );
  }

  factory StockQuote.fromRealtimeJson(
    Map<String, dynamic> json, {
    required String fallbackCode,
    required String fallbackMarket,
  }) {
    final code = json['f57'] as String? ?? fallbackCode;
    return StockQuote(
      code: code,
      name: json['f58'] as String? ?? '',
      market: code.isEmpty ? fallbackMarket : _detectMarket(code),
      price: _toScaledPrice(json['f43']),
      changePct: _toScaledPrice(json['f170']),
      changeAmt: _toScaledPrice(json['f169']),
      volume: _toDouble(json['f47']),
      openPrice: _toScaledPrice(json['f46']),
      highPrice: _toScaledPrice(json['f44']),
      lowPrice: _toScaledPrice(json['f45']),
      preClose: _toScaledPrice(json['f60']),
      turnover: _toScaledPrice(json['f168']),
    );
  }

  static String _detectMarket(String code) {
    if (code.startsWith('6') || code.startsWith('9')) return 'SH';
    return 'SZ';
  }

  static double _toDouble(dynamic value) {
    if (value == null || value == '-') return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double _toScaledPrice(dynamic value) {
    if (value == null || value == '-') return 0.0;
    if (value is int) return value / 100;
    if (value is double) return value / 100;
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed == null ? 0.0 : parsed / 100;
    }
    return 0.0;
  }

  StockQuote copyWith({
    double? price,
    double? changePct,
    double? changeAmt,
    double? openPrice,
    double? highPrice,
    double? lowPrice,
    double? volume,
    double? turnover,
    double? marketCap,
    String? industry,
  }) {
    return StockQuote(
      code: code,
      name: name,
      market: market,
      price: price ?? this.price,
      changePct: changePct ?? this.changePct,
      changeAmt: changeAmt ?? this.changeAmt,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      preClose: preClose,
      volume: volume ?? this.volume,
      turnover: turnover ?? this.turnover,
      marketCap: marketCap ?? this.marketCap,
      industry: industry ?? this.industry,
    );
  }
}

class DailyKline {
  final DateTime date;
  final double open;
  final double close;
  final double high;
  final double low;
  final double volume;
  final double amount;

  /// Previous day's close price. Populated from the prior kline entry.
  /// Defaults to close price when no prior data is available (first entry).
  final double preClose;

  const DailyKline({
    required this.date,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.volume,
    required this.amount,
    this.preClose = 0,
  });

  double get changePct =>
      preClose > 0 ? ((close - preClose) / preClose) * 100 : 0;

  factory DailyKline.fromEastMoney(String klineStr) {
    // Format: "2026-04-10,44.80,45.20,45.80,44.50,125400,5678000000"
    final parts = klineStr.split(',');
    return DailyKline(
      date: DateTime.parse(parts[0].trim()),
      open: double.parse(parts[1].trim()),
      close: double.parse(parts[2].trim()),
      high: double.parse(parts[3].trim()),
      low: double.parse(parts[4].trim()),
      volume: double.parse(parts[5].trim()),
      amount: double.parse(parts[6].trim()),
    );
  }

  /// Parse kline strings and populate preClose from the previous day's close.
  static List<DailyKline> parseKlines(List<String> klineStrings) {
    final klines = klineStrings.map(DailyKline.fromEastMoney).toList();
    // Populate preClose: each day's preClose = previous day's close.
    for (var i = 1; i < klines.length; i++) {
      klines[i] = DailyKline(
        date: klines[i].date,
        open: klines[i].open,
        close: klines[i].close,
        high: klines[i].high,
        low: klines[i].low,
        volume: klines[i].volume,
        amount: klines[i].amount,
        preClose: klines[i - 1].close,
      );
    }
    // For the first entry, preClose stays 0 (no prior data).
    return klines;
  }
}

class StockSearchResult {
  final String code;
  final String name;
  final String market;

  const StockSearchResult({
    required this.code,
    required this.name,
    required this.market,
  });

  String get fullCode => '$code.$market';

  factory StockSearchResult.fromJson(Map<String, dynamic> json) {
    // East Money search API format
    return StockSearchResult(
      code: json['Code'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      market: _detectMarket(json['Code'] as String? ?? ''),
    );
  }

  static String _detectMarket(String code) {
    if (code.startsWith('6') || code.startsWith('9')) return 'SH';
    return 'SZ';
  }
}

class StockNews {
  final String id;
  final String stockCode;
  final String title;
  final String source;
  final String sourceUrl;
  final DateTime publishedAt;
  final DateTime fetchedAt;

  const StockNews({
    required this.id,
    required this.stockCode,
    required this.title,
    required this.source,
    required this.sourceUrl,
    required this.publishedAt,
    required this.fetchedAt,
  });

  factory StockNews.fromJson(Map<String, dynamic> json, String stockCode) {
    return StockNews(
      id: json['id'] as String? ?? '',
      stockCode: stockCode,
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? '',
      sourceUrl: json['url'] as String? ?? '',
      publishedAt: json['publishTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['publishTime'] as int)
          : DateTime.now(),
      fetchedAt: DateTime.now(),
    );
  }
}

class StockInfo {
  final String code;
  final String name;
  final String? industry;
  final double? marketCap; // in billions
  final double? peRatio;
  final String? listDate;

  const StockInfo({
    required this.code,
    required this.name,
    this.industry,
    this.marketCap,
    this.peRatio,
    this.listDate,
  });
}
