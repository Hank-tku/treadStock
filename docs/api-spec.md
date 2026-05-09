# API 规范 -- 股势 TrendStock 外部数据源接口 v1.0

版本：v1.0 | 日期：2026-04-10 | 架构：纯 Flutter 客户端（无自有后端）

---

## 说明

股势 TrendStock 为纯客户端架构，所有数据通过客户端直接调用公开金融 API 获取。
本规范定义了客户端调用的外部 API 接口契约，以及 Dart 本地 Service 层的接口定义。

### Authentication / Permission / Auth Requirements

所有外部 API 均为公开接口，**无需认证**。客户端直接发送 HTTP GET 请求即可获取数据。
- 无 API Key / Token（东方财富搜索接口使用固定公开 Token）
- 无用户认证体系（纯客户端，无后端，no authentication required）
- 请求头携带标准 User-Agent 和 Referer（模拟浏览器访问，避免被拒绝）

### Request Schema / Params / Query / Body

所有请求遵循以下规范：
- **Method**：仅 GET（只读数据）
- **Request Body**：无（no request body）
- **Query Params**：每个端点的 query 参数见下方端点详情
- **Content-Type**：无请求体（N/A）
- **Accept**：`application/json`
- **User-Agent**：标准浏览器 User-Agent 字符串
- **Timeout**：连接 10s，接收 10s
- **Retry**：失败后最多自动重试 1 次，间隔 30s

---

## 端点总览 -- 外部 API（客户端直接调用）

| Method | URL | 数据源 | 用途 | 认证 | 频率限制 |
|--------|-----|--------|------|------|---------|
| GET | `https://push2.eastmoney.com/api/qt/clist/get` | 东方财富 | 全市场实时行情快照 | 无（公开接口） | IP 级别，实测约 10次/秒 |
| GET | `https://push2his.eastmoney.com/api/qt/stock/kline/get` | 东方财富 | 个股日K线数据 | 无 | IP 级别 |
| GET | `https://searchapi.eastmoney.com/api/suggest/get` | 东方财富 | 股票搜索（代码/名称） | 无 | IP 级别 |
| GET | `https://push2.eastmoney.com/api/qt/slist/get` | 东方财富 | 板块行情 | 无 | IP 级别 |
| GET | `https://finance.sina.com.cn/realstock/company/{code}/nc.shtml` | 新浪财经 | 备用行情数据源 | 无 | IP 级别 |

## 统一错误处理

所有外部 API 调用通过 Dio HTTP 客户端统一拦截，错误码映射如下：

| HTTP 状态码 | 含义 | 客户端处理行为 | 用户可见提示 |
|------------|------|-------------|------------|
| 400 | 请求参数错误 | 不重试，记录日志 | Toast「请求参数错误」 |
| 403 | API 访问受限（IP/频率） | 切换备用数据源 | Toast「数据访问受限，请稍后重试」 |
| 404 | 资源不存在 | 使用本地缓存 | 静默处理 |
| 429 | 请求频率超限 | 暂停 60s 后自动重试 | Toast「请求过于频繁，{N}秒后重试」 |
| 500 | 服务器内部错误 | 使用缓存，30s 后重试 1 次 | 缓存 Banner「数据更新失败，显示缓存数据」 |
| 502/503/504 | 服务不可用 | 使用缓存，等待用户下拉刷新 | 缓存 Banner「数据服务暂不可用」 |

网络层错误处理：

| 错误类型 | 触发条件 | 客户端处理行为 | 用户可见提示 |
|---------|---------|-------------|------------|
| SocketException | 设备无网络连接 | 切换离线模式，使用 SQLite 缓存 | 离线 Banner「离线模式，数据更新于 {时间}」 |
| TimeoutException | 请求超过 10s | 取消请求，使用缓存 | 缓存 Banner「请求超时，显示缓存数据」 |
| DioException | 连接被拒绝 | 使用缓存，标记 API 不可用 | Toast「无法连接数据服务」 |

