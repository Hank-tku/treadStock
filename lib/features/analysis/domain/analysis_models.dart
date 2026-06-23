// Scoring and analysis result models.

// ── Prediction Models ────────────────────────────────────────────

/// Predicted direction for the next trading session.
enum PredictionDirection {
  up('看涨'),
  down('看跌'),
  flat('震荡');

  final String label;
  const PredictionDirection(this.label);
}

/// Next trading day prediction for a stock.
/// Generated before 15:00 on trading days using current day's TA data,
/// predicts the direction of the next trading session.
class StockPrediction {
  final PredictionDirection direction;
  final double confidence; // 0.0 - 1.0
  final double? targetHigh; // predicted high for next trading day
  final double? targetLow; // predicted low for next trading day
  final double? supportPrice;
  final double? resistancePrice;
  final String summary; // human-readable prediction text (next trading day)
  final DateTime generatedAt;

  /// Date this prediction targets (the next trading day).
  /// Generated before 15:00 today → targets tomorrow (or next weekday if Friday).
  DateTime get targetDate {
    final t = generatedAt;
    final d = DateTime(t.year, t.month, t.day);
    // After 15:00 the data is same-day close; prediction still targets next day
    if (d.weekday == DateTime.friday) {
      return d.add(const Duration(days: 3)); // Friday → next Monday
    } else if (d.weekday == DateTime.saturday) {
      return d.add(const Duration(days: 2));
    } else if (d.weekday == DateTime.sunday) {
      return d.add(const Duration(days: 1));
    }
    return d.add(const Duration(days: 1)); // Mon-Thu → next day
  }

  const StockPrediction({
    required this.direction,
    required this.confidence,
    this.targetHigh,
    this.targetLow,
    this.supportPrice,
    this.resistancePrice,
    required this.summary,
    required this.generatedAt,
  });

  /// Short prediction tag like "看涨 68%"
  String get tag => '${direction.label} ${(confidence * 100).round()}%';

  /// Target date label, e.g. "明日(6/17)" or "下周一(6/23)"
  String get targetDateLabel {
    final d = targetDate;
    final weekDays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isTomorrow = d.difference(today).inDays == 1;
    if (isTomorrow) {
      return '明日(${d.month}/${d.day})';
    }
    return '${weekDays[d.weekday]}(${d.month}/${d.day})';
  }

  /// Predicted range string like "12.50 - 13.20"
  String? get rangeText {
    if (targetLow == null || targetHigh == null) return null;
    return '${targetLow!.toStringAsFixed(2)} - ${targetHigh!.toStringAsFixed(2)}';
  }
}

// ── Scoring Models ───────────────────────────────────────────────

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

/// Structured result of a downside-alert evaluation.
///
/// `checkDownsideAlert` returns a plain bool for backward compatibility; this
/// richer result is produced by `evaluateDownsideAlert` and carries the reason
/// plus reference support/resistance levels so the notification and UI can
/// show context instead of a bare flag.
class DownsideAlertResult {
  final bool triggered;
  final String reason;
  final double? supportPrice;
  final double? resistancePrice;

  const DownsideAlertResult({
    required this.triggered,
    this.reason = '',
    this.supportPrice,
    this.resistancePrice,
  });

  static const DownsideAlertResult empty = DownsideAlertResult(triggered: false);
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
  final StockPrediction? prediction; // next-session prediction

  const DailyRecommendation({
    required this.code,
    required this.name,
    required this.market,
    required this.category,
    required this.closePrice,
    required this.changePct,
    this.score,
    this.isBandLow = false,
    this.prediction,
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
  // User-configured price alert threshold (persisted). Null = no price alert.
  final double? alertPriceThreshold;
  // ISO date "YYYY-MM-DD" of the last fired alert (persisted, de-dup per day).
  final String? alertTriggeredDate;
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
    this.alertPriceThreshold,
    this.alertTriggeredDate,
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
    double? alertPriceThreshold,
    String? alertTriggeredDate,
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
      alertPriceThreshold: alertPriceThreshold ?? this.alertPriceThreshold,
      alertTriggeredDate: alertTriggeredDate ?? this.alertTriggeredDate,
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
