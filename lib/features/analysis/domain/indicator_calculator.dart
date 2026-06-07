import 'dart:math';
import 'package:stockpilot/features/stock/domain/stock_models.dart';

/// Result container for MACD calculation.
class MACDResult {
  final List<double> macdLine;
  final List<double> signalLine;
  final List<double> histogram;
  const MACDResult({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });
}

/// Result container for KDJ calculation.
class KDJResult {
  final List<double> kValues;
  final List<double> dValues;
  final List<double> jValues;
  const KDJResult({
    required this.kValues,
    required this.dValues,
    required this.jValues,
  });
}

/// Pure function technical indicator calculator.
/// All methods are static and side-effect free.
class IndicatorCalculator {
  IndicatorCalculator._();

  /// Calculate RSI (Relative Strength Index) using Wilder's smoothing.
  /// Returns a list of RSI values. Length = closes.length - period.
  static List<double> calculateRSI(List<double> closes, {int period = 14}) {
    if (closes.length < period + 1) return [];

    final rsiValues = <double>[];

    // First: simple average of gains and losses
    double avgGain = 0;
    double avgLoss = 0;
    for (var i = 1; i <= period; i++) {
      final change = closes[i] - closes[i - 1];
      if (change > 0) {
        avgGain += change;
      } else {
        avgLoss += change.abs();
      }
    }
    avgGain /= period;
    avgLoss /= period;

    // First RSI value
    if (avgLoss == 0) {
      rsiValues.add(100.0);
    } else {
      final rs = avgGain / avgLoss;
      rsiValues.add(100 - (100 / (1 + rs)));
    }

    // Subsequent: Wilder smoothing
    for (var i = period + 1; i < closes.length; i++) {
      final change = closes[i] - closes[i - 1];
      final gain = change > 0 ? change : 0.0;
      final loss = change < 0 ? change.abs() : 0.0;

      avgGain = (avgGain * (period - 1) + gain) / period;
      avgLoss = (avgLoss * (period - 1) + loss) / period;

      if (avgLoss == 0) {
        rsiValues.add(100.0);
      } else {
        final rs = avgGain / avgLoss;
        rsiValues.add(100 - (100 / (1 + rs)));
      }
    }

    return rsiValues;
  }

  /// Compute EMA over [values] with the given [period].
  /// Returns a list of the same length as [values] starting from index period-1.
  static List<double> _computeEMA(List<double> values, int period) {
    if (values.length < period) return [];
    final k = 2.0 / (period + 1);
    final ema = <double>[];
    // First EMA value = SMA of first `period` values
    double sum = 0;
    for (var i = 0; i < period; i++) {
      sum += values[i];
    }
    ema.add(sum / period);
    // Subsequent EMA values
    for (var i = period; i < values.length; i++) {
      ema.add(values[i] * k + ema.last * (1 - k));
    }
    return ema;
  }

  /// Calculate MACD (Moving Average Convergence Divergence).
  static MACDResult calculateMACD(
    List<double> closes, {
    int fastPeriod = 12,
    int slowPeriod = 26,
    int signalPeriod = 9,
  }) {
    if (closes.length < slowPeriod + signalPeriod) {
      return const MACDResult(macdLine: [], signalLine: [], histogram: []);
    }

    // Calculate fast and slow EMA (both indexed from their respective start)
    final fastEMA = _computeEMA(closes, fastPeriod);
    final slowEMA = _computeEMA(closes, slowPeriod);

    // MACD line: fastEMA - slowEMA, starting where both are available
    // fastEMA has length closes.length - fastPeriod + 1, starting at fastPeriod-1
    // slowEMA has length closes.length - slowPeriod + 1, starting at slowPeriod-1
    // Both align at slowPeriod-1, so we take from that point
    final offset = slowPeriod - fastPeriod; // indices into fastEMA to skip
    final macdLine = <double>[];
    for (var i = 0; i < slowEMA.length; i++) {
      macdLine.add(fastEMA[i + offset] - slowEMA[i]);
    }

    // Signal line = EMA of MACD line
    final signalLine = _computeEMA(macdLine, signalPeriod);

    // Histogram = MACD - Signal (aligned from signal start)
    final histOffset = macdLine.length - signalLine.length;
    final histogram = <double>[];
    for (var i = 0; i < signalLine.length; i++) {
      histogram.add(macdLine[i + histOffset] - signalLine[i]);
    }

    return MACDResult(macdLine: macdLine, signalLine: signalLine, histogram: histogram);
  }

  /// Calculate KDJ (Stochastic Oscillator).
  /// Returns K, D, J values. Output length = klines.length - period + 1.
  static KDJResult calculateKDJ(
    List<DailyKline> klines, {
    int period = 9,
    int kSmooth = 3,
    int dSmooth = 3,
  }) {
    if (klines.length < period) {
      return const KDJResult(kValues: [], dValues: [], jValues: []);
    }

    final kValues = <double>[];
    final dValues = <double>[];
    final jValues = <double>[];

    double prevK = 50.0;
    double prevD = 50.0;

    for (var i = period - 1; i < klines.length; i++) {
      // Find highest high and lowest low in the period window
      double highN = klines[i - period + 1].high;
      double lowN = klines[i - period + 1].low;
      for (var j = i - period + 2; j <= i; j++) {
        if (klines[j].high > highN) highN = klines[j].high;
        if (klines[j].low < lowN) lowN = klines[j].low;
      }

      // RSV
      final rsv = highN == lowN ? 50.0 : (klines[i].close - lowN) / (highN - lowN) * 100;

      // K = smoothed RSV
      final k = (kSmooth - 1) / kSmooth * prevK + 1 / kSmooth * rsv;

      // D = smoothed K
      final d = (dSmooth - 1) / dSmooth * prevD + 1 / dSmooth * k;

      // J = 3K - 2D
      final j = 3 * k - 2 * d;

      kValues.add(k);
      dValues.add(d);
      jValues.add(j);

      prevK = k;
      prevD = d;
    }

    return KDJResult(kValues: kValues, dValues: dValues, jValues: jValues);
  }

