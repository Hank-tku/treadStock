/// Domain model for a decision signal card.
///
/// Signal cards are the visual summary of a decision signal evaluation.
/// They show signal type, strength, key indicator highlights, and actionable summary.
library;

/// Overall signal type — whether this card represents an entry opportunity,
/// an exit warning, or a general watch status.
enum SignalType {
  entry('入场信号', '适合关注是否出现入场时机'),
  exit('离场信号', '注意风险，观察是否需要离场'),
  watch('观望信号', '暂无明确方向，保持观望'),
  neutral('无信号', '当前无触发信号');

  final String label;
  final String description;
  const SignalType(this.label, this.description);
}

/// Signal strength level.
enum SignalStrength {
  strong('强', 3),
  moderate('中', 2),
  weak('弱', 1),
  none('无', 0);

  final String label;
  final int level;
  const SignalStrength(this.label, this.level);
}

/// A single indicator highlight on the signal card.
class IndicatorHighlight {
  final String name; // e.g. 'RSI', 'MACD'
  final String value; // formatted value, e.g. '35.2'
  final String status; // e.g. '超卖', '金叉', '多头'
  final bool isPositive; // true = bullish / good for entry, false = bearish

  const IndicatorHighlight({
    required this.name,
    required this.value,
    required this.status,
    required this.isPositive,
  });
}

/// A decision signal card — the core domain artifact produced by the
/// DecisionSignalEngine for display in the UI.
class SignalCard {
  /// Which stock this card is for.
  final String stockCode;
  final String stockName;

  /// The strategy that produced this signal.
  final String strategyId;
  final String strategyName;

  /// Overall signal classification.
  final SignalType type;

  /// How strong the signal is.
  final SignalStrength strength;

  /// One-line summary for the card header.
  final String headline;

  /// Multi-line detail explaining the signal.
  final String detail;

  /// Key indicator highlights shown on the card.
  final List<IndicatorHighlight> highlights;

  /// Human-readable actionable suggestion.
  final String suggestion;

  /// Per-rule evaluation results (indicator -> passed).
  final Map<String, bool> ruleResults;

  /// Current indicator values used in evaluation.
  final Map<String, double> indicatorValues;

  /// Timestamp of the evaluation.
  final DateTime evaluatedAt;

  /// Current price at evaluation time.
  final double? currentPrice;

  /// Price change % at evaluation time.
  final double? changePct;

  const SignalCard({
    required this.stockCode,
    required this.stockName,
    required this.strategyId,
    required this.strategyName,
    required this.type,
    required this.strength,
    required this.headline,
    required this.detail,
    required this.highlights,
    required this.suggestion,
    required this.ruleResults,
    required this.indicatorValues,
    required this.evaluatedAt,
    this.currentPrice,
    this.changePct,
  });

  /// Number of rules that passed.
  int get passedRuleCount => ruleResults.values.where((v) => v).length;

  /// Total number of rules.
  int get totalRuleCount => ruleResults.length;

  /// Pass rate as 0.0 - 1.0.
  double get passRate =>
      totalRuleCount == 0 ? 0 : passedRuleCount / totalRuleCount;

  /// Whether this card has any actionable signal.
  bool get isActionable => type != SignalType.neutral && strength != SignalStrength.none;

  /// Short display string for the signal type + strength.
  String get tag {
    if (strength == SignalStrength.none) return '无信号';
    return '${type.label} ${strength.label}';
  }
}
