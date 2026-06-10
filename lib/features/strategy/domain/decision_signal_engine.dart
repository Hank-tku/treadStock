import '../../stock/domain/stock_models.dart';
import 'signal_rule.dart';
import 'signal_card.dart';
import 'strategy_models.dart';
import 'rule_engine.dart';

/// Decision signal engine — bridges the rule engine output to signal card
/// domain models with rich human-readable summaries.
///
/// This is the core of F101: it evaluates a stock against a strategy's rules,
/// then produces a [SignalCard] with indicator highlights, signal strength,
/// and actionable suggestions.
class DecisionSignalEngine {
  DecisionSignalEngine._();

  /// Evaluate a single stock against a strategy and produce a signal card.
  ///
  /// [klines] — historical daily K-line data for the stock.
  /// [strategy] — the strategy to evaluate against.
  /// [stockCode] / [stockName] — stock identifiers.
  /// [currentPrice] / [changePct] — current market data.
  static SignalCard evaluate({
    required List<DailyKline> klines,
    required Strategy strategy,
    required String stockCode,
    required String stockName,
    double? currentPrice,
    double? changePct,
  }) {
    final now = DateTime.now();

    // If no entry/exit rules are configured, return a neutral card
    final hasRules = (strategy.entryRules?.isNotEmpty ?? false) ||
        (strategy.exitRules?.isNotEmpty ?? false) ||
        (strategy.entryGroups?.isNotEmpty ?? false) ||
        (strategy.exitGroups?.isNotEmpty ?? false);
    if (!hasRules) {
      return SignalCard(
        stockCode: stockCode,
        stockName: stockName,
        strategyId: strategy.id,
        strategyName: strategy.name,
        type: SignalType.neutral,
        strength: SignalStrength.none,
        headline: '该策略未配置信号规则',
        detail: '策略 "${strategy.name}" 使用加权评分模式，无规则信号。可在编辑页面添加入场/离场规则。',
        highlights: const [],
        suggestion: '如需信号提醒，请编辑策略添加规则。',
        ruleResults: const {},
        indicatorValues: const {},
        evaluatedAt: now,
        currentPrice: currentPrice,
        changePct: changePct,
      );
    }

    // Not enough data
    if (klines.length < 20) {
      return SignalCard(
        stockCode: stockCode,
        stockName: stockName,
        strategyId: strategy.id,
        strategyName: strategy.name,
        type: SignalType.watch,
        strength: SignalStrength.none,
        headline: '数据不足',
        detail: '需要至少 20 根日K线，当前仅有 ${klines.length} 根。',
        highlights: const [],
        suggestion: '数据积累后再查看信号。',
        ruleResults: const {},
        indicatorValues: const {},
        evaluatedAt: now,
        currentPrice: currentPrice,
        changePct: changePct,
      );
    }

    // Run rule engine
    final entryRules = strategy.entryRules ?? [];
    final exitRules = strategy.exitRules ?? [];
    final entryGroups = strategy.entryGroups;
    final exitGroups = strategy.exitGroups;

    final result = RuleEngine.evaluate(
      klines: klines,
      entryRules: entryRules,
      exitRules: exitRules,
      entryGroups: entryGroups,
      exitGroups: exitGroups,
    );

    // Build rule results map
    final ruleResults = <String, bool>{};
    for (var i = 0; i < entryRules.length; i++) {
      final rule = entryRules[i];
      ruleResults['entry:${_ruleLabel(rule)}'] = result.entryResults[i];
    }
    for (var i = 0; i < exitRules.length; i++) {
      final rule = exitRules[i];
      ruleResults['exit:${_ruleLabel(rule)}'] = result.exitResults[i];
    }

    // Build indicator highlights
    final highlights = _buildHighlights(result.indicatorValues);

    // Determine signal type and strength
    final entryTriggered = result.entryTriggered;
    final exitTriggered = result.exitTriggered;
    final entryPassRate = _passRate(result.entryResults);
    final exitPassRate = _passRate(result.exitResults);

    final (type, strength) = _classifySignal(
      entryTriggered: entryTriggered,
      exitTriggered: exitTriggered,
      entryPassRate: entryPassRate,
      exitPassRate: exitPassRate,
      totalRules: entryRules.length + exitRules.length,
    );

    final headline = _buildHeadline(type, strength, stockName);
    final detail = _buildDetail(
      type: type,
      strength: strength,
      entryTriggered: entryTriggered,
      exitTriggered: exitTriggered,
      entryPassRate: entryPassRate,
      exitPassRate: exitPassRate,
      highlights: highlights,
      indicatorValues: result.indicatorValues,
    );
    final suggestion = _buildSuggestion(type, strength, highlights);

    return SignalCard(
      stockCode: stockCode,
      stockName: stockName,
      strategyId: strategy.id,
      strategyName: strategy.name,
      type: type,
      strength: strength,
      headline: headline,
      detail: detail,
      highlights: highlights,
      suggestion: suggestion,
      ruleResults: ruleResults,
      indicatorValues: result.indicatorValues,
      evaluatedAt: now,
      currentPrice: currentPrice,
      changePct: changePct,
    );
  }