---

## 端点详情

### 1. 全市场实时行情快照

```
GET https://push2.eastmoney.com/api/qt/clist/get
```

**用途**：获取所有 A 股股票的实时行情数据（价格、涨跌幅、成交量等），用于推荐列表展示。

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| pn | int | 是 | 页码（从 1 开始） |
| pz | int | 是 | 每页数量（全量拉取取 5000） |
| po | int | 是 | 排序方向（1=升序） |
| np | int | 是 | 是否新格式（1） |
| fltt | int | 是 | 浮点格式（2=保留2位小数） |
| invt | int | 是 | 反向标志（2） |
| fid | string | 是 | 排序字段（f3=涨跌幅） |
| fs | string | 是 | 筛选条件（市场+板块） |
| fields | string | 是 | 返回字段列表 |

**完整请求示例**：
```
GET https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=5000&po=1&np=1&fltt=2&invt=2&fid=f3&fs=m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23&fields=f2,f3,f4,f5,f6,f7,f8,f12,f14,f15,f16,f17,f18
```

**返回字段映射**：

| 字段 | 含义 | 示例 |
|------|------|------|
| f2 | 最新价 | 45.20 |
| f3 | 涨跌幅(%) | 2.35 |
| f4 | 涨跌额 | 1.05 |
| f5 | 成交量(手) | 125400 |
| f6 | 成交额 | 5678000000 |
| f7 | 振幅(%) | 2.85 |
| f8 | 换手率(%) | 1.23 |
| f12 | 股票代码 | 601318 |
| f14 | 股票名称 | 中国平安 |
| f15 | 最高价 | 45.80 |
| f16 | 最低价 | 44.50 |
| f17 | 开盘价 | 44.80 |
| f18 | 昨收价 | 44.15 |

**成功响应**：200 `{ data: { total: 5000, diff: [...] } }`

**缓存策略**：写入 SQLite `daily_quote_cache` 表，交易日内 5 分钟过期。

---

### 2. 个股日K线数据

```
GET https://push2his.eastmoney.com/api/qt/stock/kline/get
```

**用途**：获取个股历史日K线数据，用于计算均线（MA20/MA60）、布林带、波段分析。

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| secid | string | 是 | 证券ID（1.{上海代码} / 0.{深圳代码}） |
| fields1 | string | 是 | 基础字段（f1,f2,f3,f4,f5,f6） |
| fields2 | string | 是 | K线字段（f51,f52,f53,f54,f55,f56,f57） |
| klt | int | 是 | K线类型（101=日K线） |
| fqt | int | 是 | 复权类型（1=前复权） |
| beg | string | 是 | 开始日期（YYYYMMDD） |
| end | string | 是 | 结束日期（YYYYMMDD） |
| lmt | int | 是 | 返回条数（默认 120） |

**完整请求示例**：
```
GET https://push2his.eastmoney.com/api/qt/stock/kline/get?secid=1.601318&fields1=f1,f2,f3,f4,f5,f6&fields2=f51,f52,f53,f54,f55,f56,f57&klt=101&fqt=1&beg=20250101&end=20260410&lmt=120
```

**返回字段映射**（klines 数组每条格式）：

| 字段 | 含义 | 示例 |
|------|------|------|
| f51 | 日期 | 2026-04-10 |
| f52 | 开盘价 | 44.80 |
| f53 | 收盘价 | 45.20 |
| f54 | 最高价 | 45.80 |
| f55 | 最低价 | 44.50 |
| f56 | 成交量 | 125400 |
| f57 | 成交额 | 5678000000 |

**secid 市场映射**：
- 上海主板 (SH)：`1.{code}`（如 1.601318）
- 深圳主板 (SZ)：`0.{code}`（如 0.000001）
- 创业板：`0.{code}`（如 0.300750）

