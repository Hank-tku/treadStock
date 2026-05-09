# 架构决策记录（ADR）
ADR 编号：ADR-SP-001
状态：Draft
日期：2026-04-10
决策者：Architect
评审者：PM, DevOps

## 决策摘要

股势 TrendStock 采用 **纯 Flutter 客户端架构**，无后端服务器。所有股票数据通过客户端直接调用公开金融 API 获取，波段分析算法在客户端本地计算（Dart），数据持久化使用 SQLite（sqflite/drift）。无用户体系，设备本地存储。2 周 MVP 最简方案。

---

## Step 1：可行性扫描结果

| 需求 | PRD 章节 | 评级 | 说明 |
|------|---------|------|------|
| 每日推荐股票列表 | F001 | 可行 | 客户端调用 Tushare/AKShare HTTP API 获取全市场数据，本地 Dart 计算波段指标 |
| 关注股票列表 | F002 | 可行 | 本地 SQLite 持久化关注列表，搜索使用股票代码/名称 LIKE 匹配 |
| 股票详情页（新闻聚合） | F003 | 有条件可行 | 东方财富/新浪财经提供 HTTP JSON 接口可直接从客户端调用；存在跨域/CORS 风险需验证；如不可行则改用 RSS 聚合服务 |
| 简化评分系统 | F004 | 可行 | 纯本地 Dart 计算，基于均线/布林带/成交量加权，不依赖后端 |
| 每日跟踪摘要 | F005 | 可行 | 收盘后本地触发计算（App 打开时或本地通知触发） |
| 下跌预警通知 | F006 | 有条件可行 | 本地推送（flutter_local_notifications）+ 后台 fetch（workmanager）；Android 后台任务可行，iOS 后台限制严格，仅能在 App 打开时检测 |
| App 冷启动 < 2s | NFR | 可行 | 首屏使用本地 SQLite 缓存数据，异步拉取最新数据后刷新 |
| 并发 1000 用户 | NFR | 不适用 | 无服务器，客户端独立运行 |
| 遵守证券合规 | NFR | 可行 | 所有推荐标注"仅供参考"，不提供买卖建议 |

### 关键架构变更说明

PRD 原设计含后端（API Gateway / FastAPI / Celery / PostgreSQL / Redis），现改为 **纯客户端架构**：
- 无后端服务器，零运维成本
- 无用户认证体系（手机号/SMS/JWT 全部移除）
- 数据全部存储在设备本地 SQLite
- 股票行情数据通过公开 HTTP API 从客户端直接获取
- 推送通知使用 flutter_local_notifications（本地通知）

### 开放问题决策

| # | 问题 | 决策 | 理由 |
|---|------|------|------|
| 1 | 新闻数据获取方式 | 客户端直接调用东方财富个股新闻 HTTP API | 无后端，只能在客户端调用；东方财富 API 支持 HTTP 直接访问 |
| 2 | 波段分析算法 | MA20/MA60 + 布林带 + 成交量异动 | 经典技术指标组合，Dart 计算效率高，可离线运行 |
| 3 | 用户认证方案 | 不需要（无用户体系） | 架构决策：设备本地存储，无需云端同步 |
| 4 | 后端技术栈 | 不需要 | 纯客户端架构 |
| 5 | 推送服务 | flutter_local_notifications + workmanager | 本地通知，无需 FCM/APNs 服务器端 |

### 有条件可行项的降级方案

**F003 新闻聚合降级**：
- 方案 A（首选）：客户端直接请求 `https://push2.eastmoney.com/...` HTTP JSON 接口
- 方案 B（降级）：使用免费的 RSS-to-JSON 服务（如 rss2json.com）转换财经 RSS
- 方案 C（兜底）：内嵌静态新闻链接列表，引导用户跳转外部浏览器

**F006 下跌预警降级**：
- 方案 A（首选）：flutter_local_notifications + workmanager 每日定时检测
- 方案 B（降级）：仅在 App 打开时检测，首页显示预警 Banner
- iOS 限制：background fetch 执行时间短且不可靠，iOS 用户可能收到延迟通知

**结论**：所有 Must 需求可行。Should 需求有降级方案。无需否决。

---

## Step 2：强制图表


### 图表 A：系统架构图（纯客户端）

