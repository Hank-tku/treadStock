# S2: 规则引擎增强 - 规则组 + OR逻辑

## 目标
当前规则引擎限制：entry rules 全 AND，exit rules 全 OR。需支持灵活组合。

## 改动范围

### 1. signal_rule.dart — 新增 RuleGroup 模型
```dart
/// 规则组：组内规则 AND，组间 OR
class RuleGroup {
  final List<SignalRule> rules;
  const RuleGroup({required this.rules});
}
```

### 2. strategy_models.dart — 新增 ruleGroups 字段
- Strategy: 新增 `List<RuleGroup>? entryGroups` / `List<RuleGroup>? exitGroups`
- 向后兼容：如果 entryGroups 为空则 fallback 到 entryRules（AND 逻辑）
- StrategyForm 同步更新

### 3. rule_engine.dart — 支持规则组评估
- `evaluate()` 新增 `entryGroups` / `exitGroups` 参数
- 逻辑：任何一组 rules 全部满足 → entry triggered
- 向后兼容旧策略

### 4. strategy_create_page.dart / strategy_edit_page.dart
- 创建/编辑策略时支持添加多个规则组
- 每组内可加多条规则（AND）
- 组间关系 OR

### 5. 测试
- rule_engine_test.dart：规则组 OR 逻辑测试
- signal_rule_test.dart：现有测试不变

## 不改
- IndicatorCalculator — 指标计算不变
- 回测引擎 — 已通过 RuleEngine.evaluate 间接支持
- DB schema — RuleGroup JSON 序列化到现有 entry_rules_json 字段
