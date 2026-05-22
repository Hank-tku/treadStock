import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';

void main() {
  group('ApiStrategyTemplates', () {
    test('all built-in API templates generate valid strategy forms', () {
      expect(ApiStrategyTemplates.all, isNotEmpty);

      for (final template in ApiStrategyTemplates.all) {
        final form = StrategyFormData.fromTemplate(template);

        expect(form.validate(), isNull, reason: template.id);
        expect(form.name, template.name);
        expect(form.isWeightSumValid, isTrue, reason: template.id);
        expect(template.apiCapabilities, isNotEmpty, reason: template.id);
        expect(template.requiredFields, isNotEmpty, reason: template.id);
      }
    });

    test('generated form is detached from template form data', () {
      final template = ApiStrategyTemplates.all.first;
      final generated = StrategyFormData.fromTemplate(template);

      generated.name = '用户改名策略';

      expect(template.formData.name, template.name);
      expect(generated.name, '用户改名策略');
    });
  });

  group('StrategyFormData', () {
    test('validate returns error when name is empty', () {
      final form = StrategyFormData(name: '');
      expect(form.validate(), '请输入策略名称');
    });

    test('validate returns error when name exceeds 20 chars', () {
      final form = StrategyFormData(name: '这是一条超过二十个字符的超长策略名称测试用');
      expect(form.validate(), '策略名称不能超过20个字符');
    });

    test('validate passes with valid data', () {
      final form = StrategyFormData(
        name: '测试策略',
        weightMA: 0.30,
        weightBoll: 0.30,
        weightVol: 0.20,
        weightTrend: 0.20,
      );
      expect(form.validate(), isNull);
    });

    test('isWeightSumValid true when sum equals 1.0', () {
      final form = StrategyFormData(
        weightMA: 0.30,
        weightBoll: 0.30,
        weightVol: 0.20,
        weightTrend: 0.20,
      );
      expect(form.isWeightSumValid, isTrue);
    });

    test('isWeightSumValid false when sum is 0.90', () {
      final form = StrategyFormData(
        weightMA: 0.30,
        weightBoll: 0.30,
        weightVol: 0.20,
        weightTrend: 0.10,
      );
      expect(form.isWeightSumValid, isFalse);
    });

    test('isWeightSumValid true when sum is within ±0.01 tolerance', () {
      // Sum = 0.995, which is within 0.01 of 1.0
      final form = StrategyFormData(
        weightMA: 0.30,
        weightBoll: 0.30,
        weightVol: 0.20,
        weightTrend: 0.195,
      );
      expect(form.isWeightSumValid, isTrue);
    });

    test('hasMAWarning true when maShortPeriod >= maLongPeriod', () {
      final form = StrategyFormData(maShortPeriod: 60, maLongPeriod: 60);
      expect(form.hasMAWarning, isTrue);
    });

    test('hasMAWarning false when maShortPeriod < maLongPeriod', () {
      final form = StrategyFormData(maShortPeriod: 20, maLongPeriod: 60);
      expect(form.hasMAWarning, isFalse);
    });

    test('fromStrategy copies all params correctly', () {
      final now = DateTime(2026, 1, 1);
      final strategy = Strategy(
        id: 'test-id',
        name: '测试策略',
        description: '描述',
        maShortPeriod: 10,
        maLongPeriod: 40,
        bollPeriod: 15,
        bollStdDev: 2.5,
        weightMA: 0.40,
        weightBoll: 0.20,
        weightVol: 0.25,
        weightTrend: 0.15,
        recommendThreshold: 6,
        createdAt: now,
        updatedAt: now,
      );

      final form = StrategyFormData.fromStrategy(strategy);

      expect(form.name, '测试策略');
      expect(form.description, '描述');
      expect(form.maShortPeriod, 10);
      expect(form.maLongPeriod, 40);
      expect(form.bollPeriod, 15);
      expect(form.bollStdDev, 2.5);
      expect(form.weightMA, 0.40);
      expect(form.weightBoll, 0.20);
      expect(form.weightVol, 0.25);
      expect(form.weightTrend, 0.15);
      expect(form.recommendThreshold, 6);
    });

    test('fromTemplate applies template values', () {
      final template = ApiStrategyTemplates.all.first;
      final form = StrategyFormData.fromTemplate(template);

      expect(form.name, template.formData.name);
      expect(form.description, template.formData.description);
      expect(form.maShortPeriod, template.formData.maShortPeriod);
      expect(form.maLongPeriod, template.formData.maLongPeriod);
      expect(form.bollPeriod, template.formData.bollPeriod);
      expect(form.bollStdDev, template.formData.bollStdDev);
      expect(form.weightMA, template.formData.weightMA);
      expect(form.weightBoll, template.formData.weightBoll);
      expect(form.weightVol, template.formData.weightVol);
      expect(form.weightTrend, template.formData.weightTrend);
      expect(form.recommendThreshold, template.formData.recommendThreshold);
    });
  });

  group('StrategyImportHelper', () {
    test('imports valid strategy JSON', () {
      final form = StrategyImportHelper.fromJsonText('''
{
  "name": "三十天低谷",
  "description": "低位修复观察",
  "maShortPeriod": 20,
  "maLongPeriod": 60,
  "bollPeriod": 20,
  "bollStdDev": 2.0,
  "weightMA": 0.25,
  "weightBoll": 0.40,
  "weightVol": 0.20,
  "weightTrend": 0.15,
  "recommendThreshold": 7,
  "notes": "芯片股仅作为描述关键词"
}
''');

      expect(form.name, '三十天低谷');
      expect(form.weightBoll, 0.40);
      expect(form.validate(), isNull);
    });

    test('rejects invalid JSON', () {
      expect(
        () => StrategyImportHelper.fromJsonText('not json'),
        throwsFormatException,
      );
    });

    test('rejects missing required field', () {
      expect(
        () => StrategyImportHelper.fromJsonText('{"name":"缺字段"}'),
        throwsFormatException,
      );
    });

    test('rejects invalid weight sum', () {
      expect(
        () => StrategyImportHelper.fromJsonText('''
{
  "name": "权重错误",
  "description": "",
  "maShortPeriod": 20,
  "maLongPeriod": 60,
  "bollPeriod": 20,
  "bollStdDev": 2.0,
  "weightMA": 0.20,
  "weightBoll": 0.20,
  "weightVol": 0.20,
  "weightTrend": 0.20,
  "recommendThreshold": 7
}
'''),
        throwsFormatException,
      );
    });
  });

  group('Strategy', () {
    test('needsReview true after 30 days without review', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 31));
      final strategy = Strategy(
        id: 's1',
        name: 'Test',
        createdAt: oldDate,
        updatedAt: oldDate,
        lastReviewAt: null,
      );
      expect(strategy.needsReview, isTrue);
    });

    test('needsReview false if lastReviewAt is within 30 days', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 60));
      final recentReview = DateTime.now().subtract(const Duration(days: 5));
      final strategy = Strategy(
        id: 's1',
        name: 'Test',
        createdAt: oldDate,
        updatedAt: oldDate,
        lastReviewAt: recentReview,
      );
      expect(strategy.needsReview, isFalse);
    });

    test('needsReview false if strategy is less than 30 days old', () {
      final recentDate = DateTime.now().subtract(const Duration(days: 10));
      final strategy = Strategy(
        id: 's1',
        name: 'Test',
        createdAt: recentDate,
        updatedAt: recentDate,
        lastReviewAt: null,
      );
      expect(strategy.needsReview, isFalse);
    });

    test('isWeightSumValid checks sum of all 4 weights', () {
      final valid = Strategy(
        id: 's1',
        name: 'Test',
        weightMA: 0.25,
        weightBoll: 0.25,
        weightVol: 0.25,
        weightTrend: 0.25,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(valid.isWeightSumValid, isTrue);

      final invalid = Strategy(
        id: 's2',
        name: 'Test',
        weightMA: 0.10,
        weightBoll: 0.10,
        weightVol: 0.10,
        weightTrend: 0.10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(invalid.isWeightSumValid, isFalse);
    });

    test('copyWith creates modified copy', () {
      final original = Strategy(
        id: 's1',
        name: 'Original',
        description: 'Original desc',
        weightMA: 0.30,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final modified = original.copyWith(
        name: 'Modified',
        weightMA: 0.40,
        updatedAt: DateTime(2026, 6, 1),
      );

      expect(modified.id, 's1');
      expect(modified.name, 'Modified');
      expect(modified.description, 'Original desc'); // unchanged
      expect(modified.weightMA, 0.40);
      expect(modified.weightBoll, original.weightBoll); // unchanged
      expect(modified.createdAt, original.createdAt); // unchanged
      expect(modified.updatedAt, DateTime(2026, 6, 1));

      // Original unchanged
      expect(original.name, 'Original');
      expect(original.weightMA, 0.30);
    });
  });

  group('StrategyStats', () {
    test('hasEnoughData true when totalHits >= 20', () {
      final stats = StrategyStats(tradingDaysRun: 25);
      expect(stats.hasEnoughData, isTrue);
    });

    test('hasEnoughData false when totalHits < 20', () {
      final stats = StrategyStats(tradingDaysRun: 15);
      expect(stats.hasEnoughData, isFalse);
    });

    test('hitRateDisplay shows percentage with 1 decimal', () {
      final stats = StrategyStats(hitRate: 0.625, evaluatedCount: 10);
      expect(stats.hitRateDisplay, '62.5%');
    });

    test('healthScoreDisplay shows score out of 10', () {
      final stats = StrategyStats(healthScore: 7.2, evaluatedCount: 5);
      expect(stats.healthScoreDisplay, '7.2');
    });

    test('avgChangeDisplay shows -- when no data', () {
      final stats = StrategyStats(evaluatedCount: 0);
      expect(stats.avgChangeDisplay, '--');
    });

    test('extremeScoreDisplay shows max gain and max loss', () {
      final stats = StrategyStats(maxGain: 15.2, maxLoss: -8.3);
      expect(stats.extremeScoreDisplay, '+15.2% / -8.3%');
    });
  });

  group('StrategyHitRecord', () {
    StrategyHitRecord makeRecord({double? actualChange5d}) {
      return StrategyHitRecord(
        id: 'r1',
        strategyId: 's1',
        stockCode: '000001',
        stockName: '测试股票',
        recommendDate: '2026-05-01',
        recommendScore: 8,
        recommendPrice: 10.0,
        actualChange5d: actualChange5d,
        createdAt: DateTime(2026, 5, 1),
      );
    }

    test('isEvaluated true when actualChange5d is not null', () {
      final record = makeRecord(actualChange5d: 2.5);
      expect(record.isEvaluated, isTrue);
    });

    test('isEvaluated false when actualChange5d is null', () {
      final record = makeRecord();
      expect(record.isEvaluated, isFalse);
    });

    test('actualChangeDisplay shows -- when null', () {
      final record = makeRecord();
      expect(record.actualChangeDisplay, '--');
    });
  });
}