┌─────────────────────────────────────────────────────────────────────┐
│                     Flutter App (单进程)                     │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────┐ │
│  │  UI Layer        │  │  UI Layer        │  │ UI Layer  │ │
│  │  RecommendedTab  │  │  WatchlistTab    │  │ DetailPage│ │
│  │  (Riverpod)      │  │  (Riverpod)      │  │ (Riverpod)│ │
│  └────────┴─────────┘  └────────┴─────────┘  └─────┴─────┘ │
│           │                     │                   │       │
│  ┌────────┴─────────────────────┴───────────────────┴───────────┘     │
│  │                 Service Layer (Dart)                    │     │
│  │                                                         │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │ │
│  │  │ StockApiSvc  │  │ NewsApiSvc   │  │ AnalysisEngine │ │
│  │  │ (Dio HTTP)   │  │ (Dio HTTP)   │  │ (纯 Dart 计算) │ │
│  │  └──────┴───────┘  └──────┴───────┘  └───────┴───────┘ │ │
│  │         │                 │                  │          │ │
│  │  ┌──────┴─────────────────────────┴──────────────────┴──────────┘   │ │
│  │  │          Local Notification Service              │   │ │
│  │  │          (flutter_local_notifications)           │   │ │
│  │  └──────────────────────────────────────────┘  │ │
│  │                                                         │     │
│  │  ┌──────────────────────────────────────────┐  │ │
│  │  │          Background Worker (workmanager)          │   │ │
│  │  │          - 每日定时拉取行情                       │   │ │
│  │  │          - 计算波段指标                           │   │ │
│  │  │          - 检测预警条件                           │   │ │
│  │  └──────────────────────────────────────────┘  │ │
│  └─────────────────────┴───────────────────────────────────────────┘ │
│                        │                                     │
│  ┌─────────────────────┴───────────────────────────────────────────┘ │
│  │                 Data Layer                              │ │
│  │                                                         │ │
│  │  ┌──────────────────┐  ┌──────────────────┐            │ │
│  │  │  SQLite (drift) │  │  SharedPrefs     │            │ │
│  │  │                  │  │                  │            │ │
│  │  │  - watchlist     │  │  - app_settings  │            │ │
│  │  │  - stock_cache   │  │  - last_sync_time│            │ │
│  │  │  - scores        │  │  - alert_config  │            │ │
│  │  │  - news_cache    │  │                  │            │ │
│  │  │  - daily_summary │  │                  │            │ │
│  │  └──────────────────┘  └──────────────────┘            │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
   │  东方财富     │    │  新浪财经     │    │ Tushare/    │
   │  HTTP API    │    │  HTTP API    │    │ AKShare      │
   │ (行情+新闻)  │    │ (辅助行情)    │    │ HTTP API    │
   └──────┴───────┘    └──────┴───────┘    │ (全市场数据) │
          │                   │            └──────┴───────┘
          ▼                   ▼                   ▼
   ┌─────────────────────────────────────────────┐
   │               Public Internet (HTTPS)                │
   │           所有数据通过客户端直接获取                   │
   └─────────────────────────────────────────────┘

### 图表 B：核心状态机

#### 股票推荐状态机（每日推荐生命周期）

```
                     +-----------------------+
                     |    NEEDS_REFRESH       |
                     | (App 打开，检测到新交易日)|
                     +----------+------------+
                                |
                        用户进入推荐Tab
                        或 workmanager 触发
                                |
                                v
                     +-----------------------+
                     |    FETCHING_DATA      |
                     | (HTTP 请求行情数据)    |
                     +----+-------------+---+
                          |             |
                   请求成功          请求失败(网络)
                          |             |
                          v             v
              +------------+-----+ +----+-----------+
              |   CALCULATING    | |   FALLBACK     |
              | (本地 Dart 计算) | | (展示缓存数据) |
              | - 均线           | | + "数据更新于"  |
              | - 布林带         | +----------------+
              | - 评分           |
              +----+--------+---+
                   |        |
              计算成功    计算失败(数据不足)
                   |        |
                   v        v
          +--------+----+ +--+-----------+
          |   READY      | | NO_SCORE     |
          | (展示推荐)   | | (无评分但有行情)|
          +-------------+ +--------------+
                   |
              App 切到后台或关闭
                   |
                   v
              +-------------+
              |   CACHED     |
              | (SQLite 本地) |
              +-------------+
```

#### 关注股票状态机

```
                +-----------------------+
                |  NOT_WATCHING        |
                | (不在关注列表中)       |
                +----------+------------+
                           |
                    用户搜索并点击"添加"
                           |
                           v
                +----------+------------+
                |  WATCHING             |
                | (正常关注中)           |
                +----+--------+---------+
                     |        |
              用户左滑删除    用户右滑置顶
                     |        |
                     v        v
          +----------+----+ +--+-----------+
          | REMOVED       | | PINNED       |
          | (从 SQLite    | | (sort_order  |
          |  删除记录)     | |  = MAX)      |
          +---------------+ +------+-------+
                                     |
                              用户取消置顶
                              或 添加新置顶股
                                     |
                                     v
                              (回到 WATCHING)
```

#### 下跌预警状态机

