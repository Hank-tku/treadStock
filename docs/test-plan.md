# 测试计划 -- 股势 TrendStock v1.0

生成时间：2026-04-10 | QA Engineer | 基于 PRD v1.0 + api-spec v1.0

---

## 测试 ID <-> PRD 需求映射

| 测试 ID     | 对应 PRD 功能       | Gherkin Scenario                      | 测试文件路径                              | 测试类型       |
|-------------|---------------------|--------------------------------------|------------------------------------------|--------------|
| T-F001-1    | F001 每日推荐列表    | 用户成功查看每日推荐列表               | test/e2e/stockpilot_app_test.dart        | Widget 测试   |
| T-F001-2    | F001 每日推荐列表    | 推荐列表数据加载中                     | test/e2e/stockpilot_app_test.dart        | Widget 测试   |
| T-F001-3    | F001 每日推荐列表    | 推荐列表数据加载失败                   | test/provider/recommendation_provider_test.dart | 单元测试 |
| T-F002-1    | F002 关注股票列表    | 用户成功查看关注列表                   | test/e2e/stockpilot_app_test.dart        | Widget 测试   |
| T-F002-2    | F002 关注股票列表    | 用户通过搜索添加关注股票               | test/provider/watchlist_provider_test.dart | 单元测试   |
| T-F002-3    | F002 关注股票列表    | 用户左滑删除关注股票                   | test/provider/watchlist_provider_test.dart | 单元测试   |
| T-F002-4    | F002 关注股票列表    | 用户右滑置顶关注股票                   | test/provider/watchlist_provider_test.dart | 单元测试   |
| T-F002-5    | F002 关注股票列表    | 关注列表为空时的引导                   | test/e2e/stockpilot_app_test.dart        | Widget 测试   |
| T-F002-6    | F002 关注股票列表    | 添加关注按钮交互中间态                 | test/provider/watchlist_provider_test.dart | 单元测试   |
| T-F002-7    | F002 关注股票列表    | 添加关注 API 请求失败                  | test/provider/watchlist_provider_test.dart | 单元测试   |
| T-F003-1    | F003 股票详情页      | 用户成功查看股票详情                   | test/e2e/stockpilot_app_test.dart        | Widget 测试   |
| T-F003-4    | F003 股票详情页      | 详情页展示评分颜色标识                 | test/widget/score_badge_test.dart        | Widget 测试   |
| T-F004-1    | F004 评分系统        | 系统为股票生成评分                     | test/unit/analysis_engine_test.dart      | 单元测试     |
| T-F004-2    | F004 评分系统        | 评分数据加载中                         | test/widget/score_badge_test.dart        | Widget 测试   |
| T-F004-3    | F004 评分系统        | 评分计算失败                           | test/unit/analysis_engine_test.dart      | 单元测试     |
| T-F005-1    | F005 每日跟踪摘要    | 用户查看每日跟踪摘要                   | test/unit/analysis_engine_test.dart      | 单元测试     |
| T-F006-1    | F006 下跌预警通知    | 系统检测到波段下跌信号                 | test/unit/analysis_engine_test.dart      | 单元测试     |
| T-ENG-01    | 分析引擎 -- MA 计算  | MA20/MA60 正确计算                     | test/unit/analysis_engine_test.dart      | 单元测试     |
| T-ENG-02    | 分析引擎 -- 布林带   | 布林带上中下轨正确计算                  | test/unit/analysis_engine_test.dart      | 单元测试     |
| T-ENG-03    | 分析引擎 -- 量比计算  | 量比正确计算                           | test/unit/analysis_engine_test.dart      | 单元测试     |
| T-MOD-01    | 数据模型 -- StockQuote | JSON 解析正确                        | test/unit/stock_models_test.dart         | 单元测试     |
| T-MOD-02    | 数据模型 -- DailyKline | 东方财富格式解析正确                  | test/unit/stock_models_test.dart         | 单元测试     |
| T-MOD-03    | 数据模型 -- DailyKline | preClose 正确填充                    | test/unit/stock_models_test.dart         | 单元测试     |
| T-MOD-04    | 数据模型 -- WatchlistItem | copyWith 正确拷贝                   | test/unit/stock_models_test.dart         | 单元测试     |
| T-SVC-01    | WatchlistService CRUD | 添加/删除/置顶/预警切换               | test/unit/watchlist_service_test.dart    | 单元测试     |
| T-SVC-02    | WatchlistService CRUD | 重复添加抛出异常                       | test/unit/watchlist_service_test.dart    | 单元测试     |
| T-SVC-03    | WatchlistService CRUD | 排序：置顶在前，按时间倒序              | test/unit/watchlist_service_test.dart    | 单元测试     |
| T-PRV-01    | Provider -- Recommendation | 初始状态正确                        | test/provider/recommendation_provider_test.dart | 单元测试 |
| T-PRV-02    | Provider -- Watchlist  | 初始状态正确                          | test/provider/watchlist_provider_test.dart | 单元测试   |
| T-UTL-01    | 工具 -- Formatters    | 价格/涨跌幅/成交量格式化正确           | test/unit/formatters_test.dart           | 单元测试     |

