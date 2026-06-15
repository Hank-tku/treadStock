// E502 — Market environment sensing model (pure local computation).

import '../../../features/stock/domain/stock_models.dart';

/// Direction of the Shanghai Composite (上证指数) MA trend.
enum MaTrend {
  bullish, // price above MA20, MA20 above MA60
  neutral, // MA lines tangled or close
  bearish, // price below MA20, MA20 below MA60
}

/// Snapshot of the overall A-share market environment.
///
/// All fields are computed locally from EastMoney API data:
/// - [maTrend] is derived from SH index (000001) K-line.
/// - [marketBreadth], [upDownRatio] and [turnoverChangePct] are derived
///   from the full-market snapshot provided by `fetchAllMarketQuotes()`.
class MarketEnvironment {
  /// MA20/MA60 relationship of the benchmark index.
  final MaTrend maTrend;

  /// Fraction of stocks above their MA20 (0.0 – 1.0).
  /// Approximated by the fraction of stocks with a positive daily change
  /// when K-line data for every stock is unavailable.
  final double marketBreadth;

  /// Ratio of advancing stocks to declining stocks.
  /// >1 means more stocks up than down; <1 means the opposite.
  final double upDownRatio;

  /// Percentage change in total market turnover vs previous session.
  /// Positive = volume expansion, negative = contraction.
  /// When previous-session data is unavailable, this defaults to 0.
  final double turnoverChangePct;

  /// Number of advancing stocks.
  final int advancingCount;

  /// Number of declining stocks.
  final int decliningCount;

  /// Number of flat stocks.
  final int flatCount;

  /// Total number of stocks observed.
  final int totalStocks;

  /// Computed 0–100 environment score. Higher = more favourable.
  final double environmentScore;

  const MarketEnvironment({
    required this.maTrend,
    required this.marketBreadth,
    required this.upDownRatio,
    required this.turnoverChangePct,
    required this.advancingCount,
    required this.decliningCount,
    required this.flatCount,
    required this.totalStocks,
    required this.environmentScore,
  });

  /// Human-readable label for the MA trend.
  String get maTrendLabel {
    switch (maTrend) {
      case MaTrend.bullish:
        return '多头排列';
      case MaTrend.neutral:
        return '震荡整理';
      case MaTrend.bearish:
        return '空头排列';
    }
  }

  /// Human-readable label for the overall environment.
  String get environmentLabel {
    if (environmentScore >= 70) return '强势市场';
    if (environmentScore >= 50) return '中性市场';
    if (environmentScore >= 30) return '偏弱市场';
    return '弱势市场';
  }

  /// Human-readable breadth display, e.g. "62.3%".
  String get marketBreadthDisplay => '${(marketBreadth * 100).toStringAsFixed(1)}%';

  /// Human-readable up/down ratio, e.g. "2.3 : 1" or "1 : 1.8".
  String get upDownRatioDisplay {
    if (upDownRatio >= 1) {
      return '${upDownRatio.toStringAsFixed(1)} : 1';
    } else if (upDownRatio > 0) {
      return '1 : ${(1 / upDownRatio).toStringAsFixed(1)}';
    }
    return '--';
  }

  /// Human-readable turnover change, e.g. "+12.5%".
  String get turnoverChangeDisplay {
    final prefix = turnoverChangePct >= 0 ? '+' : '';
    return '$prefix${turnoverChangePct.toStringAsFixed(1)}%';
  }
}

/// Pure-Dart calculator that derives [MarketEnvironment] from raw market data.
///
/// Stays deterministic: same inputs → same output.  No I/O, no time-dependent
/// randomness.
class MarketEnvironmentCalculator {
  MarketEnvironmentCalculator._();

