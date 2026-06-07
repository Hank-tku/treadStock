import 'signal_rule.dart';
import 'strategy_models.dart';

/// Preset rule-based strategy templates.
class StrategyPresets {
  StrategyPresets._();

  /// RSI 超卖反弹 — RSI<30 AND 布林位置<0.3 时入场，RSI>70 时出场
  static Strategy rsiOversoldBounce({
    required String id,
    required DateTime now,
  }) {
    return Strategy(
      id: id,
      name: 'RSI 超卖反弹',
      description: '当RSI进入超卖区域且价格处于布林带下方时，捕捉反弹机会',
      maShortPeriod: 20,
      maLongPeriod: 60,
      bollPeriod: 20,
      bollStdDev: 2.0,
      weightMA: 0.25,
      weightBoll: 0.25,
      weightVol: 0.25,
      weightTrend: 0.25,
      recommendThreshold: 7,
      isEnabled: true,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
      entryRules: [
        SignalRule(indicator: 'rsi', condition: 'lt', value: 30),
      ],
      exitRules: [
        SignalRule(indicator: 'rsi', condition: 'gt', value: 70),
      ],
    );
  }

  /// MACD 金叉突破 — MACD 从下方穿越零线时入场，从上方穿越时出场
  static Strategy macdGoldenCross({
    required String id,
    required DateTime now,
  }) {
    return Strategy(
      id: id,
      name: 'MACD 金叉突破',
      description: '当MACD从负转正（金叉）时入场，从正转负（死叉）时出场',
      maShortPeriod: 20,
      maLongPeriod: 60,
      bollPeriod: 20,
      bollStdDev: 2.0,
      weightMA: 0.25,
      weightBoll: 0.25,
      weightVol: 0.25,
      weightTrend: 0.25,
      recommendThreshold: 7,
      isEnabled: true,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
      entryRules: [
        SignalRule(indicator: 'macd', condition: 'cross_up', value: 0),
      ],
      exitRules: [
        SignalRule(indicator: 'macd', condition: 'cross_down', value: 0),
      ],
    );
  }

  /// KDJ 低位金叉 — K线从下方穿越D线且K<30时入场，K>80时出场
  static Strategy kdjLowGoldenCross({
    required String id,
    required DateTime now,
  }) {
    return Strategy(
      id: id,
      name: 'KDJ 低位金叉',
      description: 'KDJ指标K线在低位上穿D线时捕捉短线买点，K>80时离场',
      maShortPeriod: 20,
      maLongPeriod: 60,
      bollPeriod: 20,
      bollStdDev: 2.0,
      weightMA: 0.25,
      weightBoll: 0.25,
      weightVol: 0.25,
      weightTrend: 0.25,
      recommendThreshold: 7,
      isEnabled: true,
      isDefault: false,
      createdAt: now,
      updatedAt: now,
      entryRules: [
        SignalRule(indicator: 'k', condition: 'cross_up', value: 30),
        SignalRule(indicator: 'k', condition: 'lt', value: 40),
      ],
      exitRules: [
        SignalRule(indicator: 'k', condition: 'gt', value: 80),
      ],
    );
  }

  /// Get all preset templates.
  static List<Strategy> all({
    required String Function() idGenerator,
    required DateTime now,
  }) {
    return [
      rsiOversoldBounce(id: idGenerator(), now: now),
      macdGoldenCross(id: idGenerator(), now: now),
      kdjLowGoldenCross(id: idGenerator(), now: now),
    ];
  }
}