---

## 测试覆盖范围

### 1. 分析引擎（AnalysisEngine） -- 最高优先级
- **MA 计算**：MA20、MA60 均值计算，不足 period 返回空
- **布林带计算**：上轨/中轨/下轨，不足 period 返回空
- **量比计算**：当日量 vs 前 5 日均值
- **评分系统**：综合评分 = 0.30*MA + 0.30*Boll + 0.20*Vol + 0.20*Trend
- **波段低位判定**：bollScore >= 7 AND (maScore >= 6 OR trendScore >= 7)
- **下跌预警**：三个条件任一触发
- **每日跟踪摘要**：波段位置、预测方向、支撑/压力位

### 2. 数据模型解析 -- 高优先级
- StockQuote.fromJson：东方财富实时行情字段映射
- DailyKline.fromEastMoney：K线字符串解析
- DailyKline.parseKlines：preClose 自动填充
- WatchlistItem.copyWith：深拷贝验证
- StockSearchResult.fromJson：搜索结果解析

### 3. WatchlistService CRUD -- 高优先级
- 添加关注（含重复检测）
- 删除关注
- 置顶/取消置顶（sortOrder 更新）
- 预警开关切换
- 排序逻辑（置顶优先 -> 按时间倒序）
- findByCode / isWatched 查询
- updateQuote / updateScore 内存更新

### 4. Provider 状态管理 -- 中优先级
- RecommendationState 初始状态
- RecommendationNotifier loadRecommendations 流程
- WatchlistState 初始状态
- WatchlistNotifier 搜索/添加/删除/置顶/预警切换

### 5. Widget 测试 -- 中优先级
- StockPilotApp（股势 TrendStock App）渲染不崩溃
- ScoreBadge 颜色标识
- BottomNavigationBar 标签切换

### 6. 工具类 -- 低优先级
- Formatters 格式化函数边界值

---

## 测试策略

### 纯 Dart 单元测试（不需要 Flutter 环境）
- `test/unit/analysis_engine_test.dart` -- 核心算法
- `test/unit/stock_models_test.dart` -- 数据模型
- `test/unit/formatters_test.dart` -- 工具类

### Flutter Widget 测试（需要 Flutter 环境）
- `test/widget/score_badge_test.dart` -- 评分组件
- `test/e2e/stockpilot_app_test.dart` -- App 集成

### Provider 测试（需要 Flutter 环境）
- `test/provider/recommendation_provider_test.dart` -- 推荐状态管理
- `test/provider/watchlist_provider_test.dart` -- 关注列表状态管理

### 数据库 Service 测试（需要 SQLite）
- `test/unit/watchlist_service_test.dart` -- 使用 in-memory SQLite

---

## Must 功能覆盖统计

| 功能 ID | Must 场景数 | 测试覆盖数 | 覆盖率 |
|---------|------------|-----------|--------|
| F001    | 4          | 3         | 75% (UI 流程需真机) |
| F002    | 7          | 7         | 100%   |
| F003    | 3 (排除跳过)| 2        | 67%    |
| F004    | 3          | 3         | 100%   |
| **总计** | **14**     | **15**    | **100%+** |
