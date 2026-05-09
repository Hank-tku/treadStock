import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../domain/strategy_models.dart';
import 'database.dart';

/// Service layer for strategy CRUD, hit records, and reviews.
/// All operations go through Drift (SQLite).
class StrategyService {
  final AppDatabase _db;
  final _uuid = const Uuid();
  Future<void>? _initFuture;

  /// In-memory cache of strategies with their stats.
  List<Strategy> _cache = [];

  StrategyService({AppDatabase? db}) : _db = db ?? AppDatabase();

  /// Initialize: load all strategies and compute stats.
  Future<void> init() async {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    await _db.ensureDefaultStrategy();
    await reloadCache();
  }

  /// Reload all strategies from DB into cache with stats.
  Future<void> reloadCache() async {
    final rows = await _db.select(_db.strategies).get();
    final strategies = <Strategy>[];
    for (final row in rows) {
      final stats = await _computeStats(row.id);
      strategies.add(_rowToDomain(row, stats: stats));
    }
    // Sort: enabled first, then by hit rate descending
    strategies.sort((a, b) {
      if (a.isEnabled != b.isEnabled) return a.isEnabled ? -1 : 1;
      final rateA = a.stats?.hitRate ?? 0;
      final rateB = b.stats?.hitRate ?? 0;
      return rateB.compareTo(rateA);
    });
    _cache = strategies;
  }

  /// Get all strategies from cache.
  List<Strategy> getStrategies() => List.unmodifiable(_cache);

