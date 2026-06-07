# Strategy v3: Signal Rules + Indicator Expansion Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Upgrade the strategy module from fixed 4-dimension weighted scoring to a flexible signal-rule based system with expanded technical indicators (RSI, MACD, KDJ).

**Architecture:** Introduce a new `IndicatorCalculator` class for pure indicator computation, a `SignalRule` model for declarative entry/exit conditions, and a `RuleEngine` that evaluates rules against indicator values. The existing `AnalysisEngine` becomes a thin facade delegating to these new components. Backward compatibility is maintained — old Strategy objects continue to work via automatic conversion to default signal rules.

**Tech Stack:** Flutter/Dart, Drift SQLite, Riverpod, flutter_test

---

## Task 1: Create IndicatorCalculator — RSI

**Objective:** Add RSI(14) calculation as a pure function in a new `IndicatorCalculator` class.

**Files:**
- Create: `lib/features/analysis/domain/indicator_calculator.dart`
- Test: `test/unit/indicator_calculator_test.dart`

**Step 1: Write failing tests**

```dart
// test/unit/indicator_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/analysis/domain/indicator_calculator.dart';

void main() {
  group('IndicatorCalculator.calculateRSI', () {
    test('returns empty list when closes length < period + 1', () {
      final rsi = IndicatorCalculator.calculateRSI([10, 20, 30], period: 14);
      expect(rsi, isEmpty);
    });

    test('returns RSI values with correct length', () {
      // 20 data points, period 14 → should produce 5 RSI values
      final closes = List.generate(20, (i) => 100.0 + i);
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      expect(rsi.length, 5);
    });

    test('all gains no losses gives RSI = 100', () {
      final closes = List.generate(30, (i) => (i + 1).toDouble());
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      expect(rsi.last, closeTo(100.0, 0.01));
    });

    test('all losses no gains gives RSI = 0', () {
      final closes = List.generate(30, (i) => (30 - i).toDouble());
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      expect(rsi.last, closeTo(0.0, 0.01));
    });

    test('mixed price changes gives RSI between 0 and 100', () {
      // Alternating up/down with slight uptrend
      final closes = <double>[100];
      for (var i = 1; i < 30; i++) {
        closes.add(closes.last + (i.isEven ? 2 : -1));
      }
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      for (final value in rsi) {
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThanOrEqualTo(100));
      }
    });

    test('uses Wilder smoothing (exponential)', () {
      // After first RSI, subsequent values use smoothed avg gain/loss
      final closes = <double>[50];
      for (var i = 1; i < 30; i++) {
        closes.add(closes.last * 1.02); // steady 2% gains
      }
      final rsi = IndicatorCalculator.calculateRSI(closes, period: 14);
      // RSI should be very high but not exactly 100 due to smoothing
      expect(rsi.last, greaterThan(90));
    });
  });
}
```

**Step 2: Run test to verify failure**

Run: `cd ~/code/stock && flutter test test/unit/indicator_calculator_test.dart --reporter compact`
Expected: FAIL — indicator_calculator.dart does not exist

**Step 3: Write minimal implementation**

```dart
// lib/features/analysis/domain/indicator_calculator.dart
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
```

**Step 4: Run test to verify pass**

Run: `cd ~/code/stock && flutter test test/unit/indicator_calculator_test.dart --reporter compact`
Expected: 6 passed

**Step 5: Run full suite to verify no regressions**

Run: `cd ~/code/stock && flutter test --reporter compact`
Expected: 224 passed (218 existing + 6 new)

**Step 6: Commit**

```bash
cd ~/code/stock && git add lib/features/analysis/domain/indicator_calculator.dart test/unit/indicator_calculator_test.dart && git commit -m "feat: add IndicatorCalculator with RSI calculation"
```

---

## Task 2: Add MACD to IndicatorCalculator

**Objective:** Add MACD(12,26,9) calculation (MACD line, signal line, histogram).

**Files:**
- Modify: `lib/features/analysis/domain/indicator_calculator.dart`
- Modify: `test/unit/indicator_calculator_test.dart`

**Step 1: Write failing tests**

Append to `test/unit/indicator_calculator_test.dart`:

```dart
  group('IndicatorCalculator.calculateMACD', () {
    test('returns empty result when closes length < slowPeriod + signalPeriod', () {
      final result = IndicatorCalculator.calculateMACD([10, 20, 30, 40]);
      expect(result.macdLine, isEmpty);
      expect(result.signalLine, isEmpty);
      expect(result.histogram, isEmpty);
    });

    test('MACD line crosses zero when price trend reverses from up to down', () {
      // Rising then falling
      final closes = <double>[];
      for (var i = 0; i < 30; i++) closes.add(100 + i * 2.0);
      for (var i = 0; i < 30; i++) closes.add(158 - i * 2.0);

      final result = IndicatorCalculator.calculateMACD(closes);
      // MACD should be positive during uptrend, then cross below zero
      expect(result.macdLine.first, greaterThan(0));
      expect(result.macdLine.last, lessThan(0));
    });

    test('histogram = macdLine - signalLine', () {
      final closes = List.generate(60, (i) => 100 + sin(i * 0.3) * 10);
      final result = IndicatorCalculator.calculateMACD(closes);
      for (var i = 0; i < result.histogram.length; i++) {
        expect(result.histogram[i],
            closeTo(result.macdLine[i] - result.signalLine[i], 0.001));
      }
    });

    test('signal line length <= MACD line length', () {
      final closes = List.generate(80, (i) => 100.0 + i * 0.5);
      final result = IndicatorCalculator.calculateMACD(closes);
      expect(result.signalLine.length, lessThanOrEqualTo(result.macdLine.length));
      expect(result.histogram.length, equals(result.signalLine.length));
    });
  });
```

**Step 2: Run test to verify failure**

Run: `cd ~/code/stock && flutter test test/unit/indicator_calculator_test.dart --reporter compact`
Expected: FAIL — calculateMACD does not exist

**Step 3: Add MACDResult model and calculateMACD method to IndicatorCalculator**

Add to `indicator_calculator.dart`:

```dart
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
```

Add `calculateMACD` static method using EMA:
- EMA(today) = price × k + EMA(yesterday) × (1-k), k = 2/(period+1)
- MACD line = EMA(12) - EMA(26)
- Signal line = EMA(9) of MACD line
- Histogram = MACD - Signal

**Step 4: Run test to verify pass**

Run: `cd ~/code/stock && flutter test test/unit/indicator_calculator_test.dart --reporter compact`
Expected: 10 passed

**Step 5: Run full suite**

Run: `cd ~/code/stock && flutter test --reporter compact`

**Step 6: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: add MACD calculation to IndicatorCalculator"
```

---

## Task 3: Add KDJ to IndicatorCalculator

**Objective:** Add KDJ(9,3,3) stochastic oscillator (K, D, J values).

**Files:**
- Modify: `lib/features/analysis/domain/indicator_calculator.dart`
- Modify: `test/unit/indicator_calculator_test.dart`

**Step 1: Write failing tests**

Test cases:
- Returns empty when insufficient klines
- K value between 0-100
- J value can exceed 0-100 range
- Golden cross (K crosses above D) detectable

**Step 2: Run test to verify failure**

**Step 3: Add KDJResult model and calculateKDJ method**
- RSV = (close - lowN) / (highN - lowN) × 100
- K = 2/3 × prevK + 1/3 × RSV
- D = 2/3 × prevD + 1/3 × K
- J = 3K - 2D

Note: KDJ needs highs/lows, so method takes `List<DailyKline>` instead of `List<double>`.

**Step 4: Run test to verify pass**

**Step 5: Run full suite**

**Step 6: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: add KDJ stochastic oscillator to IndicatorCalculator"
```

---

## Task 4: Create SignalRule model

**Objective:** Define the declarative rule model for strategy entry/exit conditions.

**Files:**
- Create: `lib/features/strategy/domain/signal_rule.dart`
- Test: `test/unit/signal_rule_test.dart`

**Step 1: Write failing tests**