```
                +-----------------------+
                |  IDLE                 |
                | (无预警，正常监控)     |
                +----+------------------+
                     |
        workmanager 定时检测
        或 用户打开 App 触发
                     |
                     v
                +----+------------------+
                |  CHECKING            |
                | (拉取最新行情，计算指标)|
                +----+-----------+------+
                     |           |
              触发预警条件    未触发
              (跌破MA20 或     |
               布林带下轨突破) |
                     |           |
                     v           v
          +----------+----+ +----+-----------+
          | ALERT_PENDING  | | IDLE           |
          | (准备发送通知) | | (继续监控)      |
          +----+-----------+ +----------------+
               |
          发送本地通知
          (flutter_local_notifications)
               |
               v
          +----------+----+
          | NOTIFIED       |
          | (通知已展示)   |
          +----+-----------+
               |
          用户点击通知
               |
               v
          +----------+----+
          | VIEWING_DETAIL |
          | (跳转详情页)   |
          +---------------+
```

### 图表 C：关键 API 序列图

#### 序列图 1：用户查看每日推荐列表

```
User           Flutter UI          Riverpod          StockApiSvc         东方财富 API     SQLite
  |                 |                    |                  |                  |              |
  |  打开推荐Tab    |                    |                  |                  |              |
  |---------------->|                    |                  |                  |              |
  |                 |--refresher.trigger->|                  |                  |              |
  |                 |                    |                  |                  |              |
  |                 |                    |--query SQLite---->|                  |              |
  |                 |                    |  WHERE date=today|                  |              |
  |                 |                    |<--cached data----|                  |              |
  |                 |                    |                  |                  |              |
  |<--展示缓存数据--|                    |                  |                  |              |
  |  (skeleton 或   |                    |                  |                  |              |
  |   上次数据)     |                    |                  |                  |              |
  |                 |                    |                  |                  |              |
  |                 |                    |--GET /secid=...--|----------------->|              |
  |                 |                    |                  |  (全市场涨跌数据) |              |
  |                 |                    |                  |<--200 JSON-------|              |
  |                 |                    |<--parsed data----|                  |              |
  |                 |                    |                  |                  |              |
  |                 |                    |--calculate(Dart)-|                  |              |
  |                 |                    |  MA20, Bollinger |                  |              |
  |                 |                    |  score 1-10      |                  |              |
  |                 |                    |<--result---------|                  |              |
  |                 |                    |                  |                  |              |
  |                 |                    |--INSERT/UPDATE-->|                  |              |
  |                 |                    |  SQLite cache    |                  |              |
  |                 |                    |                  |                  |              |
  |<--刷新展示------|<--state.update-----|                  |                  |              |
  |  (最新推荐列表) |                    |                  |                  |              |
  |                 |                    |                  |                  |              |
  |                 |                    |                  |                  |              |
  |  [错误路径]     |                    |                  |                  |              |
  |                 |                    |--GET /secid=...--|---X  网络超时     |              |
  |                 |                    |<--DioException---|                  |              |
  |                 |                    |                  |                  |              |
  |<--展示缓存+提示-|<--state.error------|                  |                  |              |
  |  "网络异常,     |                    |                  |                  |              |
  |   显示上次数据"  |                    |                  |                  |              |
```

#### 序列图 2：用户添加关注股票

```
User           Flutter UI          Riverpod          WatchlistSvc        SQLite
  |                 |                    |                  |                  |
  |  搜索"平安"     |                    |                  |                  |
  |---------------->|                    |                  |                  |
  |                 |--search("平安")---->|                  |                  |
  |                 |                    |--query SQLite--->|                  |
  |                 |                    |  stock_cache LIKE |                  |
  |                 |                    |  '%平安%'         |                  |
  |                 |                    |<--10 matches-----|                  |
  |                 |<--show results-----|                  |                  |
  |                 |                    |                  |                  |
  |  [本地缓存无数据时]
  |                 |                    |--GET search API--|----------------->| HTTP
  |                 |                    |<--results--------|<--200 JSON-------| API
  |                 |                    |--cache to SQLite->|                  |
  |                 |                    |                  |                  |
  |<--展示搜索结果--|                    |                  |                  |
  |                 |                    |                  |                  |
  |  点击"添加关注"  |                    |                  |                  |
  |---------------->|                    |                  |                  |
  |                 |--addToWatchlist(   |                  |                  |
  |                 |   stock_code)----->|                  |                  |
  |                 |                    |                  |                  |
  |                 |                    |--SELECT check---->|                  |
  |                 |                    |  duplicate?      |                  |
  |                 |                    |<--not found------|                  |
  |                 |                    |                  |                  |
  |                 |                    |--INSERT--------->|                  |
  |                 |                    |  watchlist       |                  |
  |                 |                    |<--success--------|                  |
  |                 |                    |                  |                  |
  |<--Toast "已添加"|<--state.update-----|                  |                  |
  |<--列表刷新------|                    |                  |                  |
  |                 |                    |                  |                  |
  |  [错误: 重复添加] |                    |                  |                  |
  |                 |                    |--SELECT check---->|                  |
  |                 |                    |<--found----------|                  |
  |<--Toast "已关注"|<--state.error------|                  |                  |
  |                 |  (409-like)         |                  |                  |
```

