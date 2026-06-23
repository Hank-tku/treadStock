/// Stock filter configuration for strategy-specific candidate pools.
///
/// Each strategy can define its own filter criteria so that different strategies
/// scan different segments of the market (e.g., large-cap only, tech sector only).
class StockFilter {
  /// Market cap range in 亿元 (hundred-million CNY).
  /// e.g. [100, 5000] = 100亿~5000亿. Null means no market-cap filter.
  /// Source: StockQuote.marketCap (Eastmoney f20 ÷ 1e8).
  final (double, double)? marketCapRange;

  /// Industry/board filter (e.g., ['电子', '计算机'])
  final List<String>? industries;

  /// Daily change % range (e.g., [-3.0, 5.0])
  final (double, double)? changeRange;

  /// Turnover rate range (e.g., [1.0, 20.0])
  final (double, double)? turnoverRange;

  /// Only include stocks above this price (CNY)
  final double? minPrice;

  /// Only include stocks below this price (CNY)
  final double? maxPrice;

  /// Only include stocks traded on specific boards.
  /// Values: 'main' (沪深主板), 'gem' (创业板), 'star' (科创板), 'bse' (北交所)
  final List<String>? boards;

  const StockFilter({
    this.marketCapRange,
    this.industries,
    this.changeRange,
    this.turnoverRange,
    this.minPrice,
    this.maxPrice,
    this.boards,
  });

  /// Whether this filter has any active criteria.
  bool get isActive =>
      marketCapRange != null ||
      (industries != null && industries!.isNotEmpty) ||
      changeRange != null ||
      turnoverRange != null ||
      minPrice != null ||
      maxPrice != null ||
      (boards != null && boards!.isNotEmpty);

  /// Human-readable description of the filter.
  String get description {
    final parts = <String>[];
    if (marketCapRange != null) {
      parts.add(
        '市值${marketCapRange!.$1.toInt()}~${marketCapRange!.$2.toInt()}亿',
      );
    }
    if (industries != null && industries!.isNotEmpty) {
      parts.add(industries!.join('/'));
    }
    if (changeRange != null) {
      parts.add('涨幅${changeRange!.$1}%~${changeRange!.$2}%');
    }
    if (turnoverRange != null) {
      parts.add('换手${turnoverRange!.$1}%~${turnoverRange!.$2}%');
    }
    if (minPrice != null || maxPrice != null) {
      final lo = minPrice?.toInt() ?? 0;
      final hi = maxPrice?.toInt() ?? 9999;
      parts.add('价格$lo~$hi元');
    }
    if (boards != null && boards!.isNotEmpty) {
      final labels = boards!.map((b) => const {
            'main': '主板',
            'gem': '创业板',
            'star': '科创板',
            'bse': '北交所',
          }[b] ?? b);
      parts.add(labels.join('/'));
    }
    return parts.isEmpty ? '全市场' : parts.join(' · ');
  }

  StockFilter copyWith({
    (double, double)? marketCapRange,
    List<String>? industries,
    (double, double)? changeRange,
    (double, double)? turnoverRange,
    double? minPrice,
    double? maxPrice,
    List<String>? boards,
  }) {
    return StockFilter(
      marketCapRange: marketCapRange ?? this.marketCapRange,
      industries: industries ?? this.industries,
      changeRange: changeRange ?? this.changeRange,
      turnoverRange: turnoverRange ?? this.turnoverRange,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      boards: boards ?? this.boards,
    );
  }

  /// Clear a specific filter dimension by returning null for it.
  StockFilter clear({
    bool clearMarketCap = false,
    bool clearIndustries = false,
    bool clearChange = false,
    bool clearTurnover = false,
    bool clearPrice = false,
    bool clearBoards = false,
  }) {
    return StockFilter(
      marketCapRange: clearMarketCap ? null : marketCapRange,
      industries: clearIndustries ? null : industries,
      changeRange: clearChange ? null : changeRange,
      turnoverRange: clearTurnover ? null : turnoverRange,
      minPrice: clearPrice ? null : minPrice,
      maxPrice: clearPrice ? null : maxPrice,
      boards: clearBoards ? null : boards,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (marketCapRange != null) {
      data['marketCapRange'] = [marketCapRange!.$1, marketCapRange!.$2];
    }
    if (industries != null && industries!.isNotEmpty) {
      data['industries'] = industries;
    }
    if (changeRange != null) {
      data['changeRange'] = [changeRange!.$1, changeRange!.$2];
    }
    if (turnoverRange != null) {
      data['turnoverRange'] = [turnoverRange!.$1, turnoverRange!.$2];
    }
    if (minPrice != null) data['minPrice'] = minPrice;
    if (maxPrice != null) data['maxPrice'] = maxPrice;
    if (boards != null && boards!.isNotEmpty) data['boards'] = boards;
    return data;
  }

  factory StockFilter.fromJson(Map<String, dynamic> json) {
    return StockFilter(
      marketCapRange: json['marketCapRange'] != null
          ? ((json['marketCapRange'] as List)[0] as num).toDouble() == 0 &&
                  ((json['marketCapRange'] as List)[1] as num).toDouble() == 0
              ? null
              : (
                  ((json['marketCapRange'] as List)[0] as num).toDouble(),
                  ((json['marketCapRange'] as List)[1] as num).toDouble(),
                )
          : null,
      industries: (json['industries'] as List?)?.cast<String>(),
      changeRange: json['changeRange'] != null
          ? (
              ((json['changeRange'] as List)[0] as num).toDouble(),
              ((json['changeRange'] as List)[1] as num).toDouble(),
            )
          : null,
      turnoverRange: json['turnoverRange'] != null
          ? (
              ((json['turnoverRange'] as List)[0] as num).toDouble(),
              ((json['turnoverRange'] as List)[1] as num).toDouble(),
            )
          : null,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      boards: (json['boards'] as List?)?.cast<String>(),
    );
  }
}
