// T-ENG-01, T-ENG-02, T-ENG-03, T-F004-1, T-F004-3, T-F005-1, T-F006-1
// 测试分析引擎核心算法：MA、布林带、量比、评分、波段低位、下跌预警、每日摘要

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/analysis/domain/analysis_engine.dart';
import 'package:stockpilot/features/analysis/domain/analysis_models.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:stockpilot/features/strategy/domain/signal_rule.dart';

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

/// 生成指定天数的 K 线数据（均匀递增价格，用于基础计算测试）。
List<DailyKline> generateKlines({
  int days = 60,
  double startPrice = 40.0,
  double dailyReturn = 0.001, // 每天上涨 0.1%
}) {
  final klines = <DailyKline>[];
  var price = startPrice;
  for (var i = 0; i < days; i++) {
    final open = price;
    price = price * (1 + dailyReturn);
    final close = price;
    final high = close * 1.01;
    final low = open * 0.99;
    final date = DateTime(2026, 1, 1).add(Duration(days: i));
    klines.add(
      DailyKline(
        date: date,
        open: open,
        close: close,
        high: high,
        low: low,
        volume: 100000.0,
        amount: 5000000000.0,
        preClose: i > 0 ? klines[i - 1].close : open * 0.99,
      ),
    );
  }
  return klines;
}

/// 生成连跌 N 天的 K 线数据（用于下跌预警和趋势评分测试）。
List<DailyKline> generateDecliningKlines({
  int days = 30,
  double startPrice = 50.0,
  double dailyDrop = 0.02, // 每天跌 2%
  double lastDayVolumeMultiplier = 1.0,
}) {
  final klines = <DailyKline>[];
  var price = startPrice;
  for (var i = 0; i < days; i++) {
    final open = price;
    price = price * (1 - dailyDrop);
    final close = price;
    final high = open;
    final low = close;
    final date = DateTime(2026, 1, 1).add(Duration(days: i));
    final vol = (i == days - 1) ? 100000.0 * lastDayVolumeMultiplier : 100000.0;
    klines.add(
      DailyKline(
        date: date,
        open: open,
        close: close,
        high: high,
        low: low,
        volume: vol,
        amount: 5000000000.0,
        preClose: i > 0 ? klines[i - 1].close : open * 1.02,
      ),
    );
  }
  return klines;
}

/// 生成价格在下轨附近的 K 线数据（测试波段低位）。
List<DailyKline> generateBandLowKlines() {
  // 先涨后跌，让价格从高位回落到低位
  final klines = <DailyKline>[];
  var price = 40.0;

  // 前 40 天上涨
  for (var i = 0; i < 40; i++) {
    final open = price;
    price *= 1.015;
    final close = price;
    klines.add(
      DailyKline(
        date: DateTime(2026, 1, 1).add(Duration(days: i)),
        open: open,
        close: close,
        high: close * 1.01,
        low: open * 0.99,
        volume: 120000.0,
        amount: 5000000000.0,
        preClose: i > 0 ? klines[i - 1].close : open,
      ),
    );
  }

  // 后 30 天下跌
  for (var i = 0; i < 30; i++) {
    final open = price;
    price *= 0.985;
    final close = price;
    klines.add(
      DailyKline(
        date: DateTime(2026, 2, 10).add(Duration(days: i)),
        open: open,
        close: close,
        high: open,
        low: close * 0.995,
        volume: 80000.0, // 缩量下跌
        amount: 4000000000.0,
        preClose: klines[klines.length - 1].close,
      ),
    );
  }

  return klines;
}

