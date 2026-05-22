# 需求追溯矩阵
生成时间：2026-05-18 | 版本：v2.0 | 基于 PRD v1.0 + v2.0
架构：纯 Flutter 客户端（无后端）

---

## v1.0 需求追溯（基线）

| 功能 ID | 功能名称 | 优先级 | Gherkin Scenario | 预期实现位置（FE） | 预期实现位置（BE） | 测试 ID | 状态 |
|--------|---------|------|-----------------|----------------|-----------------|---------|------|
| F001 | 每日推荐股票列表 | Must | 用户成功查看每日推荐列表 | `lib/features/recommendation/presentation/recommendation_tab.dart` | 无（本地计算） | T-F001-1 | 🧪 已测试 |
| F001 | 每日推荐股票列表 | Must | 推荐列表数据加载中 | `lib/features/recommendation/presentation/recommendation_tab.dart` | -- | T-F001-2 | 🧪 已测试 |
| F001 | 每日推荐股票列表 | Must | 推荐列表数据加载失败 | `lib/features/recommendation/presentation/recommendation_tab.dart` | -- | T-F001-3 | 🧪 已测试 |
| F001 | 每日推荐股票列表 | Must | 用户点击推荐股票进入详情 | `lib/features/recommendation/presentation/recommendation_tab.dart` + router | -- | T-F001-4 | 🧪 已测试 |
| F002 | 关注股票列表 | Must | 用户成功查看关注列表 | `lib/features/watchlist/presentation/watchlist_tab.dart` | 无（SQLite 本地） | T-F002-1 | 🧪 已测试 |
| F002 | 关注股票列表 | Must | 用户通过搜索添加关注股票 | `lib/features/watchlist/presentation/watchlist_tab.dart` | -- | T-F002-2 | 🧪 已测试 |
| F002 | 关注股票列表 | Must | 用户左滑删除关注股票 | `lib/features/watchlist/presentation/watchlist_tab.dart` (flutter_slidable) | -- | T-F002-3 | 🧪 已测试 |
| F002 | 关注股票列表 | Must | 用户右滑置顶关注股票 | `lib/features/watchlist/presentation/watchlist_tab.dart` (flutter_slidable) | -- | T-F002-4 | 🧪 已测试 |
| F002 | 关注股票列表 | Must | 关注列表为空时的引导 | `lib/features/watchlist/presentation/watchlist_tab.dart` | -- | T-F002-5 | 🧪 已测试 |
| F002 | 关注股票列表 | Must | 点击"添加关注"按钮后的交互中间态 | `lib/features/watchlist/presentation/watchlist_tab.dart` | -- | T-F002-6 | 🧪 已测试 |
| F002 | 关注股票列表 | Must | 添加关注 API 请求失败 | `lib/features/watchlist/presentation/watchlist_tab.dart` | -- | T-F002-7 | 🧪 已测试 |
| F003 | 股票详情页 | Must | 用户成功查看股票详情 | `lib/features/stock/presentation/stock_detail_page.dart` | -- | T-F003-1 | 🧪 已测试 |
| F003 | 股票详情页 | Must | 详情页新闻加载中 | `lib/features/stock/presentation/stock_detail_page.dart` | -- | T-F003-2 | 🧪 已测试 |
| F003 | 股票详情页 | Must | 详情页新闻加载失败 | `lib/features/stock/presentation/stock_detail_page.dart` | -- | T-F003-3 | 🧪 已测试 |
| F003 | 股票详情页 | Must | 详情页展示评分颜色标识 | `lib/features/stock/presentation/stock_detail_page.dart` + `lib/shared/widgets/score_badge.dart` | -- | T-F003-4 | 🧪 已测试 |
| F003 | 股票详情页 | Must | 未登录用户访问详情页 | N/A（无登录体系，所有功能开放） | -- | T-F003-5 | 跳过 |
| F004 | 简化评分系统 | Must | 系统为股票生成评分 | `lib/features/analysis/domain/analysis_engine.dart` | 无（Dart 本地计算） | T-F004-1 | 🧪 已测试 |
| F004 | 简化评分系统 | Must | 评分数据加载中 | `lib/shared/widgets/score_badge.dart` (ScoreBadgeLoading) | -- | T-F004-2 | 🧪 已测试 |
| F004 | 简化评分系统 | Must | 评分计算失败 | `lib/shared/widgets/score_badge.dart` (score=null -> N/A) | -- | T-F004-3 | 🧪 已测试 |
| F005 | 每日跟踪摘要 | Should | 用户查看每日跟踪摘要 | `lib/features/stock/presentation/stock_detail_page.dart` | 无（Dart 本地计算） | T-F005-1 | 🧪 已测试 |
| F005 | 每日跟踪摘要 | Should | 非交易日或盘中的跟踪摘要 | `lib/features/stock/presentation/stock_detail_page.dart` | -- | T-F005-2 | 🧪 已测试 |
| F006 | 下跌预警通知 | Should | 系统检测到波段下跌信号并发送通知 | `lib/features/analysis/domain/analysis_engine.dart` (checkDownsideAlert) | 无（本地通知） | T-F006-1 | 🧪 已测试 |
| F006 | 下跌预警通知 | Should | 用户关闭某只股票的预警通知 | `lib/features/stock/presentation/stock_detail_page.dart` (alert switch) | -- | T-F006-2 | 🧪 已测试 |
| F006 | 下跌预警通知 | Should | 用户未授予通知权限 | `lib/features/stock/presentation/stock_detail_page.dart` | -- | T-F006-3 | 🧪 已测试 |

