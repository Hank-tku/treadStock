import 'dart:math';
import '../../stock/domain/stock_models.dart';
import 'analysis_models.dart';
import '../../../core/constants/api_constants.dart';
import '../../strategy/domain/strategy_models.dart';
import '../../strategy/domain/rule_engine.dart';
import '../../strategy/domain/signal_rule.dart';

/// Pure Dart analysis engine for stock technical analysis.
/// Calculates MA, Bollinger Bands, scores, and generates summaries.
/// Supports custom strategy parameters for multi-strategy scoring.
class AnalysisEngine {
  /// Calculate Moving Average.
  List<double> calculateMA(List<double> closes, int period) {
    if (closes.length < period) return [];
    final result = <double>[];
    for (var i = period - 1; i < closes.length; i++) {
      var sum = 0.0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += closes[j];
      }
      result.add(sum / period);
    }
    return result;
  }

  /// Calculate Bollinger Bands.
  BollingerBands calculateBollinger(
    List<double> closes, {
    int period = AppConstants.bollPeriod,
    double stdDev = AppConstants.bollStdDev,
  }) {
    if (closes.length < period) {
      return const BollingerBands(upper: [], middle: [], lower: []);
    }
    final upper = <double>[];
    final middle = <double>[];
    final lower = <double>[];

    for (var i = period - 1; i < closes.length; i++) {
      var sum = 0.0;
      for (var j = i - period + 1; j <= i; j++) {
        sum += closes[j];
      }
      final avg = sum / period;
      middle.add(avg);

      var variance = 0.0;
      for (var j = i - period + 1; j <= i; j++) {
        variance += pow(closes[j] - avg, 2);
      }
      final sd = sqrt(variance / period);
      upper.add(avg + stdDev * sd);
      lower.add(avg - stdDev * sd);
    }

    return BollingerBands(upper: upper, middle: middle, lower: lower);
  }

  /// Calculate volume ratio (量比).
  double _calculateVolRatio(List<DailyKline> klines) {
    if (klines.length < 6) return 1.0;
    // Current day volume vs average of previous 5 days
    final currentVol = klines.last.volume;
    if (currentVol <= 0) return 1.0;

    var avgVol = 0.0;
    final count = min(5, klines.length - 1);
    for (var i = klines.length - count - 1; i < klines.length - 1; i++) {
      avgVol += klines[i].volume;
    }
    avgVol /= count;
    if (avgVol <= 0) return 1.0;

    return currentVol / avgVol;
  }

  /// Calculate MA score (0-10).
  double _calculateMAScore(List<double> closes, List<double> ma20, List<double> ma60) {
    if (closes.isEmpty || ma20.isEmpty || ma60.isEmpty) return 5.0;

    final price = closes.last;
    final currentMA20 = ma20.last;
    final currentMA60 = ma60.last;

    // Bullish alignment: MA20 > MA60 and price above MA20
    if (currentMA20 > currentMA60) {
      if (price > currentMA20) {
        return 9.0; // Strong bullish
      }
      // Price below MA20 but close to it (band low candidate)
      final deviation = ((currentMA20 - price) / currentMA20) * 100;
      if (deviation < 3) {
        return 7.0; // Near support
      }
      return 5.0;
    }

    // Bearish alignment: MA20 < MA60
    if (price > currentMA20) {
      return 4.0; // Potential reversal
    }
    final deviation = ((currentMA20 - price) / currentMA20) * 100;
    if (deviation < 3) {
      return 6.0; // Near MA20 in bearish market
    }
    return 3.0;
  }

  /// Calculate Bollinger score (0-10).
  double _calculateBollScore(List<double> closes, BollingerBands boll) {
    if (closes.isEmpty || boll.currentLower == null) return 5.0;

    final price = closes.last;
    final upper = boll.currentUpper!;
    final lower = boll.currentLower!;

    if (upper == lower) return 5.0;

    // Position within bands (0 = at lower, 1 = at upper)
    final position = (price - lower) / (upper - lower);

    if (position <= 0.1) {
      return 9.0; // At or below lower band (band low)
    } else if (position <= 0.3) {
      return 8.0; // Near lower band
    } else if (position <= 0.4) {
      return 7.0; // Lower half
    } else if (position <= 0.6) {
      return 5.0; // Middle
    } else if (position <= 0.7) {
      return 4.0; // Upper half
    } else if (position <= 0.9) {
      return 2.0; // Near upper band
    } else {
      return 1.0; // At or above upper band (band high)
    }
  }

  /// Calculate volume score (0-10).
  double _calculateVolScore(List<DailyKline> klines) {
    if (klines.isEmpty) return 5.0;

    final volRatio = _calculateVolRatio(klines);
    final changePct = klines.last.changePct;

    // Shrinking volume + declining narrowing ( consolidation bottom )
    if (volRatio < 0.8 && changePct > -1 && changePct < 1) {
      return 8.0;
    }

    // Volume increase + price increase (breakout)
    if (volRatio > 1.5 && changePct > 2) {
      return 8.0;
    }

    // Volume increase + price decrease (distribution)
    if (volRatio > 1.5 && changePct < -2) {
      return 2.0;
    }

    // Normal volume
    if (volRatio >= 0.8 && volRatio <= 1.2) {
      return 5.0;
    }

    return 5.0;
  }

  /// Calculate trend score (0-10).
  double _calculateTrendScore(List<DailyKline> klines) {
    if (klines.length < 5) return 5.0;

    // Count consecutive decline days
    int declineDays = 0;
    for (var i = klines.length - 1; i >= max(0, klines.length - 10); i--) {
      if (klines[i].close < klines[i].open) {
        declineDays++;
      } else {
        break;
      }
    }

    // Count consecutive rise days
    int riseDays = 0;
    for (var i = klines.length - 1; i >= max(0, klines.length - 10); i--) {
      if (klines[i].close > klines[i].open) {
        riseDays++;
      } else {
        break;
      }
    }

    // Consecutive decline 3-5 days then stabilize = oversold bounce expected
    if (declineDays >= 3 && declineDays <= 5) {
      final lastChange = klines.last.changePct;
      if (lastChange > -1 && lastChange < 1) {
        return 8.0; // Stabilizing after decline
      }
      return 7.0;
    }

    // Consecutive rise 5+ days = pullback risk
    if (riseDays >= 5) {
      return 3.0;
    }

    // Oscillating within 3 days
    if (declineDays <= 2 && riseDays <= 2) {
      return 5.0;
    }

    return 5.0;
  }

  /// Calculate comprehensive stock score using default constants (1-10).
  /// Backwards-compatible with existing callers.
  StockScore calculateScore(List<DailyKline> klines) {
    return calculateScoreWithParams(
      klines,
      maShortPeriod: AppConstants.maShortPeriod,
      maLongPeriod: AppConstants.maLongPeriod,
      bollPeriod: AppConstants.bollPeriod,
      bollStdDev: AppConstants.bollStdDev,
      weightMA: AppConstants.weightMA,
      weightBoll: AppConstants.weightBoll,
      weightVol: AppConstants.weightVol,
      weightTrend: AppConstants.weightTrend,
    );
  }

  /// Calculate comprehensive stock score using custom strategy parameters.
  StockScore calculateScoreWithParams(
    List<DailyKline> klines, {
    int maShortPeriod = 20,
    int maLongPeriod = 60,
    int bollPeriod = 20,
    double bollStdDev = 2.0,
    double weightMA = 0.30,
    double weightBoll = 0.30,
    double weightVol = 0.20,
    double weightTrend = 0.20,
  }) {
    if (klines.length < maLongPeriod) {
      return const StockScore(
        score: 0,
        maScore: 0,
        bollScore: 0,
        volScore: 0,
        trendScore: 0,
        isBandLow: false,
        reason: '数据不足',
      );
    }

    final closes = klines.map((k) => k.close).toList();
    final maShort = calculateMA(closes, maShortPeriod);
    final maLong = calculateMA(closes, maLongPeriod);
    final boll = calculateBollinger(closes, period: bollPeriod, stdDev: bollStdDev);

    final maScore = _calculateMAScore(closes, maShort, maLong);
    final bollScore = _calculateBollScore(closes, boll);
    final volScore = _calculateVolScore(klines);
    final trendScore = _calculateTrendScore(klines);

    final rawScore = weightMA * maScore +
        weightBoll * bollScore +
        weightVol * volScore +
        weightTrend * trendScore;

    final score = rawScore.round().clamp(1, 10);

    final isBandLow = bollScore >= 7 && (maScore >= 6 || trendScore >= 7);

    String? reason;
    if (isBandLow) {
      reason = '处于波段低位，均线支撑强';
    } else if (score >= 8) {
      reason = '技术面强势，多头排列';
    } else if (score >= 5) {
      reason = '技术面中性，观望为主';
    } else {
      reason = '技术面偏弱，注意风险';
    }

    return StockScore(
      score: score,
      maScore: maScore.roundToDouble(),
      bollScore: bollScore.roundToDouble(),
      volScore: volScore.roundToDouble(),
      trendScore: trendScore.roundToDouble(),
      isBandLow: isBandLow,
      reason: reason,
    );
  }

  /// Calculate score using a Strategy object.
  StockScore calculateScoreForStrategy(List<DailyKline> klines, Strategy strategy) {
    if (strategy.isRuleBased) {
      return _evaluateWithRules(klines, strategy);
    }
    // Existing weighted logic (unchanged)
    return calculateScoreWithParams(
      klines,
      maShortPeriod: strategy.maShortPeriod,
      maLongPeriod: strategy.maLongPeriod,
      bollPeriod: strategy.bollPeriod,
      bollStdDev: strategy.bollStdDev,
      weightMA: strategy.weightMA,
      weightBoll: strategy.weightBoll,
      weightVol: strategy.weightVol,
      weightTrend: strategy.weightTrend,
    );
  }

  StockScore _evaluateWithRules(List<DailyKline> klines, Strategy strategy) {
    final result = RuleEngine.evaluate(
      klines: klines,
      entryRules: strategy.entryRules!,
      exitRules: strategy.exitRules ?? [],
    );

    // Map rule evaluation to StockScore:
    // - entryTriggered → high score (9)
    // - partial matches → medium score based on percentage of rules passing
    // - exitTriggered → low score (2)
    int score;
    String reason;

    if (result.entryTriggered && !result.exitTriggered) {
      score = 9;
      reason = '信号触发：所有入场条件满足';
    } else if (result.exitTriggered) {
      score = 2;
      reason = '信号触发：出场条件已满足';
    } else {
      // Calculate how many entry rules passed
      final passCount = result.entryResults.where((r) => r).length;
      final total = result.entryResults.length;
      final ratio = total > 0 ? passCount / total : 0.0;
      score = (ratio * 8 + 1).round().clamp(1, 10);
      if (ratio >= 0.8) {
        reason = '大部分信号接近触发';
      } else if (ratio >= 0.5) {
        reason = '部分信号满足，继续观察';
      } else {
        reason = '信号未触发，等待时机';
      }
    }

    // Build indicator detail string for reason
    final indStr = result.indicatorValues.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(1)}')
        .join(', ');
    if (indStr.isNotEmpty) {
      reason = '$reason\n$indStr';
    }

    return StockScore(
      score: score,
      maScore: result.indicatorValues.containsKey('macd') ? (result.entryTriggered ? 9.0 : 5.0) : 0,
      bollScore: result.indicatorValues.containsKey('rsi') ? (result.entryTriggered ? 9.0 : 5.0) : 0,
      volScore: 0,
      trendScore: 0,
      isBandLow: result.entryTriggered,
      reason: reason,
    );
  }

  /// Check if stock is at band low position.
  bool isBandLow(List<DailyKline> klines) {
    if (klines.length < 20) return false;
    final closes = klines.map((k) => k.close).toList();
    final ma20 = calculateMA(closes, AppConstants.maShortPeriod);
    final ma60 = calculateMA(closes, AppConstants.maLongPeriod);
    final boll = calculateBollinger(closes);

    final bollScore = _calculateBollScore(closes, boll);
    final maScore = _calculateMAScore(closes, ma20, ma60);
    final trendScore = _calculateTrendScore(klines);

    return bollScore >= 7 && (maScore >= 6 || trendScore >= 7);
  }

  /// Check downside alert condition.
  bool checkDownsideAlert(List<DailyKline> klines) {
    if (klines.length < 21) return false;

    final closes = klines.map((k) => k.close).toList();
    final ma20 = calculateMA(closes, AppConstants.maShortPeriod);
    final boll = calculateBollinger(closes);
    final volRatio = _calculateVolRatio(klines);
    final lastDay = klines.last;
    final changePct = lastDay.changePct;

    // Condition 1: Price below MA20 and daily drop > 2%
    if (ma20.isNotEmpty && lastDay.close < ma20.last && changePct < -2) {
      return true;
    }

    // Condition 2: Price below Bollinger lower band
    if (boll.currentLower != null && lastDay.close < boll.currentLower!) {
      return true;
    }

    // Condition 3: 3 consecutive down days with volume increase on 3rd day
    if (klines.length >= 3 && volRatio > 1.3) {
      bool threeDown = true;
      for (var i = klines.length - 3; i < klines.length; i++) {
        if (klines[i].close >= klines[i].open) {
          threeDown = false;
          break;
        }
      }
      if (threeDown) return true;
    }

    return false;
  }

  /// Generate daily tracking summary.
  DailySummary generateSummary(List<DailyKline> klines, String stockCode) {
    if (klines.isEmpty) {
      return DailySummary(
        stockCode: stockCode,
        date: DateTime.now().toIso8601String().substring(0, 10),
        openPrice: 0,
        closePrice: 0,
        highPrice: 0,
        lowPrice: 0,
        changePct: 0,
        bandPosition: 'middle',
        prediction: 'flat',
        summaryText: '数据不足，无法生成摘要',
      );
    }

    final lastDay = klines.last;
    final closes = klines.map((k) => k.close).toList();
    final boll = calculateBollinger(closes);
    final ma20 = calculateMA(closes, AppConstants.maShortPeriod);

    String bandPosition = 'middle';
    double? supportPrice;
    double? resistancePrice;

    if (boll.currentLower != null && boll.currentUpper != null) {
      final price = lastDay.close;
      final upper = boll.currentUpper!;
      final lower = boll.currentLower!;

      if (price <= lower) {
        bandPosition = 'lower';
      } else if (price >= upper) {
        bandPosition = 'upper';
      }

      supportPrice = lower;
      resistancePrice = upper;
    }

    if (ma20.isNotEmpty) {
      supportPrice ??= ma20.last;
    }

    // Prediction
    String prediction = 'flat';
    final changePct = lastDay.changePct;
    if (changePct > 1) {
      prediction = 'up';
    } else if (changePct < -1) {
      prediction = 'down';
    }

    // Summary text
    final buffer = StringBuffer();
    buffer.writeln('收盘价 ${_formatPrice(lastDay.close)}，涨幅 ${_formatPct(changePct)}');
    buffer.write('波段位置：');

    switch (bandPosition) {
      case 'upper':
        buffer.writeln('上轨附近');
        break;
      case 'lower':
        buffer.writeln('下轨附近（波段低位）');
        break;
      default:
        buffer.writeln('中轨附近');
    }

    if (supportPrice != null) {
      buffer.write('支撑位 ${_formatPrice(supportPrice)}');
    }
    if (resistancePrice != null) {
      buffer.write('，压力位 ${_formatPrice(resistancePrice)}');
    }

    switch (prediction) {
      case 'up':
        buffer.write('\n预计明日继续震荡上行');
        break;
      case 'down':
        buffer.write('\n预计明日可能继续调整');
        break;
      default:
        buffer.write('\n预计明日继续震荡');
    }

    return DailySummary(
      stockCode: stockCode,
      date: DateTime.now().toIso8601String().substring(0, 10),
      openPrice: lastDay.open,
      closePrice: lastDay.close,
      highPrice: lastDay.high,
      lowPrice: lastDay.low,
      changePct: changePct,
      bandPosition: bandPosition,
      prediction: prediction,
      supportPrice: supportPrice,
      resistancePrice: resistancePrice,
      summaryText: buffer.toString(),
    );
  }

  String _formatPrice(double price) => price.toStringAsFixed(2);

  String _formatPct(double pct) {
    final prefix = pct >= 0 ? '+' : '';
    return '$prefix${pct.toStringAsFixed(2)}%';
  }
}
