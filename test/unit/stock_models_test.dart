// T-MOD-01, T-MOD-02, T-MOD-03, T-MOD-04
// 测试数据模型解析：StockQuote、DailyKline、WatchlistItem

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/analysis/domain/analysis_models.dart';

void main() {
  // =========================================================================
  // T-MOD-01: StockQuote.fromJson
  // =========================================================================
  group('T-MOD-01: StockQuote.fromJson', () {
    test('正确解析东方财富实时行情 JSON', () {
      final json = {
        'f2': 45.20, // 最新价
        'f3': 2.35, // 涨跌幅
        'f4': 1.05, // 涨跌额
        'f5': 125400, // 成交量
        'f6': 5678000000, // 成交额
        'f7': 2.85, // 振幅
        'f8': 1.23, // 换手率
        'f12': '601318', // 代码
        'f14': '中国平安', // 名称
        'f15': 45.80, // 最高价
        'f16': 44.50, // 最低价
        'f17': 44.80, // 开盘价
        'f18': 44.15, // 昨收
      };

      final quote = StockQuote.fromJson(json);

      expect(quote.price, 45.20);
      expect(quote.changePct, 2.35);
      expect(quote.changeAmt, 1.05);
      expect(quote.volume, 125400);
      expect(quote.turnover, 1.23);
      expect(quote.code, '601318');
      expect(quote.name, '中国平安');
      expect(quote.highPrice, 45.80);
      expect(quote.lowPrice, 44.50);
      expect(quote.openPrice, 44.80);
      expect(quote.preClose, 44.15);
    });

    test('市场检测：6 开头 -> SH', () {
      final json = {'f12': '600000', 'f14': '浦发银行'};
      final quote = StockQuote.fromJson(json);
      expect(quote.market, 'SH');
    });

    test('市场检测：9 开头 -> SH', () {
      final json = {'f12': '900901', 'f14': '某B股'};
      final quote = StockQuote.fromJson(json);
      expect(quote.market, 'SH');
    });

    test('市场检测：0 开头 -> SZ', () {
      final json = {'f12': '000001', 'f14': '平安银行'};
      final quote = StockQuote.fromJson(json);
      expect(quote.market, 'SZ');
    });

    test('市场检测：3 开头 -> SZ (创业板)', () {
      final json = {'f12': '300750', 'f14': '宁德时代'};
      final quote = StockQuote.fromJson(json);
      expect(quote.market, 'SZ');
    });

    test('缺失字段默认为 0 或空字符串', () {
      final json = <String, dynamic>{};
      final quote = StockQuote.fromJson(json);

      expect(quote.price, 0.0);
      expect(quote.changePct, 0.0);
      expect(quote.code, '');
      expect(quote.name, '');
      expect(quote.market, 'SZ'); // 空字符串不以 6/9 开头，默认 SZ
    });

    test('字段值为 "-" 时解析为 0.0', () {
      final json = {'f2': '-', 'f3': '-', 'f12': '601318', 'f14': 'test'};
      final quote = StockQuote.fromJson(json);
      expect(quote.price, 0.0);
      expect(quote.changePct, 0.0);
    });

    test('字段值为 int 时正确转换', () {
      final json = {'f2': 45, 'f3': 2, 'f12': '601318', 'f14': 'test'};
      final quote = StockQuote.fromJson(json);
      expect(quote.price, 45.0);
      expect(quote.changePct, 2.0);
    });

    test('字段值为 String 时正确转换', () {
      final json = {
        'f2': '45.20',
        'f3': '2.35',
        'f12': '601318',
        'f14': 'test',
      };
      final quote = StockQuote.fromJson(json);
      expect(quote.price, 45.20);
      expect(quote.changePct, 2.35);
    });

    test('fullCode 格式正确', () {
      final json = {'f12': '601318', 'f14': '中国平安'};
      final quote = StockQuote.fromJson(json);
      expect(quote.fullCode, '601318.SH');
    });

    test('f20 总市值换算为亿元 (÷1e8)', () {
      // f20 返回元，例如 1.62e11 元 = 1620 亿元
      final json = {
        'f12': '601318',
        'f14': '中国平安',
        'f20': 162000000000.0,
      };
      final quote = StockQuote.fromJson(json);
      expect(quote.marketCap, closeTo(1620.0, 0.01));
    });

    test('f100 行业字段正确解析', () {
      final json = {
        'f12': '002472',
        'f14': '双环传动',
        'f100': '汽车',
      };
      final quote = StockQuote.fromJson(json);
      expect(quote.industry, '汽车');
    });

    test('缺少 f20/f100 时 marketCap/industry 为 null', () {
      // Sina 回退路径无这两个字段，必须容忍 null。
      final json = {'f12': '601318', 'f14': '中国平安'};
      final quote = StockQuote.fromJson(json);
      expect(quote.marketCap, isNull);
      expect(quote.industry, isNull);
    });

    test('copyWith 正确更新指定字段', () {
      const quote = StockQuote(
        code: '601318',
        name: '中国平安',
        market: 'SH',
        price: 45.20,
        changePct: 2.35,
        changeAmt: 1.05,
        openPrice: 44.80,
        highPrice: 45.80,
        lowPrice: 44.50,
        preClose: 44.15,
        volume: 125400,
        turnover: 1.23,
      );
      final updated = quote.copyWith(price: 50.0, changePct: 5.0);
      expect(updated.price, 50.0);
      expect(updated.changePct, 5.0);
      expect(updated.code, '601318'); // 其他字段不变
      expect(updated.name, '中国平安');
    });

    test('fromRealtimeJson 正确解析 stock/get 缩放字段', () {
      final quote = StockQuote.fromRealtimeJson(
        {
          'f43': 4286,
          'f44': 4421,
          'f45': 3905,
          'f46': 4140,
          'f47': 561344,
          'f48': 2349735662.29,
          'f57': '002472',
          'f58': '双环传动',
          'f60': 4139,
          'f168': 750,
          'f169': 147,
          'f170': 355,
        },
        fallbackCode: '002472',
        fallbackMarket: 'SZ',
      );

      expect(quote.code, '002472');
      expect(quote.name, '双环传动');
      expect(quote.market, 'SZ');
      expect(quote.price, 42.86);
      expect(quote.changePct, 3.55);
      expect(quote.changeAmt, 1.47);
      expect(quote.openPrice, 41.40);
      expect(quote.highPrice, 44.21);
      expect(quote.lowPrice, 39.05);
      expect(quote.preClose, 41.39);
      expect(quote.turnover, 7.50);
    });
  });

  // =========================================================================
  // T-MOD-02: DailyKline.fromEastMoney
  // =========================================================================
  group('T-MOD-02: DailyKline.fromEastMoney', () {
    test('正确解析标准 K 线字符串', () {
      const klineStr = '2026-04-10,44.80,45.20,45.80,44.50,125400,5678000000';
      final kline = DailyKline.fromEastMoney(klineStr);

      expect(kline.date, DateTime(2026, 4, 10));
      expect(kline.open, 44.80);
      expect(kline.close, 45.20);
      expect(kline.high, 45.80);
      expect(kline.low, 44.50);
      expect(kline.volume, 125400);
      expect(kline.amount, 5678000000);
    });

    test('preClose 默认为 0', () {
      const klineStr = '2026-04-10,44.80,45.20,45.80,44.50,125400,5678000000';
      final kline = DailyKline.fromEastMoney(klineStr);
      expect(kline.preClose, 0);
    });
  });

  // =========================================================================
  // T-MOD-03: DailyKline.parseKlines preClose 填充
  // =========================================================================
  group('T-MOD-03: DailyKline.parseKlines', () {
    test('preClose 从前一天 close 自动填充', () {
      final klineStrings = [
        '2026-04-08,44.00,44.50,45.00,43.50,100000,4500000000',
        '2026-04-09,44.50,45.00,45.50,44.00,110000,4900000000',
        '2026-04-10,45.00,45.20,45.80,44.80,120000,5400000000',
      ];

      final klines = DailyKline.parseKlines(klineStrings);

      expect(klines.length, 3);

      // 第一条 preClose = 0（无前一天数据）
      expect(klines[0].preClose, 0);
      expect(klines[0].close, 44.50);

      // 第二条 preClose = 第一条的 close
      expect(klines[1].preClose, 44.50);
      expect(klines[1].close, 45.00);

      // 第三条 preClose = 第二条的 close
      expect(klines[2].preClose, 45.00);
      expect(klines[2].close, 45.20);
    });

    test('单条 K 线 preClose 为 0', () {
      final klineStrings = [
        '2026-04-10,44.80,45.20,45.80,44.50,125400,5678000000',
      ];
      final klines = DailyKline.parseKlines(klineStrings);
      expect(klines[0].preClose, 0);
    });

    test('changePct 正确计算', () {
      final klineStrings = [
        '2026-04-08,100.00,110.00,111.00,99.00,100000,10000000000',
        '2026-04-09,110.00,121.00,122.00,109.00,100000,12000000000',
      ];
      final klines = DailyKline.parseKlines(klineStrings);

      // 第一条 preClose=0 -> changePct=0
      expect(klines[0].changePct, 0);

      // 第二条 preClose=110, close=121 -> changePct = (121-110)/110 * 100 = 10%
      expect(klines[1].changePct, closeTo(10.0, 0.01));
    });
  });

  // =========================================================================
  // T-MOD-04: WatchlistItem.copyWith
  // =========================================================================
  group('T-MOD-04: WatchlistItem', () {
    test('copyWith 正确拷贝所有字段', () {
      final now = DateTime(2026, 4, 10);
      final item2 = WatchlistItem(
        id: 'test-id',
        stockCode: '601318',
        stockName: '中国平安',
        market: 'SH',
        isPinned: false,
        sortOrder: 0,
        alertEnabled: true,
        createdAt: now,
        updatedAt: now,
      );

      final updated = item2.copyWith(
        isPinned: true,
        sortOrder: 5,
        currentPrice: 50.0,
        currentChangePct: 3.0,
      );

      expect(updated.id, 'test-id');
      expect(updated.stockCode, '601318');
      expect(updated.stockName, '中国平安');
      expect(updated.market, 'SH');
      expect(updated.isPinned, true);
      expect(updated.sortOrder, 5);
      expect(updated.alertEnabled, true);
      expect(updated.currentPrice, 50.0);
      expect(updated.currentChangePct, 3.0);
      // createdAt 不变
      expect(updated.createdAt, now);
      // updatedAt 应该被更新
      expect(updated.updatedAt.isAfter(now) || updated.updatedAt == now, true);
    });

    test('fullCode 格式正确', () {
      final item = WatchlistItem(
        id: 'test',
        stockCode: '000001',
        stockName: '平安银行',
        market: 'SZ',
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );
      expect(item.fullCode, '000001.SZ');
    });

    test('mutable real-time fields 默认为 null', () {
      final item = WatchlistItem(
        id: 'test',
        stockCode: '600000',
        stockName: '浦发银行',
        market: 'SH',
        createdAt: DateTime(2026, 4, 10),
        updatedAt: DateTime(2026, 4, 10),
      );
      expect(item.currentPrice, isNull);
      expect(item.currentChangePct, isNull);
      expect(item.currentScore, isNull);
      expect(item.isAlertTriggered, isNull);
      expect(item.supportPrice, isNull);
      expect(item.resistancePrice, isNull);
    });
  });

  // =========================================================================
  // StockSearchResult.fromJson
  // =========================================================================
  group('StockSearchResult.fromJson', () {
    test('正确解析搜索结果', () {
      final json = {'Code': '601318', 'Name': '中国平安'};
      final result = StockSearchResult.fromJson(json);
      expect(result.code, '601318');
      expect(result.name, '中国平安');
      expect(result.market, 'SH');
    });

    test('缺失字段默认空字符串', () {
      final json = <String, dynamic>{};
      final result = StockSearchResult.fromJson(json);
      expect(result.code, '');
      expect(result.name, '');
      expect(result.market, 'SZ');
    });

    test('fullCode 格式正确', () {
      final json = {'Code': '000001', 'Name': '平安银行'};
      final result = StockSearchResult.fromJson(json);
      expect(result.fullCode, '000001.SZ');
    });
  });
}