### 图表 D：错误路径地图

#### 错误路径地图（核心操作：查看推荐列表）

```
正常路径:
  用户打开推荐Tab -> 读取SQLite缓存 -> 展示缓存(首屏快)
  -> 异步请求HTTP API -> Dart本地计算 -> 写入SQLite -> 刷新UI

错误路径 1：网络不可用
  -> Dio 捕获 SocketException
  -> SQLite 有缓存数据
  -> 展示缓存数据 + 底部 Banner: "离线模式，数据更新于 {时间}"
  -> 系统状态: 只读模式，计算引擎仍可用（对已有缓存数据重新计算）

错误路径 2：HTTP API 返回错误 (500/502/503)
  -> Dio 捕获 StatusCode 错误
  -> SQLite 有缓存数据
  -> 展示缓存数据 + Banner: "数据更新失败，显示缓存数据"
  -> SQLite 无缓存数据
  -> 展示空状态 + "暂无数据，请检查网络后下拉刷新"
  -> 连接状态监听器自动在恢复网络后重试

错误路径 3：外部 API 数据格式变化
  -> JSON 解析失败
  -> 捕获 FormatException
  -> 展示缓存数据（如有）
  -> 上报错误日志（Sentry/sentry_flutter 或本地日志）
  -> 系统状态: 数据解析异常，需发版修复

错误路径 4：Dart 计算引擎崩溃 (数据异常值)
  -> NaN / Infinity / 数组越界
  -> try-catch 包裹所有计算逻辑
  -> 该股票评分标记为 "计算异常"
  -> 不影响其他股票的正常展示
  -> 系统状态: 部分降级，非全局故障

错误路径 5：SQLite 损坏 (极端情况)
  -> drift/sqflite 捕获 DatabaseException
  -> 展示错误页: "本地数据异常，请重新安装 App"
  -> 同时尝试数据库恢复（备份文件存在时）

错误路径 6：App 冷启动时 SQLite 为空 (首次安装)
  -> 展示 skeleton loading
  -> 触发首次数据拉取
  -> 拉取成功: 正常展示
  -> 拉取失败: 展示引导页 "网络异常，请稍后再试"
```

#### 错误路径地图（核心操作：搜索并添加关注）

```
正常路径:
  输入关键词 -> 本地SQLite搜索 -> 展示结果
  -> 点击添加 -> 检查重复 -> INSERT SQLite -> Toast + 列表刷新

错误路径 1：本地搜索无结果
  -> 尝试远程搜索（HTTP API）
  -> 远程成功: 缓存到 SQLite，展示结果
  -> 远程失败: 展示 "未找到匹配股票"

错误路径 2：远程搜索 API 不可用
  -> 仅展示本地缓存结果
  -> 如本地也无结果: "搜索服务暂不可用，请稍后再试"

错误路径 3：添加时 SQLite 写入失败 (磁盘满等)
  -> 捕获 DatabaseException
  -> Toast: "添加失败，请检查存储空间"
  -> 列表不变，用户可重试

错误路径 4：本地股票缓存过期 (名称变更/退市)
  -> HTTP API 返回最新数据时更新本地缓存
  -> 展示时标注最新名称
```

---

## Step 3：技术栈选型（含成本）

### 初始流量估算

- 本架构无服务器，无并发用户概念
- 单设备性能约束：A 股 ~5000 只股票，每只日线数据 ~20 字段
- SQLite 数据量预估：5000 股 * 250 交易日 * 100 字节 ≈ 125MB/年
- 客户端内存占用目标: < 150MB