  /// Calculate Bollinger Band relative position of [price].
  /// Returns 0.0 when price is at [lower], 1.0 when at [upper].
  static double calculateBollPosition(double price, double upper, double lower) {
    if (upper == lower) return 0.5;
    return ((price - lower) / (upper - lower)).clamp(0.0, 1.0);
  }

  /// Compute a single Simple Moving Average value for the last [period] items.
  static double? _sma(List<double> values, int period) {
    if (values.length < period) return null;
    var sum = 0.0;
    for (var i = values.length - period; i < values.length; i++) {
      sum += values[i];
    }
    return sum / period;
  }

  /// Calculate Bollinger Bands (upper, middle, lower) for the latest data point.
  /// Returns a record (upper, middle, lower) or null if insufficient data.
  static ({double upper, double middle, double lower})? calculateBollingerBands(
    List<double> closes, {
    int period = 20,
    double stdDev = 2.0,
  }) {
    if (closes.length < period) return null;

    // Calculate SMA for the last `period` closes
    var sum = 0.0;
    for (var i = closes.length - period; i < closes.length; i++) {
      sum += closes[i];
    }
    final middle = sum / period;

    var variance = 0.0;
    for (var i = closes.length - period; i < closes.length; i++) {
      variance += pow(closes[i] - middle, 2);
    }
    final sd = sqrt(variance / period);
    return (upper: middle + stdDev * sd, middle: middle, lower: middle - stdDev * sd);
  }

  /// Calculate MA alignment score (0.0–10.0).
  /// 10.0 = perfect bullish alignment (MA5 > MA10 > MA20 > MA60).
  /// Each satisfied adjacent pair adds 2.5.
  /// Returns 5.0 if data is insufficient for any MA.
  static double calculateMAAlignment(
    List<double> closes, {
    List<int> periods = const [5, 10, 20, 60],
  }) {
    // Compute the MA for each period
    final mas = <double>[];
    for (final p in periods) {
      final ma = _sma(closes, p);
      if (ma == null) return 5.0; // insufficient data
      mas.add(ma);
    }

    // Check adjacent pairs: mas[0] > mas[1] > mas[2] > mas[3]
    var score = 0.0;
    final pairs = periods.length - 1; // 3 pairs
    final scorePerPair = 10.0 / pairs;
    for (var i = 0; i < pairs; i++) {
      if (mas[i] > mas[i + 1]) {
        score += scorePerPair;
      }
    }
    return score;
  }

  /// Detect volume-price divergence over [lookback] days.
  /// Returns 1 if divergence detected, 0 otherwise.
  /// - Price up + volume down (>=3 days each) = top divergence (顶背离)
  /// - Price down + volume up (>=3 days each) = bottom divergence (底背离)
  static double calculateVolumePriceDivergence(
    List<DailyKline> klines, {
    int lookback = 5,
  }) {
    if (klines.length < lookback + 1) return 0;

    final recent = klines.sublist(klines.length - lookback);

    // Count price-up days and volume-down days
    int priceUpDays = 0;
    int priceDownDays = 0;
    int volUpDays = 0;
    int volDownDays = 0;

    for (var i = 0; i < recent.length; i++) {
      if (i == 0) {
        // Use close vs open for the first day comparison (no prior day in window)
        // Skip first day for trend counting; we need day-over-day changes
        continue;
      }
      if (recent[i].close > recent[i - 1].close) {
        priceUpDays++;
      } else if (recent[i].close < recent[i - 1].close) {
        priceDownDays++;
      }
      if (recent[i].volume > recent[i - 1].volume) {
        volUpDays++;
      } else if (recent[i].volume < recent[i - 1].volume) {
        volDownDays++;
      }
    }

    // Top divergence: price rising but volume shrinking
    if (priceUpDays >= 3 && volDownDays >= 3) return 1;
    // Bottom divergence: price falling but volume expanding
    if (priceDownDays >= 3 && volUpDays >= 3) return 1;

    return 0;
  }

  /// Calculate volume ratio (量比): current day volume / avg of previous [avgDays] days.
  static double calculateVolumeRatio(List<DailyKline> klines, {int avgDays = 5}) {
    if (klines.length < avgDays + 1) return 1.0;
    final currentVol = klines.last.volume;
    if (currentVol <= 0) return 1.0;

    var avgVol = 0.0;
    final count = min(avgDays, klines.length - 1);
    for (var i = klines.length - count - 1; i < klines.length - 1; i++) {
      avgVol += klines[i].volume;
    }
    avgVol /= count;
    if (avgVol <= 0) return 1.0;

    return currentVol / avgVol;
  }
}
