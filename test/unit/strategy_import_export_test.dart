import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/strategy_import_export.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';

/// Helper to build a consistent [Strategy] for testing.
Strategy _makeStrategy({
  String id = 'test-strategy-001',
  String name = '测试策略',
  String description = '用于导入导出测试的策略',
}) {
  final now = DateTime(2026, 6, 8, 10, 0, 0);
  return Strategy(
    id: id,
    name: name,
    description: description,
    maShortPeriod: 20,
    maLongPeriod: 60,
    bollPeriod: 20,
    bollStdDev: 2.0,
    weightMA: 0.30,
    weightBoll: 0.30,
    weightVol: 0.20,
    weightTrend: 0.20,
    recommendThreshold: 7,
    isEnabled: true,
    isDefault: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // -----------------------------------------------------------------------
  // 1. Export produces valid JSON with wrapper
  // -----------------------------------------------------------------------
  group('exportStrategy', () {
    test('produces valid JSON with wrapper envelope', () {
      final strategy = _makeStrategy();
      final exported = StrategyImportExport.exportStrategy(strategy);
      final parsed = jsonDecode(exported) as Map<String, dynamic>;

      expect(parsed['version'], 1);
      expect(parsed['app'], 'stockpilot');
      expect(parsed.containsKey('exportedAt'), isTrue);
      expect(parsed.containsKey('strategy'), isTrue);

      // exportedAt should be a parseable ISO-8601 string
      final ts = parsed['exportedAt'] as String;
      expect(() => DateTime.parse(ts), returnsNormally);

      // strategy field should contain the strategy data
      final strategyJson = parsed['strategy'] as Map<String, dynamic>;
      expect(strategyJson['id'], strategy.id);
      expect(strategyJson['name'], strategy.name);
    });
  });

  // -----------------------------------------------------------------------
  // 2. Import round-trip: export → import should produce equivalent strategy
  // -----------------------------------------------------------------------
  group('importStrategy round-trip', () {
    test('export then import produces equivalent strategy', () {
      final original = _makeStrategy();
      final exported = StrategyImportExport.exportStrategy(original);
      final imported = StrategyImportExport.importStrategy(exported);

      expect(imported.id, original.id);
      expect(imported.name, original.name);
      expect(imported.description, original.description);
      expect(imported.maShortPeriod, original.maShortPeriod);
      expect(imported.maLongPeriod, original.maLongPeriod);
      expect(imported.bollPeriod, original.bollPeriod);
      expect(imported.bollStdDev, original.bollStdDev);
      expect(imported.weightMA, original.weightMA);
      expect(imported.weightBoll, original.weightBoll);
      expect(imported.weightVol, original.weightVol);
      expect(imported.weightTrend, original.weightTrend);
      expect(imported.recommendThreshold, original.recommendThreshold);
      expect(imported.isEnabled, original.isEnabled);
      expect(imported.isDefault, original.isDefault);
    });
  });

  // -----------------------------------------------------------------------
  // 3. Import raw strategy JSON (without wrapper) also works
  // -----------------------------------------------------------------------
  group('importStrategy raw JSON', () {
    test('imports raw strategy JSON without wrapper envelope', () {
      final original = _makeStrategy();
      final rawJson = jsonEncode(original.toJson());

      final imported = StrategyImportExport.importStrategy(rawJson);

      expect(imported.id, original.id);
      expect(imported.name, original.name);
      expect(imported.maShortPeriod, original.maShortPeriod);
    });
  });

  // -----------------------------------------------------------------------
  // 4. Validate returns null for valid export
  // -----------------------------------------------------------------------
  group('validateImportJson', () {
    test('returns null for valid wrapped export', () {
      final strategy = _makeStrategy();
      final exported = StrategyImportExport.exportStrategy(strategy);

      expect(StrategyImportExport.validateImportJson(exported), isNull);
    });

    // -------------------------------------------------------------------
    // 5. Validate returns error message for invalid JSON
    // -------------------------------------------------------------------
    test('returns error message for invalid JSON', () {
      final error = StrategyImportExport.validateImportJson('not json at all');
      expect(error, isNotNull);
      expect(error, contains('JSON parse error'));
    });

    // -------------------------------------------------------------------
    // 6. Validate returns error for missing strategy field
    // -------------------------------------------------------------------
    test('returns error for wrapper without strategy field', () {
      // Wrap with envelope keys but omit 'strategy'
      final wrapper = {
        'version': 1,
        'app': 'stockpilot',
        'exportedAt': DateTime.now().toIso8601String(),
      };
      final json = jsonEncode(wrapper);

      final error = StrategyImportExport.validateImportJson(json);
      expect(error, isNotNull);
    });

    test('returns null for valid raw strategy JSON', () {
      final strategy = _makeStrategy();
      final rawJson = jsonEncode(strategy.toJson());

      expect(StrategyImportExport.validateImportJson(rawJson), isNull);
    });
  });

  // -----------------------------------------------------------------------
  // 7. Batch export produces one JSON string per strategy
  // -----------------------------------------------------------------------
  group('batchExport', () {
    test('produces one JSON string per strategy', () {
      final strategies = [
        _makeStrategy(id: 's1', name: '策略一'),
        _makeStrategy(id: 's2', name: '策略二'),
        _makeStrategy(id: 's3', name: '策略三'),
      ];

      final exports = StrategyImportExport.batchExport(strategies);

      expect(exports, hasLength(3));

      for (var i = 0; i < strategies.length; i++) {
        final parsed = jsonDecode(exports[i]) as Map<String, dynamic>;
        expect(parsed['strategy']['id'], strategies[i].id);
        expect(parsed['strategy']['name'], strategies[i].name);
      }
    });

    test('returns empty list for empty input', () {
      expect(StrategyImportExport.batchExport([]), isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // 8. Import throws FormatException for completely invalid input
  // -----------------------------------------------------------------------
  group('importStrategy error handling', () {
    test('throws FormatException for non-JSON string', () {
      expect(
        () => StrategyImportExport.importStrategy('not valid json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for JSON array instead of object', () {
      expect(
        () => StrategyImportExport.importStrategy('[1, 2, 3]'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