---

## v2.0 策略管理需求追溯

### SF001 策略列表页（Must）— 7 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF001-1 | 用户查看策略列表（策略卡片显示名称/描述/状态/命中率/健康度，按启用状态排序） | `strategy_tab.dart` + `strategy_provider.dart` | ⚠️ 需 widget 测试 |
| T-SF001-2 | 策略列表为空（首次使用，展示默认策略 + 创建按钮） | `strategy_tab.dart` | ⚠️ 需 widget 测试 |
| T-SF001-3 | 用户点击"创建新策略"按钮跳转创建表单 | `strategy_tab.dart` → `/strategy/new` (`app.dart`) | ⚠️ 需 widget 测试 |
| T-SF001-4 | 策略列表加载中（Skeleton 占位动画） | `strategy_tab.dart` | ⚠️ 需 widget 测试 |
| T-SF001-5 | 策略列表加载失败（SQLite 异常，错误提示 + 重试） | `strategy_tab.dart` + `strategy_provider.dart` | ⚠️ 需 widget 测试 |
| T-SF001-6 | 用户启用/停用策略切换（开关动画、列表重排序、Toast 提示） | `strategy_tab.dart` + `strategy_service.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |
| T-SF001-7 | 启用/停用数据库更新失败（开关恢复、Toast 错误提示） | `strategy_tab.dart` + `strategy_service.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |

### SF002 策略创建/编辑表单（Must）— 6 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF002-1 | 用户成功创建策略（填写名称/描述/参数，权重和=1.0，保存写入 SQLite，返回列表） | `strategy_edit_page.dart` + `strategy_service.dart` | ⚠️ 需 widget 测试 |
| T-SF002-2 | 权重之和不等于 1.0 时提交被阻止（红色错误提示） | `strategy_edit_page.dart` + `strategy_models.dart` | 🧪 已测试 (`strategy_models_test.dart`) |
| T-SF002-3 | 策略名称为空时提交被阻止（红色错误提示） | `strategy_edit_page.dart` + `strategy_models.dart` | 🧪 已测试 (`strategy_models_test.dart`) |
| T-SF002-4 | MA 短期周期 ≥ MA 长期周期时黄色警告（不阻止提交） | `strategy_edit_page.dart` + `strategy_models.dart` | 🧪 已测试 (`strategy_models_test.dart`) |
| T-SF002-5 | 用户编辑已有策略（预填参数、更新 SQLite、返回详情页） | `strategy_edit_page.dart` + `strategy_service.dart` (`/strategy/:id/edit`) | ⚠️ 需 widget 测试 |
| T-SF002-6 | 保存策略 SQLite 写入失败（保留表单数据、Toast 提示） | `strategy_edit_page.dart` + `strategy_service.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |

### SF003 推荐列表按策略分组展示（Must）— 6 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF003-1 | 用户查看按策略分组的推荐列表（分组标题含策略名+数量，组内评分降序，组间命中率降序） | `recommendation_tab.dart` + `strategy_provider.dart` (`strategyRecommendationProvider`) | ⚠️ 需 widget 测试 |
| T-SF003-2 | 多个策略推荐同一只股票（在各分组分别出现，评分可能不同） | `recommendation_tab.dart` + `strategy_provider.dart` | ⚠️ 需 widget 测试 |
| T-SF003-3 | 仅有 1 个策略启用时推荐列表展示（与 v1.0 类似） | `recommendation_tab.dart` | ⚠️ 需 widget 测试 |
| T-SF003-4 | 所有策略均停用时推荐空状态（提示前往策略管理） | `recommendation_tab.dart` | ⚠️ 需 widget 测试 |
| T-SF003-5 | 推荐列表加载中（按策略分组骨架屏，部分完成先展示） | `recommendation_tab.dart` | ⚠️ 需 widget 测试 |
| T-SF003-6 | 某策略计算异常不影响其他策略（异常分组显示提示） | `recommendation_tab.dart` + `strategy_provider.dart` | ⚠️ 需 widget 测试 |

### SF004 策略详情页（Must）— 9 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF004-1 | 用户查看策略详情（≥20 交易日：命中率/极限分值/平均差/总推荐/健康度 + 最近 20 条记录） | `strategy_detail_page.dart` + `strategy_provider.dart` | ⚠️ 需 widget 测试 |
| T-SF004-2 | 策略运行不足 20 个交易日（标注数据不足，展示已有记录） | `strategy_detail_page.dart` + `strategy_service.dart` | ⚠️ 需 widget 测试 |
| T-SF004-3 | 策略从未产生过推荐（所有指标显示"--"，提示无记录） | `strategy_detail_page.dart` | ⚠️ 需 widget 测试 |
| T-SF004-4 | 策略详情页加载中（名称正常 + Skeleton） | `strategy_detail_page.dart` | ⚠️ 需 widget 测试 |
| T-SF004-5 | 策略详情页统计计算失败（名称正常 + 错误提示 + 重新计算按钮） | `strategy_detail_page.dart` | ⚠️ 需 widget 测试 |
| T-SF004-6 | 用户点击推荐记录中的股票（跳转 StockDetailPage） | `strategy_detail_page.dart` → `/stock/:code` (`app.dart`) | ⚠️ 需 widget 测试 |
| T-SF004-7 | 用户在详情页点击"编辑"按钮（跳转编辑表单） | `strategy_detail_page.dart` → `/strategy/:id/edit` (`app.dart`) | ⚠️ 需 widget 测试 |
| T-SF004-8 | 用户点击"删除策略"（确认对话框 → 删除 → 返回列表 + Toast） | `strategy_detail_page.dart` + `strategy_service.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |
| T-SF004-9 | 用户尝试删除默认策略（删除按钮不显示或 disabled） | `strategy_detail_page.dart` | ⚠️ 需 widget 测试 |

### SF005 策略执行引擎（Must）— 3 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF005-1 | 多策略并行计算推荐（每策略独立参数评分，产生各自推荐列表） | `strategy_provider.dart` + `analysis_engine.dart` | 🧪 已测试 (`analysis_engine_test.dart`, `strategy_service_test.dart`) |
| T-SF005-2 | 策略参数影响评分结果（不同阈值/权重导致不同推荐） | `strategy_provider.dart` + `analysis_engine.dart` | 🧪 已测试 (`analysis_engine_test.dart`) |
| T-SF005-3 | 策略计算超时降级（标记超时，不影响其他策略） | `strategy_provider.dart` | 🧪 已测试 (`strategy_service_test.dart`) |

