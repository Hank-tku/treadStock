import '../../analysis/domain/indicator_calculator.dart';
import '../../stock/domain/stock_models.dart';
import 'signal_rule.dart';

class RuleEvaluationResult {
  final bool entryTriggered;
  final bool exitTriggered;
  final List<bool> entryResults;
  final List<bool> exitResults;
  final Map<String, double> indicatorValues;
  final Map<String, double> prevIndicatorValues;

  const RuleEvaluationResult({
    required this.entryTriggered,
    required this.exitTriggered,
    required this.entryResults,
    required this.exitResults,
    required this.indicatorValues,
    required this.prevIndicatorValues,
  });
}

class RuleEngine {
  /// Evaluate entry/exit rules against the latest kline data.
  ///
  /// Supports both flat rule lists (legacy AND/OR) and grouped rules.
  /// - Flat entry rules: all must pass (AND)
  /// - Grouped entry rules: any group must fully pass (OR of ANDs)
  /// - Flat exit rules: any must pass (OR)
  /// - Grouped exit rules: any group must fully pass (OR of ANDs)
  static RuleEvaluationResult evaluate({
    required List<DailyKline> klines,
    required List<SignalRule> entryRules,
    List<SignalRule> exitRules = const [],
    List<RuleGroup>? entryGroups,
    List<RuleGroup>? exitGroups,
    int rsiPeriod = 14,
    int macdFast = 12,
    int macdSlow = 26,
    int macdSignal = 9,
    int kdjPeriod = 9,
    int emaPeriod = 20,
    int atrPeriod = 14,
    int maShortPeriod = 5,
    int maLongPeriod = 20,
  }) {
    // Compute indicators
    final closes = klines.map((k) => k.close).toList();
    final rsiValues = IndicatorCalculator.calculateRSI(closes, period: rsiPeriod);
    final macdResult = IndicatorCalculator.calculateMACD(
      closes,
      fastPeriod: macdFast,
      slowPeriod: macdSlow,
      signalPeriod: macdSignal,
    );
    final kdjResult = IndicatorCalculator.calculateKDJ(klines, period: kdjPeriod);

    // New indicators
    final emaValues = IndicatorCalculator.calculateEMA(closes, period: emaPeriod);
    final atrValues = IndicatorCalculator.calculateATR(klines, period: atrPeriod);
    final obvValues = IndicatorCalculator.calculateOBV(klines);

    // MA lines for indicator cross (MA_short and MA_long)
    final maShortValues = IndicatorCalculator.computeEMA(closes, maShortPeriod);
    final maLongValues = IndicatorCalculator.computeEMA(closes, maLongPeriod);

    // Build current + previous indicator value maps
    final current = <String, double>{};
    final prev = <String, double>{};

    if (rsiValues.isNotEmpty) {
      current['rsi'] = rsiValues.last;
      if (rsiValues.length >= 2) prev['rsi'] = rsiValues[rsiValues.length - 2];
    }
    if (macdResult.macdLine.isNotEmpty) {
      current['macd'] = macdResult.macdLine.last;
      if (macdResult.macdLine.length >= 2) {
        prev['macd'] = macdResult.macdLine[macdResult.macdLine.length - 2];
      }
    }
    if (macdResult.signalLine.isNotEmpty) {
      current['macd_signal'] = macdResult.signalLine.last;
      if (macdResult.signalLine.length >= 2) {
        prev['macd_signal'] = macdResult.signalLine[macdResult.signalLine.length - 2];
      }
    }
    if (macdResult.histogram.isNotEmpty) {
      current['macd_hist'] = macdResult.histogram.last;
      if (macdResult.histogram.length >= 2) {
        prev['macd_hist'] = macdResult.histogram[macdResult.histogram.length - 2];
      }
    }
    if (kdjResult.kValues.isNotEmpty) {
      current['k'] = kdjResult.kValues.last;
      current['d'] = kdjResult.dValues.last;
      current['j'] = kdjResult.jValues.last;
      if (kdjResult.kValues.length >= 2) {
        prev['k'] = kdjResult.kValues[kdjResult.kValues.length - 2];
        prev['d'] = kdjResult.dValues[kdjResult.dValues.length - 2];
      }
    }

    // EMA
    if (emaValues.isNotEmpty) {
      current['ema'] = emaValues.last;
      if (emaValues.length >= 2) prev['ema'] = emaValues[emaValues.length - 2];
    }

    // ATR
    if (atrValues.isNotEmpty) {
      current['atr'] = atrValues.last;
      if (atrValues.length >= 2) prev['atr'] = atrValues[atrValues.length - 2];
    }

    // OBV
    if (obvValues.isNotEmpty) {
      current['obv'] = obvValues.last;
      if (obvValues.length >= 2) prev['obv'] = obvValues[obvValues.length - 2];
    }

    // MA lines for indicator cross
    if (maShortValues.isNotEmpty) {
      current['ma_short'] = maShortValues.last;
      if (maShortValues.length >= 2) prev['ma_short'] = maShortValues[maShortValues.length - 2];
    }
    if (maLongValues.isNotEmpty) {
      current['ma_long'] = maLongValues.last;
      if (maLongValues.length >= 2) prev['ma_long'] = maLongValues[maLongValues.length - 2];
    }

    // Bollinger Bands position
    final boll = IndicatorCalculator.calculateBollingerBands(closes);
    if (boll != null) {
      current['boll_position'] = IndicatorCalculator.calculateBollPosition(
        closes.last,
        boll.upper,
        boll.lower,
      );
    }

    // MA alignment
    current['ma_alignment'] = IndicatorCalculator.calculateMAAlignment(closes);

    // Volume-price divergence
    current['vol_price_divergence'] =
        IndicatorCalculator.calculateVolumePriceDivergence(klines);

    // Volume ratio
    current['vol_ratio'] = IndicatorCalculator.calculateVolumeRatio(klines);

    // Evaluate a single rule
    bool evalRule(SignalRule rule) {
      // Indicator-vs-indicator cross
      if (rule.isIndicatorCross && rule.indicator2 != null) {
        final curA = current[rule.indicator];
        final prevA = prev[rule.indicator];
        final curB = current[rule.indicator2];
        final prevB = prev[rule.indicator2];
        if (curA == null || prevA == null || curB == null || prevB == null) {
          return false;
        }
        return rule.evaluateIndicatorCross(
          prevA: prevA,
          curA: curA,
          prevB: prevB,
          curB: curB,
        );
      }

      // Standard evaluation
      final val = current[rule.indicator];
      final prevVal = prev[rule.indicator];
      if (val == null) return false;
      if (rule.condition == 'cross_up' || rule.condition == 'cross_down') {
        if (prevVal == null) return false;
        return rule.evaluateWithPrev(prevVal, val);
      }
      return rule.evaluate(val);
    }

    final entryResults = entryRules.map(evalRule).toList();
    final exitResults = exitRules.map(evalRule).toList();

    // Evaluate rule groups (OR of ANDs)
    bool entryFromGroups = false;
    bool exitFromGroups = false;

    if (entryGroups != null && entryGroups.isNotEmpty) {
      entryFromGroups = entryGroups.any(
        (group) => group.rules.isNotEmpty && group.rules.every(evalRule),
      );
    }
    if (exitGroups != null && exitGroups.isNotEmpty) {
      exitFromGroups = exitGroups.any(
        (group) => group.rules.isNotEmpty && group.rules.every(evalRule),
      );
    }

    final entryTriggered = entryResults.isNotEmpty
        ? entryResults.every((r) => r) || entryFromGroups
        : entryFromGroups;
    final exitTriggered = exitResults.isNotEmpty
        ? exitResults.any((r) => r) || exitFromGroups
        : exitFromGroups;

    return RuleEvaluationResult(
      entryTriggered: entryTriggered,
      exitTriggered: exitTriggered,
      entryResults: entryResults,
      exitResults: exitResults,
      indicatorValues: current,
      prevIndicatorValues: prev,
    );
  }
}
