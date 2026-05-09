# 股势 TrendStock 运维手册

版本：v1.0 | 状态：Draft | 作者：DevOps | 日期：2026-04-10

---

## 1. 日常运维操作

### 1.1 每日检查清单

每个工作日开盘前（9:00 前）检查以下内容：

| 检查项 | 工具 / 方法 | 预期结果 | 异常处理 |
|--------|------------|---------|---------|
| Sentry Crash 仪表板 | [Sentry Dashboard](https://sentry.io/organizations/stockpilot) | 无 P0/P1 issue | 立即通知并评估是否回滚 |
| Play Store 崩溃率 | Play Console → 质量 → 崩溃报告 | ANR < 0.1%，Crash < 0.5% | 超过阈值立即告警 |
| App Store 崩溃率 | App Store Connect → 质量 | Crash < 0.5% | 同上 |
| 外部 API 健康状态 | 手动打开 App → 查看推荐列表 | 正常展示今日数据 | 检查 Banner 是否显示缓存提示 |
| Google Play 审核状态 | Play Console → 发布 → 概览 | 无被拒状态 | 被拒：立即查看原因并修复 |

### 1.2 发布新版本流程

```
Step 1: 触发 CI 构建
  → GitHub Actions → workflows/dispatch.yml → "Run workflow"
  → 输入版本号 (e.g., v1.0.1)

Step 2: 下载 Artifacts
  → GitHub Actions → Artifacts → stockpilot-android-aab / stockpilot-ios-ipa

Step 3: 内部验收（真机）
  → Android: adb install app-release.aab（直接安装）
  → iOS: Xcode → Devices → + → 拖入 IPA（需设备 UDID 在 provisioning profile）

Step 4: 提交 Google Play
  → Play Console → 应用 → 生产 → 创建版本
  → 上传 AAB → 发布到内部测试（1h 审核）→ 验证通过 → 发布到生产

Step 5: 提交 App Store
  → Xcode → Product → Archive → Distribute App → App Store Connect
  → 或：Transporter CLI: xcrun altool --upload-app -t ios -f Runner.ipa
  → App Store Connect → TestFlight → 添加构建 → 提交审核 → 生产发布

Step 6: 通知
  → Slack #stockpilot-releases 通报版本号和变更摘要
```

### 1.3 版本标签与 Git 操作

```bash
# 合并到 main 后，打标签
git tag -a v1.0.1 -m "v1.0.1: fix crash on watchlist swipe"
git push origin v1.0.1

# 查看历史标签
git tag -l
git log --oneline --graph --decorate
```

---

## 2. 故障排查指南

### 2.1 问题分类与响应

| 级别 | 描述 | 响应时间 | 处理人 |
|------|------|---------|--------|
| P0 | App 完全无法启动 / 崩溃率 > 1% | 15 分钟内 | 值班工程师 |
| P1 | 核心功能不可用（推荐 / 关注列表无法加载）| 1 小时内 | 值班工程师 |
| P2 | 非核心功能异常（新闻加载失败 / 推送失效）| 24 小时内 | 负责工程师 |
| P3 | UI 显示问题 / 性能降级 | 下个版本 | 任意工程师 |

---

### 场景 A：用户反馈"推荐列表是空的"或"数据不更新"

**排查路径：**

```bash
# Step 1: 确认问题范围
# 询问用户：仅推荐列表还是所有数据？仅 Android 还是 iOS？

# Step 2: 检查 Sentry 是否有相关 error
# Sentry Dashboard → Search: "fetchAllMarketQuotes" OR "CALCULATING"

# Step 3: 检查外部 API 是否可用
# 本地模拟请求：
curl -s "https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=5&po=1&np=1&fltt=2&invt=2&fid=f3&fs=m:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23&fields=f2,f3,f12,f14" | head -c 500

# Step 4: 检查是否是缓存过期问题
# App → 设置 → 清除缓存 → 重启 App

# Step 5: 检查是否是 SQLite 损坏（极端情况）
# Android: adb shell run-as com.stockpilot.stockpilot cat databases/stockpilot.db
# iOS: 需要第三方工具（如 iPhone Backup Extractor）
```

**可能原因：**

| 原因 | 症状 | 解决方案 |
|------|------|---------|
| 东方财富 API 不可用 | 多个用户同时反馈 | 展示缓存 + Banner；评估备用数据源（新浪财经）|
| SQLite 缓存损坏 | 单用户偶发 | 清除缓存；如持续发生则发版修复 |
| 客户端版本过旧 | 旧版本 API 请求格式变更 | 强制更新 App |

---

### 场景 B：用户反馈"下跌预警通知没有收到"

**排查路径：**

```bash
# Step 1: 检查用户通知权限
# App → 设置 → 通知权限是否打开

# Step 2: 检查 workmanager 任务是否执行
# Android: adb shell dumpsys workmanager
# 查看 com.stockpilot.stockpilot 的 scheduled tasks

# Step 3: 检查 flutter_local_notifications 插件日志
# Debug 日志：flutter run --release（需要 debug build）
# Release 日志：adb logcat | grep flutter（Android）

# Step 4: 检查该股票是否触发预警条件（数据库查询）
# 预警条件：收盘价跌破 MA20 且跌幅 > 2%；或跌破布林带下轨；或连续 3 天放量下跌

# Step 5: iOS 特殊限制说明
# iOS 后台任务执行不可靠，建议用户保持 App 在后台运行或使用前台提醒
```

**可能原因：**

| 原因 | 症状 | 解决方案 |
|------|------|---------|
| 用户未授予通知权限 | 通知开关灰色 | 引导用户开启权限 |
| iOS 后台任务被系统杀死 | 仅 iOS 用户反馈 | 文档说明 iOS 限制；考虑 v2 引入后端推送 |
| workmanager 未正确注册 | 仅部分 Android 用户 | 发版修复；检查 `AndroidManifest.xml` receiver 配置 |
| 该股票未触发预警条件 | 逻辑上无预警 | 向用户说明：需满足 3 个条件之一才会触发 |

---

### 场景 C：评分显示"计算中"或"数据不足，暂无评分"

**排查路径：**

```bash
# Step 1: 检查日 K 线数据是否足够
# 评分计算需要至少 60 个交易日数据（MA60 计算）
# 少于 60 天 → 展示"数据不足，暂无评分"

# Step 2: 检查计算引擎是否有 unhandled exception
# Sentry Dashboard → Search: "calculateScore" OR "AnalysisEngine"

# Step 3: 检查是否是停牌股票
# 停牌股票无日 K 线数据 → 无评分

# Step 4: 确认是数据问题还是算法问题
# App → 详情页 → 查看历史 K 线数据条数
```

**正常展示：**

| 状态 | 展示文案 | 原因 |
|------|---------|------|
| 计算中 | "计算中..." | 异步计算中，1-2 秒后刷新 |
| 数据不足 | "数据不足，暂无评分" | 上市不足 60 个交易日的新股或停牌股 |
| 无评分 | 不显示评分区域 | 该股票不纳入评分范围 |

---

### 场景 D：App 冷启动时间超过 2 秒

**排查路径：**

```bash
# Step 1: 使用 Flutter DevTools 性能分析
flutter run --profile
# 在 DevTools 的 Timeline 视图中查看 startup

# Step 2: 检查 Drift 数据库初始化时间
# 在 lib/database/database.dart 的 open() 方法前后添加计时日志

# Step 3: 检查首次网络请求阻塞
# 冷启动时是否等待 API 返回才展示 UI？
# 正常：先展示 skeleton → 异步请求 → 展示数据

# Step 4: 检查 flutter_local_notifications 和 workmanager 初始化
# 延迟初始化（非核心功能）：
Future.delayed(Duration.zero, () async {
  await NotificationService.init();
  await Workmanager.init();
});
```

**性能目标：** App 冷启动时间 P95 < 2s（中端 Android，骁龙 778G）

---

### 场景 E：Google Play 审核被拒

**常见原因：**

| 原因 | 说明 | 解决 |
|------|------|------|
| 金融类 App 未声明 | Play Console 分类含理财但未声明 | 在应用内容声明中选择"理财与保险" |
| 缺少隐私政策 | 隐私政策 URL 不可访问 | 部署隐私政策到 GitHub Pages |
| 截图不符合规范 | 使用了非真实截图 | 使用真实 App 截图 |
| 内购未配置 | 如有付费功能但未配置内购 | 按需配置或移除付费功能 |

**处理步骤：**
1. 查看 Play Console 审核详情中的具体拒绝原因
2. 修复对应问题（通常 2-4 小时内）
3. 重新提交，选择"严重程度较低的账号降级风险"说明
4. 关注审核结果（通常 1-24 小时）

---

## 3. 监控指标

### 3.1 核心业务指标

| 指标 | 定义 | 正常范围 | 告警阈值 | 采集方式 |
|------|------|---------|---------|---------|
| 日活用户（DAU）| 每日打开 App 的独立用户数 | 基线待建立 | 连续 3 天下降 > 30% → P2 | Play Console / App Store Connect |
| 关注列表平均留存股数 | 每用户关注股票数量 | 目标 > 5 | < 3 → P2 | 客户端上报（v2 后端端）|
| 推荐列表点击率 | 点击推荐股票的 UV / 展示 UV | 基线待建立 | -- | 同上 |
| 评分准确率 | 预判正确数 / 总预判数 | 目标 > 40%（死亡线）| < 40% → P1（算法重构）| 本地 SQLite 统计 |

### 3.2 技术指标

| 指标 | 定义 | 正常范围 | 告警阈值 | 采集方式 |
|------|------|---------|---------|---------|
| App 崩溃率 | Crash Sessions / Total Sessions | < 0.5% | > 1% → P0 | Sentry / Play Console |
| ANR 率 | ANR Sessions / Total Sessions | < 0.1% | > 0.5% → P1 | Play Console |
| 冷启动时间 | App 进程启动到首帧渲染 | P95 < 2s | > 3s → P2 | Flutter DevTools（手动）|
| 列表滑动帧率 | SwiperRenderFrame / Total | 目标 >= 55fps | < 30fps → P2 | Flutter DevTools（手动）|
| 行情 API 成功率 | success / (success + failure) | > 95% | < 80% 持续 30min → P1 | Sentry 事件统计 |
| 新闻 API 成功率 | success / (success + failure) | > 90% | < 70% 持续 30min → P1 | 同上 |
| A/B 测试覆盖率 | 当前功能开关开启比例 | 0-100% 可配置 | -- | App 内开关控制 |

### 3.3 Sentry 自定义事件

在 `lib/core/instrumentation.dart` 中配置以下事件：

```dart
// 行情 API 调用结果
Sentry.captureMessage(
  'api_market',
  level: SentryLevel.warning,
  extra: {
    'success': true,
    'duration_ms': 320,
    'stock_count': 4850,
  },
);

// 计算引擎异常
Sentry.captureException(
  CalculationException(stockCode: '601318', reason: 'NaN in MA'),
  stackTrace: stackTrace,
);

// 评分准确率统计（每日上报一次）
Sentry.captureMessage(
  'score_accuracy',
  level: SentryLevel.info,
  extra: {
    'total_predictions': 150,
    'correct': 72,
    'accuracy': 0.48,
  },
);
```

---

## 4. 告警与通知

### 4.1 Sentry 告警规则配置

在 [Sentry Alert Rules](https://sentry.io/organizations/stockpilot/alerts/) 配置以下规则：

| 规则名称 | 条件 | 频率 | 通知渠道 | 动作 |
|---------|------|------|---------|------|
| P0-Crash-Spike | `issue.first_seen:1h` AND `count():100` | 即时 | Slack #incidents + PagerDuty | 立即回滚 + 通知值班工程师 |
| P1-API-Degraded | `event.tags.api:market` AND `failure_rate:0.2` 持续 30min | 5min | Slack #alerts | 评估备用数据源 |
| P2-New-Issue | 新 issue 首次出现 | 每小时汇总 | Slack #alerts | 下一工作日处理 |

### 4.2 Slack 频道说明

| 频道 | 用途 | 通知来源 |
|------|------|---------|
| `#stockpilot-releases` | 发布通知 | GitHub Actions CI 完成后自动通知 |
| `#stockpilot-alerts` | 非紧急告警（P1/P2）| Sentry 告警规则 |
| `#stockpilot-incidents` | 紧急故障（P0）| Sentry PagerDuty + 值班工程师 |

---

## 5. 数据库与存储

### 5.1 SQLite 数据清理（workmanager）

每晚 2:00 自动执行清理任务：

```dart
// lib/database/cleanup_task.dart

Future<void> cleanupOldData() async {
  final cutoff = DateTime.now().subtract(const Duration(days: 30));

  // 清理 30 天前的推荐缓存（非关注股日线缓存）
  await (delete(dailyQuoteCache)
        ..where((t) => t.updatedAt.isSmallerThanValue(cutoff))
        ..where((t) => t.stockCode.isNotIn(watchlistStockCodes)))
      .go();

  // 清理 7 天前的新闻缓存
  final newsCutoff = DateTime.now().subtract(const Duration(days: 7));
  await (delete(newsCache)
        ..where((t) => t.fetchedAt.isSmallerThanValue(newsCutoff)))
      .go();

  // 清理 30 天前的每日推荐缓存
  await (delete(dailyRecommendationCache)
        ..where((t) => t.createdAt.isSmallerThanValue(cutoff)))
      .go();
}
```

### 5.2 数据库损坏应急

```bash
# Step 1: 检测是否损坏
adb shell run-as com.stockpilot.stockpilot sqlite3 databases/stockpilot.db "PRAGMA integrity_check;"

# Step 2: 导出可恢复的数据
adb shell run-as com.stockpilot.stockpilot cat databases/stockpilot.db > /tmp/stockpilot_backup.db

# Step 3: 删除损坏数据库（App 会自动重建空数据库）
adb shell rm databases/stockpilot.db

# Step 4: 通知用户重新打开 App，数据将重新从 API 拉取
```

---

## 6. 值班与交接

### 6.1 值班工程师职责

- 每天 9:00-18:00 关注 Slack `#stockpilot-alerts` 和 `#stockpilot-incidents`
- 收到 P0 告警后 15 分钟内响应
- 非工作时间：Sentry PagerDuty 自动电话通知 P0

### 6.2 交接清单

值班结束时，在 Slack `#stockpilot-ops` 发布交接信息：

```
[交接] 2026-04-10
- 当前 open issues: [链接]
- 待处理发布: v1.0.2 (QA 验收中)
- 已知风险: 东方财富 API 最近 24h 成功率 92%（略低于目标 95%），已观察中
- 下一班: @engineer_name
```

---

## 7. 事后复盘模板（P0/P1 必填）

```markdown
# 事后复盘 - {简短标题}

## 基本信息
- **事件编号**: INC-2026-XXXX
- **级别**: P0 / P1
- **发生时间**: {YYYY-MM-DD HH:MM}
- **发现时间**: {YYYY-MM-DD HH:MM}
- **恢复时间**: {YYYY-MM-DD HH:MM}
- **总时长**: {X} 小时 {Y} 分钟
- **影响用户数**: {N} 人（约 {X}% 的 DAU）

## 事件经过
- {HH:MM} - 发现问题（来源：告警 / 用户反馈）
- {HH:MM} - 确认问题范围
- {HH:MM} - 开始修复
- {HH:MM} - 修复完成，验证正常

## 根本原因
{具体原因}

## 预防措施
- [ ] {具体可落地的改进项}

## 告警改进
- [ ] 哪些告警太晚触发或未触发？
- [ ] 建议新增 / 调整的告警规则？
```

---

## 8. 相关文档

| 文档 | 路径 |
|------|------|
| 部署计划 | `docs/deploy-plan.md` |
| PRD | `docs/prd.md` |
| 架构决策 | `docs/arch-decision.md` |
| Sentry Dashboard | https://sentry.io/organizations/stockpilot |
| Play Console | https://play.google.com/console/stockpilot |
| App Store Connect | https://appstoreconnect.apple.com |
