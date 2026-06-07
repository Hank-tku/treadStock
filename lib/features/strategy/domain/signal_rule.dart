/// A declarative rule that evaluates a technical indicator against a condition.
class SignalRule {
  final String indicator; // 'rsi', 'macd', 'macd_signal', 'macd_hist', 'k', 'd', 'j', 'boll_position', 'ma_alignment', 'vol_price_divergence', 'vol_ratio'
  final String condition; // 'lt', 'gt', 'in_range', 'cross_up', 'cross_down'
  final double value;
  final double? value2; // for 'in_range' upper bound

  const SignalRule({
    required this.indicator,
    required this.condition,
    required this.value,
    this.value2,
  });

  /// Evaluate the rule against a current value.
  bool evaluate(double current) {
    switch (condition) {
      case 'gt':
        return current > value;
      case 'lt':
        return current < value;
      case 'in_range':
        return current >= value && current <= (value2 ?? value);
      default:
        return false;
    }
  }

  /// Evaluate cross conditions with previous value.
  bool evaluateWithPrev(double previous, double current) {
    switch (condition) {
      case 'cross_up':
        return previous < value && current >= value;
      case 'cross_down':
        return previous > value && current <= value;
      default:
        return evaluate(current);
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
