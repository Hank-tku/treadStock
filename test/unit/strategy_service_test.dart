import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/data/database.dart';
import 'package:stockpilot/features/strategy/data/strategy_service.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:uuid/uuid.dart';

void main() {
  // ── Shared helpers ──────────────────────────────────────────────

  late AppDatabase db;
  late StrategyService service;

  /// Standard setUp: in-memory DB, no init (clean slate).
  Future<void> setUpClean() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = StrategyService(db: db);
  }

  /// Standard tearDown.
  Future<void> tearDownDb() async {
    await db.close();
  }

  /// Insert a bare-minimum strategy row and return its id.
  Future<String> insertStrategy({DateTime? createdAt}) async {
    final id = const Uuid().v4();
    final now = createdAt ?? DateTime(2026, 1, 1);
    await db
        .into(db.strategies)
        .insert(
          StrategiesCompanion.insert(
            id: id,
            name: '测试策略',
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Insert a hit record with pre-filled evaluation data.
  Future<void> insertHitRecord({
    required String strategyId,
    required double actualChange5d,
    required bool isHit,
    String? recommendDate,
    DateTime? createdAt,
  }) async {
    final id = const Uuid().v4();
    await db
        .into(db.strategyHitRecords)
        .insert(
          StrategyHitRecordsCompanion.insert(
            id: id,
            strategyId: strategyId,
            stockCode: '000001',
            stockName: '测试股票',
            recommendDate: recommendDate ?? '2026-03-01',
            recommendScore: 7,
            recommendPrice: 10.0,
            actualChange5d: Value(actualChange5d),
            isHit: Value(isHit),
            createdAt: createdAt ?? DateTime(2026, 3, 1),
          ),
        );
  }

  // ════════════════════════════════════════════════════════════════
  //  Existing groups (kept verbatim)
  // ════════════════════════════════════════════════════════════════

  group('StrategyService initialization', () {
    setUp(() async {
      await setUpClean();
    });

    tearDown(() async {
      await tearDownDb();
    });

    test('creates default strategy on first init', () async {
      await service.init();

      final strategies = service.getStrategies();

      expect(strategies.map((s) => s.name), contains('默认波段策略'));
      expect(strategies.where((s) => s.isDefault), hasLength(1));
    });

    test('does not duplicate default strategy on repeated init', () async {
      await service.init();
      await service.init();

      final defaults = service.getStrategies().where(
        (strategy) => strategy.isDefault,
      );

      expect(defaults, hasLength(1));
    });
  });

  group('CRUD operations', () {
    setUp(() async {
      await setUpClean();
    });

    tearDown(() async {
      await tearDownDb();
    });

    test('createStrategy creates a new strategy with correct params', () async {
      await service.init();

      final form = StrategyFormData(
        name: '测试策略',
        description: '描述',
        maShortPeriod: 10,
        maLongPeriod: 30,
        bollPeriod: 15,
        bollStdDev: 2.5,
        weightMA: 0.40,
        weightBoll: 0.30,
        weightVol: 0.20,
        weightTrend: 0.10,
        recommendThreshold: 8,
      );

      final strategy = await service.createStrategy(form);

      expect(strategy.name, '测试策略');
      expect(strategy.description, '描述');
      expect(strategy.maShortPeriod, 10);
      expect(strategy.maLongPeriod, 30);
      expect(strategy.bollPeriod, 15);
      expect(strategy.bollStdDev, 2.5);
      expect(strategy.weightMA, 0.40);
      expect(strategy.weightBoll, 0.30);
      expect(strategy.weightVol, 0.20);
      expect(strategy.weightTrend, 0.10);
      expect(strategy.recommendThreshold, 8);
      expect(strategy.isEnabled, isTrue);
      expect(strategy.isDefault, isFalse);

      // Verify it appears in the cache
      final found = service.getStrategy(strategy.id);
      expect(found, isNotNull);
      expect(found!.name, '测试策略');
    });

    test('createStrategy persists strategy to database', () async {
      await service.init();

      final form = StrategyFormData(name: '持久化测试策略', description: '验证持久化');

      final strategy = await service.createStrategy(form);

      // Create a new service instance with the same database
      final service2 = StrategyService(db: db);
      await service2.init();

      final found = service2.getStrategy(strategy.id);
      expect(found, isNotNull);
      expect(found!.name, '持久化测试策略');
      expect(found.description, '验证持久化');
    });

    test('updateStrategy updates name and params', () async {
      await service.init();

      final form = StrategyFormData(
        name: '原始策略',
        description: '原始描述',
        maShortPeriod: 20,
        maLongPeriod: 60,
        recommendThreshold: 7,
      );
      final strategy = await service.createStrategy(form);

      final updatedForm = StrategyFormData(
        name: '更新后策略',
        description: '更新后描述',
        maShortPeriod: 15,
        maLongPeriod: 45,
        recommendThreshold: 9,
      );
      final updated = await service.updateStrategy(strategy.id, updatedForm);

      expect(updated.name, '更新后策略');
      expect(updated.description, '更新后描述');
      expect(updated.maShortPeriod, 15);
      expect(updated.maLongPeriod, 45);
      expect(updated.recommendThreshold, 9);

      // Verify cache is updated
      final fromCache = service.getStrategy(strategy.id);
      expect(fromCache!.name, '更新后策略');
    });

    test('updateStrategy throws for non-existent strategy', () async {
      await service.init();

      final form = StrategyFormData(name: '不存在');

      expect(
        () => service.updateStrategy('non-existent-id', form),
        throwsStateError,
      );
    });

    test('deleteStrategy removes non-default strategy', () async {
      await service.init();

      final form = StrategyFormData(name: '待删除策略');
      final strategy = await service.createStrategy(form);

      expect(service.getStrategy(strategy.id), isNotNull);

      await service.deleteStrategy(strategy.id);

      expect(service.getStrategy(strategy.id), isNull);
      expect(
        service.getStrategies().where((s) => s.id == strategy.id),
        isEmpty,
      );
    });

    test('deleteStrategy throws for default strategy', () async {
      await service.init();

      final defaultStrategy = service.getStrategies().firstWhere(
        (s) => s.isDefault,
      );

      expect(
        () => service.deleteStrategy(defaultStrategy.id),
        throwsA(isA<Exception>()),
      );
    });

    test('toggleEnabled switches from enabled to disabled', () async {
      await service.init();

      final form = StrategyFormData(name: '切换测试策略');
      final strategy = await service.createStrategy(form);

      expect(strategy.isEnabled, isTrue);

      await service.toggleEnabled(strategy.id, false);

      final toggled = service.getStrategy(strategy.id);
      expect(toggled!.isEnabled, isFalse);

      // Toggle back
      await service.toggleEnabled(strategy.id, true);

      final toggledBack = service.getStrategy(strategy.id);
      expect(toggledBack!.isEnabled, isTrue);
    });

    test('toggleEnabled persists state to database', () async {
      await service.init();

      final form = StrategyFormData(name: '持久化切换测试');
      final strategy = await service.createStrategy(form);

      await service.toggleEnabled(strategy.id, false);

      // Create a new service instance with the same database
      final service2 = StrategyService(db: db);
      await service2.init();

      final found = service2.getStrategy(strategy.id);
      expect(found, isNotNull);
      expect(found!.isEnabled, isFalse);
    });
  });

  group('Hit Records', () {
    setUp(() async {
      await setUpClean();
    });

    tearDown(() async {
      await tearDownDb();
    });

    test(
      'recordRecommendations writes hit records once per stock per day',
      () async {
        final strategyId = await insertStrategy();
        final recommendations = [
          (code: '601318', name: '中国平安', score: 8, price: 50.0),
          (code: '000001', name: '平安银行', score: 7, price: 12.0),
        ];

        await service.recordRecommendations(strategyId, recommendations);
        await service.recordRecommendations(strategyId, recommendations);

        final records = await service.getHitRecords(strategyId, limit: 10);
        expect(records, hasLength(2));
        expect(records.map((record) => record.stockCode), contains('601318'));
        expect(
          records.every((record) => record.actualChange5d == null),
          isTrue,
        );
        expect(records.every((record) => record.isHit == null), isTrue);
      },
    );

    test(
      'backfillActualChanges updates due records with current prices',
      () async {
        final strategyId = await insertStrategy();
        final oldDate = DateTime.now().subtract(const Duration(days: 8));
        final recommendDate = oldDate.toIso8601String().substring(0, 10);

        await db
            .into(db.strategyHitRecords)
            .insert(
              StrategyHitRecordsCompanion.insert(
                id: const Uuid().v4(),
                strategyId: strategyId,
                stockCode: '601318',
                stockName: '中国平安',
                recommendDate: recommendDate,
                recommendScore: 8,
                recommendPrice: 50.0,
                createdAt: oldDate,
              ),
            );

        final updated = await service.backfillActualChanges({'601318': 55.0});

        expect(updated, 1);
        final records = await service.getHitRecords(strategyId);
        expect(records.single.actualChange5d, closeTo(10.0, 0.001));
        expect(records.single.isHit, isTrue);
      },
    );

    test(
      'backfillActualChanges applies hit-rate threshold (>0.5%), not >0',
      () async {
        // Regression: a trivially green stock (e.g. +0.3%) must NOT count as
        // a hit, while +0.6% should. See AppConstants.hitRateThresholdPct.
        final strategyId = await insertStrategy();
        final oldDate = DateTime.now().subtract(const Duration(days: 8));
        final recommendDate = oldDate.toIso8601String().substring(0, 10);

        // Stock A: recommend 100 → current 100.3 (+0.3%) → miss
        // Stock B: recommend 100 → current 100.6 (+0.6%) → hit
        for (final entry in [
          ('000001', 100.0, 100.3),
          ('000002', 100.0, 100.6),
        ]) {
          final (code, recPrice, _) = entry;
          await db.into(db.strategyHitRecords).insert(
            StrategyHitRecordsCompanion.insert(
              id: const Uuid().v4(),
              strategyId: strategyId,
              stockCode: code,
              stockName: code,
              recommendDate: recommendDate,
              recommendScore: 7,
              recommendPrice: recPrice,
              createdAt: oldDate,
            ),
          );
        }

        await service.backfillActualChanges({
          '000001': 100.3,
          '000002': 100.6,
        });

        final records = await service.getHitRecords(strategyId);
        final recA = records.firstWhere((r) => r.stockCode == '000001');
        final recB = records.firstWhere((r) => r.stockCode == '000002');
        expect(recA.isHit, isFalse, reason: '+0.3% 低于阈值应判 miss');
        expect(recB.isHit, isTrue, reason: '+0.6% 超过阈值应判 hit');
      },
    );

    test(
      'backfillActualChanges keeps pending records when price is unavailable',
      () async {
        final strategyId = await insertStrategy();
        final oldDate = DateTime.now().subtract(const Duration(days: 8));
        final recommendDate = oldDate.toIso8601String().substring(0, 10);

        await db
            .into(db.strategyHitRecords)
            .insert(
              StrategyHitRecordsCompanion.insert(
                id: const Uuid().v4(),
                strategyId: strategyId,
                stockCode: '601318',
                stockName: '中国平安',
                recommendDate: recommendDate,
                recommendScore: 8,
                recommendPrice: 50.0,
                createdAt: oldDate,
              ),
            );

        final updated = await service.backfillActualChanges({'000001': 12.0});

        expect(updated, 0);
        final records = await service.getHitRecords(strategyId);
        expect(records.single.actualChange5d, isNull);
        expect(records.single.isHit, isNull);
      },
    );
  });

  // ════════════════════════════════════════════════════════════════
  //  NEW: Statistics
  // ════════════════════════════════════════════════════════════════

  group('Statistics', () {
    setUp(() async {
      await setUpClean();
    });

    tearDown(() async {
      await tearDownDb();
    });

    test('computeStats returns empty stats when no hit records', () async {
      final strategyId = await insertStrategy();

      final stats = await service.computeStats(strategyId);

      expect(stats.hitRate, 0.0);
      expect(stats.maxGain, isNull);
      expect(stats.maxLoss, isNull);
      expect(stats.avgChange, 0.0);
      expect(stats.totalRecommendations, 0);
      expect(stats.hitCount, 0);
      expect(stats.evaluatedCount, 0);
      expect(stats.healthScore, 0.0);
      // Display helpers should show '--' when no evaluated data
      expect(stats.hitRateDisplay, '--');
      expect(stats.avgChangeDisplay, '--');
      expect(stats.healthScoreDisplay, '--');
    });

    test('computeStats calculates hit rate correctly', () async {
      final strategyId = await insertStrategy();

      // 3 hits, 2 misses → hitRate = 0.6
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 5.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 3.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -2.0,
        isHit: false,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 1.5,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -1.0,
        isHit: false,
      );

      final stats = await service.computeStats(strategyId);

      expect(stats.evaluatedCount, 5);
      expect(stats.hitCount, 3);
      expect(stats.hitRate, closeTo(0.6, 0.001));
    });

    test('computeStats calculates average change correctly', () async {
      final strategyId = await insertStrategy();

      // avg change = (5.0 + 3.0 + (-2.0) + 1.5 + (-1.0)) / 5 = 6.5 / 5 = 1.3
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 5.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 3.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -2.0,
        isHit: false,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 1.5,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -1.0,
        isHit: false,
      );

      final stats = await service.computeStats(strategyId);

      expect(stats.avgChange, closeTo(1.3, 0.001));
    });

    test(
      'computeStats hasEnoughData is false with <20 evaluated records',
      () async {
        // Strategy created just now → tradingDaysRun = 0
        final strategyId = await insertStrategy(createdAt: DateTime.now());

        final stats = await service.computeStats(strategyId);

        expect(stats.tradingDaysRun, lessThan(20));
        expect(stats.hasEnoughData, isFalse);
      },
    );

    test('computeStats health score is in 0-10 range', () async {
      final strategyId = await insertStrategy();

      // Insert records with a mix of positive and negative changes
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 8.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -3.0,
        isHit: false,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 4.5,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -6.0,
        isHit: false,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 2.0,
        isHit: true,
      );

      final stats = await service.computeStats(strategyId);

      expect(stats.healthScore, greaterThanOrEqualTo(0.0));
      expect(stats.healthScore, lessThanOrEqualTo(10.0));
    });
  });

  // ════════════════════════════════════════════════════════════════
  //  NEW: Checklist Generation
  // ════════════════════════════════════════════════════════════════

  group('Checklist Generation', () {
    setUp(() async {
      await setUpClean();
    });

    tearDown(() async {
      await tearDownDb();
    });

    test('generateChecklist returns 5 items', () async {
      final strategyId = await insertStrategy();

      final checklist = await service.generateChecklist(strategyId);

      expect(checklist, hasLength(5));
    });

    test(
      'generateChecklistResult falls back to previous available period',
      () async {
        final strategyId = await insertStrategy();
        final oldDate = DateTime.now().subtract(const Duration(days: 60));
        await insertHitRecord(
          strategyId: strategyId,
          actualChange5d: 2.0,
          isHit: true,
          recommendDate: oldDate.toIso8601String().substring(0, 10),
          createdAt: oldDate,
        );

        final result = await service.generateChecklistResult(strategyId);

        expect(result.items, hasLength(5));
        expect(result.period.usedFallback, isTrue);
        expect(result.period.evaluatedCount, 1);
        expect(result.period.sourceNote, contains('上一可用周期'));
      },
    );

    test('checklist marks pass when hit rate > 50%', () async {
      final strategyId = await insertStrategy();

      // 4 hits, 1 miss → hitRate = 80%
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 3.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 2.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 1.5,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 4.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -1.0,
        isHit: false,
      );

      final checklist = await service.generateChecklist(strategyId);

      // Item 0: hit rate > 50% → pass
      expect(checklist[0].title, contains('命中率'));
      expect(checklist[0].result, CheckResult.pass);
      expect(checklist[0].detail, contains('80.0%'));
    });

    test('checklist marks fail when hit rate < 50%', () async {
      final strategyId = await insertStrategy();

      // 1 hit, 4 misses → hitRate = 20%
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: 1.0,
        isHit: true,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -2.0,
        isHit: false,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -3.0,
        isHit: false,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -1.5,
        isHit: false,
      );
      await insertHitRecord(
        strategyId: strategyId,
        actualChange5d: -4.0,
        isHit: false,
      );

      final checklist = await service.generateChecklist(strategyId);

      // Item 0: hit rate < 50% → fail
      expect(checklist[0].title, contains('命中率'));
      expect(checklist[0].result, CheckResult.fail);
    });

    test('checklist detects downward hit rate trend', () async {
      final strategyId = await insertStrategy();

      // Insert enough records so evaluatedCount >= 10,
      // then the trend checklist item shows a real detail instead of "数据不足"
      for (int i = 0; i < 10; i++) {
        await insertHitRecord(
          strategyId: strategyId,
          actualChange5d: i % 2 == 0 ? 2.0 : -1.0,
          isHit: i % 2 == 0,
        );
      }

      final checklist = await service.generateChecklist(strategyId);

      // Item 3 (index 3) = "命中率趋势"
      expect(checklist[3].title, contains('命中率趋势'));
      expect(checklist[3].result, CheckResult.pass);
      // With >= 10 evaluated records, detail should NOT say "数据不足"
      expect(checklist[3].detail, isNot(contains('数据不足')));
      expect(checklist[3].detail, contains('命中率'));
    });
  });

  // ════════════════════════════════════════════════════════════════
  //  NEW: Suggestions
  // ════════════════════════════════════════════════════════════════

  group('Suggestions', () {
    test('suggests raising threshold when hit rate < 50%', () {
      final strategy = Strategy(
        id: 'test',
        name: '测试',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        recommendThreshold: 6,
      );

      final stats = StrategyStats(
        hitRate: 0.35,
        avgChange: 0.5,
        evaluatedCount: 10,
        hitCount: 3,
      );

      final suggestions = service.generateSuggestions(strategy, stats);

      expect(suggestions, isNotEmpty);
      expect(
        suggestions.any((s) => s.parameterKey == 'recommendThreshold'),
        isTrue,
      );
      expect(
        suggestions
            .firstWhere((s) => s.parameterKey == 'recommendThreshold')
            .suggestedValue,
        7, // 6 + 1
      );
    });

    test('suggests checking MA weight when avg change is negative', () {
      final strategy = Strategy(
        id: 'test',
        name: '测试',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        recommendThreshold: 7,
      );

      final stats = StrategyStats(
        hitRate: 0.6,
        avgChange: -1.5,
        evaluatedCount: 10,
        hitCount: 6,
      );

      final suggestions = service.generateSuggestions(strategy, stats);

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.parameterKey == 'weightMA'), isTrue);
      expect(suggestions.any((s) => s.suggestion.contains('MA')), isTrue);
    });

    test('suggests increasing boll weight when max loss > 10%', () {
      final strategy = Strategy(
        id: 'test',
        name: '测试',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        recommendThreshold: 7,
      );

      final stats = StrategyStats(
        hitRate: 0.55,
        avgChange: 0.5,
        maxLoss: -12.5,
        evaluatedCount: 10,
        hitCount: 6,
      );

      final suggestions = service.generateSuggestions(strategy, stats);

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.parameterKey == 'weightBoll'), isTrue);
      expect(suggestions.any((s) => s.suggestion.contains('布林带')), isTrue);
    });

    test('returns empty list when strategy performs well', () {
      final strategy = Strategy(
        id: 'test',
        name: '测试',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        recommendThreshold: 7,
      );

      final stats = StrategyStats(
        hitRate: 0.75,
        avgChange: 2.5,
        maxLoss: -3.0,
        evaluatedCount: 30,
        hitCount: 22,
        totalRecommendations: 30,
        tradingDaysRun: 30,
      );

      final suggestions = service.generateSuggestions(strategy, stats);

      expect(suggestions, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════════
  //  NEW: Reviews
  // ════════════════════════════════════════════════════════════════

  group('Reviews', () {
    setUp(() async {
      await setUpClean();
    });

    tearDown(() async {
      await tearDownDb();
    });

    test('createReview persists review with checklist and note', () async {
      final strategyId = await insertStrategy();

      final checklistItems = [
        ChecklistItem(title: '命中率', result: CheckResult.pass, detail: '60%'),
        ChecklistItem(title: '平均差', result: CheckResult.pass, detail: '+1.5%'),
        ChecklistItem(
          title: '极限跌幅',
          result: CheckResult.warning,
          detail: '-8.2%',
        ),
        ChecklistItem(title: '趋势', result: CheckResult.pass, detail: 'flat'),
        ChecklistItem(title: '频率', result: CheckResult.pass, detail: '日均3只'),
      ];

      final review = await service.createReview(
        strategyId,
        checklistItems,
        note: '测试复盘笔记',
      );

      expect(review.strategyId, strategyId);
      expect(review.checklistItems, hasLength(5));
      expect(review.checklistItems[0].title, '命中率');
      expect(review.checklistItems[0].result, CheckResult.pass);
      expect(review.note, '测试复盘笔记');
      expect(review.healthScore, greaterThanOrEqualTo(0.0));
      expect(review.hitRateTrend, isNotNull);

      // Verify the review is persisted in DB via getReviewHistory
      final history = await service.getReviewHistory(strategyId);
      expect(history, hasLength(1));
      expect(history.first.id, review.id);
      expect(history.first.checklistItems, hasLength(5));
      expect(history.first.note, '测试复盘笔记');
    });

    test(
      'getReviewHistory returns reviews sorted by date descending',
      () async {
        final strategyId = await insertStrategy();

        final checklistItems = [
          ChecklistItem(title: '命中', result: CheckResult.pass, detail: 'ok'),
          ChecklistItem(title: '差值', result: CheckResult.pass, detail: 'ok'),
          ChecklistItem(title: '跌幅', result: CheckResult.pass, detail: 'ok'),
          ChecklistItem(title: '趋势', result: CheckResult.pass, detail: 'ok'),
          ChecklistItem(title: '频率', result: CheckResult.pass, detail: 'ok'),
        ];

        // Create two reviews (slightly apart in time)
        final review1 = await service.createReview(
          strategyId,
          checklistItems,
          note: '早期复盘',
        );

        // Small delay to ensure different timestamps
        await Future<void>.delayed(const Duration(seconds: 2));

        final review2 = await service.createReview(
          strategyId,
          checklistItems,
          note: '晚期复盘',
        );

        final history = await service.getReviewHistory(strategyId);

        expect(history, hasLength(2));
        // Most recent first
        expect(history.first.id, review2.id);
        expect(history.last.id, review1.id);
      },
    );
  });
}
