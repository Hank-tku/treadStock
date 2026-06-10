import '../../../features/analysis/domain/analysis_models.dart';

/// Represents a single decision label derived from technical analysis.
enum DecisionLabelType {
  // ── Bullish signals ──
  bullishAlignment('多头排列', DecisionSentiment.bullish),
  maSupport('均线支撑', DecisionSentiment.bullish),
  bandLow('波段低位', DecisionSentiment.bullish),
  volumeBreakout('放量突破', DecisionSentiment.bullish),
  oversoldBounce('超跌反弹', DecisionSentiment.bullish),
  shrinkingConsolidation('缩量盘整', DecisionSentiment.neutral),

  // ── Neutral signals ──
  neutralMA('均线中性', DecisionSentiment.neutral),
  midBand('中轨震荡', DecisionSentiment.neutral),
  normalVolume('量能平稳', DecisionSentiment.neutral),

  // ── Bearish signals ──
  bearishAlignment('空头排列', DecisionSentiment.bearish),
  bandHigh('波段高位', DecisionSentiment.bearish),
  volumeDistribution('放量下跌', DecisionSentiment.bearish),
  pullbackRisk('回调风险', DecisionSentiment.bearish),
  weakTrend('趋势偏弱', DecisionSentiment.bearish),

  // ── Special ──
  dataInsufficient('数据不足', DecisionSentiment.unknown);

  final String displayName;
  final DecisionSentiment sentiment;

  const DecisionLabelType(this.displayName, this.sentiment);
}

/// Sentiment classification for decision labels.
enum DecisionSentiment { bullish, neutral, bearish, unknown }

/// A computed decision label ready for display.
class DecisionLabel {
  final DecisionLabelType type;
  final String detail;

  const DecisionLabel({required this.type, required this.detail});

  String get displayName => type.displayName;
  DecisionSentiment get sentiment => type.sentiment;
}

/// Generates decision labels from technical analysis scores.
class DecisionLabelEngine {
  /// Generate decision labels from a StockScore.
  /// Returns up to 4 most relevant labels.
  static List<DecisionLabel> generate(StockScore score) {
    if (score.score == 0) {
      return const [
        DecisionLabel(
          type: DecisionLabelType.dataInsufficient,
          detail: 'K线数据不足，暂无法生成决策标签',
        ),
      ];
    }

    final labels = <DecisionLabel>[];

    // MA labels
    _addMALabels(score, labels);
    // Bollinger labels
    _addBollLabels(score, labels);
    // Volume labels
    _addVolLabels(score, labels);
    // Trend labels
    _addTrendLabels(score, labels);

    // Sort: bullish first, then neutral, then bearish. Within same sentiment,
    // keep insertion order. Limit to 4.
    labels.sort((a, b) {
      const order = {
        DecisionSentiment.bullish: 0,
        DecisionSentiment.neutral: 1,
        DecisionSentiment.bearish: 2,
        DecisionSentiment.unknown: 3,
      };
      return order[a.sentiment]!.compareTo(order[b.sentiment]!);
    });

    return labels.take(4).toList();
  }

  static void _addMALabels(StockScore score, List<DecisionLabel> labels) {
    final ma = score.maScore;

    if (ma >= 8) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.bullishAlignment,
        detail: '短期均线在长期均线上方，价格站上短期均线，多头趋势明确',
      ));
    } else if (ma >= 6) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.maSupport,
        detail: '价格接近短期均线，均线形成支撑',
      ));
    } else if (ma <= 3) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.bearishAlignment,
        detail: '短期均线在长期均线下方，空头趋势明显',
      ));
    } else {
      labels.add(DecisionLabel(
        type: DecisionLabelType.neutralMA,
        detail: '均线走势不明朗，暂无明显方向',
      ));
    }
  }

  static void _addBollLabels(StockScore score, List<DecisionLabel> labels) {
    final boll = score.bollScore;

    if (boll >= 8) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.bandLow,
        detail: '价格处于布林带下轨附近，属于波段低位区间',
      ));
    } else if (boll >= 5) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.midBand,
        detail: '价格在布林带中轨附近震荡',
      ));
    } else if (boll <= 3) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.bandHigh,
        detail: '价格处于布林带上轨附近，属于波段高位区间',
      ));
    }
  }

  static void _addVolLabels(StockScore score, List<DecisionLabel> labels) {
    final vol = score.volScore;

    if (vol >= 7) {
      // score 7-8 can be either breakout or shrinking consolidation
      if (score.isBandLow) {
        labels.add(DecisionLabel(
          type: DecisionLabelType.volumeBreakout,
          detail: '放量配合波段低位，可能有资金进场',
        ));
      } else {
        labels.add(DecisionLabel(
          type: DecisionLabelType.shrinkingConsolidation,
          detail: '缩量盘整中，量能萎缩等待方向选择',
        ));
      }
    } else if (vol <= 3) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.volumeDistribution,
        detail: '放量下跌，可能存在资金出逃',
      ));
    } else {
      labels.add(DecisionLabel(
        type: DecisionLabelType.normalVolume,
        detail: '量能平稳，无异常放量或缩量',
      ));
    }
  }

  static void _addTrendLabels(StockScore score, List<DecisionLabel> labels) {
    final trend = score.trendScore;

    if (trend >= 7) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.oversoldBounce,
        detail: '连续回调后企稳，可能出现超跌反弹',
      ));
    } else if (trend <= 3) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.pullbackRisk,
        detail: '连续上涨后回调风险加大',
      ));
    } else if (score.score <= 4) {
      labels.add(DecisionLabel(
        type: DecisionLabelType.weakTrend,
        detail: '近期走势偏弱，短期趋势不乐观',
      ));
    }
  }
}
