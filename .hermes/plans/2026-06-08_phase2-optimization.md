# Phase 2 Optimization Plan — TrendStock

> **For Hermes:** Use subagent-driven-development skill to implement tasks in parallel where possible.

**Goal:** P2 缓存 + P3 新指标 + P4 UI + P5 测试覆盖 300+

**Architecture:** Flutter/Dart, Drift SQLite, Riverpod, GoRouter

**Tech Stack:** Flutter 3.x, dart, drift, riverpod, dio

---

## P2: K线数据本地缓存层

### Task 2.1: 创建 KlineCache Drift 表 + DAO

**Files:**
- Create: `lib/features/stock/data/kline_cache.dart`
- Create: `test/unit/kline_cache_test.dart`

实现一个 Drift 表 `kline_cache`，字段：stockCode (PK), market, klinesJson, fetchedAt, expiresAt。
提供 DAO 方法：
- `getCachedKlines(code)` — 如果 expiresAt > now 返回缓存数据，否则返回 null
- `saveKlines(code, market, klines, ttl)` — 保存 K 线 JSON + 设置过期时间
- `clearExpired()` — 清除所有过期缓存
- `clearAll()` — 清除全部缓存

TTL 默认：盘中 5 分钟，盘后到次日开盘前。

TDD：先写测试验证 CRUD，再实现。

### Task 2.2: 创建 CachedStockApiService 装饰器

**Files:**
- Create: `lib/features/stock/data/cached_stock_api_service.dart`
- Create: `test/unit/cached_stock_api_service_test.dart`

用 Decorator 模式包装 `StockApiService`：
- `fetchStockKline()` — 先查缓存，miss 才调 API 然后写缓存
- `clearCache()` — 清除所有缓存
- 注入 KlineCache 和 StockApiService

TDD：mock 两个依赖，验证缓存命中/miss 逻辑。

### Task 2.3: 注册到 Riverpod provider

**Files:**
- Modify: `lib/shared/providers.dart`

添加 `klineCacheProvider` 和 `cachedStockApiServiceProvider`，替换原来直接用的 `stockApiServiceProvider`。

---

## P3: 更多信号指标规则

### Task 3.1: 添加 BOLL 位置 + 均线多头排列 + 量价背离指标到 RuleEngine

**Files:**
- Modify: `lib/features/strategy/domain/rule_engine.dart`
- Modify: `lib/features/analysis/domain/indicator_calculator.dart` (添加 calculateBollPosition, calculateMAAlignment, calculateVolumePriceDivergence)
- Create: `test/unit/new_indicators_test.dart`

在 RuleEngine.evaluate 中新增指标值计算：
- `boll_position` — 当前价在布林带的位置 (0-1)
- `ma_alignment` — 均线多头排列度 (MA5>MA10>MA20>MA60 得分 0-10)
- `vol_price_divergence` — 量价背离检测 (价涨量缩 或 价跌量增 → 1, 否则 0)
- `vol_ratio` — 量比

在 IndicatorCalculator 中添加对应静态方法。

TDD: 每个新指标先写测试验证计算逻辑。

### Task 3.2: 添加新的预设策略模板

**Files:**
- Modify: `lib/features/strategy/domain/strategy_presets.dart`

新增 3 个预设：
1. **布林带下轨反弹** — boll_position < 0.15 AND rsi < 35 → 入场
2. **均线多头排列** — ma_alignment > 7 AND vol_ratio > 1.2 → 入场
3. **量价背离抄底** — vol_price_divergence == 1 AND rsi < 40 → 入场

---

## P4: UI 策略规则编辑器

### Task 4.1: 创建 SignalRuleEditSheet widget

**Files:**
- Create: `lib/features/strategy/presentation/widgets/signal_rule_edit_sheet.dart`
- Create: `test/widget/signal_rule_edit_sheet_test.dart`

一个 BottomSheet widget，包含：
- 指标选择下拉（RSI/MACD/K/BOLL位置/均线排列/量价背离）
- 条件选择下拉（lt/gt/in_range/cross_up/cross_down）
- 阈值输入（value, 可选 value2 for in_range）
- 确定/取消按钮
- 返回 SignalRule?

### Task 4.2: 在策略编辑页集成规则编辑器

**Files:**
- Modify: `lib/features/strategy/presentation/strategy_edit_page.dart`

在策略编辑页的表单中：
- 当 `isRuleBased` 开关打开时，显示入场规则列表 + 出场规则列表
- 每条规则显示 indicator/condition/value，可删除
- 底部"添加规则"按钮 → 打开 SignalRuleEditSheet
- 保存时把规则列表写入 Strategy

---

## P5: 测试覆盖冲刺 300+

### Task 5.1: 补充 Widget Test — 策略 Tab

**Files:**
- Create: `test/widget/strategy_tab_test.dart`

测试策略列表页渲染、策略详情页导航、创建/编辑流程。

### Task 5.2: 补充 Widget Test — 自选 Tab

**Files:**
- Create: `test/widget/watchlist_tab_test.dart`

测试自选列表渲染、添加/删除、排序。

### Task 5.3: 补充单元测试 — IndicatorCalculator 新方法

**Files:**
- Modify: `test/unit/indicator_calculator_test.dart`

给 RSI, MACD, KDJ 补更多边界用例 + 新指标测试。

---

## Execution Order

- **P2 Tasks (2.1 → 2.2 → 2.3)** — 串行，有依赖
- **P3 Tasks (3.1 → 3.2)** — 串行，3.2 依赖 3.1
- **P4 Tasks (4.1 → 4.2)** — 串行，4.2 依赖 4.1
- **P5 Tasks (5.1, 5.2, 5.3)** — 可并行

**ParallelGroup 1:** P2 + P3 (P3 不依赖 P2)
**ParallelGroup 2:** P4 (依赖 P3.1 的指标列表)
**ParallelGroup 3:** P5 (贯穿全程)
