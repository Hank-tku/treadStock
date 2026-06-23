import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/strategy_models.dart';
import '../domain/signal_rule.dart';
import '../domain/stock_filter.dart';
import '../../stock/data/kline_cache.dart';
import 'database.dart';

/// Service layer for strategy CRUD, hit records, and reviews.
/// All operations go through Drift (SQLite).
class StrategyService {
  final AppDatabase _db;
  final KlineCacheDatabase? _klineCache;
  final _uuid = const Uuid();
  Future<void>? _initFuture;

  /// In-memory cache of strategies with their stats.
  List<Strategy> _cache = [];

  StrategyService({AppDatabase? db, KlineCacheDatabase? klineCache})
      : _db = db ?? AppDatabase(),
        _klineCache = klineCache;

  /// Initialize: load all strategies and compute stats.
  Future<void> init() async {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    await _db.ensureDefaultStrategy();
    await reloadCache();
    // Fire-and-forget: backfill from local K-line cache without blocking startup.
    backfillFromLocalData();
  }

  /// Reload all strategies from DB into cache with stats.
  /// Uses batch DB fetch + single Isolate call to avoid blocking UI.
  Future<void> reloadCache() async {
    final rows = await _db.select(_db.strategies).get();
    if (rows.isEmpty) {
      _cache = [];
      return;
    }

    // Batch fetch all hit records in one query (main thread)
    final allHitRecords = await _db.select(_db.strategyHitRecords).get();
    final now = DateTime.now();

    // Prepare serializable input for each strategy
    final inputs = <List<dynamic>>[];
    for (final row in rows) {
      final records =
          allHitRecords.where((r) => r.strategyId == row.id).toList();
      inputs.add([
        records.map((r) => r.actualChange5d).toList(),
        records.map((r) => r.isHit).toList(),
        records.length,
        now.difference(row.createdAt).inDays,
      ]);
    }

    // Compute all stats in a single Isolate call (off main thread)
    final allStats = await _runBatchStatsInIsolate(inputs);

    final strategies = List<Strategy>.generate(rows.length, (i) {
      return _rowToDomain(rows[i], stats: allStats[i]);
    });

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

    // Serialize rules and groups to JSON
    final Value<String?> entryRulesVal = form.entryRules.isNotEmpty
        ? Value(jsonEncode(form.entryRules.map((r) => r.toJson()).toList()))
        : const Value.absent();
    final Value<String?> exitRulesVal = form.exitRules.isNotEmpty
        ? Value(jsonEncode(form.exitRules.map((r) => r.toJson()).toList()))
        : const Value.absent();
    final Value<String?> entryGroupsVal = form.entryGroups.isNotEmpty
        ? Value(jsonEncode(form.entryGroups.map((g) => g.toJson()).toList()))
        : const Value.absent();
    final Value<String?> exitGroupsVal = form.exitGroups.isNotEmpty
        ? Value(jsonEncode(form.exitGroups.map((g) => g.toJson()).toList()))
        : const Value.absent();
    final Value<String?> stockFilterVal =
        (form.stockFilter != null && form.stockFilter!.isActive)
            ? Value(jsonEncode(form.stockFilter!.toJson()))
            : const Value.absent();

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
            entryRulesJson: entryRulesVal,
            exitRulesJson: exitRulesVal,
            entryGroupsJson: entryGroupsVal,
            exitGroupsJson: exitGroupsVal,
            stockFilterJson: stockFilterVal,
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

    // Serialize rules and groups to JSON
    final Value<String?> entryRulesVal = form.entryRules.isNotEmpty
        ? Value(jsonEncode(form.entryRules.map((r) => r.toJson()).toList()))
        : const Value.absent();
    final Value<String?> exitRulesVal = form.exitRules.isNotEmpty
        ? Value(jsonEncode(form.exitRules.map((r) => r.toJson()).toList()))
        : const Value.absent();
    final Value<String?> entryGroupsVal = form.entryGroups.isNotEmpty
        ? Value(jsonEncode(form.entryGroups.map((g) => g.toJson()).toList()))
        : const Value.absent();
    final Value<String?> exitGroupsVal = form.exitGroups.isNotEmpty
        ? Value(jsonEncode(form.exitGroups.map((g) => g.toJson()).toList()))
        : const Value.absent();
    final Value<String?> stockFilterVal =
        (form.stockFilter != null && form.stockFilter!.isActive)
            ? Value(jsonEncode(form.stockFilter!.toJson()))
            : const Value.absent();

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
        entryRulesJson: entryRulesVal,
        exitRulesJson: exitRulesVal,
        entryGroupsJson: entryGroupsVal,
        exitGroupsJson: exitGroupsVal,
        stockFilterJson: stockFilterVal,
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
      final existing =
          await (_db.select(_db.strategyHitRecords)..where(
                (t) =>
                    t.strategyId.equals(strategyId) &
                    t.stockCode.equals(rec.code) &
                    t.recommendDate.equals(today),
              ))
              .getSingleOrNull();
      if (existing != null) continue;

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
      // A "hit" must clear a small positive threshold (covers trading costs +
      // avoids trivially green stocks inflating the hit rate). See
      // AppConstants.hitRateThresholdPct.
      final isHit = changePct > AppConstants.hitRateThresholdPct;

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

  /// Backfill actual 5-day changes from local K-line cache.
  /// Automatically retrieves closing prices from cached K-line data
  /// for records that are due but haven't been filled yet.
  /// Returns the number of records updated.
  Future<int> backfillFromLocalData() async {
    if (_klineCache == null) return 0;

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

      // Get K-line data from local cache
      final klines = await _klineCache.getCachedKlines(record.stockCode);
      if (klines == null || klines.isEmpty) continue;

      // Sort klines by date ascending
      final sorted = List.of(klines)
        ..sort((a, b) => a.date.compareTo(b.date));

      // Find klines on or after the recommend date
      final afterRec = sorted.where((k) =>
          !k.date.isBefore(recDate)).toList();
      if (afterRec.isEmpty) continue;

      // Need at least 5 trading days after the recommend date
      // The first entry is the recommend date itself, so we need index 5
      if (afterRec.length < 6) continue;

      // Use the close price on the 5th trading day after recommend date
      final day5Close = afterRec[5].close;
      if (day5Close <= 0 || record.recommendPrice <= 0) continue;

      final changePct =
          ((day5Close - record.recommendPrice) / record.recommendPrice) * 100;
      final isHit = changePct > AppConstants.hitRateThresholdPct;

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
    final allRecords = await (_db.select(
      _db.strategyHitRecords,
    )..where((t) => t.strategyId.equals(strategyId))).get();

    return _computeStatsForRows(strategyId, allRecords);
  }

  Future<StrategyStats> _computeStatsForRows(
    String strategyId,
    List<StrategyHitRecordRow> records,
  ) async {
    final strategy = await (_db.select(
      _db.strategies,
    )..where((t) => t.id.equals(strategyId))).getSingleOrNull();
    if (strategy == null) {
      return const StrategyStats();
    }

    // Prepare serializable data on main thread, then compute in Isolate
    final actualChanges = records.map((r) => r.actualChange5d).toList();
    final isHitFlags = records.map((r) => r.isHit).toList();
    final totalRecords = records.length;
    final tradingDaysRun =
        DateTime.now().difference(strategy.createdAt).inDays;

    return Isolate.run(
      () => computeStatsPure(actualChanges, isHitFlags, totalRecords, tradingDaysRun),
    );
  }

  Future<_ReviewRecordSelection> _selectReviewRecords(
    String strategyId, {
    DateTime? now,
  }) async {
    final end = now ?? DateTime.now();
    final requestedStart = end.subtract(const Duration(days: 30));
    final evaluatedRows =
        await (_db.select(_db.strategyHitRecords)..where(
              (t) => t.strategyId.equals(strategyId) & t.isHit.isNotNull(),
            ))
            .get();

    final currentRows = evaluatedRows.where((row) {
      final date = DateTime.tryParse(row.recommendDate);
      return date != null &&
          !date.isBefore(requestedStart) &&
          !date.isAfter(end);
    }).toList();

    if (currentRows.isNotEmpty) {
      return _ReviewRecordSelection(
        records: currentRows,
        period: ReviewPeriodInfo(
          requestedStart: requestedStart,
          requestedEnd: end,
          dataStart: requestedStart,
          dataEnd: end,
          evaluatedCount: currentRows.length,
          sourceNote: '使用近30日已回填记录',
        ),
      );
    }

    final datedRows =
        evaluatedRows
            .map(
              (row) => (row: row, date: DateTime.tryParse(row.recommendDate)),
            )
            .where((item) => item.date != null)
            .toList()
          ..sort((a, b) => b.date!.compareTo(a.date!));

    if (datedRows.isEmpty) {
      return _ReviewRecordSelection(
        records: const [],
        period: ReviewPeriodInfo(
          requestedStart: requestedStart,
          requestedEnd: end,
          dataStart: requestedStart,
          dataEnd: end,
          evaluatedCount: 0,
          sourceNote: '近30日暂无已回填记录',
        ),
      );
    }

    final fallbackEnd = datedRows.first.date!;
    final fallbackStart = fallbackEnd.subtract(const Duration(days: 30));
    final fallbackRows = datedRows
        .where(
          (item) =>
              !item.date!.isBefore(fallbackStart) &&
              !item.date!.isAfter(fallbackEnd),
        )
        .map((item) => item.row)
        .toList();

    return _ReviewRecordSelection(
      records: fallbackRows,
      period: ReviewPeriodInfo(
        requestedStart: requestedStart,
        requestedEnd: end,
        dataStart: fallbackStart,
        dataEnd: fallbackEnd,
        evaluatedCount: fallbackRows.length,
        sourceNote: '近30日无已回填记录，改用上一可用周期',
      ),
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

    final reviewData = await _selectReviewRecords(strategyId, now: now);
    final reviewRecords = reviewData.records;

    final hitRate30d = reviewRecords.isEmpty
        ? 0.0
        : reviewRecords.where((r) => r.isHit == true).length /
              reviewRecords.length;
    final avgChange30d = reviewRecords.isEmpty
        ? 0.0
        : reviewRecords
                  .map((r) => r.actualChange5d ?? 0.0)
                  .reduce((a, b) => a + b) /
              reviewRecords.length;
    final maxLoss30d = reviewRecords.isEmpty
        ? null
        : reviewRecords
              .map((r) => r.actualChange5d ?? 0.0)
              .reduce((a, b) => a < b ? a : b);

    // Determine hit rate trend (compare first half vs second half)
    final sorted = List.of(reviewRecords)
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
    final uniqueDates = reviewRecords
        .map((r) => r.recommendDate)
        .toSet()
        .length;
    final avgDailyCount30d = uniqueDates > 0
        ? (reviewRecords.length / uniqueDates).round()
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
    final result = await generateChecklistResult(strategyId);
    return result.items;
  }

  /// Generate a checklist and the exact period used for the review.
  Future<ReviewChecklistResult> generateChecklistResult(
    String strategyId,
  ) async {
    final reviewData = await _selectReviewRecords(strategyId);
    final stats = await _computeStatsForRows(strategyId, reviewData.records);
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
            ? '${reviewData.period.sourceNote}，无评估数据'
            : '命中率 ${hitRatePct.toStringAsFixed(1)}%，样本 ${stats.evaluatedCount} 条',
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
            ? '${reviewData.period.sourceNote}，无评估数据'
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
            ? '${reviewData.period.sourceNote}，无评估数据'
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

    return ReviewChecklistResult(items: items, period: reviewData.period);
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
    // Parse entry/exit rules from JSON
    List<SignalRule>? entryRules;
    List<SignalRule>? exitRules;
    if (row.entryRulesJson != null) {
      try {
        final list = jsonDecode(row.entryRulesJson!) as List;
        entryRules = list.map((e) => SignalRule.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    if (row.exitRulesJson != null) {
      try {
        final list = jsonDecode(row.exitRulesJson!) as List;
        exitRules = list.map((e) => SignalRule.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // Parse entry/exit rule groups from JSON
    List<RuleGroup>? entryGroups;
    List<RuleGroup>? exitGroups;
    if (row.entryGroupsJson != null) {
      try {
        final list = jsonDecode(row.entryGroupsJson!) as List;
        entryGroups = list.map((e) => RuleGroup.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    if (row.exitGroupsJson != null) {
      try {
        final list = jsonDecode(row.exitGroupsJson!) as List;
        exitGroups = list.map((e) => RuleGroup.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    // Parse stock filter from JSON
    StockFilter? stockFilter;
    if (row.stockFilterJson != null) {
      try {
        stockFilter = StockFilter.fromJson(
          jsonDecode(row.stockFilterJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

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
      entryRules: entryRules,
      exitRules: exitRules,
      entryGroups: entryGroups,
      exitGroups: exitGroups,
      stockFilter: stockFilter,
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

  // ── Isolate Helpers ──────────────────────────────────────────

  /// Run batch stats computation in a background Isolate.
  Future<List<StrategyStats>> _runBatchStatsInIsolate(
    List<List<dynamic>> inputs,
  ) async {
    return await Isolate.run(() => computeAllStatsPure(inputs));
  }

}

class _ReviewRecordSelection {
  final List<StrategyHitRecordRow> records;
  final ReviewPeriodInfo period;

  const _ReviewRecordSelection({required this.records, required this.period});
}

// ── Isolate Entry Points (top-level for Isolate.run) ─────────────

/// Pure stats computation for a single strategy.
/// No DB/HTTP access — only serializable input → StrategyStats output.
StrategyStats computeStatsPure(
  List<double?> actualChanges,
  List<bool?> isHitFlags,
  int totalRecords,
  int tradingDaysRun,
) {
  final evaluatedChanges = <double>[];
  int hitCount = 0;
  for (int i = 0; i < actualChanges.length; i++) {
    final change = actualChanges[i];
    if (change != null) {
      evaluatedChanges.add(change);
      if (isHitFlags[i] == true) hitCount++;
    }
  }

  double? maxGain;
  double? maxLoss;
  double avgChange = 0.0;
  double healthScore = 0.0;

  if (evaluatedChanges.isNotEmpty) {
    maxGain = evaluatedChanges.reduce((a, b) => a > b ? a : b);
    maxLoss = evaluatedChanges.reduce((a, b) => a < b ? a : b);
    avgChange =
        evaluatedChanges.reduce((a, b) => a + b) / evaluatedChanges.length;

    final hitRate = hitCount / evaluatedChanges.length;

    // Health score = hit_rate_score*0.5 + avg_change_score*0.3 + stability_score*0.2
    final hitRateScore = (hitRate * 10).clamp(0.0, 10.0);
    final avgChangeScore = ((avgChange + 10) / 2).clamp(0.0, 10.0);
    // Stability: lower standard deviation = higher score
    final mean = avgChange;
    final variance = evaluatedChanges
            .map((c) => (c - mean) * (c - mean))
            .reduce((a, b) => a + b) /
        evaluatedChanges.length;
    final stdDev = sqrt(variance);
    final stabilityScore = (10 - stdDev).clamp(0.0, 10.0);

    healthScore =
        hitRateScore * 0.5 + avgChangeScore * 0.3 + stabilityScore * 0.2;
  }

  return StrategyStats(
    hitRate: evaluatedChanges.isEmpty ? 0.0 : hitCount / evaluatedChanges.length,
    maxGain: maxGain,
    maxLoss: maxLoss,
    avgChange: avgChange,
    totalRecommendations: totalRecords,
    hitCount: hitCount,
    evaluatedCount: evaluatedChanges.length,
    healthScore: healthScore,
    tradingDaysRun: tradingDaysRun,
  );
}

/// Pure batch stats computation for multiple strategies.
/// Input: list of [actualChanges, isHitFlags, totalRecords, tradingDaysRun].
List<StrategyStats> computeAllStatsPure(List<List<dynamic>> inputs) {
  return inputs.map((input) {
    final actualChanges = (input[0] as List).cast<double?>();
    final isHitFlags = (input[1] as List).cast<bool?>();
    final totalRecords = input[2] as int;
    final tradingDaysRun = input[3] as int;
    return computeStatsPure(actualChanges, isHitFlags, totalRecords, tradingDaysRun);
  }).toList();
}
