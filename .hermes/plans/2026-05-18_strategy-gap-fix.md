# 策略管理系统差距修复 Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** 修复 v2.0 策略管理系统的差距：补全测试覆盖、补齐交互缺漏、验证遗留 code-review 问题、更新追溯矩阵

**Architecture:** 纯 Flutter 客户端，StrategyService(Drift SQLite) + Riverpod StateNotifier + GoRouter

**Tech Stack:** Flutter/Dart, Drift, Riverpod, flutter_test

---

## Task 1: StrategyService CRUD 测试

**Objective:** 为 createStrategy / updateStrategy / deleteStrategy / toggleEnabled 补全单元测试

**Files:**
- Modify: `test/unit/strategy_service_test.dart`

**Step 1: 写失败测试 — createStrategy**

```dart
test('createStrategy creates a new strategy with correct params', () async {
  final form = StrategyFormData(
    name: '测试策略',
    description: '测试描述',
    maShortPeriod: 10,
    maLongPeriod: 30,
    bollPeriod: 15,
    bollStdDev: 2.0,
    weightMA: 0.25,
    weightBoll: 0.25,
    weightVol: 0.25,
    weightTrend: 0.25,
    recommendThreshold: 6,
  );
  final strategy = await service.createStrategy(form);
  expect(strategy.name, '测试策略');
  expect(strategy.isEnabled, true);
  expect(strategy.isDefault, false);
  expect(strategy.maShortPeriod, 10);
  // verify persisted
  final all = service.getStrategies();
  expect(any((s) => s.id == strategy.id), true);
});
```

**Step 2: 运行验证失败**

Run: `flutter test test/unit/strategy_service_test.dart`
Expected: 编译通过

**Step 3: 写失败测试 — updateStrategy / deleteStrategy / toggleEnabled**

```dart
test('updateStrategy updates name and params', () async { ... });
test('deleteStrategy removes non-default strategy', () async { ... });
test('deleteStrategy throws for default strategy', () async { ... });
test('toggleEnabled switches strategy state', () async { ... });
test('toggleEnabled persists to database', () async { ... });
```

**Step 4: 运行全量测试**

Run: `flutter test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add test/unit/strategy_service_test.dart
git commit -m "test: add StrategyService CRUD unit tests"
```

---

## Task 2: StrategyService 命中记录与回填测试

**Objective:** 为 recordRecommendations / backfillActualChanges / _pruneOldRecords 补全测试

**Files:**
- Modify: `test/unit/strategy_service_test.dart`

**Step 1: 写失败测试**

```dart
group('Hit Records', () {
  test('recordRecommendations writes hit records', () async { ... });
  test('backfillActualChanges updates actualChange5d and isHit', () async { ... });
  test('backfillActualChanges keeps NULL when price unavailable', () async { ... });
  test('pruneOldRecords keeps latest 400 when exceeding 500', () async { ... });
  test('getHitRecords returns records sorted by date desc', () async { ... });
});
```

**Step 2: 运行验证**

Run: `flutter test test/unit/strategy_service_test.dart`

**Step 3: Commit**

```bash
git commit -m "test: add StrategyService hit record and backfill tests"
```

---

## Task 3: StrategyService 统计计算与复盘测试

**Objective:** 为 _computeStats / generateChecklist / generateSuggestions / createReview 补全测试

**Files:**
- Modify: `test/unit/strategy_service_test.dart`

**Step 1: 写失败测试**

```dart
group('Statistics', () {
  test('computeStats returns correct hit rate', () async { ... });
  test('computeStats shows -- when data insufficient', () async { ... });
  test('computeStats calculates health score correctly', () async { ... });
});

group('Checklist', () {
  test('generateChecklist returns 5 items', () async { ... });
  test('checklist marks fail when hit rate < 50%', () async { ... });
});

group('Suggestions', () {
  test('suggests raising threshold when hit rate < 50%', () async { ... });
  test('suggests increasing boll weight when max loss > 10%', () async { ... });
  test('returns empty when strategy performs well', () async { ... });
});

group('Reviews', () {
  test('createReview persists review with checklist results', () async { ... });
  test('getReviewHistory returns reviews sorted by date desc', () async { ... });
});
```

**Step 2: 运行验证**

Run: `flutter test test/unit/strategy_service_test.dart`

**Step 3: Commit**

```bash
git commit -m "test: add StrategyService stats, checklist, suggestions, reviews tests"
```

---

## Task 4: StrategyFormData 和 Strategy 模型测试

**Objective:** 为 validate / isWeightSumValid / needsReview / hasMAWarning 补全测试

**Files:**
- Modify: `test/unit/strategy_models_test.dart`

**Step 1: 写失败测试**

```dart
group('StrategyFormData', () {
  test('validate returns error when name empty', () { ... });
  test('validate passes with valid data', () { ... });
  test('isWeightSumValid true when sum is 1.0', () { ... });
  test('isWeightSumValid false when sum is 0.9', () { ... });
  test('hasMAWarning true when maShort >= maLong', () { ... });
  test('hasMAWarning false when maShort < maLong', () { ... });
  test('fromStrategy copies all params', () { ... });
  test('fromTemplate applies template values', () { ... });
});

group('Strategy', () {
  test('needsReview true after 30 days', () { ... });
  test('needsReview false if lastReviewAt is recent', () { ... });
  test('isWeightSumValid checks sum', () { ... });
});

group('StrategyStats', () {
  test('hasEnoughData true when hit count >= 20', () { ... });
  test('hitRateDisplay shows percentage', () { ... });
  test('healthScoreDisplay shows score out of 10', () { ... });
});
```

