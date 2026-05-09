# 安全基线文档
项目：股势 TrendStock | 版本：v1.0 | 日期：2026-04-10
状态：Draft | 决策者：Architect

---

## 1. 认证与授权方案

### 当前状态：无认证

股势 TrendStock v1 采用纯客户端架构，**不包含用户认证体系**。
- 无登录/注册流程
- 无 JWT / OAuth / SMS 验证
- 无用户身份识别

### 安全含义

| 影响面 | 说明 | 风险等级 | 缓解措施 |
|--------|------|---------|---------|
| 数据隔离 | 所有数据存储在同一设备 SQLite 中，无需隔离 | 低 | 单设备无多用户需求 |
| 数据同步 | 无云端同步，数据不会离开设备 | 低 | 天然隔离 |
| API 调用 | 所有 API 调用来自客户端，无法区分用户 | 中 | 东方财富等 API 无需认证 |

### v2 引入认证时的要求（预留）

当需要引入用户体系时，必须满足：
- 手机号 + 验证码登录（阿里云 SMS）
- JWT Access Token (1h) + Refresh Token (30d)
- Token 存储在 flutter_secure_storage（iOS Keychain / Android EncryptedSharedPreferences）
- Refresh Token 支持撤销（服务端维护黑名单）

---


## 2. API 端点权限表

股势 TrendStock v1 为纯客户端架构，所有外部 API 调用均从客户端直接发起。以下为端点权限矩阵：

### 外部 API 端点权限

| Endpoint | 用途 | 认证要求 | 频率限制 | 数据分类 |
|----------|------|---------|---------|---------|
| push2.eastmoney.com/api/qt/clist/get | 全市场行情 | 无（公开） | 建议 < 10次/分钟 | 公开 |
| push2his.eastmoney.com/api/qt/stock/kline/get | 个股K线 | 无（公开） | 建议 < 30次/分钟 | 公开 |
| searchapi.eastmoney.com/api/suggest/get | 股票搜索 | 无（公开） | 建议 < 20次/分钟 | 公开 |
| search-api-web.eastmoney.com/search/jsonp | 新闻搜索 | 无（公开） | 建议 < 10次/分钟 | 公开 |
| hq.sinajs.cn/list | 新浪行情（备选） | 无（公开） | 建议 < 10次/分钟 | 公开 |
| sentry.io | 崩溃上报 | DSN Token | 免费 5k/月 | 内部 |

### 本地 Service 层权限（Dart 内部调用，非 HTTP 端点）

| Service 方法 | 调用方 | 数据访问权限 | 说明 |
|-------------|--------|------------|------|
| StockApiService.fetchAllMarketQuotes | AnalysisEngine, RecommendationTab | 读：全市场行情 | 无写入 |
| StockApiService.fetchStockKline | AnalysisEngine | 读：个股K线 | 缓存到 SQLite |
| StockApiService.searchStock | SearchSheet | 读：股票搜索结果 | 缓存到 SQLite |
| StockApiService.fetchStockNews | NewsSection | 读：个股新闻 | 缓存到 SQLite |
| WatchlistService.getWatchlist | WatchlistTab | 读写：关注列表 | 完整 CRUD |
| WatchlistService.addToWatchlist | SearchSheet | 写：关注列表 | 需检查重复 |
| WatchlistService.removeFromWatchlist | WatchlistTab | 删：关注列表 | 不可逆 |
| AnalysisEngine.calculateScore | BackgroundWorker | 读：K线数据，写：评分 | 纯计算 |
| AnalysisEngine.checkDownsideAlert | AlertService | 读：K线数据 | 只读检测 |
| ScoreService.submitScore | DetailPage | 写：评分记录 | 需登录态（v2） |
| ScoreService.getScoreHistory | HistoryPage | 读：评分历史 | 只读 |
| AlertService.dispatchNotification | BackgroundWorker | 触发：本地通知 | 需通知权限 |

### 端点安全规则

| 规则 | 说明 |
|------|------|
| 所有外部请求必须 HTTPS | Android: usesCleartextTraffic=false; iOS: ATS 默认强制 |
| 请求超时设置 | connectTimeout: 10s, receiveTimeout: 15s |
| 重试策略 | 最多 3 次，exponential backoff (1s, 2s, 4s) |
| User-Agent 标识 | 使用标准 UA，不暴露 App 版本信息 |
| 响应验证 | 所有 JSON 响应必须经过 schema 验证后再使用 |

## 3. 数据分类与保护

### 数据分类矩阵

