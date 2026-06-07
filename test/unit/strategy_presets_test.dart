import 'package:flutter_test/flutter_test.dart';
import 'package:stockpilot/features/strategy/domain/strategy_models.dart';
import 'package:stockpilot/features/strategy/domain/strategy_presets.dart';

void main() {
  final validIndicators = {
    'rsi', 'macd', 'macd_signal', 'macd_hist',
    'k', 'd', 'j', 'boll_position',
    'ma_alignment', 'vol_price_divergence', 'vol_ratio',
  };
  final validConditions = {'lt', 'gt', 'in_range', 'cross_up', 'cross_down'};

  List<Strategy> makePresets() => StrategyPresets.all(
    idGenerator: () => 'test-id',
    now: DateTime(2026, 1, 1),
  );

  test('all() returns exactly 6 presets', () {
    expect(makePresets().length, 6);
  });

  test('all presets have non-empty name and description', () {
    for (final preset in makePresets()) {
      expect(preset.name, isNotEmpty);
      expect(preset.description, isNotEmpty);
    }
  });

  test('all presets have non-empty entryRules', () {
    for (final preset in makePresets()) {
      expect(preset.entryRules, isNotNull);
      expect(preset.entryRules!, isNotEmpty,
          reason: '${preset.name} should have entry rules');
    }
  });

  test('all presets have exitRules', () {
    for (final preset in makePresets()) {
      expect(preset.exitRules, isNotNull,
          reason: '${preset.name} should have exit rules');
      expect(preset.exitRules!, isNotEmpty,
          reason: '${preset.name} should have non-empty exit rules');
    }
  });

  test('all rules have valid indicator and condition values', () {
    for (final preset in makePresets()) {
      final allRules = [...?preset.entryRules, ...?preset.exitRules];
      for (final rule in allRules) {
        expect(validIndicators, contains(rule.indicator),
            reason: '${preset.name}: invalid indicator "${rule.indicator}"');
        expect(validConditions, contains(rule.condition),
            reason: '${preset.name}: invalid condition "${rule.condition}"');
      }
    }
  });

  test('all presets have unique names', () {
    final names = makePresets().map((p) => p.name).toList();
    expect(names.toSet().length, names.length,
        reason: 'Preset names should be unique');
  });
}