**Step 2: 运行验证**

Run: `flutter test test/unit/strategy_models_test.dart`

**Step 3: Commit**

```bash
git commit -m "test: add StrategyFormData, Strategy, StrategyStats model tests"
```

---

## Task 5: F007 补齐"3项异常建议停用"快捷按钮

**Objective:** 在复盘面板中，当 3 项以上 CheckList 标记为 fail 时，展示"建议停用策略"快捷按钮

**Files:**
- Modify: `lib/features/strategy/presentation/strategy_detail_page.dart` (L377 _showReviewDialog 方法内)

**Step 1: 写失败测试**（Widget Test）

在 `test/widget/` 下新增 `strategy_review_dialog_test.dart`:
- 测试: 3 项 fail 时显示"建议停用策略"按钮
- 测试: 少于 3 项 fail 时不显示该按钮

**Step 2: 实现 UI 变更**

在 `_showReviewDialog` 中，提交成功后检查 fail 计数：
```dart
final failCount = state.checklistItems!.where((i) => i.result == CheckResult.fail).length;
if (failCount >= 3) {
  // 在确认复盘成功后展示建议区域 + "停用策略"按钮
}
```

**Step 3: 运行验证**

Run: `flutter test`

**Step 4: Commit**

```bash
git commit -m "feat: add strategy disable suggestion when 3+ checklist items fail"
```

---

## Task 6: F008 补齐"采纳并编辑"跳转功能

**Objective:** 在迭代建议区域，每条建议旁添加"采纳并编辑"按钮，点击跳转编辑页并预填参数

**Files:**
- Modify: `lib/features/strategy/presentation/strategy_detail_page.dart` (L265 _buildSuggestions 方法)
- Modify: `lib/app.dart` (路由，确认 `/strategy/:id/edit` 支持预填参数)

**Step 1: 写失败测试**

- 测试: 建议列表中每条建议有"采纳并编辑"按钮
- 测试: 点击按钮跳转到编辑页，query 参数含 suggestedValue

**Step 2: 实现变更**

在 `_buildSuggestions` 中，为每个 `StrategySuggestion` 添加 `TextButton`:
```dart
TextButton(
  onPressed: () => context.push('/strategy/${widget.strategyId}/edit',
    extra: {'suggestion': suggestion}),
  child: Text('采纳并编辑'),
)
```

在 `StrategyEditPage` 中接收 suggestion extra 并预填对应字段。

**Step 3: 运行验证**

Run: `flutter test`

**Step 4: Commit**

```bash
git commit -m "feat: add adopt-and-edit button for strategy suggestions"
```

---

## Task 7: 验证 v1 Code Review 遗留问题

**Objective:** 逐一验证 F-S01/F-S02/F-S04/F-S05/F-S07/F-S08/F-S09 的修复状态

**Files:**
- Inspect: `lib/main.dart` (F-S02 风险声明弹窗)
- Inspect: `lib/features/stock/domain/stock_models.dart` (F-S04 preClose)
- Inspect: `lib/features/stock/data/stock_api_service.dart` (F-S05 JSON解析)
- Inspect: `lib/features/watchlist/presentation/watchlist_provider.dart` (F-S07 ref.watch)
- Inspect: `lib/features/stock/presentation/stock_detail_page.dart` (F-S08 alert持久化)
- Inspect: `android/app/src/main/AndroidManifest.xml` (F-S01 cleartext)

**Step 1: 逐个检查，记录状态**

对每个 issue：
- 读取相关文件
- 判断是否已修复
- 如未修复，写修复代码 + 测试

**Step 2: 更新 docs/code-review.md**

将每个 issue 状态更新为 ✅ 已修复 / ❌ 待修复 / ⚠️ 不适用

**Step 3: Commit**

```bash
git commit -m "docs: verify and update v1 code review issue status"
```

---

## Task 8: 更新追溯矩阵到 v2.0

**Objective:** 在 docs/traceability-matrix.md 中新增策略管理功能 F001-F009 的追溯条目

**Files:**
- Modify: `docs/traceability-matrix.md`

**Step 1: 新增策略管理追溯表**

```markdown
## v2.0 策略管理功能追溯

| 功能 ID | 功能名称 | 优先级 | Gherkin Scenario | 实现位置 | 测试 ID | 状态 |
|--------|---------|------|-----------------|---------|---------|------|
| SF001 | 策略列表页 | Must | 用户查看策略列表 | strategy_tab.dart | T-SF001-1 | 🧪 已测试 |
... (覆盖全部验收场景)
```

**Step 2: 更新统计信息**

- Must 功能总数更新
- 覆盖率重新计算

**Step 3: Commit**

```bash
git commit -m "docs: update traceability matrix for v2.0 strategy features"
```

---

## 执行顺序与依赖

```
Task 1 ─┐
Task 2 ─┤ (可并行: 1, 2, 3, 4 是独立的测试任务)
Task 3 ─┤
Task 4 ─┘
    ↓
Task 5 → Task 6 (UI改动，需串行，都改 strategy_detail_page.dart)
    ↓
Task 7 (独立验证)
    ↓
Task 8 (文档更新，最后做)
```

**预计总工作量**: 8 个任务，每个 5-15 分钟

## 验证标准

- [ ] `flutter analyze` 零错误
- [ ] `flutter test` 全部通过
- [ ] 策略相关测试从 4 个增加到 30+ 个
- [ ] F007 3项异常停用建议交互完成
- [ ] F008 采纳并编辑跳转完成
- [ ] v1 code review 遗留问题状态已确认
- [ ] 追溯矩阵已更新到 v2.0