### SF006 策略命中记录持久化（Must）— 4 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF006-1 | 系统自动记录策略推荐（写入 StrategyHitRecords，actual_change_5d=NULL） | `strategy_service.dart` (StrategyHitRecords table) | 🧪 已测试 (`strategy_service_test.dart`) |
| T-SF006-2 | 系统回填 5 日实际涨跌幅（查询收盘价、计算涨跌幅、更新 is_hit） | `strategy_service.dart` (backfill) | 🧪 已测试 (`strategy_service_test.dart`) |
| T-SF006-3 | 回填数据时行情数据不可用（保持 NULL，下次重试） | `strategy_service.dart` | 🧪 已测试 (`strategy_service_test.dart`) |
| T-SF006-4 | 命中记录数据量控制（超过 500 条自动清理至 400 条） | `strategy_service.dart` (cleanup) | 🧪 已测试 (`strategy_service_test.dart`) |

### SF007 策略周期性复盘打分（Should）— 4 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF007-1 | 系统自动生成复盘 Check List（5 项检查 + 自动判定 + 数据依据） | `strategy_service.dart` + `strategy_detail_page.dart` | 🧪 逻辑已测试 (`strategy_service_test.dart`) / ⚠️ UI 需 widget 测试 |
| T-SF007-2 | 用户确认复盘 Check List（通过/需关注/异常标识 + 健康度评分 + 备注 + 写入 StrategyReviews） | `strategy_detail_page.dart` + `strategy_service.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |
| T-SF007-3 | 复盘 Check List 中 3 项以上异常（建议停用 + 快捷按钮） | `strategy_service.dart` + `strategy_detail_page.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |
| T-SF007-4 | 用户查看历史复盘记录（时间线列表 + 完整 Check List 详情） | `strategy_detail_page.dart` + `strategy_service.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |

### SF008 策略迭代方向建议（Should）— 3 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF008-1 | 系统基于统计数据给出迭代建议（命中率/平均差/极限跌幅/趋势/频率 → 建议） | `strategy_service.dart` + `strategy_detail_page.dart` | 🧪 逻辑已测试 (`strategy_service_test.dart`) / ⚠️ UI 需 widget 测试 |
| T-SF008-2 | 用户采纳建议后跳转编辑（参数自动调整到建议值） | `strategy_detail_page.dart` → `/strategy/:id/edit` (`app.dart`, extra: suggestion) | ⚠️ 需 widget 测试 |
| T-SF008-3 | 策略表现良好时无迭代建议（展示"表现良好，无需调整"） | `strategy_service.dart` + `strategy_detail_page.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |

### SF009 默认策略自动迁移（Should）— 2 场景

| 测试 ID | Gherkin Scenario | 实现位置 | 状态 |
|---------|-----------------|---------|------|
| T-SF009-1 | 首次打开 v2.0 自动创建默认策略（Strategy 表为空 → 插入默认波段策略，is_default=true） | `database.dart` (`_ensureDefaultStrategy`) + `strategy_service.dart` | 🧪 已测试 (`strategy_service_test.dart`) |
| T-SF009-2 | 默认策略不可删除但可编辑（无删除按钮，编辑正常可用） | `strategy_detail_page.dart` + `strategy_service.dart` | 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试 |

---

## 状态说明
- 🧪 已测试: 单元/集成测试通过（逻辑层）
- 🧪 逻辑已测试 / ⚠️ UI 需 widget 测试: Service/Provider 已有测试覆盖，UI 交互待补充 widget 测试
- ⚠️ 需 widget 测试: 纯 UI 交互场景，尚未编写 widget 测试
- 待实现: 尚未开始编码
- 实现中（FE/BE 更新）: 正在编码
- 已实现（Reviewer 验证）: 代码完成，Review 通过
- 跳过: 不适用（如无登录体系）

