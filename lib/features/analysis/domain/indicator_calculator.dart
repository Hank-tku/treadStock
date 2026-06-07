import 'dart:math';

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
}