| 分类 | 数据类型 | 存储位置 | 保护措施 | 泄露影响 |
|------|---------|---------|---------|---------|
| 公开数据 | 股票行情（价格、涨跌幅） | SQLite | 无需加密 | 低 |
| 公开数据 | 股票基础信息（名称、行业、市值） | SQLite | 无需加密 | 低 |
| 公开数据 | 新闻标题和摘要 | SQLite | 无需加密 | 低 |
| 用户偏好 | 关注列表 | SQLite | v1 明文存储 / v1.1 加密 | 中 |
| 用户偏好 | 评分记录 | SQLite | v1 明文存储 / v1.1 加密 | 中 |
| 用户偏好 | 预警开关设置 | SQLite | 无需加密 | 低 |
| 设备信息 | App 版本、最后同步时间 | SharedPreferences | 无需加密 | 低 |
| 敏感 | API 请求 URL 和参数 | 内存（Dio） | 不持久化 | 中 |

### 加密要求（v1.1 实施）

```dart
// SQLite 加密（使用 drift 的加密扩展）
// 或者使用 sqlcipher 包
@DriftDatabase(tables: [WatchlistItems, UserScores])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // v1.1: 使用 sqlcipher 替换 sqflite
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(join(dbFolder.path, 'stockpilot.sqlite'));
      // v1: 使用明文 sqflite
      // v1.1: 替换为 openEncryptedDatabase
      return NativeDatabase.createInBackground(file);
    });
  }
}
```

---

## 4. 网络安全

### HTTPS 强制

```dart
// Dio 拦截器：强制 HTTPS
final dio = Dio(BaseOptions(
  baseUrl: 'https://push2.eastmoney.com',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 15),
));

// 禁止 HTTP 降级
// Android: android:usesCleartextTraffic="false" (AndroidManifest.xml)
// iOS: App Transport Security 默认强制 HTTPS (Info.plist)
```

### 证书锁定（v1.1 实施）

```dart
// v1: 依赖系统证书信任链（足够 MVP 使用）
// v1.1: 对东方财富域名实施 Certificate Pinning
// dio.interceptors.add(CertificatePinningInterceptor(
//   allowedSHAFingerprints: ['sha256/ABC123...'],
// ));
```

### API Key 保护

当前架构：无 API Key（使用东方财富等免费公开接口）
如未来引入需要 Key 的 API（Tushare Pro 等）：
- **禁止**将 API Key 硬编码在客户端代码中
- 必须通过后端代理转发请求
- API Key 仅存储在服务端环境变量中

---

## 5. 合规要求

### 证券合规（《证券期货投资者适当性管理办法》）

| 要求 | 实现方式 | 验收标准 |
|------|---------|---------|
| 不含投资建议 | 所有推荐标注"仅供参考，不构成投资建议" | 推荐列表、详情页、通知均需标注 |
| 不承诺收益 | 不展示"稳赚""必涨"等表述 | 全局搜索禁止词汇列表 |
| 风险提示 | 首次打开 App 展示风险提示弹窗 | 用户点击"我已知悉"后才能使用 |
| 数据来源声明 | 标注数据来源（东方财富/新浪财经） | 每个数据展示区域标注来源 |

### 风险提示文案（必须展示）

```
免责声明：
1. 本应用提供的股票推荐和评分仅基于技术面指标计算，仅供参考，不构成任何投资建议。
2. 股市有风险，投资需谨慎。用户应根据自身情况独立判断，自行承担投资风险。
3. 本应用不保证数据的准确性和完整性，不对因使用本应用信息导致的投资损失承担责任。
4. 数据来源：东方财富、新浪财经等公开渠道。
```

### 首次启动弹窗（必须实现）

```
+---------------------------------------------+
|                                             |
|          投资风险提示                        |
|                                             |
|  本应用提供的信息仅供参考，                  |
|  不构成任何投资建议。                        |
|                                             |
|  股市有风险，投资需谨慎。                    |
|                                             |
|  [我已阅读并知悉]         [退出应用]         |
+---------------------------------------------+
```

### 个人信息保护（中国《个人信息保护法》）

| 要求 | 实现方式 |
|------|---------|
| 最小必要原则 | v1 不收集任何个人信息（无账号体系） |
| 本地存储声明 | Privacy Policy 说明数据仅存储在设备本地 |
| 无追踪 | 不集成第三方广告 SDK、无追踪器 |
| 删除权 | 用户卸载 App 即删除所有数据，提供"清除数据"功能 |

---

## 6. Flutter 客户端安全约束清单


### FE 约束（Flutter 客户端硬性约束）

以下为前端（Flutter）必须遵守的安全约束，违反任何一条将导致 Code Review FAIL：

### BE 约束说明（纯客户端架构）

股势 TrendStock v1 为纯客户端架构，无后端服务器。以下为数据访问层（Dart）的安全约束，
等效于传统架构中后端的安全要求：


