// K-line chart widget + adapter tests.
//
// Covers two layers:
//   1. toKLineEntries: pure-function mapping DailyKline → KLineEntity, with
//      assertions on OHLCV fidelity and time conversion. This is the most
//      valuable test — wrong mapping would invert the chart.
//   2. StockKlineChart: a smoke mount that the k_chart widget builds without
//      throwing for a representative data set (real pixel rendering cannot be
//      asserted in widget tests).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:stockpilot/features/stock/domain/stock_models.dart';
import 'package:stockpilot/features/stock/presentation/kline_chart/kline_adapter.dart';
import 'package:stockpilot/features/stock/presentation/kline_chart/stock_kline_chart.dart';

/// Minimal DailyKline generator for chart tests (mirrors the helper in
/// analysis_engine_test.dart, kept local so this file is self-contained).
List<DailyKline> _generateKlines({
  int days = 60,
  double startPrice = 40.0,
  double dailyReturn = 0.001,
}) {
  final klines = <DailyKline>[];
  var price = startPrice;
  for (var i = 0; i < days; i++) {
    final open = price;
    price = price * (1 + dailyReturn);
    final close = price;
    klines.add(
      DailyKline(
        date: DateTime(2026, 1, 1).add(Duration(days: i)),
        open: open,
        close: close,
        high: close * 1.01,
        low: open * 0.99,
        volume: 100000.0,
        amount: 5000000000.0,
        preClose: i > 0 ? klines[i - 1].close : open * 0.99,
      ),
    );
  }
  return klines;
}

void main() {
  group('toKLineEntries', () {
    test('maps OHLCV fields faithfully', () {
      final klines = _generateKlines(days: 3);
      final entries = toKLineEntries(klines);

      expect(entries.length, 3);
      for (var i = 0; i < klines.length; i++) {
        expect(entries[i].open, klines[i].open);
        expect(entries[i].high, klines[i].high);
        expect(entries[i].low, klines[i].low);
        expect(entries[i].close, klines[i].close);
        expect(entries[i].vol, klines[i].volume);
        expect(entries[i].amount, klines[i].amount);
      }
    });

    test('converts date to millisecond epoch', () {
      final klines = _generateKlines(days: 1);
      final entries = toKLineEntries(klines);

      expect(entries[0].time, isNotNull);
      expect(
        entries[0].time!,
        klines[0].date.millisecondsSinceEpoch,
      );
    });

    test('preserves oldest→newest ordering', () {
      final klines = _generateKlines(days: 5);
      final entries = toKLineEntries(klines);

      // The chart library requires this order; an inversion would draw the
      // newest candle on the left.
      for (var i = 1; i < entries.length; i++) {
        expect(entries[i].time!, greaterThan(entries[i - 1].time!));
      }
    });

    test('empty input yields empty output', () {
      expect(toKLineEntries([]), isEmpty);
    });
  });

  group('StockKlineChart', () {
    testWidgets('mounts without throwing for representative data', (
      tester,
    ) async {
      final klines = _generateKlines(days: 60);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockKlineChart(klines: klines),
            ),
          ),
        ),
      );
      // Let the chart's first frame / layout pass complete.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The underlying chart widget should be present.
      expect(find.byType(KChartWidget), findsOneWidget);
    });

    testWidgets('recomputes when klines change', (tester) async {
      var klines = _generateKlines(days: 60);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockKlineChart(klines: klines),
            ),
          ),
        ),
      );
      await tester.pump();

      // Swap to a longer series and rebuild — should not throw.
      klines = _generateKlines(days: 120);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockKlineChart(klines: klines),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(KChartWidget), findsOneWidget);
    });
  });
}