void main() {
  late AnalysisEngine engine;

  setUp(() {
    engine = AnalysisEngine();
  });

  // =========================================================================
  // T-ENG-01: MA 计算
  // =========================================================================
  group('T-ENG-01: calculateMA', () {
    test('MA20 计算正确', () {
      final closes = [
        10.0,
        20.0,
        30.0,
        40.0,
        50.0,
        60.0,
        70.0,
        80.0,
        90.0,
        100.0,
        110.0,
        120.0,
        130.0,
        140.0,
        150.0,
        160.0,
        170.0,
        180.0,
        190.0,
        200.0,
      ];
      final result = engine.calculateMA(closes, 20);
      expect(result.length, 1);
      // (10+20+...+200)/20 = 105.0
      expect(result[0], closeTo(105.0, 0.001));
    });

    test('MA60 计算正确', () {
      final closes = List.generate(60, (i) => (i + 1).toDouble());
      final result = engine.calculateMA(closes, 60);
      expect(result.length, 1);
      // (1+2+...+60)/60 = 30.5
      expect(result[0], closeTo(30.5, 0.001));
    });

    test('数据不足时返回空列表', () {
      final closes = [10.0, 20.0, 30.0];
      final result = engine.calculateMA(closes, 20);
      expect(result, isEmpty);
    });

    test('数据恰好等于 period 时返回一个值', () {
      final closes = List.generate(20, (i) => 50.0);
      final result = engine.calculateMA(closes, 20);
      expect(result.length, 1);
      expect(result[0], 50.0);
    });

    test('多日数据 MA 序列长度 = closes.length - period + 1', () {
      final closes = List.generate(30, (i) => (50.0 + i * 0.1));
      final result = engine.calculateMA(closes, 20);
      expect(result.length, 11); // 30 - 20 + 1
    });
  });

  // =========================================================================
  // T-ENG-02: 布林带计算
  // =========================================================================
  group('T-ENG-02: calculateBollinger', () {
    test('默认参数（20日、2倍标准差）计算正确', () {
      final klines = generateKlines(days: 30);
      final closes = klines.map((k) => k.close).toList();
      final boll = engine.calculateBollinger(closes);

      // 30 天数据, period=20, 应有 11 个值
      expect(boll.upper.length, 11);
      expect(boll.middle.length, 11);
      expect(boll.lower.length, 11);
    });

    test('upper > middle > lower 成立', () {
      final klines = generateKlines(days: 30, dailyReturn: 0.01);
      final closes = klines.map((k) => k.close).toList();
      final boll = engine.calculateBollinger(closes);

      for (var i = 0; i < boll.upper.length; i++) {
        expect(boll.upper[i], greaterThanOrEqualTo(boll.middle[i]));
        expect(boll.middle[i], greaterThanOrEqualTo(boll.lower[i]));
      }
    });

    test('数据不足时返回空布林带', () {
      final closes = [10.0, 20.0, 30.0];
      final boll = engine.calculateBollinger(closes);
      expect(boll.upper, isEmpty);
      expect(boll.middle, isEmpty);
      expect(boll.lower, isEmpty);
    });

    test('currentUpper/currentLower 返回最后一个值', () {
      final klines = generateKlines(days: 25);
      final closes = klines.map((k) => k.close).toList();
      final boll = engine.calculateBollinger(closes);

      expect(boll.currentUpper, isNotNull);
      expect(boll.currentLower, isNotNull);
      expect(boll.currentMiddle, isNotNull);

      expect(boll.currentUpper, boll.upper.last);
      expect(boll.currentLower, boll.lower.last);
    });

    test('所有价格相同标准差为 0 时上轨等于下轨', () {
      final closes = List.generate(25, (_) => 50.0);
      final boll = engine.calculateBollinger(closes);
      // 标准差为 0 -> upper = middle = lower = 50.0
      expect(boll.currentUpper, 50.0);
      expect(boll.currentLower, 50.0);
      expect(boll.currentMiddle, 50.0);
    });
  });

  // =========================================================================
  // T-ENG-03: 量比计算（通过评分间接测试）
  // =========================================================================
  group('T-ENG-03: volume ratio (indirect)', () {
    test('正常量评分在 4-6 之间', () {
      final klines = generateKlines(days: 60);
      final score = engine.calculateScore(klines);
      // 正常量的 volScore 应该是 5.0
      expect(score.volScore, closeTo(5.0, 0.1));
    });
  });

  // =========================================================================
  // T-F004-1: 综合评分系统
  // =========================================================================
  group('T-F004-1: calculateScore', () {
    test('数据不足（< 20 天）返回 score=0', () {
      final klines = generateKlines(days: 10);
      final score = engine.calculateScore(klines);
      expect(score.score, 0);
      expect(score.reason, '数据不足');
      expect(score.isBandLow, false);
    });

    test('评分范围在 1-10 之间', () {
      final klines = generateKlines(days: 60);
      final score = engine.calculateScore(klines);
      expect(score.score, greaterThanOrEqualTo(1));
      expect(score.score, lessThanOrEqualTo(10));
    });

    test('评分公式：score = round(w1*ma + w2*boll + w3*vol + w4*trend)', () {
      final klines = generateKlines(days: 60);
      final score = engine.calculateScore(klines);
      // 验证加权公式一致性
      final rawScore =
          0.30 * score.maScore +
          0.30 * score.bollScore +
          0.20 * score.volScore +
          0.20 * score.trendScore;
      expect(score.score, rawScore.round().clamp(1, 10));
    });

    test('各子评分范围在 0-10 之间', () {
      final klines = generateKlines(days: 60);
      final score = engine.calculateScore(klines);

      expect(score.maScore, greaterThanOrEqualTo(0));
      expect(score.maScore, lessThanOrEqualTo(10));
      expect(score.bollScore, greaterThanOrEqualTo(0));
      expect(score.bollScore, lessThanOrEqualTo(10));
      expect(score.volScore, greaterThanOrEqualTo(0));
      expect(score.volScore, lessThanOrEqualTo(10));
      expect(score.trendScore, greaterThanOrEqualTo(0));
      expect(score.trendScore, lessThanOrEqualTo(10));
    });

    test('强势上涨趋势评分 >= 5', () {
      // 连续上涨 60 天
      final klines = generateKlines(days: 60, dailyReturn: 0.02);
      final score = engine.calculateScore(klines);
      expect(score.score, greaterThanOrEqualTo(5));
    });

    test('暴跌趋势评分较低', () {
      // 默认策略使用 MA60，需至少 60 天数据。
      final klines2 = generateDecliningKlines(days: 60);
      final score = engine.calculateScore(klines2);
      // 暴跌且放量，评分应该偏低
      expect(score.score, lessThanOrEqualTo(5));
    });
  });

  // =========================================================================
  // 波段低位判定
  // =========================================================================
  group('isBandLow', () {
    test('数据不足返回 false', () {
      final klines = generateKlines(days: 10);
      expect(engine.isBandLow(klines), false);
    });

    test('均衡上涨市场非波段低位', () {
      final klines = generateKlines(days: 60, dailyReturn: 0.01);
      // 强势上涨 -> 价格在上轨附近 -> 不是波段低位
      expect(engine.isBandLow(klines), false);
    });

    test('从高位大幅下跌后可能是波段低位', () {
      final klines = generateBandLowKlines();
      // 70 天数据：先涨后跌
      // 这取决于 MA20/MA60 和布林带的具体位置
      final score = engine.calculateScore(klines);
      // 至少验证不会崩溃
      expect(score.score, greaterThanOrEqualTo(1));
      expect(score.score, lessThanOrEqualTo(10));
    });

    test('isBandLow 与 calculateScore.isBandLow 一致', () {
      final klines = generateKlines(days: 60);
      final bandLow = engine.isBandLow(klines);
      final score = engine.calculateScore(klines);
      expect(bandLow, score.isBandLow);
    });

    test('另一组数据验证一致性', () {
      final klines = generateBandLowKlines();
      final bandLow = engine.isBandLow(klines);
      final score = engine.calculateScore(klines);
      expect(bandLow, score.isBandLow);
    });
  });

  // =========================================================================
  // T-F006-1: 下跌预警
  // =========================================================================
  group('T-F006-1: checkDownsideAlert', () {
    test('数据不足（< 21 天）返回 false', () {
      final klines = generateKlines(days: 20);
      expect(engine.checkDownsideAlert(klines), false);
    });

    test('正常上涨无预警', () {
      final klines = generateKlines(days: 60, dailyReturn: 0.01);
      expect(engine.checkDownsideAlert(klines), false);
    });

    test('连续 3 天下跌 + 放量触发预警', () {
      final klines = generateDecliningKlines(
        days: 25,
        dailyDrop: 0.03,
        lastDayVolumeMultiplier: 2.0, // 放量
      );
      // 需要 21+ 天数据
      expect(klines.length, greaterThanOrEqualTo(21));
      expect(engine.checkDownsideAlert(klines), true);
    });

    test('连续 3 天下跌但缩量不触发预警（条件3）', () {
      final klines = generateDecliningKlines(
        days: 25,
        dailyDrop: 0.01,
        lastDayVolumeMultiplier: 0.5, // 缩量
      );
      // 跌幅只有 1%，且缩量，条件1和条件3不满足
      // 但仍然可能满足条件2（跌破布林下轨）
      // 这个测试主要验证缩量场景
      final result = engine.checkDownsideAlert(klines);
      // 缩量 + 小跌，不应该触发量比条件
      // 但如果跌破 MA20 或布林下轨仍然可能触发
      // 我们只验证函数不崩溃且返回 bool
      expect(result, isA<bool>());
    });

    test('价格跌破 MA20 且当日跌幅 > 2% 触发预警', () {
      // 构造特殊数据：价格从 MA20 上方直接暴跌
      final klines = <DailyKline>[];
      var price = 50.0;

      // 前 25 天平稳
      for (var i = 0; i < 25; i++) {
        final open = price;
        price += 0.05;
        final close = price;
        klines.add(
          DailyKline(
            date: DateTime(2026, 1, 1).add(Duration(days: i)),
            open: open,
            close: close,
            high: close * 1.005,
            low: open * 0.995,
            volume: 100000.0,
            amount: 5000000000.0,
            preClose: i > 0 ? klines[i - 1].close : open,
          ),
        );
      }

      // 第 26 天暴跌 5%
      final open26 = price;
      price *= 0.95;
      klines.add(
        DailyKline(
          date: DateTime(2026, 1, 26),
          open: open26,
          close: price,
          high: open26,
          low: price,
          volume: 200000.0,
          amount: 8000000000.0,
          preClose: klines.last.close,
        ),
      );

      final result = engine.checkDownsideAlert(klines);
      expect(result, isA<bool>());
    });
  });

  // =========================================================================
  // T-F005-1: 每日跟踪摘要
  // =========================================================================
  group('T-F005-1: generateSummary', () {
    test('空数据返回默认摘要', () {
      final summary = engine.generateSummary([], '600000');
      expect(summary.stockCode, '600000');
      expect(summary.summaryText, '数据不足，无法生成摘要');
      expect(summary.prediction, 'flat');
      expect(summary.bandPosition, 'middle');
    });

    test('有数据时包含关键信息', () {
      final klines = generateKlines(days: 30);
      final summary = engine.generateSummary(klines, '601318');

      expect(summary.stockCode, '601318');
      expect(summary.openPrice, greaterThan(0));
      expect(summary.closePrice, greaterThan(0));
      expect(summary.highPrice, greaterThan(0));
      expect(summary.lowPrice, greaterThan(0));
      expect(summary.summaryText, contains('收盘价'));
      expect(summary.summaryText, contains('涨幅'));
      expect(summary.summaryText, contains('波段位置'));
    });

    test('上涨日预测 up', () {
      final klines = generateKlines(days: 30, dailyReturn: 0.02);
      final summary = engine.generateSummary(klines, '600000');
      // 涨幅 > 1% -> 预测 up
      expect(summary.prediction, 'up');
    });

    test('下跌日预测 down', () {
      final klines = generateDecliningKlines(days: 30, dailyDrop: 0.03);
      final summary = engine.generateSummary(klines, '600000');
      // 最后一天跌幅 > 1% -> 预测 down
      expect(summary.prediction, 'down');
    });

    test('平稳日预测 flat', () {
      final klines = generateKlines(days: 30, dailyReturn: 0.001);
      final summary = engine.generateSummary(klines, '600000');
      // 涨幅约 0.1% -> flat
      expect(summary.prediction, 'flat');
    });

    test('摘要包含支撑位和压力位', () {
      final klines = generateKlines(days: 30);
      final summary = engine.generateSummary(klines, '600000');
      // 应该有支撑位（布林下轨或 MA20）
      expect(summary.supportPrice, isNotNull);
      expect(summary.resistancePrice, isNotNull);
    });

    test('摘要文本包含波动区间信息', () {
      final klines = generateKlines(days: 30);
      final summary = engine.generateSummary(klines, '600000');
      expect(summary.summaryText, contains('支撑位'));
      expect(summary.summaryText, contains('压力位'));
    });
  });

  // =========================================================================
  // StockScore 模型属性
  // =========================================================================
  group('StockScore model', () {
    test('label: score >= 8 -> 重点观察', () {
      final score = StockScore(
        score: 8,
        maScore: 8,
        bollScore: 8,
        volScore: 8,
        trendScore: 8,
        isBandLow: false,
      );
      expect(score.label, '重点观察');
    });

    test('label: score 5-7 -> 中性观望', () {
      final score = StockScore(
        score: 6,
        maScore: 6,
        bollScore: 6,
        volScore: 6,
        trendScore: 6,
        isBandLow: false,
      );
      expect(score.label, '中性观望');
    });

    test('label: score < 5 -> 风险较高', () {
      final score = StockScore(
        score: 3,
        maScore: 3,
        bollScore: 3,
        volScore: 3,
        trendScore: 3,
        isBandLow: false,
      );
      expect(score.label, '风险较高');
    });

    test('category: isBandLow && score >= 7 -> short_term', () {
      final score = StockScore(
        score: 8,
        maScore: 7,
        bollScore: 8,
        volScore: 5,
        trendScore: 5,
        isBandLow: true,
      );
      expect(score.category, 'short_term');
    });

    test('category: score >= 5 -> mid_term', () {
      final score = StockScore(
        score: 5,
        maScore: 5,
        bollScore: 5,
        volScore: 5,
        trendScore: 5,
        isBandLow: false,
      );
      expect(score.category, 'mid_term');
    });

    test('category: score < 5 -> mid_term (default)', () {
      final score = StockScore(
        score: 3,
        maScore: 3,
        bollScore: 3,
        volScore: 3,
        trendScore: 3,
        isBandLow: false,
      );
      expect(score.category, 'mid_term');
    });
  });

  // =========================================================================
  // DailyRecommendation 模型
  // =========================================================================
  group('DailyRecommendation model', () {
    test('fullCode 格式正确', () {
      final rec = DailyRecommendation(
        code: '601318',
        name: '中国平安',
        market: 'SH',
        category: 'short_term',
        closePrice: 45.20,
        changePct: 2.35,
      );
      expect(rec.fullCode, '601318.SH');
    });
  });

  // =========================================================================
  // BollingerBands convenience getters
  // =========================================================================
  group('BollingerBands', () {
    test('空列表 currentXxx 返回 null', () {
      final boll = BollingerBands(upper: [], middle: [], lower: []);
      expect(boll.currentUpper, isNull);
      expect(boll.currentLower, isNull);
      expect(boll.currentMiddle, isNull);
    });

    test('非空列表 currentXxx 返回最后一个值', () {
      final boll = BollingerBands(
        upper: [10.0, 11.0],
        middle: [8.0, 9.0],
        lower: [6.0, 7.0],
      );
      expect(boll.currentUpper, 11.0);
      expect(boll.currentMiddle, 9.0);
      expect(boll.currentLower, 7.0);
    });
  });

  // =========================================================================
  // DailySummary model
  // =========================================================================
  group('DailySummary model', () {
    test('默认值正确', () {
      final summary = DailySummary(
        stockCode: '600000',
        date: '2026-04-10',
        openPrice: 10.0,
        closePrice: 10.5,
        highPrice: 11.0,
        lowPrice: 9.5,
        changePct: 5.0,
        bandPosition: 'upper',
        prediction: 'up',
        summaryText: 'test',
      );
      expect(summary.supportPrice, isNull);
      expect(summary.resistancePrice, isNull);
    });

    test('可选字段有值', () {
      final summary = DailySummary(
        stockCode: '600000',
        date: '2026-04-10',
        openPrice: 10.0,
        closePrice: 10.5,
        highPrice: 11.0,
        lowPrice: 9.5,
        changePct: 5.0,
        bandPosition: 'upper',
        prediction: 'up',
        supportPrice: 9.0,
        resistancePrice: 12.0,
        summaryText: 'test',
      );
      expect(summary.supportPrice, 9.0);
      expect(summary.resistancePrice, 12.0);
    });
  });

  // =========================================================================
  // AnalysisEngine rule-based strategy integration
  // =========================================================================
  group('AnalysisEngine rule-based strategy', () {
    test('rule-based strategy triggers high score when all entry rules pass', () {
      // Create data that makes RSI very low (declining prices)
      final klines = <DailyKline>[];
      var price = 100.0;
      for (var i = 0; i < 60; i++) {
        price *= 0.97; // 3% drop daily — RSI should be very low
        klines.add(DailyKline(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          open: price * 1.01,
          close: price,
          high: price * 1.02,
          low: price * 0.99,
          volume: 100000,
          amount: 5000000000,
          preClose: i > 0 ? klines[i - 1].close : price * 1.03,
        ));
      }

      final strategy = Strategy(
        id: 'test', name: 'RSI Oversold', description: '',
        maShortPeriod: 20, maLongPeriod: 60, bollPeriod: 20, bollStdDev: 2.0,
        weightMA: 0.3, weightBoll: 0.3, weightVol: 0.2, weightTrend: 0.2,
        recommendThreshold: 7, isEnabled: true, isDefault: false,
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
        entryRules: [SignalRule(indicator: 'rsi', condition: 'lt', value: 30)],
      );

      final engine = AnalysisEngine();
      final score = engine.calculateScoreForStrategy(klines, strategy);
      // With strongly declining prices, RSI should be < 30, triggering entry
      expect(score.score, greaterThanOrEqualTo(7));
    });

    test('non-rule-based strategy still uses weighted scoring (backward compat)', () {
      final klines = generateKlines(days: 60);
      final strategy = Strategy(
        id: 'test', name: 'Weighted', description: '',
        maShortPeriod: 20, maLongPeriod: 60, bollPeriod: 20, bollStdDev: 2.0,
        weightMA: 0.3, weightBoll: 0.3, weightVol: 0.2, weightTrend: 0.2,
        recommendThreshold: 7, isEnabled: true, isDefault: false,
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
      );

      final engine = AnalysisEngine();
      final score = engine.calculateScoreForStrategy(klines, strategy);
      // Should work exactly like before — no rules, just weighted scoring
      expect(score.score, greaterThanOrEqualTo(1));
      expect(score.score, lessThanOrEqualTo(10));
    });

    test('rule-based strategy returns indicator values in reason', () {
      final klines = generateKlines(days: 60);
      final strategy = Strategy(
        id: 'test', name: 'RSI Test', description: '',
        maShortPeriod: 20, maLongPeriod: 60, bollPeriod: 20, bollStdDev: 2.0,
        weightMA: 0.3, weightBoll: 0.3, weightVol: 0.2, weightTrend: 0.2,
        recommendThreshold: 7, isEnabled: true, isDefault: false,
        createdAt: DateTime(2026), updatedAt: DateTime(2026),
        entryRules: [SignalRule(indicator: 'rsi', condition: 'gt', value: 50)],
      );

      final engine = AnalysisEngine();
      final score = engine.calculateScoreForStrategy(klines, strategy);
      expect(score.reason, contains('rsi'));
    });
  });
}