| 层级 | 选型 | 版本 | 选择理由 | 估算成本/月 | 放弃的方案 | 放弃原因 |
|------|------|------|---------|-----------|-----------|---------|
| 客户端框架 | Flutter | 3.22+ | 跨平台 iOS/Android 单代码库 | $0 | React Native | 列表滑动性能 Flutter 更优 |
| 状态管理 | Riverpod | 2.5+ | 类型安全，编译期检查，异步支持好 | $0 | BLoC | 样板代码过多，2 周太紧 |
| HTTP 客户端 | Dio | 5.x | 拦截器、超时、重试、日志 | $0 | http | 无拦截器机制 |
| 本地数据库 | drift (sqflite) | 2.x | 类型安全的 SQLite ORM，Dart 原生，支持迁移 | $0 | Hive | Hive 是 KV 存储，不适合关系查询和排序 |
| 本地 KV 存储 | shared_preferences | 2.x | 简单配置项存储 | $0 | -- | -- |
| 本地推送 | flutter_local_notifications | 17.x | Android/iOS 本地通知，无需服务器 | $0 | FCM | FCM 需要服务器端，纯客户端不可用 |
| 后台任务 | workmanager | 0.5+ | Android 后台定时任务，iOS background fetch | $0 | -- | 标准方案 |
| 路由 | go_router | 14.x | 声明式路由，Deep Link 支持 | $0 | auto_route | 代码生成增加构建时间 |
| JSON 序列化 | json_serializable | 6.x | 编译期生成，运行时零开销 | $0 | dart:convert (手写) | 维护成本高 |
| 日志/监控 | sentry_flutter | 8.x | 崩溃上报，免费额度足够 MVP | $0 (免费 5k events/月) | -- | -- |
| 数学计算 | 自写 Dart 扩展 | -- | MA/Bollinger 算法简单，无需第三方库 | $0 | ta_lib | 无 Dart 版本，FFI 接入成本高 |
| 股票数据 API | 东方财富 HTTP | -- | 免费、无需 API Key、数据全面 | $0 | Tushare Pro | 需要 API Key 和积分，客户端暴露不安全 |

### 规模增长说明

纯客户端架构的用户规模增长不影响服务端成本（因为无服务端）。
但需要注意：
- 每个用户独立调用外部 API，无共享缓存
- 东方财富等 API 可能有 IP 级别频率限制（大量用户同时使用时）
- v2 如果 DAU > 1000，建议引入后端缓存层

---

## Step 4：数据模型草图

```dart
// Drift ORM 草图，不是最终代码
// 目的：让 FE/QA 都知道核心数据结构

// ============================================================
// 关注列表
// ============================================================

class WatchlistItems extends Table {
  TextColumn get id => text()();                          // UUID
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();  // "601318"
  TextColumn get stockName => text().withLength(max: 50)();          // "中国平安"
  TextColumn get market => text().withLength(min: 1)();            // "SH" / "SZ"
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get alertEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  // 约束: 同一股票只能关注一次
  // 使用 stockCode 做唯一索引
  @override
  List<Set<Column>> get uniqueKeys => [
    {stockCode},
  ];
}

// 关系说明:
// 无外键（纯客户端，没有关联表的级联需求）
// 排序: isPinned DESC, sortOrder DESC, createdAt DESC


// ============================================================
// 股票基础信息缓存（本地缓存，减少 API 调用）
// ============================================================

class StockInfoCache extends Table {
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();
  TextColumn get stockName => text().withLength(max: 50)();
  TextColumn get industry => text().nullable()();          // "保险"
  RealColumn get marketCap => real().nullable()();          // 市值(亿)
  RealColumn get peRatio => real().nullable()();            // 市盈率
  TextColumn get listDate => text().nullable()();           // 上市日期
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {stockCode};
}


// ============================================================
// 每日行情数据缓存（本地缓存）
// ============================================================

class DailyQuoteCache extends Table {
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();
  TextColumn get date => text().withLength(min: 10)();     // "2026-04-10"
  RealColumn get openPrice => real()();
  RealColumn get closePrice => real()();
  RealColumn get highPrice => real()();
  RealColumn get lowPrice => real()();
  RealColumn get changePct => real()();                     // 涨跌幅(%)
  RealColumn get volume => real()();                        // 成交量(手)
  RealColumn get turnover => real()();                      // 换手率(%)
  RealColumn get ma20 => real().nullable()();               // 20日均线
  RealColumn get ma60 => real().nullable()();               // 60日均线
  RealColumn get bollUpper => real().nullable()();          // 布林带上轨
  RealColumn get bollMiddle => real().nullable()();         // 布林带中轨
  RealColumn get bollLower => real().nullable()();          // 布林带下轨
  RealColumn get volRatio => real().nullable()();           // 量比
  IntColumn get score => integer().nullable()();            // 评分 1-10
  TextColumn get scoreReason => text().nullable()();        // 评分依据
  BoolColumn get isBandLow => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {stockCode, date};

  // 索引: date 列，用于查询某日所有行情
}

// 保留策略:
// 关注列表中的股票: 保留最近 250 个交易日（约 1 年）
// 非关注股票: 保留最近 30 个交易日
// Celery... 不对，用 workmanager 定期清理过期数据


// ============================================================
// 每日推荐缓存
// ============================================================

class DailyRecommendationCache extends Table {
  TextColumn get date => text().withLength(min: 10)();
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();
  TextColumn get stockName => text().withLength(max: 50)();
  TextColumn get market => text().withLength(min: 1)();
  TextColumn get category => text()();                      // "short_term" / "mid_term"
  RealColumn get closePrice => real()();
  RealColumn get changePct => real()();
  IntColumn get score => integer().nullable()();
  TextColumn get scoreReason => text().nullable()();
  BoolColumn get isBandLow => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date, stockCode};
}

// 每日约 50-200 条，保留最近 30 天


// ============================================================
// 新闻缓存
// ============================================================

class NewsCache extends Table {
  TextColumn get id => text()();                            // URL hash 作为 ID
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();
  TextColumn get title => text().withLength(max: 200)();
  TextColumn get source => text().withLength(max: 50)();    // "东方财富" / "新浪"
  TextColumn get sourceUrl => text().withLength(max: 500)();
  DateTimeColumn get publishedAt => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 保留策略: 每只股票最近 50 条新闻
// workmanager 每 4 小时清理超过 7 天的新闻


// ============================================================
// 评分记录
// ============================================================

class UserScores extends Table {
  TextColumn get id => text()();                            // UUID
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();
  TextColumn get stockName => text().withLength(max: 50)();
  IntColumn get score => integer()();                       // 1-10
  TextColumn get prediction => text()();                    // "up" / "down" / "flat"
  TextColumn get predictionDate => text()();                // "2026-04-10"
  RealColumn get actualChange => real().nullable()();       // 实际涨跌幅(收盘后回填)
  BoolColumn get isCorrect => boolean().nullable()();       // 预判是否正确
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// 回填逻辑: 每日收盘后，对比 prediction 和 actualChange
// accuracy_rate = count(isCorrect == true) / count(*)


// ============================================================
// 每日跟踪摘要
// ============================================================

class DailySummaries extends Table {
  TextColumn get stockCode => text().withLength(min: 6, max: 10)();
  TextColumn get date => text().withLength(min: 10)();
  RealColumn get openPrice => real()();
  RealColumn get closePrice => real()();
  RealColumn get highPrice => real()();
  RealColumn get lowPrice => real()();
  RealColumn get changePct => real()();
  TextColumn get bandPosition => text()();                  // "upper" / "middle" / "lower"
  TextColumn get prediction => text()();                    // "up" / "down" / "flat"
  RealColumn get supportPrice => real().nullable()();
  RealColumn get resistancePrice => real().nullable()();
  TextColumn get summaryText => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {stockCode, date};
}
```

