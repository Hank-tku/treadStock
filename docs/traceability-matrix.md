# 需求追溯矩阵
生成时间：2026-04-10 | 版本：基于 PRD v1.0
架构：纯 Flutter 客户端（无后端）

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

## 状态说明
- 待实现: 尚未开始编码
- 实现中（FE/BE 更新）: 正在编码
- 已实现（Reviewer 验证）: 代码完成，Review 通过
- 已测试（QA 验证）: 测试通过
- 未通过（见 code-review.md）: Review 或测试失败

## Must 功能覆盖统计
- 总 Must 功能：4 个（F001, F002, F003, F004）
- Must Gherkin Scenario 总数：15 个（F003-5 因无登录体系跳过，实际 14 个）
- 预期实现路径已填写：15/15
- 覆盖率：100%

## Should 功能覆盖统计
- 总 Should 功能：2 个（F005, F006）
- Should Gherkin Scenario 总数：5 个
- 预期实现路径已填写：5/5
- 覆盖率：100%

## 关键共享组件映射

| 共享组件 | 路径 | 被以下功能使用 |
|---------|------|--------------|
| StockListItem | `lib/shared/widgets/stock_list_item.dart` | F001, F002 |
| ScoreBadge | `lib/shared/widgets/score_badge.dart` | F001, F002, F003, F004 |
| SkeletonLoader | `lib/shared/widgets/skeleton_loader.dart` | F001, F002, F003 |
| ErrorRetry | 内嵌于各页面 | F001, F003 |
| DisclaimLabel | `lib/shared/widgets/disclaimer_label.dart` | F001, F002, F003, F004 |
| EmptyState | `lib/shared/widgets/empty_state.dart` | F001, F002 |
| CacheBanner | `lib/shared/widgets/cache_banner.dart` | F001 |
| ToastHelper | `lib/shared/widgets/toast_helper.dart` | F001, F002, F003 |
| BandLowTag | `lib/shared/widgets/band_low_tag.dart` | F001 |

## 关键 Service/Provider 映射

| Service | 路径 | 职责 |
|---------|------|------|
| StockApiService | `lib/features/stock/data/stock_api_service.dart` | HTTP 请求东方财富/新浪 API |
| AnalysisEngine | `lib/features/analysis/domain/analysis_engine.dart` | MA/Bollinger/评分计算 |
| WatchlistService | `lib/features/watchlist/data/watchlist_service.dart` | 关注列表 CRUD |
| RecommendationProvider | `lib/features/recommendation/presentation/recommendation_provider.dart` | 推荐列表状态管理 |
| WatchlistProvider | `lib/features/watchlist/presentation/watchlist_provider.dart` | 关注列表状态管理 |

## 数据库表映射

| Drift Table | 路径 | 写入方 | 读取方 |
|------------|------|--------|--------|
| WatchlistItems | `lib/features/watchlist/data/watchlist_service.dart` (v1 内存实现) | WatchlistService | WatchlistTab, SearchSheet |
| StockInfoCache | 待 Drift 数据库实现 | StockApiService | StockDetailPage |
| DailyQuoteCache | 待 Drift 数据库实现 | StockApiService | AnalysisEngine, RecommendationTab |
| DailyRecommendationCache | 待 Drift 数据库实现 | AnalysisEngine | RecommendationTab |
| NewsCache | 待 Drift 数据库实现 | NewsService | StockDetailPage |