  /// Get a single strategy by ID from cache.
  Strategy? getStrategy(String id) {
    try {
      return _cache.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all enabled strategies from cache.
  List<Strategy> getEnabledStrategies() =>
      _cache.where((s) => s.isEnabled).toList();

  // ── Strategy CRUD ──────────────────────────────────────────

  /// Create a new strategy.
  Future<Strategy> createStrategy(StrategyFormData form) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    await _db
        .into(_db.strategies)
        .insert(
          StrategiesCompanion.insert(
            id: id,
            name: form.name.trim(),
            description: Value(form.description.trim()),
            maShortPeriod: Value(form.maShortPeriod),
            maLongPeriod: Value(form.maLongPeriod),
            bollPeriod: Value(form.bollPeriod),
            bollStdDev: Value(form.bollStdDev),
            weightMA: Value(form.weightMA),
            weightBoll: Value(form.weightBoll),
            weightVol: Value(form.weightVol),
            weightTrend: Value(form.weightTrend),
            recommendThreshold: Value(form.recommendThreshold),
            isEnabled: const Value(true),
            isDefault: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );

    await reloadCache();
    return _cache.firstWhere((s) => s.id == id);
  }

  /// Update an existing strategy.
  Future<Strategy> updateStrategy(String id, StrategyFormData form) async {
    final now = DateTime.now();
    await (_db.update(_db.strategies)..where((t) => t.id.equals(id))).write(
      StrategiesCompanion(
        name: Value(form.name.trim()),
        description: Value(form.description.trim()),
        maShortPeriod: Value(form.maShortPeriod),
        maLongPeriod: Value(form.maLongPeriod),
        bollPeriod: Value(form.bollPeriod),
        bollStdDev: Value(form.bollStdDev),
        weightMA: Value(form.weightMA),
        weightBoll: Value(form.weightBoll),
        weightVol: Value(form.weightVol),
        weightTrend: Value(form.weightTrend),
        recommendThreshold: Value(form.recommendThreshold),
        updatedAt: Value(now),
      ),
    );

    await reloadCache();
    return _cache.firstWhere((s) => s.id == id);
  }

  /// Delete a strategy (not allowed for default strategies).
  Future<void> deleteStrategy(String id) async {
    final strategy = getStrategy(id);
    if (strategy != null && strategy.isDefault) {
      throw Exception('DEFAULT_STRATEGY_CANNOT_DELETE');
    }
    // Delete associated hit records and reviews first
    await (_db.delete(
      _db.strategyHitRecords,
    )..where((t) => t.strategyId.equals(id))).go();
    await (_db.delete(
      _db.strategyReviews,
    )..where((t) => t.strategyId.equals(id))).go();
    await (_db.delete(_db.strategies)..where((t) => t.id.equals(id))).go();
    await reloadCache();
  }

  /// Toggle strategy enabled/disabled status.
  Future<void> toggleEnabled(String id, bool isEnabled) async {
    final now = DateTime.now();
    await (_db.update(_db.strategies)..where((t) => t.id.equals(id))).write(
      StrategiesCompanion(isEnabled: Value(isEnabled), updatedAt: Value(now)),
    );
    await reloadCache();
  }

  // ── Hit Records ────────────────────────────────────────────

  /// Record a batch of recommendations for a strategy on a given date.
  Future<void> recordRecommendations(
    String strategyId,
    List<({String code, String name, int score, double price})> recommendations,
  ) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now();

    for (final rec in recommendations) {
      final id = _uuid.v4();
      await _db
          .into(_db.strategyHitRecords)
          .insert(
            StrategyHitRecordsCompanion.insert(
              id: id,
              strategyId: strategyId,
              stockCode: rec.code,
              stockName: rec.name,
              recommendDate: today,
              recommendScore: rec.score,
              recommendPrice: rec.price,
              createdAt: now,
            ),
          );
    }

    // Prune old records if exceeding 500
    await _pruneOldRecords(strategyId);
  }

  /// Get hit records for a strategy, most recent first.
  Future<List<StrategyHitRecord>> getHitRecords(
    String strategyId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final query = (_db.select(_db.strategyHitRecords)
      ..where((t) => t.strategyId.equals(strategyId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.recommendDate),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit, offset: offset));
    final rows = await query.get();
    return rows.map(_hitRowToDomain).toList();
  }

  /// Fill in actual 5-day changes for records that are due.
  /// Returns the number of records updated.
  Future<int> backfillActualChanges(Map<String, double> currentPrices) async {
    // Find all unfilled records
    final unfilled = await (_db.select(
      _db.strategyHitRecords,
    )..where((t) => t.isHit.isNull())).get();

    int updated = 0;
    final now = DateTime.now();

    for (final record in unfilled) {
      final recDate = DateTime.tryParse(record.recommendDate);
      if (recDate == null) continue;

      // Only backfill if at least 7 calendar days have passed (approx 5 trading days)
      final daysSince = now.difference(recDate).inDays;
      if (daysSince < 7) continue;

      final currentPrice = currentPrices[record.stockCode];
      if (currentPrice == null || currentPrice <= 0) continue;

      final changePct =
          ((currentPrice - record.recommendPrice) / record.recommendPrice) *
          100;
      final isHit = changePct > 0;

      await (_db.update(
        _db.strategyHitRecords,
      )..where((t) => t.id.equals(record.id))).write(
        StrategyHitRecordsCompanion(
          actualChange5d: Value(changePct),
          isHit: Value(isHit),
        ),
      );
      updated++;
    }

    if (updated > 0) {
      await reloadCache();
    }
    return updated;
  }

  /// Prune old hit records for a strategy (keep most recent 400).
  Future<void> _pruneOldRecords(String strategyId) async {
    final count =
        await (_db.select(_db.strategyHitRecords)
              ..where((t) => t.strategyId.equals(strategyId)))
            .get()
            .then((rows) => rows.length);

    if (count > 500) {
      // Delete the 100 oldest records
      final oldest =
          await (_db.select(_db.strategyHitRecords)
                ..where((t) => t.strategyId.equals(strategyId))
                ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
                ..limit(100))
              .get();

      for (final record in oldest) {
        await (_db.delete(
          _db.strategyHitRecords,
        )..where((t) => t.id.equals(record.id))).go();
      }
    }
  }

  // ── Statistics ──────────────────────────────────────────────

  /// Compute statistics for a strategy from hit records.
  Future<StrategyStats> _computeStats(String strategyId) async {
    final strategy = await (_db.select(
      _db.strategies,
    )..where((t) => t.id.equals(strategyId))).getSingleOrNull();
    if (strategy == null) {
      return const StrategyStats();
    }

    final allRecords = await (_db.select(
      _db.strategyHitRecords,
    )..where((t) => t.strategyId.equals(strategyId))).get();

    final evaluated = allRecords
        .where((r) => r.actualChange5d != null)
        .toList();
    final hitCount = evaluated.where((r) => r.isHit == true).length;

    double? maxGain;
    double? maxLoss;
    double avgChange = 0.0;
    double healthScore = 0.0;

    if (evaluated.isNotEmpty) {
      final changes = evaluated.map((r) => r.actualChange5d!).toList();
      maxGain = changes.reduce((a, b) => a > b ? a : b);
      maxLoss = changes.reduce((a, b) => a < b ? a : b);
      avgChange = changes.reduce((a, b) => a + b) / changes.length;

      final hitRate = hitCount / evaluated.length;

      // Health score = hit_rate_score*0.5 + avg_change_score*0.3 + stability_score*0.2
      final hitRateScore = (hitRate * 10).clamp(0.0, 10.0);
      final avgChangeScore = ((avgChange + 10) / 2).clamp(0.0, 10.0);
      // Stability: lower standard deviation = higher score
      final mean = avgChange;
      final variance =
          changes.map((c) => (c - mean) * (c - mean)).reduce((a, b) => a + b) /
          changes.length;
      final stdDev = _sqrt(variance);
      final stabilityScore = (10 - stdDev).clamp(0.0, 10.0);

      healthScore =
          hitRateScore * 0.5 + avgChangeScore * 0.3 + stabilityScore * 0.2;
    }

    final tradingDaysRun = DateTime.now().difference(strategy.createdAt).inDays;

    return StrategyStats(
      hitRate: evaluated.isEmpty ? 0.0 : hitCount / evaluated.length,
      maxGain: maxGain,
      maxLoss: maxLoss,
      avgChange: avgChange,
      totalRecommendations: allRecords.length,
      hitCount: hitCount,
      evaluatedCount: evaluated.length,
      healthScore: healthScore,
      tradingDaysRun: tradingDaysRun,
    );
  }

  /// Compute stats and return (for external use, e.g. strategy detail page).
  Future<StrategyStats> computeStats(String strategyId) async {
    return _computeStats(strategyId);
  }

  // ── Reviews ─────────────────────────────────────────────────

  /// Create a review record for a strategy.
  Future<StrategyReview> createReview(
    String strategyId,
    List<ChecklistItem> checklistItems, {
    String? note,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    // Compute 30-day metrics
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentRecords =
        await (_db.select(_db.strategyHitRecords)..where(
              (t) => t.strategyId.equals(strategyId) & t.isHit.isNotNull(),
            ))
            .get();

    final last30Records = recentRecords.where((r) {
      final recDate = DateTime.tryParse(r.recommendDate);
      return recDate != null && recDate.isAfter(thirtyDaysAgo);
    }).toList();

    final hitRate30d = last30Records.isEmpty
        ? 0.0
        : last30Records.where((r) => r.isHit == true).length /
              last30Records.length;
    final avgChange30d = last30Records.isEmpty
        ? 0.0
        : last30Records
                  .map((r) => r.actualChange5d ?? 0.0)
                  .reduce((a, b) => a + b) /
              last30Records.length;
    final maxLoss30d = last30Records.isEmpty
        ? null
        : last30Records
              .map((r) => r.actualChange5d ?? 0.0)
              .reduce((a, b) => a < b ? a : b);

    // Determine hit rate trend (compare first half vs second half)
    final sorted = List.of(last30Records)
      ..sort((a, b) => a.recommendDate.compareTo(b.recommendDate));
    String hitRateTrend = 'flat';
    if (sorted.length >= 10) {
      final mid = sorted.length ~/ 2;
      final firstHalf =
          sorted.sublist(0, mid).where((r) => r.isHit == true).length / mid;
      final secondHalf =
          sorted.sublist(mid).where((r) => r.isHit == true).length /
          (sorted.length - mid);
      if (secondHalf > firstHalf + 0.1) {
        hitRateTrend = 'up';
      } else if (secondHalf < firstHalf - 0.1) {
        hitRateTrend = 'down';
      }
    }

    // Average daily count
    final uniqueDates = last30Records
        .map((r) => r.recommendDate)
        .toSet()
        .length;
    final avgDailyCount30d = uniqueDates > 0
        ? (last30Records.length / uniqueDates).round()
        : 0;

    // Health score
    final stats = await _computeStats(strategyId);

    // Serialize checklist to JSON
    final checklistJson = jsonEncode(
      checklistItems
          .map(
            (item) => {
              'title': item.title,
              'result': item.result.name,
              'detail': item.detail,
            },
          )
          .toList(),
    );

    await _db
        .into(_db.strategyReviews)
        .insert(
          StrategyReviewsCompanion.insert(
            id: id,
            strategyId: strategyId,
            reviewDate: now,
            healthScore: stats.healthScore,
            hitRate30d: hitRate30d,
            avgChange30d: avgChange30d,
            maxLoss30d: Value(maxLoss30d),
            hitRateTrend: hitRateTrend,
            avgDailyCount30d: avgDailyCount30d,
            checklistResult: checklistJson,
            note: Value(note),
            createdAt: now,
          ),
        );

    // Update lastReviewAt on strategy
    await (_db.update(
      _db.strategies,
    )..where((t) => t.id.equals(strategyId))).write(
      StrategiesCompanion(lastReviewAt: Value(now), updatedAt: Value(now)),
    );

    await reloadCache();

    return StrategyReview(
      id: id,
      strategyId: strategyId,
      reviewDate: now,
      healthScore: stats.healthScore,
      hitRate30d: hitRate30d,
      avgChange30d: avgChange30d,
      maxLoss30d: maxLoss30d,
      hitRateTrend: hitRateTrend,
      avgDailyCount30d: avgDailyCount30d,
      checklistItems: checklistItems,
      note: note,
      createdAt: now,
    );
  }

  /// Get review history for a strategy.
  Future<List<StrategyReview>> getReviewHistory(String strategyId) async {
    final rows =
        await (_db.select(_db.strategyReviews)
              ..where((t) => t.strategyId.equals(strategyId))
              ..orderBy([(t) => OrderingTerm.desc(t.reviewDate)]))
            .get();
    return rows.map(_reviewRowToDomain).toList();
  }

  // ── Review Checklist Generation ─────────────────────────────

  /// Generate a checklist for strategy review based on recent data.
  Future<List<ChecklistItem>> generateChecklist(String strategyId) async {
    final stats = await _computeStats(strategyId);
    final items = <ChecklistItem>[];

    // 1. Hit rate > 50%?
    final hitRatePct = stats.hitRate * 100;
    items.add(
      ChecklistItem(
        title: '近30日命中率是否 > 50%',
        result: stats.evaluatedCount == 0
            ? CheckResult.warning
            : (hitRatePct > 50 ? CheckResult.pass : CheckResult.fail),
        detail: stats.evaluatedCount == 0
            ? '无评估数据'
            : '命中率 ${hitRatePct.toStringAsFixed(1)}%',
      ),
    );

    // 2. Average change positive?
    items.add(
      ChecklistItem(
        title: '近30日平均差是否为正',
        result: stats.evaluatedCount == 0
            ? CheckResult.warning
            : (stats.avgChange > 0 ? CheckResult.pass : CheckResult.fail),
        detail: stats.evaluatedCount == 0
            ? '无评估数据'
            : '平均差 ${stats.avgChangeDisplay}',
      ),
    );

    // 3. Max loss > -10%?
    items.add(
      ChecklistItem(
        title: '极限跌幅是否超过 -10%',
        result: stats.maxLoss == null
            ? CheckResult.warning
            : (stats.maxLoss! > -10 ? CheckResult.pass : CheckResult.fail),
        detail: stats.maxLoss == null
            ? '无评估数据'
            : '极限跌幅 ${stats.maxLoss!.toStringAsFixed(1)}%',
      ),
    );

    // 4. Hit rate trend
    items.add(
      ChecklistItem(
        title: '命中率趋势',
        result: CheckResult.pass,
        detail: stats.evaluatedCount < 10
            ? '数据不足，无法判断趋势'
            : '近期命中率 ${hitRatePct.toStringAsFixed(1)}%',
      ),
    );

    // 5. Recommendation frequency reasonable?
    final avgDaily = stats.tradingDaysRun > 0
        ? stats.totalRecommendations / stats.tradingDaysRun
        : 0.0;
    items.add(
      ChecklistItem(
        title: '推荐频率是否合理（日均 0-10 只）',
        result: avgDaily > 10
            ? CheckResult.warning
            : (avgDaily < 0.5 && stats.tradingDaysRun > 5
                  ? CheckResult.warning
                  : CheckResult.pass),
        detail: '日均推荐 ${avgDaily.toStringAsFixed(1)} 只',
      ),
    );

    return items;
  }

  /// Generate iteration suggestions based on strategy stats.
  List<StrategySuggestion> generateSuggestions(
    Strategy strategy,
    StrategyStats stats,
  ) {
    final suggestions = <StrategySuggestion>[];

    if (stats.evaluatedCount == 0) return suggestions;

    // Hit rate < 50%: suggest raising threshold
    if (stats.hitRate < 0.5) {
      suggestions.add(
        StrategySuggestion(
          condition: '命中率 ${(stats.hitRate * 100).toStringAsFixed(1)}% < 50%',
          suggestion:
              '推荐阈值偏低，建议将推荐阈值从 ${strategy.recommendThreshold} 提高到 ${strategy.recommendThreshold + 1}',
          parameterKey: 'recommendThreshold',
          suggestedValue: strategy.recommendThreshold + 1,
        ),
      );
    }

    // Average change negative: suggest checking MA weight
    if (stats.avgChange < 0) {
      suggestions.add(
        StrategySuggestion(
          condition: '平均差 ${stats.avgChangeDisplay} 为负',
          suggestion: '策略整体偏悲观，建议检查 MA 权重是否需要提高',
          parameterKey: 'weightMA',
          suggestedValue: null,
        ),
      );
    }

    // Max loss > 10%: suggest increasing Bollinger weight
    if (stats.maxLoss != null && stats.maxLoss! < -10) {
      suggestions.add(
        StrategySuggestion(
          condition: '极限跌幅 ${stats.maxLoss!.toStringAsFixed(1)}% 超过 -10%',
          suggestion: '策略选股波动过大，建议增加布林带权重以筛选更稳定的标的',
          parameterKey: 'weightBoll',
          suggestedValue: null,
        ),
      );
    }

    // Too many daily recommendations: suggest raising threshold
    if (stats.totalRecommendations > 0 && stats.tradingDaysRun > 0) {
      final avgDaily = stats.totalRecommendations / stats.tradingDaysRun;
      if (avgDaily > 10) {
        suggestions.add(
          StrategySuggestion(
            condition: '日均推荐 ${avgDaily.toStringAsFixed(1)} 只，推荐过多',
            suggestion: '推荐过多，建议提高推荐阈值',
            parameterKey: 'recommendThreshold',
            suggestedValue: strategy.recommendThreshold + 1,
          ),
        );
      }
    }

    return suggestions;
  }

  // ── Row Mappers ─────────────────────────────────────────────

  Strategy _rowToDomain(StrategyRow row, {StrategyStats? stats}) {
    return Strategy(
      id: row.id,
      name: row.name,
      description: row.description,
      maShortPeriod: row.maShortPeriod,
      maLongPeriod: row.maLongPeriod,
      bollPeriod: row.bollPeriod,
      bollStdDev: row.bollStdDev,
      weightMA: row.weightMA,
      weightBoll: row.weightBoll,
      weightVol: row.weightVol,
      weightTrend: row.weightTrend,
      recommendThreshold: row.recommendThreshold,
      isEnabled: row.isEnabled,
      isDefault: row.isDefault,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastReviewAt: row.lastReviewAt,
      stats: stats,
    );
  }

  StrategyHitRecord _hitRowToDomain(StrategyHitRecordRow row) {
    return StrategyHitRecord(
      id: row.id,
      strategyId: row.strategyId,
      stockCode: row.stockCode,
      stockName: row.stockName,
      recommendDate: row.recommendDate,
      recommendScore: row.recommendScore,
      recommendPrice: row.recommendPrice,
      actualChange5d: row.actualChange5d,
      isHit: row.isHit,
      createdAt: row.createdAt,
    );
  }

  StrategyReview _reviewRowToDomain(StrategyReviewRow row) {
    List<ChecklistItem> items = [];
    try {
      final decoded = jsonDecode(row.checklistResult) as List;
      items = decoded
          .map(
            (item) => ChecklistItem(
              title: item['title'] as String,
              result: CheckResult.values.firstWhere(
                (r) => r.name == item['result'],
                orElse: () => CheckResult.warning,
              ),
              detail: item['detail'] as String,
            ),
          )
          .toList();
    } catch (_) {
      // Fallback if JSON is malformed
    }

    return StrategyReview(
      id: row.id,
      strategyId: row.strategyId,
      reviewDate: row.reviewDate,
      healthScore: row.healthScore,
      hitRate30d: row.hitRate30d,
      avgChange30d: row.avgChange30d,
      maxLoss30d: row.maxLoss30d,
      hitRateTrend: row.hitRateTrend,
      avgDailyCount30d: row.avgDailyCount30d,
      checklistItems: items,
      note: row.note,
      createdAt: row.createdAt,
    );
  }

  /// Simple square root via Newton's method to avoid dart:math import.
  static double _sqrt(double value) {
    if (value <= 0) return 0.0;
    double x = value;
    double y = (x + 1) / 2;
    while (y < x) {
      x = y;
      y = (x + value / x) / 2;
    }
    return x;
  }
}