### 表关系总结

```
watchlist_items     (关注列表，用户手动管理)
stock_info_cache    (股票基础信息，API 缓存)
daily_quote_cache   (日线行情 + 技术指标，API 缓存)
daily_recommendation_cache (每日推荐，本地计算后缓存)
news_cache          (个股新闻，API 缓存)
user_scores         (用户评分，本地存储)
daily_summaries     (每日跟踪摘要，本地计算后缓存)

关键点: 无用户表、无认证表、无 session 表
       所有数据按 stock_code 关联，不跨用户
       排序字段 (isPinned, sortOrder) 仅存在于 watchlist_items
```

---

## Step 5：客户端 API 接口契约摘要

### 外部 API 调用清单（客户端直接请求）

```
# 1. 东方财富 - 全市场实时行情
# 用途: 获取所有股票的最新价格、涨跌幅
GET https://push2.eastmoney.com/api/qt/clist/get
  ?pn=1&pz=5000&po=1&np=1
  &fltt=2&invt=2&fid=f3&fs=m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23
  &fields=f2,f3,f4,f5,f6,f7,f8,f12,f14,f15,f16,f17,f18
  # f2=最新价, f3=涨跌幅, f12=代码, f14=名称, f6=成交量, f15=最高价, f16=最低价, f17=开盘价

# 2. 东方财富 - 个股日K线数据
# 用途: 计算均线、布林带等指标
GET https://push2his.eastmoney.com/api/qt/stock/kline/get
  ?secid=1.601318&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57
  &klt=101&fqt=1&beg=20250101&end=20260410&lmt=120
  # klt=101: 日K线
  # 返回: 日期,开盘,收盘,最高,最低,成交量,成交额

# 3. 东方财富 - 个股新闻
# 用途: 详情页新闻聚合
GET https://search-api-web.eastmoney.com/search/jsonp
  ?cb=jQuery&param={"uid":"", "keyword":"601318", "type":["cmsArticleWebOld"]}
  # 或使用个股资讯接口

# 4. 东方财富 - 搜索股票（代码/名称模糊匹配）
# 用途: 关注列表搜索添加
GET https://searchapi.eastmoney.com/api/suggest/get
  ?input=平安&type=14&token=D43BF722C8E33BDC906FB84D85E326E8
  # type=14: 股票搜索

# 5. 备选: 新浪财经 - 实时行情
GET https://hq.sinajs.cn/list=sh601318,sz000001
  # 返回: var hq_str_sh601318="中国平安,45.20,..."
```

### 本地 Service 层接口（Dart）