---

## 覆盖统计

### v1.0 Must 功能
- 总 Must 功能：4 个（F001, F002, F003, F004）
- Must Gherkin Scenario 总数：15 个（F003-5 因无登录体系跳过，实际 14 个）
- 预期实现路径已填写：15/15
- 覆盖率：100%

### v1.0 Should 功能
- 总 Should 功能：2 个（F005, F006）
- Should Gherkin Scenario 总数：5 个
- 覆盖率：100%

### v2.0 Must 功能
- 总 Must 功能：6 个（SF001, SF002, SF003, SF004, SF005, SF006）
- Must Gherkin Scenario 总数：35 个
  - SF001: 7 场景
  - SF002: 6 场景
  - SF003: 6 场景
  - SF004: 9 场景
  - SF005: 3 场景
  - SF006: 4 场景
- 已有单元测试覆盖：10/35（SF005 全部 + SF006 全部 + SF002 验证类）
- 需 widget 测试补充：25/35（SF001/SF003/SF004 纯 UI + SF002 部分）
- 预期实现路径已填写：35/35
- 覆盖率：100%

### v2.0 Should 功能
- 总 Should 功能：3 个（SF007, SF008, SF009）
- Should Gherkin Scenario 总数：9 个
  - SF007: 4 场景
  - SF008: 3 场景
  - SF009: 2 场景
- 已有单元测试覆盖（逻辑层）：7/9
- 需 widget 测试补充（UI 层）：9/9
- 预期实现路径已填写：9/9
- 覆盖率：100%

### 总体覆盖率
| 版本 | 优先级 | 功能数 | 场景数 | 单元测试覆盖 | Widget 测试覆盖 |
|------|--------|--------|--------|-------------|----------------|
| v1.0 | Must | 4 | 14 | 14 ✅ | 14 ✅ |
| v1.0 | Should | 2 | 5 | 5 ✅ | 5 ✅ |
| v2.0 | Must | 6 | 35 | 10 🧪 | 0 ⚠️ (25 待补充) |
| v2.0 | Should | 3 | 9 | 7 🧪 | 0 ⚠️ (9 待补充) |
| **合计** | -- | **15** | **63** | **36 已测试** | **19 已测试 + 34 待补充** |

---

## 关键共享组件映射

| 共享组件 | 路径 | 被以下功能使用 |
|---------|------|--------------|
| StockListItem | `lib/shared/widgets/stock_list_item.dart` | F001, F002, SF003 |
| ScoreBadge | `lib/shared/widgets/score_badge.dart` | F001, F002, F003, F004, SF003 |
| SkeletonLoader | `lib/shared/widgets/skeleton_loader.dart` | F001, F002, F003, SF001, SF003, SF004 |
| ErrorRetry | 内嵌于各页面 | F001, F003, SF001, SF004 |
| DisclaimLabel | `lib/shared/widgets/disclaimer_label.dart` | F001, F002, F003, F004, SF001, SF004 |
| EmptyState | `lib/shared/widgets/empty_state.dart` | F001, F002, SF001, SF003 |
| CacheBanner | `lib/shared/widgets/cache_banner.dart` | F001, SF003 |
| ToastHelper | `lib/shared/widgets/toast_helper.dart` | F001, F002, F003, SF001, SF002, SF004 |
| BandLowTag | `lib/shared/widgets/band_low_tag.dart` | F001 |

---

## Service / Provider 映射

### v1.0 Service/Provider

| Service | 路径 | 职责 |
|---------|------|------|
| StockApiService | `lib/features/stock/data/stock_api_service.dart` | HTTP 请求东方财富/新浪 API |
| AnalysisEngine | `lib/features/analysis/domain/analysis_engine.dart` | MA/Bollinger/评分计算 |
| WatchlistService | `lib/features/watchlist/data/watchlist_service.dart` | 关注列表 CRUD |
| RecommendationProvider | `lib/features/recommendation/presentation/recommendation_provider.dart` | 推荐列表状态管理 |
| WatchlistProvider | `lib/features/watchlist/presentation/watchlist_provider.dart` | 关注列表状态管理 |

