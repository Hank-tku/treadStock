import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/strategy_models.dart';
import '../../../../shared/providers.dart';

/// Daily hit rate data point for the trend chart.
class DailyHitRate {
  final DateTime date;
  final double hitRate; // 0.0 - 1.0
  final int totalSignals;
  final int hitCount;

  const DailyHitRate({
    required this.date,
    required this.hitRate,
    required this.totalSignals,
    required this.hitCount,
  });

  /// Formatted date label, e.g. "06/10".
  String get dateLabel {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$m/$d';
  }
}

/// Provider that computes daily hit rates for a given strategy.
///
/// Reads all hit records (up to 200) and groups them by recommendDate.
/// Only evaluated records (where actualChange5d != null) contribute.
final hitRateTrendProvider = FutureProvider.family
    .autoDispose<List<DailyHitRate>, String>((ref, strategyId) async {
  final service = ref.read(strategyServiceProvider);
  await service.init();

  // Fetch up to 200 records to cover ~30 trading days
  final records = await service.getHitRecords(strategyId, limit: 200);

  if (records.isEmpty) return [];

  // Group evaluated records by date
  final Map<String, List<StrategyHitRecord>> grouped = {};
  for (final r in records) {
    if (!r.isEvaluated) continue;
    grouped.putIfAbsent(r.recommendDate, () => []).add(r);
  }

  if (grouped.isEmpty) return [];

  // Sort dates ascending
  final sortedDates = grouped.keys.toList()..sort();

  // Take last 30 trading days
  final recentDates =
      sortedDates.length > 30 ? sortedDates.sublist(sortedDates.length - 30) : sortedDates;

  return recentDates.map((dateStr) {
    final dayRecords = grouped[dateStr]!;
    final total = dayRecords.length;
    final hits = dayRecords.where((r) => r.isHit == true).length;
    return DailyHitRate(
      date: DateTime.parse(dateStr),
      hitRate: total > 0 ? hits / total : 0.0,
      totalSignals: total,
      hitCount: hits,
    );
  }).toList();
});