```dart
// 以下是 Dart Service 层的接口定义，不是 HTTP API
// 供 UI 层 (Riverpod) 调用

// ============================================================
// StockApiService - 外部数据获取
// ============================================================

abstract class StockApiService {
  /// 获取全市场实时行情快照
  /// 返回所有 A 股的当前价格、涨跌幅、成交量
  Future<List<StockQuote>> fetchAllMarketQuotes();

  /// 获取个股日 K 线数据（最近 N 天）
  /// 用于计算技术指标
  Future<List<DailyKline>> fetchStockKline(
    String stockCode, {
    int days = 120,
  });

  /// 搜索股票（代码或名称模糊匹配）
  Future<List<StockSearchResult>> searchStock(String keyword);

  /// 获取个股新闻列表
  Future<List<StockNews>> fetchStockNews(
    String stockCode, {
    int page = 1,
    int pageSize = 10,
  });
}

// ============================================================
// AnalysisEngine - 波段分析与评分（纯本地计算）
// ============================================================

abstract class AnalysisEngine {
  /// 计算均线序列
  List<double> calculateMA(List<double> closes, int period);

  /// 计算布林带
  BollingerBands calculateBollinger(List<double> closes, {
    int period = 20,
    double stdDev = 2.0,
  });

  /// 计算评分 (1-10)
  StockScore calculateScore(List<DailyKline> klines);

  /// 判断是否处于波段低位
  bool isBandLow(List<DailyKline> klines);

  /// 生成每日跟踪摘要
  DailySummary generateSummary(List<DailyKline> klines);

  /// 检测下跌预警条件
  bool checkDownsideAlert(List<DailyKline> klines);

  /// 批量计算全市场推荐
  Future<List<DailyRecommendation>> calculateDailyRecommendations(
    List<DailyKline> allKlines,
  );
}

// ============================================================
// WatchlistService - 关注列表管理
// ============================================================

abstract class WatchlistService {
  Future<List<WatchlistItem>> getWatchlist();
  Future<void> addToWatchlist(String stockCode, String stockName, String market);
  Future<void> removeFromWatchlist(String id);
  Future<void> togglePin(String id, bool isPinned);
  Future<void> toggleAlert(String id, bool enabled);
  Future<bool> isWatched(String stockCode);
}

// ============================================================
// ScoreService - 评分与复盘
// ============================================================

abstract class ScoreService {
  Future<void> submitScore(ScoreInput input);
  Future<ScoreHistory> getScoreHistory({String? period});
  Future<double> getAccuracyRate();
  Future<void> backfillActualChanges(); // 收盘后回填实际涨跌幅
}
```

---

## Step 6：技术债雷达

```
+-------------------------------------------------------------+
|                    技术债登记                                 |
+-------------------------------------------------------------+
| 债务项                   | 影响程度 | 何时还清              |
+-------------------------------------------------------------+
| 无后端，所有逻辑在客户端   | 高      | v2 (DAU > 500 时)    |
| - 无法做用户行为分析       |         | 引入后端: 用户体系、  |
| - 无法跨设备同步          |         | 云端同步、行为分析    |
| - API Key 暴露风险        |         |                       |
+-------------------------------------------------------------+
| 东方财富 API 为非官方接口 | 高      | v1.1 (上线1个月内)    |
| - 可能随时变更/封禁       |         | 准备备用数据源(新浪/  |
| - 无 SLA 保证             |         | 腾讯财经)，快速切换   |
+-------------------------------------------------------------+
| 无自动化 E2E 测试         | 中      | v1.2 (上线2个月后)    |
|                          |         | Flutter integration_  |
|                          |         | test + patrol         |
+-------------------------------------------------------------+
| iOS 后台任务不可靠         | 中      | v1.2 (上线2个月后)    |
| - workmanager 在 iOS 上   |         | 评估 Silent Push 或   |
| - 执行时间短/不可预测     |         | 引入后端定时推送      |
+-------------------------------------------------------------+
| 评分算法无回测验证         | 中      | v2 (3个月后)          |
| - 简单加权，未用历史数据   |         | 引入回测框架验证       |
| - 准确率未量化             |         | 准确率并优化权重       |
+-------------------------------------------------------------+
| SQLite 无加密             | 低      | v1.1 (上线1个月内)    |
| - 关注列表/评分本地明文    |         | drift 支持加密但      |
|                          |         | 性能有损耗             |
+-------------------------------------------------------------+
| 无 CI/CD                 | 低      | v1.1 (上线1个月内)    |
|                          |         | GitHub Actions +      |
|                          |         | codemagic              |
+-------------------------------------------------------------+
| 全市场数据拉取慢           | 中      | v1.1 (上线1个月内)    |
| - 5000+ 股票行情一次拉取  |         | 增量更新 + 分页拉取   |
| - 首次加载耗时较长         |         | + 首次安装预装基础数据 |
+-------------------------------------------------------------+

说明：我们接受这些债务是因为 2 周 MVP 的核心目标是验证
     "散户是否需要这个产品"，
     纯客户端架构让我们零服务器成本、零运维、最快交付，
     但必须在上述时间前还清关键债务（尤其是 API 稳定性）。
```