```dart
// test/unit/signal_rule_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/signal_rule.dart';

void main() {
  group('SignalRule', () {
    test('evaluate gt condition returns true when value > threshold', () {
      final rule = SignalRule(indicator: 'rsi', condition: 'gt', value: 70);
      expect(rule.evaluate(75), isTrue);
      expect(rule.evaluate(65), isFalse);
    });

    test('evaluate lt condition returns true when value < threshold', () {
      final rule = SignalRule(indicator: 'rsi', condition: 'lt', value: 30);
      expect(rule.evaluate(25), isTrue);
      expect(rule.evaluate(35), isFalse);
    });

    test('evaluate in_range condition checks inclusive bounds', () {
      final rule = SignalRule(indicator: 'rsi', condition: 'in_range', value: 30, value2: 70);
      expect(rule.evaluate(30), isTrue);
      expect(rule.evaluate(50), isTrue);
      expect(rule.evaluate(70), isTrue);
      expect(rule.evaluate(29), isFalse);
      expect(rule.evaluate(71), isFalse);
    });

    test('evaluate cross_up detects previous < threshold and current >= threshold', () {
      final rule = SignalRule(indicator: 'macd', condition: 'cross_up', value: 0);
      expect(rule.evaluateWithPrev(-0.5, 0.3), isTrue);
      expect(rule.evaluateWithPrev(0.1, 0.3), isFalse); // already above
      expect(rule.evaluateWithPrev(-0.5, -0.1), isFalse); // still below
    });

    test('evaluate cross_down detects previous > threshold and current <= threshold', () {
      final rule = SignalRule(indicator: 'macd', condition: 'cross_down', value: 0);
      expect(rule.evaluateWithPrev(0.5, -0.3), isTrue);
      expect(rule.evaluateWithPrev(-0.1, -0.3), isFalse);
    });

    test('fromJson / toJson roundtrip preserves all fields', () {
      final rule = SignalRule(
        indicator: 'boll_position',
        condition: 'lt',
        value: 0.3,
        value2: null,
      );
      final json = rule.toJson();
      final restored = SignalRule.fromJson(json);
      expect(restored.indicator, rule.indicator);
      expect(restored.condition, rule.condition);
      expect(restored.value, rule.value);
    });
  });
}
```

**Step 2: Run test to verify failure**

**Step 3: Write implementation**

```dart
// lib/features/strategy/domain/signal_rule.dart

/// A declarative rule that evaluates a technical indicator against a condition.
class SignalRule {
  final String indicator;  // 'rsi', 'macd', 'macd_signal', 'macd_hist', 'k', 'd', 'j', 'ma_score', 'boll_score', 'vol_score', 'trend_score', 'boll_position'
  final String condition;  // 'lt', 'gt', 'in_range', 'cross_up', 'cross_down'
  final double value;
  final double? value2;    // for 'in_range' upper bound

  const SignalRule({
    required this.indicator,
    required this.condition,
    required this.value,
    this.value2,
  });

  /// Evaluate the rule against a current value.
  bool evaluate(double current) {
    switch (condition) {
      case 'gt': return current > value;
      case 'lt': return current < value;
      case 'in_range': return current >= value && current <= (value2 ?? value);
      default: return false;
    }
  }

  /// Evaluate cross conditions with previous value.
  bool evaluateWithPrev(double previous, double current) {
    switch (condition) {
      case 'cross_up': return previous < value && current >= value;
      case 'cross_down': return previous > value && current <= value;
      default: return evaluate(current);
    }
  }

  Map<String, dynamic> toJson() => {
    'indicator': indicator,
    'condition': condition,
    'value': value,
    if (value2 != null) 'value2': value2,
  };

  factory SignalRule.fromJson(Map<String, dynamic> json) => SignalRule(
    indicator: json['indicator'] as String,
    condition: json['condition'] as String,
    value: (json['value'] as num).toDouble(),
    value2: json['value2'] != null ? (json['value2'] as num).toDouble() : null,
  );
}
```

**Step 4: Run test to verify pass**

**Step 5: Run full suite**

