import 'dart:math';

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
}