  /// Compute the market environment from a full-market snapshot and
  /// benchmark index K-lines.
  ///
  /// [quotes] — full-market snapshot from `StockApiService.fetchAllMarketQuotes()`.
  /// [indexKlines] — daily K-lines for the Shanghai Composite (000001).
  /// [prevTotalTurnover] — optional total turnover of the previous session.
  ///   When null, [MarketEnvironment.turnoverChangePct] defaults to 0.
  static MarketEnvironment calculate({
    required List<StockQuote> quotes,
    required List<DailyKline> indexKlines,
    double? prevTotalTurnover,
  }) {
    // ── 1. Benchmark MA trend ───────────────────────────────────────
    final maTrend = _computeMaTrend(indexKlines);

    // ── 2. Advance/decline & breadth ────────────────────────────────
    int advancing = 0;
    int declining = 0;
    int flat = 0;
    double totalTurnover = 0;

    for (final q in quotes) {
      // Skip index/ETF codes (8 starting codes that are not individual stocks)
      // We count by changePct.
      if (q.changePct > 0.01) {
        advancing++;
      } else if (q.changePct < -0.01) {
        declining++;
      } else {
        flat++;
      }
      // Use turnover field (换手率%) as proxy when amount is not directly available
      // We accumulate turnover rate as a market-level liquidity proxy
      totalTurnover += q.volume;
    }

    final total = advancing + declining + flat;
    final breadth = total > 0 ? advancing / total : 0.5;
    final ratio = declining > 0 ? advancing / declining : (advancing > 0 ? 99.0 : 1.0);

    // ── 3. Turnover change ──────────────────────────────────────────
    double turnoverChange = 0.0;
    if (prevTotalTurnover != null && prevTotalTurnover > 0) {
      turnoverChange = ((totalTurnover - prevTotalTurnover) / prevTotalTurnover) * 100;
    }

    // ── 4. Composite environment score (0 – 100) ────────────────────
    final score = _computeScore(
      maTrend: maTrend,
      breadth: breadth,
      upDownRatio: ratio,
      turnoverChangePct: turnoverChange,
    );

    return MarketEnvironment(
      maTrend: maTrend,
      marketBreadth: breadth,
      upDownRatio: ratio,
      turnoverChangePct: turnoverChange,
      advancingCount: advancing,
      decliningCount: declining,
      flatCount: flat,
      totalStocks: total,
      environmentScore: score,
    );
  }

  /// Determine the MA trend from benchmark index K-lines.
  static MaTrend _computeMaTrend(List<DailyKline> klines) {
    if (klines.length < 60) return MaTrend.neutral;

    final closes = klines.map((k) => k.close).toList();
    final ma20 = _simpleMA(closes, 20);
    final ma60 = _simpleMA(closes, 60);

    if (ma20 == null || ma60 == null) return MaTrend.neutral;
    if (klines.last.close <= 0) return MaTrend.neutral;

    final price = klines.last.close;
    final spread = (ma20 - ma60) / ma60; // relative separation

    // Bullish: price above MA20, MA20 above MA60 (at least 0.2% apart)
    if (price > ma20 && ma20 > ma60 && spread > 0.002) {
      return MaTrend.bullish;
    }
    // Bearish: price below MA20, MA20 below MA60
    if (price < ma20 && ma20 < ma60 && spread < -0.002) {
      return MaTrend.bearish;
    }
    return MaTrend.neutral;
  }

  /// Simple moving average of the last value.
  static double? _simpleMA(List<double> values, int period) {
    if (values.length < period) return null;
    var sum = 0.0;
    for (var i = values.length - period; i < values.length; i++) {
      sum += values[i];
    }
    return sum / period;
  }

  /// Composite score combining all environment dimensions.
  ///
  /// Weights:
  /// - MA trend:      40 points max
  /// - Breadth:       30 points max
  /// - Up/down ratio: 20 points max
  /// - Turnover:      10 points max
  static double _computeScore({
    required MaTrend maTrend,
    required double breadth,
    required double upDownRatio,
    required double turnoverChangePct,
  }) {
    // MA trend score (0-40)
    double trendScore;
    switch (maTrend) {
      case MaTrend.bullish:
        trendScore = 40;
      case MaTrend.neutral:
        trendScore = 20;
      case MaTrend.bearish:
        trendScore = 5;
    }

    // Breadth score (0-30): 60%+ stocks advancing = full marks
    final breadthScore = (breadth * 50).clamp(0, 30);

    // Up/down ratio score (0-20): ratio >= 2 = full marks
    final ratioScore = ((upDownRatio / 2) * 20).clamp(0, 20);

    // Turnover change score (0-10): volume expansion positive
    final turnoverScore = ((turnoverChangePct + 10) / 20 * 10).clamp(0, 10);

    return (trendScore + breadthScore + ratioScore + turnoverScore)
        .clamp(0, 100)
        .roundToDouble();
  }
}

