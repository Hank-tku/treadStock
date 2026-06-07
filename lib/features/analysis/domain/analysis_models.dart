// Scoring and analysis result models.

class StockScore {
  final int score; // 1-10
  final double maScore;
  final double bollScore;
  final double volScore;
  final double trendScore;
  final bool isBandLow;
  final String? reason;

  const StockScore({
    required this.score,
    required this.maScore,
    required this.bollScore,
    required this.volScore,
    required this.trendScore,
    required this.isBandLow,
    this.reason,
  });

  String get label {
    if (score >= 8) return '重点观察';
    if (score >= 5) return '中性观望';
    return '风险较高';
  }

  String get category {
    if (isBandLow && score >= 7) return 'short_term';
    if (score >= 5) return 'mid_term';
    return 'mid_term';
  }
}

class BollingerBands {
  final List<double> upper;
  final List<double> middle;
  final List<double> lower;

  const BollingerBands({
    required this.upper,
    required this.middle,
    required this.lower,
  });

  double? get currentUpper => upper.isNotEmpty ? upper.last : null;
  double? get currentMiddle => middle.isNotEmpty ? middle.last : null;
  double? get currentLower => lower.isNotEmpty ? lower.last : null;
}

class DailyRecommendation {
  final String code;
  final String name;
  final String market;
  final String category; // "short_term" / "mid_term"
  final double closePrice;
  final double changePct;
  final StockScore? score;
  final bool isBandLow;

  const DailyRecommendation({
    required this.code,
    required this.name,
    required this.market,
    required this.category,
    required this.closePrice,
    required this.changePct,
    this.score,
    this.isBandLow = false,
  });

  String get fullCode => '$code.$market';
}

class DailySummary {
  final String stockCode;
  final String date;
  final double openPrice;
  final double closePrice;
  final double highPrice;
  final double lowPrice;
  final double changePct;
  final String bandPosition; // "upper" / "middle" / "lower"
  final String prediction; // "up" / "down" / "flat"
  final double? supportPrice;
  final double? resistancePrice;
  final String summaryText;

  const DailySummary({
    required this.stockCode,
    required this.date,
    required this.openPrice,
    required this.closePrice,
    required this.highPrice,
    required this.lowPrice,
    required this.changePct,
    required this.bandPosition,
    required this.prediction,
    this.supportPrice,
    this.resistancePrice,
    required this.summaryText,
  });
}

class WatchlistItem {
  final String id;
  final String stockCode;
  final String stockName;
  final String market;
  final bool isPinned;
  final int sortOrder;
  final bool alertEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Real-time data (not persisted)
  double? currentPrice;
  double? currentChangePct;
  StockScore? currentScore;
  bool? isAlertTriggered;
  double? supportPrice;
  double? resistancePrice;

  WatchlistItem({
    required this.id,
    required this.stockCode,
    required this.stockName,
    required this.market,
    this.isPinned = false,
    this.sortOrder = 0,
    this.alertEnabled = true,
    required this.createdAt,
    required this.updatedAt,
    this.currentPrice,
    this.currentChangePct,
    this.currentScore,
    this.isAlertTriggered,
    this.supportPrice,
    this.resistancePrice,
  });

  String get fullCode => '$stockCode.$market';

  WatchlistItem copyWith({
    bool? isPinned,
    int? sortOrder,
    bool? alertEnabled,
    double? currentPrice,
    double? currentChangePct,
    StockScore? currentScore,
    bool? isAlertTriggered,
    double? supportPrice,
    double? resistancePrice,
  }) {
    return WatchlistItem(
      id: id,
      stockCode: stockCode,
      stockName: stockName,
      market: market,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      currentPrice: currentPrice ?? this.currentPrice,
      currentChangePct: currentChangePct ?? this.currentChangePct,
      currentScore: currentScore ?? this.currentScore,
      isAlertTriggered: isAlertTriggered ?? this.isAlertTriggered,
      supportPrice: supportPrice ?? this.supportPrice,
      resistancePrice: resistancePrice ?? this.resistancePrice,
    );
  }
}