#### 必须遵守（Code Review FAIL 条件）


| # | 约束 | 严重性 | 检查方式 |
|---|------|--------|---------|
| S01 | 禁止硬编码任何 API Key / Secret / Token | CRITICAL | grep 扫描 |
| S02 | 禁止使用 HTTP 明文请求（必须 HTTPS） | HIGH | AndroidManifest + Dio 配置 |
| S03 | 禁止在日志中输出敏感数据（股票行情除外） | HIGH | 代码审查 |
| S04 | 必须展示风险提示弹窗（首次启动） | HIGH | 功能测试 |
| S05 | 所有推荐/评分展示区域必须标注"仅供参考" | HIGH | UI 审查 |
| S06 | SQLite 数据库文件禁止放在外部存储（SD卡） | MEDIUM | 路径检查 |
| S07 | 禁止使用 dart:io 的 File 写入 App 沙盒外 | MEDIUM | 代码审查 |
| S08 | WebView 加载外部页面时必须禁用 JavaScript 注入 | MEDIUM | WebView 配置 |
| S09 | SharedPreferences 不存储敏感数据 | LOW | 代码审查 |
| S10 | release 构建必须开启混淆（--obfuscate） | HIGH | CI 配置检查 |

### Release 构建安全配置

```yaml
# android/app/build.gradle
android {
    buildTypes {
        release {
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

```bash
# iOS Release 构建
flutter build ios --release --obfuscate --split-debug-info=/<project-name>/symbols/
flutter build apk --release --obfuscate --split-debug-info=/<project-name>/symbols/
```

### ProGuard 规则（必须包含）

```
# android/app/proguard-rules.pro
# 保留模型类（JSON 序列化需要）
-keep class com.example.stockpilot.** { *; }
# 移除日志
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
```

---


### 数据访问层（DAL）安全约束

| # | 约束 | 严重性 | 说明 |
|---|------|--------|------|
| D01 | 禁止 SQL 注入 | CRITICAL | 使用 drift ORM 参数化查询，禁止拼接 SQL 字符串 |
| D02 | 禁止直接执行原始 SQL | HIGH | 除非经过安全审查，所有查询必须通过 drift 类型安全 API |
| D03 | 数据库文件权限 | MEDIUM | SQLite 文件仅 App 沙盒内可访问，禁止复制到外部存储 |
| D04 | 敏感数据禁止明文日志 | HIGH | SQLite 查询结果中如包含用户偏好数据，禁止 print/debugPrint |

## 8. 外部 API 安全评估

| API 提供方 | 用途 | 是否需要认证 | 安全风险 | 缓解措施 |
|-----------|------|------------|---------|---------|
| 东方财富 push2.eastmoney.com | 行情数据 | 否（公开接口） | 接口可能变更/封禁 | 多数据源备选 |
| 东方财富 search-api-web.eastmoney.com | 搜索 | 否 | 同上 | 新浪搜索备选 |
| 新浪财经 hq.sinajs.cn | 备选行情 | 否 | 数据格式可能变更 | 解析异常兜底 |
| sentry.io | 崩溃上报 | 是（DSN 公开但可控） | DSN 泄露风险 | DSN 设置速率限制 |

---

## 9. 数据备份与恢复

### 当前方案（v1）

- **无自动云备份**（纯本地架构）
- 用户数据随 App 卸载消失
- 提供手动导出功能（JSON 格式）：关注列表 + 评分记录

### 手动导出格式

```json
{
  "version": "1.0",
  "exported_at": "2026-04-10T12:00:00Z",
  "watchlist": [
    {
      "stock_code": "601318",
      "stock_name": "中国平安",
      "is_pinned": true,
      "alert_enabled": true
    }
  ],
  "scores": [
    {
      "stock_code": "601318",
      "score": 8,
      "prediction": "up",
      "prediction_date": "2026-04-10"
    }
  ]
}
```

---

## 10. 安全审计检查清单

| 检查项 | 状态 | 备注 |
|--------|------|------|
| 无硬编码密钥/Token | 待验证 | CI grep 扫描 |
| 全链路 HTTPS | 待验证 | 网络抓包测试 |
| 首次启动风险提示 | 待实现 | 必须功能 |
| "仅供参考"标注 | 待实现 | 必须功能 |
| SQLite 在沙盒内 | 待验证 | 路径检查 |
| Release 混淆开启 | 待验证 | 构建配置 |
| 无第三方追踪 SDK | 待验证 | 依赖检查 |
| ProGuard 规则配置 | 待验证 | Android 构建 |
| Privacy Policy 文案 | 待编写 | 上架必需 |