### v2.0 新增 Service/Provider

| Service / Provider | 路径 | 职责 | 覆盖功能 |
|-------------------|------|------|---------|
| StrategyService | `lib/features/strategy/data/strategy_service.dart` | 策略 CRUD、命中记录读写、回填、复盘计算、迭代建议、数据清理 | SF001, SF002, SF004, SF006, SF007, SF008, SF009 |
| StrategyListProvider | `lib/features/strategy/presentation/strategy_provider.dart` | 策略列表状态管理、启用/停用切换 | SF001 |
| StrategyDetailProvider | `lib/features/strategy/presentation/strategy_provider.dart` | 策略详情/统计/复盘状态管理 | SF004, SF007 |
| StrategyRecommendationProvider | `lib/features/strategy/presentation/strategy_provider.dart` | 多策略推荐计算 + 按策略分组 | SF003, SF005 |

---

## 数据库表映射

### v1.0 表

| Drift Table | 路径 | 写入方 | 读取方 |
|------------|------|--------|--------|
| WatchlistItems | `lib/features/watchlist/data/watchlist_service.dart` (v1 内存实现) | WatchlistService | WatchlistTab, SearchSheet |
| StockInfoCache | 待 Drift 数据库实现 | StockApiService | StockDetailPage |
| DailyQuoteCache | 待 Drift 数据库实现 | StockApiService | AnalysisEngine, RecommendationTab |
| DailyRecommendationCache | 待 Drift 数据库实现 | AnalysisEngine | RecommendationTab |
| NewsCache | 待 Drift 数据库实现 | NewsService | StockDetailPage |

### v2.0 新增表

| Drift Table | 定义路径 | 写入方 | 读取方 | 对应功能 |
|------------|---------|--------|--------|---------|
| Strategies | `lib/features/strategy/data/tables.dart` | StrategyService, AppDatabase (migration) | StrategyTab, StrategyDetailPage, RecommendationTab | SF001–SF009 |
| StrategyHitRecords | `lib/features/strategy/data/tables.dart` | StrategyService (推荐记录 + 回填) | StrategyDetailPage (统计), StrategyService (复盘) | SF004, SF006, SF007, SF008 |
| StrategyReviews | `lib/features/strategy/data/tables.dart` | StrategyService (复盘保存) | StrategyDetailPage (历史复盘) | SF007 |

### 数据库迁移

| 迁移路径 | Schema 版本 | 变更内容 | 实现位置 |
|---------|-----------|---------|---------|
| v1 → v2 | 1 → 2 | 新增 Strategies + StrategyHitRecords + StrategyReviews 表，自动插入默认策略 | `lib/features/strategy/data/database.dart` (`onUpgrade`) |

---

## 路由映射

| 路由 | 页面 | 版本 | 实现位置 |
|------|------|------|---------|
| /recommend | 推荐 Tab（改造：按策略分组） | v2.0 | `lib/features/recommendation/presentation/recommendation_tab.dart` |
| /watchlist | 关注 Tab | v1.0 | `lib/features/watchlist/presentation/watchlist_tab.dart` |
| /strategies | 策略列表 Tab | v2.0 新增 | `lib/features/strategy/presentation/strategy_tab.dart` |
| /stock/:code | 股票详情页 | v1.0 | `lib/features/stock/presentation/stock_detail_page.dart` |
| /strategy/:id | 策略详情页 | v2.0 新增 | `lib/features/strategy/presentation/strategy_detail_page.dart` |
| /strategy/new | 创建策略 | v2.0 新增 | `lib/features/strategy/presentation/strategy_edit_page.dart` |
| /strategy/:id/edit | 编辑策略 | v2.0 新增 | `lib/features/strategy/presentation/strategy_edit_page.dart` |

路由配置：`lib/app.dart` (`AppRouter.router`)