**成功响应**：200 `{ data: { code: "601318", name: "中国平安", klines: ["2026-04-10,44.80,45.20,45.80,44.50,125400,5678000000", ...] } }`

**缓存策略**：写入 SQLite `daily_quote_cache` 表，保留最近 250 个交易日。

---

### 3. 股票搜索

```
GET https://searchapi.eastmoney.com/api/suggest/get
```

**用途**：搜索股票（代码或名称模糊匹配），用于关注列表添加功能。

**请求参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| input | string | 是 | 搜索关键词（代码或名称） |
| type | string | 是 | 搜索类型（14=股票） |
| token | string | 是 | API Token（公开固定值） |

**完整请求示例**：
```
GET https://searchapi.eastmoney.com/api/suggest/get?input=平安&type=14&token=D43BF722C8E33BDC906FB84D85E326E8
```

**成功响应**：200，返回匹配股票列表（名称、代码、市场），最多 10 条。

**缓存策略**：搜索结果写入 SQLite `stock_info_cache` 表。

---

## 本地 Service 层接口（Dart）

以下为 Dart Service 层的接口定义，供 UI 层 (Riverpod Provider) 调用。

### StockApiService -- 外部数据获取

```dart
abstract class StockApiService {
  /// 获取全市场实时行情快照
  Future<List<StockQuote>> fetchAllMarketQuotes();

  /// 获取个股日K线数据（最近 N 天）
  Future<List<DailyKline>> fetchStockKline(String stockCode, {int days = 120});

  /// 搜索股票（代码或名称模糊匹配）
  Future<List<StockSearchResult>> searchStock(String keyword);

  /// 获取个股新闻列表
  Future<List<StockNews>> fetchStockNews(String stockCode, {int page = 1, int pageSize = 10});
}
```

### AnalysisEngine -- 波段分析与评分

```dart
abstract class AnalysisEngine {
  /// 计算均线序列
  List<double> calculateMA(List<double> closes, int period);

  /// 计算布林带
  BollingerBands calculateBollinger(List<double> closes, {int period = 20, double stdDev = 2.0});

  /// 计算评分 (1-10)
  StockScore calculateScore(List<DailyKline> klines);

  /// 判断是否处于波段低位
  bool isBandLow(List<DailyKline> klines);

  /// 生成每日跟踪摘要
  DailySummary generateSummary(List<DailyKline> klines);

  /// 检测下跌预警条件
  bool checkDownsideAlert(List<DailyKline> klines);

  /// 批量计算全市场推荐
  Future<List<DailyRecommendation>> calculateDailyRecommendations(List<StockQuote> allQuotes);
}
```

### WatchlistService -- 关注列表管理

```dart
abstract class WatchlistService {
  Future<List<WatchlistItem>> getWatchlist();
  Future<void> addToWatchlist(String stockCode, String stockName, String market);
  Future<void> removeFromWatchlist(String id);
  Future<void> togglePin(String id, bool isPinned);
  Future<void> toggleAlert(String id, bool enabled);
  Future<bool> isWatched(String stockCode);
}
```

### NewsService -- 新闻服务

```dart
abstract class NewsService {
  Future<List<StockNews>> getNews(String stockCode, {bool forceRefresh = false});
  Future<void> clearExpiredNews();
}
```

---

## 数据模型定义

### StockQuote（实时行情快照）
```dart
class StockQuote {
  final String code;      // "601318"
  final String name;      // "中国平安"
  final String market;    // "SH" / "SZ"
  final double price;     // 45.20
  final double changePct; // 2.35 (%)
  final double changeAmt; // 1.05
  final double openPrice; // 44.80
  final double highPrice; // 45.80
  final double lowPrice;  // 44.50
  final double preClose;  // 44.15
  final double volume;    // 125400 (手)
  final double turnover;  // 1.23 (%)
}
```

