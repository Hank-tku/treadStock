// T-UTL-01: Formatters 工具类测试

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/shared/utils/formatters.dart';

void main() {
  group('T-UTL-01: Formatters', () {
    group('formatPrice', () {
      test('正常价格格式化', () {
        expect(Formatters.formatPrice(45.20), '¥45.20');
      });

      test('null 返回 --', () {
        expect(Formatters.formatPrice(null), '--');
      });

      test('0 返回 --', () {
        expect(Formatters.formatPrice(0), '--');
      });
    });

    group('formatPriceLarge', () {
      test('正常价格格式化', () {
        expect(Formatters.formatPriceLarge(100.5), '¥100.50');
      });

      test('null 返回 --', () {
        expect(Formatters.formatPriceLarge(null), '--');
      });
    });

    group('formatChangePct', () {
      test('正值显示 + 号', () {
        expect(Formatters.formatChangePct(2.35), '+2.35%');
      });

      test('负值显示 - 号', () {
        expect(Formatters.formatChangePct(-1.28), '-1.28%');
      });

      test('0 显示 +0.00%', () {
        expect(Formatters.formatChangePct(0), '+0.00%');
      });

      test('null 返回 --', () {
        expect(Formatters.formatChangePct(null), '--');
      });
    });

    group('formatChangeAmt', () {
      test('正值显示 + 号', () {
        expect(Formatters.formatChangeAmt(1.05), '+1.05');
      });

      test('负值显示 - 号', () {
        expect(Formatters.formatChangeAmt(-0.82), '-0.82');
      });

      test('null 返回 --', () {
        expect(Formatters.formatChangeAmt(null), '--');
      });
    });

    group('formatMarketCap', () {
      test('正常值显示', () {
        expect(Formatters.formatMarketCap(8542.0), '8,542亿');
      });

      test('大于 10000 显示万亿', () {
        expect(Formatters.formatMarketCap(25000.0), '2.5万亿');
      });

      test('null 返回 --', () {
        expect(Formatters.formatMarketCap(null), '--');
      });
    });

    group('formatPE', () {
      test('正常值', () {
        expect(Formatters.formatPE(12.8), '12.8');
      });

      test('null 返回 --', () {
        expect(Formatters.formatPE(null), '--');
      });
    });

    group('formatVolume', () {
      test('正常值带千分位', () {
        expect(Formatters.formatVolume(125400.0), '125,400手');
      });

      test('null 返回 --', () {
        expect(Formatters.formatVolume(null), '--');
      });
    });

    group('formatDate', () {
      test('正确格式化', () {
        final date = DateTime(2026, 4, 10);
        expect(Formatters.formatDate(date), '4月10日');
      });

      test('单数月日', () {
        final date = DateTime(2026, 1, 5);
        expect(Formatters.formatDate(date), '1月5日');
      });
    });

    group('formatTime', () {
      test('正确格式化', () {
        final date = DateTime(2026, 4, 10, 14, 30);
        expect(Formatters.formatTime(date), '14:30');
      });

      test('单数时分补零', () {
        final date = DateTime(2026, 4, 10, 9, 5);
        expect(Formatters.formatTime(date), '09:05');
      });
    });

    group('formatRelativeTime', () {
      test('不到 1 分钟 -> 刚刚', () {
        final now = DateTime.now();
        expect(Formatters.formatRelativeTime(now), '刚刚');
      });

      test('30 分钟前', () {
        final time = DateTime.now().subtract(Duration(minutes: 30));
        expect(Formatters.formatRelativeTime(time), '30分钟前');
      });

      test('2 小时前', () {
        final time = DateTime.now().subtract(Duration(hours: 2));
        expect(Formatters.formatRelativeTime(time), '2小时前');
      });

      test('昨天', () {
        final time = DateTime.now().subtract(Duration(hours: 25));
        expect(Formatters.formatRelativeTime(time), '昨天');
      });

      test('3 天前', () {
        final time = DateTime.now().subtract(Duration(days: 3));
        expect(Formatters.formatRelativeTime(time), '3天前');
      });

      test('7 天前显示日期', () {
        final time = DateTime.now().subtract(Duration(days: 10));
        final formatted = Formatters.formatRelativeTime(time);
        // 应该是 "X月X日" 格式
        expect(formatted, contains('月'));
        expect(formatted, contains('日'));
      });
    });

    group('formatRange', () {
      test('正常范围', () {
        expect(Formatters.formatRange(43.5, 46.8), '预期波动 ¥43.5-¥46.8');
      });

      test('null 返回 --', () {
        expect(Formatters.formatRange(null, 46.8), '--');
        expect(Formatters.formatRange(43.5, null), '--');
        expect(Formatters.formatRange(null, null), '--');
      });
    });
  });
}