  /// Evaluate a stock against multiple strategies, returning one card per strategy.
  static List<SignalCard> evaluateMultiple({
    required List<DailyKline> klines,
    required List<Strategy> strategies,
    required String stockCode,
    required String stockName,
    double? currentPrice,
    double? changePct,
  }) {
    return strategies
        .map((s) => evaluate(
              klines: klines,
              strategy: s,
              stockCode: stockCode,
              stockName: stockName,
              currentPrice: currentPrice,
              changePct: changePct,
            ))
        .toList();
  }

  // ── Private helpers ────────────────────────────────────────────────

  static String _ruleLabel(SignalRule rule) {
    final names = {
      'rsi': 'RSI',
      'macd': 'MACD',
      'macd_signal': 'MACD信号',
      'macd_hist': 'MACD柱',
      'k': 'K值',
      'd': 'D值',
      'j': 'J值',
      'boll_position': '布林位置',
      'ma_alignment': '均线排列',
      'vol_price_divergence': '量价背离',
      'vol_ratio': '量比',
      'ema': 'EMA',
      'atr': 'ATR',
      'obv': 'OBV',
      'ma_short': '短期MA',
      'ma_long': '长期MA',
    };
    final conds = {
      'gt': '>',
      'lt': '<',
      'in_range': '区间',
      'cross_up': '上穿',
      'cross_down': '下穿',
      'indicator_cross_up': '上穿',
      'indicator_cross_down': '下穿',
    };
    final name = names[rule.indicator] ?? rule.indicator;
    final cond = conds[rule.condition] ?? rule.condition;

    if (rule.isIndicatorCross && rule.indicator2 != null) {
      final name2 = names[rule.indicator2] ?? rule.indicator2;
      return '$name $cond $name2';
    }

    if (rule.condition == 'in_range' && rule.value2 != null) {
      return '$name $cond [${rule.value.toStringAsFixed(1)}, ${rule.value2!.toStringAsFixed(1)}]';
    }
    return '$name $cond ${rule.value.toStringAsFixed(1)}';
  }

  static double _passRate(List<bool> results) {
    if (results.isEmpty) return 0;
    return results.where((r) => r).length / results.length;
  }

  static (SignalType, SignalStrength) _classifySignal({
    required bool entryTriggered,
    required bool exitTriggered,
    required double entryPassRate,
    required double exitPassRate,
    required int totalRules,
  }) {
    // Both triggered — conflict, prefer exit (risk-first)
    if (entryTriggered && exitTriggered) {
      return (SignalType.watch, SignalStrength.moderate);
    }

    if (entryTriggered) {
      final strength = entryPassRate >= 0.8
          ? SignalStrength.strong
          : SignalStrength.moderate;
      return (SignalType.entry, strength);
    }

    if (exitTriggered) {
      final strength = exitPassRate >= 0.8
          ? SignalStrength.strong
          : SignalStrength.moderate;
      return (SignalType.exit, strength);
    }

    // No signal triggered — check if close to triggering
    if (totalRules > 0) {
      final maxRate = entryPassRate > exitPassRate ? entryPassRate : exitPassRate;
      if (maxRate >= 0.5) {
        return (SignalType.watch, SignalStrength.weak);
      }
    }

    return (SignalType.neutral, SignalStrength.none);
  }

