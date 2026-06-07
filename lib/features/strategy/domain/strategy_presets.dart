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

  /// 布林带下轨反弹 — 价格触及布林带下沿且RSI超卖时入场，回到上轨附近出场
  static Strategy bollBandBounce({
    required String id,
    required DateTime now,
  }) {
    return Strategy(
      id: id,
      name: '布林带下轨反弹',
      description: '当价格触及布林带下轨且RSI处于超卖区时捕捉反弹机会',
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
        SignalRule(indicator: 'boll_position', condition: 'lt', value: 0.15),
        SignalRule(indicator: 'rsi', condition: 'lt', value: 35),
      ],
      exitRules: [
        SignalRule(indicator: 'boll_position', condition: 'gt', value: 0.7),
      ],
    );
  }

  /// 均线多头排列 — 短期均线在长期均线之上且量能放大时入场，多头结构破坏时出场
  static Strategy maBullAlignment({
    required String id,
    required DateTime now,
  }) {
    return Strategy(
      id: id,
      name: '均线多头排列',
      description: '当均线呈现完美多头排列且量能放大时捕捉趋势延续机会',
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
        SignalRule(indicator: 'ma_alignment', condition: 'gt', value: 7),
        SignalRule(indicator: 'vol_ratio', condition: 'gt', value: 1.2),
      ],
      exitRules: [
        SignalRule(indicator: 'ma_alignment', condition: 'lt', value: 4),
      ],
    );
  }

  /// 量价背离抄底 — 量价出现底背离信号且RSI处于低位时入场，RSI回升后出场
  static Strategy volPriceDivergenceBottom({
    required String id,
    required DateTime now,
  }) {
    return Strategy(
      id: id,
      name: '量价背离抄底',
      description: '当量价出现底背离信号且RSI处于低位时，捕捉底部反转机会',
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
        SignalRule(indicator: 'vol_price_divergence', condition: 'gt', value: 0.5),
        SignalRule(indicator: 'rsi', condition: 'lt', value: 40),
      ],
      exitRules: [
        SignalRule(indicator: 'rsi', condition: 'gt', value: 65),
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
      bollBandBounce(id: idGenerator(), now: now),
      maBullAlignment(id: idGenerator(), now: now),
      volPriceDivergenceBottom(id: idGenerator(), now: now),
    ];
  }
}