**Step 6: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: add SignalRule model for declarative strategy conditions"
```

---

## Task 5: Create RuleEngine

**Objective:** Build an engine that takes K-line data + signal rules, computes indicators, and evaluates all rules.

**Files:**
- Create: `lib/features/strategy/domain/rule_engine.dart`
- Test: `test/unit/rule_engine_test.dart`

**Step 1: Write failing tests**

Test cases:
- Empty klines returns RuleEvaluationResult with all rules skipped
- Single entry rule: RSI < 30 evaluates correctly with known data
- Multiple entry rules (AND logic): all must pass
- Exit rules evaluated independently
- RuleEngine provides indicatorValues map for inspection

**Step 2: Run test to verify failure**

**Step 3: Write implementation**

```dart
// lib/features/strategy/domain/rule_engine.dart
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
  /// Evaluate entry and exit rules against kline data.
  static RuleEvaluationResult evaluate({
    required List<DailyKline> klines,
    required List<SignalRule> entryRules,
    List<SignalRule> exitRules = const [],
    int rsiPeriod = 14,
    int macdFast = 12,
    int macdSlow = 26,
    int macdSignal = 9,
    int kdjPeriod = 9,
  }) {
    // Compute all indicators
    final closes = klines.map((k) => k.close).toList();
    final rsiValues = IndicatorCalculator.calculateRSI(closes, period: rsiPeriod);
    final macdResult = IndicatorCalculator.calculateMACD(closes, fastPeriod: macdFast, slowPeriod: macdSlow, signalPeriod: macdSignal);
    final kdjResult = IndicatorCalculator.calculateKDJ(klines, period: kdjPeriod);

    // Build current indicator value map
    final current = <String, double>{};
    final prev = <String, double>{};

    if (rsiValues.isNotEmpty) {
      current['rsi'] = rsiValues.last;
      if (rsiValues.length >= 2) prev['rsi'] = rsiValues[rsiValues.length - 2];
    }
    if (macdResult.macdLine.isNotEmpty) {
      current['macd'] = macdResult.macdLine.last;
      if (macdResult.signalLine.isNotEmpty) current['macd_signal'] = macdResult.signalLine.last;
      if (macdResult.histogram.isNotEmpty) current['macd_hist'] = macdResult.histogram.last;
      if (macdResult.macdLine.length >= 2) prev['macd'] = macdResult.macdLine[macdResult.macdLine.length - 2];
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

    // Evaluate rules
    bool evalRule(SignalRule rule) {
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

    return RuleEvaluationResult(
      entryTriggered: entryResults.isNotEmpty && entryResults.every((r) => r),
      exitTriggered: exitResults.isNotEmpty && exitResults.any((r) => r),
      entryResults: entryResults,
      exitResults: exitResults,
      indicatorValues: current,
      prevIndicatorValues: prev,
    );
  }
}
```

**Step 4: Run test to verify pass**

**Step 5: Run full suite**

**Step 6: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: add RuleEngine for evaluating signal rules against kline data"
```

---

## Task 6: Extend Strategy model with signal rules (backward compatible)

**Objective:** Add optional `entryRules` and `exitRules` fields to Strategy model. When present, RuleEngine is used instead of weighted scoring.

**Files:**
- Modify: `lib/features/strategy/domain/strategy_models.dart`
- Modify: `test/unit/strategy_models_test.dart`

**Key design decisions:**
- Add `List<SignalRule>? entryRules` and `List<SignalRule>? exitRules` to Strategy
- When `entryRules` is null or empty → fall back to existing weighted scoring (backward compat)
- Add `fromJson`/`toJson` support for new fields
- Add `get isRuleBased => entryRules != null && entryRules!.isNotEmpty`
- DB migration: add `entry_rules_json` and `exit_rules_json` TEXT columns (nullable) to strategies table

**Step 1: Write failing tests**

Test cases:
- Strategy with null entryRules is not rule-based
- Strategy with empty entryRules is not rule-based
- Strategy with entry rules is rule-based
- JSON roundtrip preserves entryRules and exitRules
- Old JSON without rules fields deserializes correctly (backward compat)

**Step 2: Run test to verify failure**

**Step 3: Modify Strategy model, add rules fields**

**Step 4: Run test to verify pass**

**Step 5: Run full suite**

**Step 6: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: extend Strategy model with optional signal rules (backward compat)"
```

---

## Task 7: DB migration — add rules columns

**Objective:** Add `entry_rules_json` and `exit_rules_json` columns to strategies table.

**Files:**
- Modify: `lib/features/strategy/data/tables.dart`
- Run: `dart run build_runner build` to regenerate Drift code

**Step 1:** Add columns to `StrategiesTable`:
```dart
TextColumn get entryRulesJson => text().nullable()();
TextColumn get exitRulesJson => text().nullable()();
```

**Step 2:** Bump schema version, add migration in database class

**Step 3:** Run build_runner to regenerate

**Step 4:** Run full test suite

**Step 5: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: DB migration — add signal rules JSON columns to strategies table"
```

---

## Task 8: Wire RuleEngine into AnalysisEngine

**Objective:** Update `calculateScoreForStrategy` to use RuleEngine when strategy is rule-based.

**Files:**
- Modify: `lib/features/analysis/domain/analysis_engine.dart`
- Modify: `test/unit/analysis_engine_test.dart`

**Step 1: Write failing tests**

Test cases:
- Rule-based strategy with RSI < 30 + Boll position < 0.3 triggers entry on appropriate data
- Old-style strategy still produces same weighted score (backward compat)
- Rule-based strategy returns StockScore with additional indicator details

**Step 2: Run test to verify failure**

**Step 3: Modify calculateScoreForStrategy:**
```dart
StockScore calculateScoreForStrategy(List<DailyKline> klines, Strategy strategy) {
  if (strategy.isRuleBased) {
    return _evaluateWithRules(klines, strategy);
  }
  // Existing weighted logic (unchanged)
  return calculateScoreWithParams(klines, ...);
}

StockScore _evaluateWithRules(List<DailyKline> klines, Strategy strategy) {
  final result = RuleEngine.evaluate(
    klines: klines,
    entryRules: strategy.entryRules!,
    exitRules: strategy.exitRules ?? [],
  );
  // Map rule evaluation to StockScore
  // entryTriggered → high score, exitTriggered → low score
  // Include indicator values in reason text
}
```

**Step 4: Run test to verify pass**

**Step 5: Run full suite**

**Step 6: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: wire RuleEngine into AnalysisEngine for rule-based strategies"
```

---

## Task 9: Add preset rule-based strategy templates

**Objective:** Create 3 new preset strategies using signal rules alongside existing templates.

**Files:**
- Modify: `lib/features/strategy/domain/strategy_models.dart` (StrategyImportHelper or presets)

**New templates:**
1. **RSI 超卖反弹** — entry: RSI < 30 AND Boll position < 0.3; exit: RSI > 70
2. **MACD 金叉突破** — entry: MACD cross_up 0 AND volume ratio > 1.2; exit: MACD cross_down 0
3. **KDJ 低位金叉** — entry: K cross_up D AND K < 30; exit: K > 80

**Step 1: Write failing test** — verify each template has correct rules

**Step 2: Run test to verify failure**

**Step 3: Add templates to StrategyImportHelper or a new StrategyPresets class**

**Step 4: Run test to verify pass**

**Step 5: Run full suite**

**Step 6: Commit**

```bash
cd ~/code/stock && git add -A && git commit -m "feat: add 3 preset rule-based strategy templates"
```

---

## Task 10: Final integration — verify all tests pass, no regressions

**Objective:** Run full test suite + flutter analyze to confirm zero errors.

**Step 1:** Run `cd ~/code/stock && flutter analyze`
**Step 2:** Run `cd ~/code/stock && flutter test --reporter compact`
**Step 3:** Fix any issues found
**Step 4:** Final commit

```bash
cd ~/code/stock && git add -A && git commit -m "feat: strategy v3 signal rules — integration complete"
```

---

## Summary

| Task | Description | New Tests |
|------|-------------|-----------|
| 1 | IndicatorCalculator — RSI | 6 |
| 2 | IndicatorCalculator — MACD | 4 |
| 3 | IndicatorCalculator — KDJ | 4 |
| 4 | SignalRule model | 6 |
| 5 | RuleEngine | 5 |
| 6 | Strategy model extension | 5 |
| 7 | DB migration | 0 (schema only) |
| 8 | AnalysisEngine wiring | 3 |
| 9 | Preset templates | 3 |
| 10 | Integration verification | 0 |

**Total new tests: ~36 | Expected final: ~254 tests, all green**