### DailyKline（日K线）
```dart
class DailyKline {
  final DateTime date;
  final double open;
  final double close;
  final double high;
  final double low;
  final double volume;
  final double amount;
}
```

### StockScore（评分结果）
```dart
class StockScore {
  final int score;           // 1-10
  final double maScore;      // 均线评分 0-10
  final double bollScore;    // 布林带评分 0-10
  final double volScore;     // 量比评分 0-10
  final double trendScore;   // 趋势评分 0-10
  final bool isBandLow;      // 是否波段低位
  final String? reason;      // 评分依据文字
}
```

### DailyRecommendation（每日推荐）
```dart
class DailyRecommendation {
  final String code;
  final String name;
  final String market;
  final String category;     // "short_term" / "mid_term"
  final double closePrice;
  final double changePct;
  final StockScore? score;
}
```

### WatchlistItem（关注列表项）
```dart
class WatchlistItem {
  final String id;           // UUID
  final String stockCode;
  final String stockName;
  final String market;
  final bool isPinned;
  final int sortOrder;
  final bool alertEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### StockNews（新闻条目）
```dart
class StockNews {
  final String id;
  final String stockCode;
  final String title;
  final String source;
  final String sourceUrl;
  final DateTime publishedAt;
  final DateTime fetchedAt;
}
```

---

## 评分算法规范

### 评分公式

```
score = round(w1 * ma_score + w2 * boll_score + w3 * vol_score + w4 * trend_score)

默认权重: w1=0.30, w2=0.30, w3=0.20, w4=0.20
```

### 各子评分规则

**ma_score（均线评分 0-10）**：
- MA20 > MA60 且价格在 MA20 上方：8-10
- 价格在 MA20 下方但接近 MA20（偏离 < 3%）：6-8（波段低位候选）
- MA20 < MA60（空头排列）：2-5

**boll_score（布林带评分 0-10）**：
- 价格 <= 布林带下轨：8-10（波段低位）
- 价格在中轨附近（偏离中轨 < 5%）：5-7
- 价格 >= 布林带上轨：1-4（波段高位）

**vol_score（量比评分 0-10）**：
- 缩量企稳（量比 < 0.8 且跌幅收窄）：7-9
- 放量上涨（量比 > 1.5 且涨幅 > 2%）：7-9
- 放量下跌（量比 > 1.5 且跌幅 > 2%）：1-3
- 其他：4-6

**trend_score（趋势评分 0-10）**：
- 连跌 3-5 天后企稳：7-9（超跌反弹预期）
- 连涨 5 天以上：2-4（回调风险）
- 震荡 3 天以内：5-6

### 波段低谷判定
```
isBandLow = (boll_score >= 7) AND (ma_score >= 6 OR trend_score >= 7)
```

### 下跌预警条件（任一触发）
- 收盘价跌破 MA20 且当日跌幅 > 2%
- 收盘价跌破布林带下轨
- 连续 3 天下跌且第 3 天放量（量比 > 1.3）

### 推荐分类
- 短线波段：score >= 7 且 isBandLow == true（适合 3-5 天短线操作）
- 中线波段：score >= 5 且 ma_score >= 5（适合 10-30 天中线操作）

---

## SQLite 数据库表

| 表名 | 主键 | 用途 | 保留策略 |
|------|------|------|---------|
| watchlist_items | id (UUID) | 用户关注列表 | 永久（用户手动管理） |
| stock_info_cache | stock_code | 股票基础信息 | 永久 |
| daily_quote_cache | stock_code + date | 日线行情 + 技术指标 | 关注股 250 天，其他 30 天 |
| daily_recommendation_cache | date + stock_code | 每日推荐结果 | 最近 30 天 |
| news_cache | id (URL hash) | 个股新闻 | 每只股票最近 50 条 |
| user_scores | id (UUID) | 评分记录 | 永久 |
| daily_summaries | stock_code + date | 每日跟踪摘要 | 最近 90 天 |