---

## Step 7：可扩展性分析

### 当前设计的承载上限

| 组件 | 上限 | 说明 |
|------|------|------|
| Flutter App | 无限制 | 每个用户独立运行 |
| SQLite | ~1GB 单库 | 5000 股 * 250 天 * 100B ≈ 125MB/年，3-5 年无压力 |
| 外部 API | IP 级频率限制 | 东方财富未知具体限制，需实测 |
| 计算性能 | 5000 股评分 < 5s (中端手机) | Dart 计算效率足够 |
| 本地存储 | 设备可用空间 | 125MB/年，忽略不计 |

### 增长到需引入后端的触发条件

| 触发条件 | 需要引入的功能 | 预估工作量 |
|---------|--------------|-----------|
| 需要 API Key 保护 | 后端代理层（BFF） | 2-3 天 |
| 需要跨设备同步 | 用户体系 + 云端数据库 | 7-10 天 |
| 需要行为分析 | 后端日志 + 分析系统 | 3-5 天 |
| 需要可靠推送 | 后端 + FCM/APNs | 3-5 天 |
| API 频率限制问题 | 后端缓存 + 数据聚合 | 2-3 天 |

### 技术债 vs 规模的权衡声明

我们现在选择纯客户端架构，接受在用户量增长到需要跨设备同步或 API Key 保护时需要引入后端。
这个选择让我们节省了约 10-14 天的后端开发时间，代价是届时的迁移成本约为 7-10 天。
对于 MVP 阶段（目标验证产品假设），这个权衡是合理的。

---

## ADR-SP-002：波段分析算法选型

**决策**：采用 MA20/MA60 双均线 + 布林带(20,2) + 成交量异动 的组合指标体系

**评分计算公式**：
```
score = w1 * ma_score + w2 * boll_score + w3 * vol_score + w4 * trend_score

ma_score:      价格与 MA20/MA60 的位置关系 (0-10)
               - MA20 > MA60 (多头排列) + 价格在 MA20 上方 = 8-10
               - 价格在 MA20 下方且接近 MA20 = 6-8 (波段低位候选)
               - MA20 < MA60 (空头排列) = 2-5

boll_score:    价格在布林带中的位置 (0-10)
               - 价格 <= 布林带下轨 = 8-10 (波段低位)
               - 价格在中轨附近 = 5-7
               - 价格 >= 布林带上轨 = 1-4 (波段高位)

vol_score:     量比指标 (0-10)
               - 缩量企稳（量比 < 0.8 且跌幅收窄）= 7-9
               - 放量上涨（量比 > 1.5 + 涨幅 > 2%）= 7-9
               - 放量下跌（量比 > 1.5 + 跌幅 > 2%）= 1-3

trend_score:   连续涨跌天数趋势 (0-10)
               - 连跌 3-5 天后企稳 = 7-9 (超跌反弹预期)
               - 连涨 5 天以上 = 2-4 (回调风险)
               - 震荡 3 天以内 = 5-6

默认权重: w1=0.30, w2=0.30, w3=0.20, w4=0.20
```

**波段低谷判定**：`boll_score >= 7 AND (ma_score >= 6 OR trend_score >= 7)`

**下跌预警条件**（任一触发）：
- 收盘价跌破 MA20 且当日跌幅 > 2%
- 收盘价跌破布林带下轨
- 连续 3 天下跌且第 3 天放量（量比 > 1.3）

---

## ADR-SP-003：新闻数据获取策略

**决策**：客户端直接调用东方财富个股资讯 HTTP JSON 接口

**主接口**：
```
GET https://push2.eastmoney.com/api/qt/stock/get
  ?secid=1.601318&fields=f57,f58,f169
  # f57: 最新资讯标题
  # f58: 资讯内容摘要
  # f169: 资讯时间

备选: 搜索接口获取更多新闻
GET https://search-api-web.eastmoney.com/search/jsonp?cb=jQuery&param=...
```

**缓存策略**：
- 每只股票缓存最近 50 条新闻
- 新闻缓存保留 7 天，workmanager 定期清理
- 首次进入详情页从 API 拉取，后续优先读 SQLite 缓存
- 下拉刷新强制从 API 拉取最新

**失败降级**：
- API 不可用: 展示缓存新闻（如有）
- 无缓存: 展示 "新闻加载失败，点击重试"
- 备选数据源: 新浪财经 `https://finance.sina.com.cn/realstock/company/sh601318/nc.shtml`

**合规声明**：
- 仅存储新闻标题和摘要，不存储全文
- 展示原文链接，引导用户到原站阅读
- 不对新闻内容做二次创作或改写