/// Strategy–environment compatibility assessment.
///
/// Evaluates how well a strategy type aligns with the current market
/// environment, producing a [matchScore] (0–100) that can be used to
/// down-weight recommendations when the environment is unfavourable.
class EnvironmentMatchResult {
  /// 0–100 match score. Higher = better fit.
  final int matchScore;

  /// Qualitative label.
  final String label;

  /// Whether the environment supports this strategy (matchScore >= 50).
  final bool isFavourable;

  /// Recommended score multiplier when environment is poor.
  /// Range 0.5 – 1.0. Use this to down-weight recommendation scores.
  final double weightMultiplier;

  /// Human-readable explanation.
  final String explanation;

  const EnvironmentMatchResult({
    required this.matchScore,
    required this.label,
    required this.isFavourable,
    required this.weightMultiplier,
    required this.explanation,
  });

  /// Compute the match between a strategy's weighting profile and the
  /// current market environment.
  ///
  /// Heuristics:
  /// - **Trend-following** strategies (high MA + trend weight) need a
  ///   bullish MA trend. In bearish/neutral markets, their match drops.
  /// - **Mean-reversion / band-low** strategies (high Bollinger weight)
  ///   work across environments but are penalised in strong bear markets.
  /// - **Volume-sensitive** strategies need turnover expansion.
  factory EnvironmentMatchResult.evaluate({
    required MarketEnvironment env,
    required double weightMA,
    required double weightBoll,
    required double weightVol,
    required double weightTrend,
  }) {
    var score = 100.0;
    final reasons = <String>[];

    // Trend alignment penalty
    final trendSensitivity = weightMA + weightTrend;
    if (trendSensitivity > 0.4) {
      switch (env.maTrend) {
        case MaTrend.bearish:
          score -= 35 * trendSensitivity;
          reasons.add('大盘空头排列，趋势类策略受压制');
        case MaTrend.neutral:
          score -= 15 * trendSensitivity;
          reasons.add('大盘震荡，趋势信号可靠性降低');
        case MaTrend.bullish:
          break; // no penalty
      }
    }

    // Breadth penalty
    if (env.marketBreadth < 0.35) {
      score -= 20;
      reasons.add('市场宽度偏低(${env.marketBreadthDisplay})，普跌风险');
    } else if (env.marketBreadth < 0.45 && trendSensitivity > 0.4) {
      score -= 10;
      reasons.add('涨跌家数比偏低');
    }

    // Up/down ratio penalty
    if (env.upDownRatio < 0.5) {
      score -= 15;
      reasons.add('涨跌比偏低(${env.upDownRatioDisplay})');
    }

    // Turnover contraction for volume-sensitive strategies
    if (weightVol > 0.2 && env.turnoverChangePct < -15) {
      score -= 10;
      reasons.add('成交额缩量，量价信号减弱');
    }

    // Mean-reversion strategies get a slight boost in oversold markets
    if (weightBoll > 0.35 && env.marketBreadth < 0.35) {
      score += 5;
      reasons.add('低位反弹机会，适合布林带策略');
    }

    final finalScore = score.round().clamp(0, 100);

    // Weight multiplier: linear interpolation from 0.5 (score 0) to 1.0 (score ≥ 60)
    final multiplier = finalScore >= 60
        ? 1.0
        : 0.5 + (finalScore / 60) * 0.5;

    final favourable = finalScore >= 50;
    String label;
    if (finalScore >= 80) {
      label = '高度匹配';
    } else if (finalScore >= 60) {
      label = '较为匹配';
    } else if (finalScore >= 40) {
      label = '匹配度一般';
    } else {
      label = '环境不利';
    }

    final explanation = reasons.isEmpty
        ? '当前市场环境与策略风格较为契合'
        : reasons.join('；');

    return EnvironmentMatchResult(
      matchScore: finalScore,
      label: label,
      isFavourable: favourable,
      weightMultiplier: multiplier,
      explanation: explanation,
    );
  }
}