  static List<IndicatorHighlight> _buildHighlights(
    Map<String, double> values,
  ) {
    final highlights = <IndicatorHighlight>[];

    // RSI
    final rsi = values['rsi'];
    if (rsi != null) {
      highlights.add(IndicatorHighlight(
        name: 'RSI',
        value: rsi.toStringAsFixed(1),
        status: rsi < 30
            ? '超卖'
            : rsi > 70
                ? '超买'
                : rsi < 45
                    ? '偏低'
                    : rsi > 55
                        ? '偏高'
                        : '中性',
        isPositive: rsi < 40,
      ));
    }

    // MACD
    final macdHist = values['macd_hist'];
    if (macdHist != null) {
      highlights.add(IndicatorHighlight(
        name: 'MACD',
        value: macdHist.toStringAsFixed(3),
        status: macdHist > 0 ? '多头' : '空头',
        isPositive: macdHist > 0,
      ));
    }

    // KDJ
    final k = values['k'];
    final d = values['d'];
    if (k != null && d != null) {
      final kdStatus = k > d ? 'K>D' : 'K<D';
      highlights.add(IndicatorHighlight(
        name: 'KDJ',
        value: 'K:${k.toStringAsFixed(1)} D:${d.toStringAsFixed(1)}',
        status: k < 20 && d < 20 ? '低位' : k > 80 && d > 80 ? '高位' : kdStatus,
        isPositive: k > d && k < 80,
      ));
    }

    // Bollinger position
    final bollPos = values['boll_position'];
    if (bollPos != null) {
      final bollStatus = bollPos < 0.2
          ? '下轨附近'
          : bollPos > 0.8
              ? '上轨附近'
              : '中轨附近';
      highlights.add(IndicatorHighlight(
        name: '布林',
        value: '${(bollPos * 100).toStringAsFixed(0)}%',
        status: bollStatus,
        isPositive: bollPos < 0.3,
      ));
    }

    // Volume ratio
    final volRatio = values['vol_ratio'];
    if (volRatio != null) {
      highlights.add(IndicatorHighlight(
        name: '量比',
        value: volRatio.toStringAsFixed(2),
        status: volRatio > 2.0
            ? '放量'
            : volRatio < 0.5
                ? '缩量'
                : '正常',
        isPositive: volRatio >= 0.8 && volRatio <= 2.0,
      ));
    }

    return highlights;
  }

  static String _buildHeadline(
    SignalType type,
    SignalStrength strength,
    String stockName,
  ) {
    if (type == SignalType.entry) {
      if (strength == SignalStrength.strong) {
        return '$stockName 多信号共振，关注入场时机';
      }
      if (strength == SignalStrength.moderate) {
        return '$stockName 部分入场条件满足';
      }
      return '$stockName 入场信号偏弱';
    }

    if (type == SignalType.exit) {
      if (strength == SignalStrength.strong) {
        return '$stockName 多个离场信号触发';
      }
      if (strength == SignalStrength.moderate) {
        return '$stockName 出现离场迹象';
      }
      return '$stockName 离场信号偏弱';
    }

    if (type == SignalType.watch) {
      return '$stockName 部分条件接近触发，保持观察';
    }

    return '$stockName 暂无信号触发';
  }

  static String _buildDetail({
    required SignalType type,
    required SignalStrength strength,
    required bool entryTriggered,
    required bool exitTriggered,
    required double entryPassRate,
    required double exitPassRate,
    required List<IndicatorHighlight> highlights,
    required Map<String, double> indicatorValues,
  }) {
    final parts = <String>[];

    if (entryTriggered) {
      parts.add('入场规则通过 ${(entryPassRate * 100).toStringAsFixed(0)}%。');
    } else if (entryPassRate > 0) {
      parts.add('入场规则通过率 ${(entryPassRate * 100).toStringAsFixed(0)}%，未完全满足。');
    }

    if (exitTriggered) {
      parts.add('离场规则已触发。');
    } else if (exitPassRate > 0) {
      parts.add('离场规则通过率 ${(exitPassRate * 100).toStringAsFixed(0)}%。');
    }

    // Key indicator summary
    final positiveIndicators =
        highlights.where((h) => h.isPositive).map((h) => h.name);
    final negativeIndicators =
        highlights.where((h) => !h.isPositive).map((h) => h.name);

    if (positiveIndicators.isNotEmpty) {
      parts.add('偏多指标：${positiveIndicators.join('、')}。');
    }
    if (negativeIndicators.isNotEmpty) {
      parts.add('偏空指标：${negativeIndicators.join('、')}。');
    }

    if (parts.isEmpty) {
      parts.add('当前无匹配规则或数据不足，无法生成信号。');
    }

    return parts.join('');
  }

  static String _buildSuggestion(
    SignalType type,
    SignalStrength strength,
    List<IndicatorHighlight> highlights,
  ) {
    if (strength == SignalStrength.none) {
      return '暂无操作建议，可等待信号触发。';
    }

    if (type == SignalType.entry) {
      if (strength == SignalStrength.strong) {
        return '多个条件共振，可加入关注密切观察。下一步关注是否站上短期均线。';
      }
      if (strength == SignalStrength.moderate) {
        return '部分条件满足，建议观察 1-2 日确认方向。注意成交量是否配合。';
      }
      return '信号偏弱，建议等待更多条件满足后再关注。';
    }

    if (type == SignalType.exit) {
      if (strength == SignalStrength.strong) {
        return '多个离场条件触发，建议考虑减仓或止损。注意观察关键支撑位。';
      }
      if (strength == SignalStrength.moderate) {
        return '出现离场迹象，建议收紧止损线。关注短期均线支撑情况。';
      }
      return '离场信号偏弱，建议保持观察，暂不急于操作。';
    }

    if (type == SignalType.watch) {
      return '部分指标接近触发条件，保持观察。注意大盘环境配合。';
    }

    return '暂无操作建议，继续观察。';
  }
}
