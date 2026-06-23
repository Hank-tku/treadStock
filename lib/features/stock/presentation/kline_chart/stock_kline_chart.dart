import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:k_chart_plus/k_chart_plus.dart';
import 'package:k_chart_plus/chart_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../stock/domain/stock_models.dart';
import 'kline_adapter.dart';

/// A K-line (candlestick) chart for the stock detail page.
///
/// Wraps k_chart_plus's [KChartWidget] with the app's A-stock color
/// convention (red = up, green = down) and overlays MA20/MA60 plus Bollinger
/// Bands. Volume is shown as a secondary sub-chart.
///
/// The chart requires a bounded height, so callers must place it inside a
/// fixed-height container (e.g. a SizedBox) — see [StockKlineChart.defaultHeight].
class StockKlineChart extends StatefulWidget {
  const StockKlineChart({super.key, required this.klines});

  /// Source K-line data, oldest → newest.
  final List<DailyKline> klines;

  /// Recommended chart height (main chart + volume sub-chart + padding).
  static const double defaultHeight = 360;

  @override
  State<StockKlineChart> createState() => _StockKlineChartState();
}

class _StockKlineChartState extends State<StockKlineChart> {
  List<KLineEntity>? _datas;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(covariant StockKlineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.klines != widget.klines) {
      _recompute();
    }
  }

  void _recompute() {
    // Map domain data, then let the library fill in MA / BOLL / volume
    // indicator values in-place. MA day list = [20, 60] per A-stock convention.
    final entries = toKLineEntries(widget.klines);
    DataUtil.calculate(entries, [20, 60]);
    _datas = entries;
  }

  @override
  Widget build(BuildContext context) {
    final datas = _datas;
    if (datas == null || datas.isEmpty) {
      return const SizedBox.shrink();
    }

    // A-stock color convention: red = up, green = down. k_chart_plus defaults
    // to the international convention (green = up), so every up/down pair must
    // be overridden explicitly to avoid a fully inverted chart.
    final chartColors = ChartColors()
      ..bgColor = Colors.transparent
      ..upColor = StockColors.up
      ..dnColor = StockColors.down
      ..volColor = context.sc.textTertiary
      // Volume bars reuse the up/down palette.
      ..nowPriceUpColor = StockColors.up
      ..nowPriceDnColor = StockColors.down
      // MA line colors: ma5Color maps to the first MA day (MA20 here),
      // ma30Color to the second (MA60).
      ..ma5Color = StockColors.brand
      ..ma30Color = StockColors.warning
      // Bollinger band lines in muted tones.
      ..kLineColor = context.sc.textSecondary
      // Grid + crosshair in border tones.
      ..gridColor = context.sc.border
      ..hCrossColor = context.sc.textSecondary
      ..selectFillColor = StockColors.up.withValues(alpha: 0.1)
      ..selectBorderColor = StockColors.up
      ..infoWindowTitleColor = context.sc.textPrimary
      ..infoWindowNormalColor = context.sc.textSecondary
      ..infoWindowUpColor = StockColors.up
      ..infoWindowDnColor = StockColors.down;

    final chartStyle = ChartStyle();

    return SizedBox(
      height: StockKlineChart.defaultHeight,
      child: KChartWidget(
        datas,
        chartStyle,
        chartColors,
        isTrendLine: false,
        // Overlay both MA and Bollinger Bands on the main chart.
        mainStateLi: const {MainState.MA, MainState.BOLL},
        // Keep the volume sub-chart visible.
        volHidden: false,
        showNowPrice: true,
        showInfoDialog: true,
        // Long-press tooltip shows OHLC values — standard for market apps.
        isTapShowInfoDialog: false,
        timeFormat: TimeFormat.YEAR_MONTH_DAY,
        maDayList: const [20, 60],
        mBaseHeight: StockKlineChart.defaultHeight,
        chartTranslations: const ChartTranslations(),
      ),
    );
  }
}
