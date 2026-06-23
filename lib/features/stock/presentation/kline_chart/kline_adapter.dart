import 'package:k_chart_plus/k_chart_plus.dart';
import '../../../stock/domain/stock_models.dart';

/// Maps our domain [DailyKline] list into the [KLineEntry] list expected by
/// k_chart_plus.
///
/// DailyKline is already ordered oldest→newest (guaranteed by
/// `DailyKline.parseKlines`), which matches the chart library's expectation.
/// Only the OHLCV fields are mapped; the library computes MA / BOLL / volume
/// indicators itself via `DataUtil.calculateAll`.
List<KLineEntity> toKLineEntries(List<DailyKline> klines) {
  final result = <KLineEntity>[];
  for (final k in klines) {
    result.add(
      KLineEntity.fromCustom(
        open: k.open,
        high: k.high,
        low: k.low,
        close: k.close,
        vol: k.volume,
        amount: k.amount,
        // The chart library expects a millisecond epoch for the time axis.
        time: k.date.millisecondsSinceEpoch,
      ),
    );
  }
  return result;
}
