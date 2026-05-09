# 股势 TrendStock 部署计划

版本：v1.0 | 状态：Draft | 作者：DevOps | 日期：2026-04-10
前置文档：`docs/prd.md` / `docs/arch-decision.md`

---

## 1. 版本管理策略

### 1.1 语义化版本（Semantic Versioning）

```
<major>.<minor>.<patch>+<build>
```

| 字段 | 含义 | 触发条件 | 示例 |
|------|------|---------|------|
| `major` | 主版本 | 重大架构变更 / 破坏性 API 变更 | v2.0.0 |
| `minor` | 次版本 | 新功能上线 / 功能范围变更 | v1.1.0 |
| `patch` | 补丁版本 | Bug 修复 / 性能优化 / 合规文案调整 | v1.0.1 |
| `build` | 构建号 | CI 自动递增（对应 Flutter `versionCode`） | v1.0.0+1 |

**当前版本**：`1.0.0+1`（MVP 首版）

### 1.2 版本标签含义

| 标签 | 渠道 | 受众 | 更新频率 | 说明 |
|------|------|------|---------|------|
| `v<major>.0.0-alpha` | Alpha 内测 | 开发团队 + 少量内部测试机 | 按需 | 早期功能验证 |
| `v<minor>.0-beta` | Beta 公开测试 | Google Play 内部测试轨道 / TestFlight | 每周 1-2 次 | 功能相对稳定，向外部用户开放 |
| `v<minor>.0-rc` | Release Candidate | QA 团队 | 发布前 2-3 天 | 最终验收测试 |
| `v<minor>.0` | 正式生产 | 所有用户 | 视需求 | 稳定版 |
| `v<minor>.0-hotfix` | 热修复 | 所有用户 | 紧急情况 | 仅用于 P0/P1 Bug 修复 |

### 1.3 分支策略

```
main
  │
  ├── feature/*  (功能开发分支)
  │
  └── release/v1.x.x  (发布分支，仅修复 cherry-pick)
```

- `main`：最新开发主干，所有 PR 合并到此
- `release/v<minor>.x`：发布准备分支，仅接受 Bug 修复和合规变更
- `feature/*`：功能开发分支，开发完成后合并回 main
- **禁止**在 release 分支开发新功能

---

## 2. 发布渠道

### 2.1 Android — Google Play

| 轨道 | 用途 | 审核 | 适用阶段 |
|------|------|------|---------|
| **内部测试** (Internal Testing) | 团队成员快速验收 | 无 | 开发期 / 热修复验证 |
| **封闭测试** (Closed — Alpha/Beta) | 种子用户内测（< 20 人）| 约 1 小时 | MVP 发布后 2 周 |
| **公开测试** (Open Beta) | 扩大内测范围（上限 1000 人）| 约 1-3 天 | 验证成功后 |
| **正式生产** (Production) | 所有用户 | 约 1-7 天 | 稳定版全量发布 |

**审核注意事项**：
- 股势 TrendStock 涉及金融数据展示，需在 Play Console "理财与保险" 分类下声明
- 所有股票推荐页面必须包含"仅供参考，不构成投资建议"免责声明
- App 隐私政策必须在 Play Store 页面公开链接

### 2.2 iOS — App Store

| 轨道 | 用途 | 审核 | 适用阶段 |
|------|------|------|---------|
| **TestFlight 内部** | 开发团队 | 无 | 开发期 |
| **TestFlight 外部** | 外部测试用户（< 100 人）| 约 1-2 天 | MVP 发布后 2 周 |
| **App Store 生产** | 所有用户 | 约 1-7 天（首次 7 天，后续 1-2 天）| 稳定版全量发布 |

**审核注意事项**：
- App Store 分类：Finance（理财）
- 同上，股票推荐页必须包含免责声明
- 隐私政策 URL 必须提供（可通过 GitHub Pages 托管）
- iOS 15+ 最低支持版本符合 PRD 要求

---

## 3. 构建命令

### 3.1 Android

#### Debug 构建（本地开发）

```bash
flutter build apk --debug
# 输出: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release 构建（正式发布，含混淆）

```bash
flutter build appbundle --release \
  --target-platform android-arm,android-arm64 \
  --obfuscate \
  --split-debug-info=build/debug-info
```

参数说明：
- `--obfuscate`：启用 Dart 符号混淆（代码安全）
- `--split-debug-info`：输出符号文件，用于 Release 崩溃堆栈还原
- `--target-platform`：排除 x86（模拟器专用），减少包体积
- 最终产物：`build/app/outputs/bundle/release/app-release.aab`（上传 Play Store）
- 同时生成 APK 供内部分发：`flutter build apk --release`

#### Android 混淆配置

ProGuard 规则文件：`android/app/proguard-rules.pro`（已配置）

关键保护规则：
```properties
# Flutter 框架保留
-keep class io.flutter.** { *; }

# Drift ORM 保留
-keep class drift.** { *; }

# Dart 模型类保留（json_serializable / drift）
-keep class com.stockpilot.stockpilot.** { *; }

# 移除日志（Release 构建）
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
```

### 3.2 iOS

#### Debug 构建（本地开发 / 模拟器）

```bash
flutter build ios --simulator --no-codesign
# 输出: build/ios/iphonesimulator/Runner.app
```

#### Release 构建（App Store 发布）

```bash
# Step 1: 导出 (Flutter 会自动调用 xcodebuild + lipo)
flutter build ios --release

# Step 2: 使用 xcarchive 打包（CI 中使用）
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/Runner.xcarchive \
  archive

# Step 3: 导出 IPA（用于 TestFlight 或 Ad Hoc）
xcodebuild -exportArchive \
  -archivePath build/ios/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa
```

#### iOS 代码签名配置

`ios/Runner.xcconfig`（已存在）中配置：
```
CODE_SIGN_IDENTITY = ""      # 留空，CI 中通过环境变量覆盖
CODE_SIGNING_REQUIRED = NO   # CI 中关闭强制签名
CODE_SIGNING_ALLOWED = NO
```

`ios/ExportOptions.plist`（需新建）：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

---

## 4. CI/CD 流水线

### 4.1 流水线概览

```
PR 提交
  │
  ▼
GitHub Actions: CI (Quality Gate)
  ├── flutter analyze
  ├── flutter test
  ├── drift/sqflite 代码生成
  └── 安全扫描（trufflehog）
  │
  ▼
main 分支合并
  │
  ▼
GitHub Actions: Build & Release
  ├── 构建 Android AAB (Release)
  ├── 构建 iOS IPA (Release)
  ├── 上传 Artifacts (保留 30 天)
  └── 通知（Slack / 内部群）
  │
  ▼
手动确认发布
  ├── Android: 上传 Google Play Console (内部测试 → 生产)
  └── iOS: 上传 App Store Connect (TestFlight → 生产)
```

### 4.2 CI 工作流（质量门禁）

文件名：`.github/workflows/ci.yml`

触发条件：`pull_request` + `push to main`

```yaml
name: CI

on:
  pull_request:
    branches: [main, 'release/**']
  push:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
        # drift + json_serializable 代码生成
      - run: flutter analyze --no-fatal-infos --no-fatal-warnings
      - run: flutter test --coverage
        env:
          CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
      - uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
          only-verified: false

  android-build:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - name: Build Android App Bundle
        run: |
          flutter build appbundle --release \
            --target-platform android-arm64 \
            --obfuscate \
            --split-debug-info=build/debug-info
        env:
          FLUTTER_BUILD_NAME: ${{ vars.APP_VERSION_NAME || '1.0.0' }}
          FLUTTER_BUILD_NUMBER: ${{ github.run_number }}
      - name: Upload AAB artifact
        uses: actions/upload-artifact@v4
        with:
          name: stockpilot-android-aab
          path: build/app/outputs/bundle/release/app-release.aab
          retention-days: 30

  ios-build:
    needs: quality
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - name: Set up code signing
        run: |
          mkdir -p ~/private_keys
          echo "${{ secrets.APPCENTER_IOS_SIGNING_KEY }}" | base64 --decode > ~/private_keys/RunnerDistribution.p12
          keychain install-cert ~/private_keys/RunnerDistribution.p12
          keychain set-keychain-password -p "" -s default
        env:
          APP_CENTER_ACCESS_TOKEN: ${{ secrets.APP_CENTER_ACCESS_TOKEN }}
      - name: Build iOS IPA
        run: |
          flutter build ios --release
          # 转换为 xcarchive → IPA
          xcodebuild -workspace ios/Runner.xcworkspace \
            -scheme Runner \
            -configuration Release \
            -archivePath build/ios/Runner.xcarchive \
            -derivedDataPath build/ios/derived \
            archive
          xcodebuild -exportArchive \
            -archivePath build/ios/Runner.xcarchive \
            -exportOptionsPlist ios/ExportOptions.plist \
            -exportPath build/ios/ipa
        env:
          FLUTTER_BUILD_NAME: ${{ vars.APP_VERSION_NAME || '1.0.0' }}
          FLUTTER_BUILD_NUMBER: ${{ github.run_number }}
      - name: Upload IPA artifact
        uses: actions/upload-artifact@v4
        with:
          name: stockpilot-ios-ipa
          path: build/ios/ipa/Runner.ipa
          retention-days: 30
```

### 4.3 发布后处理清单

| 步骤 | 操作 | 责任人 |
|------|------|--------|
| 1 | 下载 CI Artifacts（AAB / IPA） | 发布工程师 |
| 2 | 内部快速验收（真机安装测试） | QA |
| 3 | Google Play Console 上传 AAB，选择内部测试轨道 | DevOps |
| 4 | App Store Connect 上传 IPA，选择 TestFlight | DevOps |
| 5 | 等待审核通过（内部测试约 1 小时，生产约 1-7 天）| -- |
| 6 | 批准发布到生产（Google Play 可选分阶段推送 5% → 20% → 100%）| PM / DevOps |
| 7 | 监控崩溃率（Sentry Dashboard）| DevOps |
| 8 | 如 24h 内无 P0/P1 问题，标记发布完成 | DevOps |

---

## 5. 发布前检查清单

### 5.1 功能检查

- [ ] 所有 Must（MoSCoW）功能已完成并通过 QA
- [ ] 关注列表滑动操作（左滑删除 / 右滑置顶）功能正常
- [ ] 搜索 + 添加关注流程可正常执行
- [ ] 新闻加载失败时展示缓存数据 + 提示
- [ ] 评分颜色标识（绿/黄/红）+ 文字说明同时展示（WCAG 合规）
- [ ] 免责声明"仅供参考，不构成投资建议"已在推荐页 / 详情页展示
- [ ] iOS 支持方向锁定竖屏（Info.plist `UISupportedInterfaceOrientations` 已配置）

### 5.2 合规检查

- [ ] App 隐私政策页面已上线（可在 GitHub Pages 托管 `stockpilot.app/privacy`）
- [ ] Play Store 和 App Store 描述文案不包含任何买卖建议表述
- [ ] Google Play Console "理财与保险" 分类已声明
- [ ] App Store Connect 隐私标签已填写（HTTP API 调用情况：需说明）

### 5.3 技术检查

- [ ] `android/app/build.gradle.kts` 中 `minifyEnabled = true` 和 `shrinkResources = true` 已启用
- [ ] ProGuard 规则覆盖 Drift、Flutter、json_serializable
- [ ] Android `applicationId` = `com.stockpilot.stockpilot`
- [ ] iOS `CFBundleIdentifier` = `com.stockpilot.stockpilot`
- [ ] `minSdk` >= 21（Android 5.0，覆盖 99%+ 设备）
- [ ] `targetSdk` = Flutter 默认（当前 34）
- [ ] iOS 最低支持版本 = iOS 15（Info.plist 或 `Podfile`）

---

## 6. 回滚策略

由于纯客户端架构无服务端部署，回滚 = 安装上一个版本 APK/IPA。

| 场景 | 回滚方式 |
|------|---------|
| Google Play 生产版需要回滚 | Play Console → Release → Management → Rollback（自动回滚到上一版）|
| Google Play 分阶段推送中回滚 | Play Console → Release → 暂停分阶段推送，降级为上一版 |
| App Store 生产版需要回滚 | App Store Connect → TestFlight → 手动分发上一版 IPA（App Store 不支持自动回滚，需提交新版本）|
| TestFlight 回滚 | App Store Connect → TestFlight → Build 详情 → 移除 Build（用户自动使用最新通过审核版）|
| 紧急热修复 | CI 重新触发构建 → 快速审核通道（Google Play 约 2 小时，iOS 约 1-2 天）|

---

## 7. 数据源监控与降级

### 7.1 外部 API 健康监控

| 数据源 | 用途 | 监控方式 | 降级方案 |
|--------|------|---------|---------|
| 东方财富行情 API | 全市场实时行情 | App 内主动检测（失败时展示缓存）| 降级：展示最近缓存 + Banner |
| 东方财富新闻 API | 个股新闻 | 同上 | 降级：展示缓存 + 引导外部浏览器打开 |
| 东方财富日 K 线 API | 波段计算 | 同上 | 降级：使用已有日线缓存数据（最多缺失最近 1 天）|

**监控指标（App 内上报至 Sentry）**：
- `api.eastmoney.market.success_rate`：行情 API 成功率（目标 > 95%）
- `api.eastmoney.news.success_rate`：新闻 API 成功率
- `calc.engine.error_count`：计算引擎异常次数

### 7.2 Sentry 告警规则

| 规则 | 触发条件 | 动作 |
|------|---------|------|
| P0 | `crash rate > 1%` 或 24h 内 > 50 次 crash | 立即通知（Slack #incidents）|
| P1 | `api.eastmoney.*.success_rate < 80%` 持续 30 分钟 | Slack #alerts |
| P2 | 任意 Dart unhandled exception 单日 > 20 次 | 下一工作日处理 |

---

## 8. 灾难恢复（DR）

### 8.1 RTO / RPO

| 场景 | RTO | RPO | 恢复方式 |
|------|-----|-----|---------|
| 外部 API 不可用（东方财富）| < 2h（手动切换备用数据源）| < 24h 缓存 | 使用 SQLite 缓存数据 + Banner 提示用户 |
| App 崩溃率突增 | < 1h（暂停分阶段推送 / 回滚）| 无数据丢失（本地存储不受影响）| Rollback 到上一版本 |
| Play Store / App Store 审核被拒 | < 4h（修复 + 重新提交）| 无 | 修复后重新提交 |
| 开发者账号被盗 | < 24h（联系 Google/Apple 恢复）| 取决于账号恢复时间 | 提前开启双因素认证 |

### 8.2 备份策略

纯客户端架构的关键备份：
- **GitHub Repository**：所有代码、CI 配置、文档
- **Sentry**：崩溃记录、错误堆栈（永久保留，免费版 30 天）
- **Play Console**：历史 APK/AAB（永久保留）
- **App Store Connect**：历史 IPA（永久保留）
- **SQLite 数据**：由用户在设备本地管理（App 不负责云端备份）

---

## 9. 发布节奏

| 阶段 | 发布频率 | 说明 |
|------|---------|------|
| MVP 开发期 | 按需 Alpha 构建 | 仅内部测试 |
| MVP 发布后 2 周 | 每 3-5 天一个新 Beta | 快速迭代收集种子用户反馈 |
| 验证成功后 | 每 1-2 周一个正式版 | 稳定节奏 + 热修复 |
| 稳定期 | 每 4 周一个版本 | 功能按 sprint 交付 |

---

## 10. 健康检查（Health Check）

由于股势 TrendStock 是纯客户端架构（无服务端），传统 HTTP 健康检查端点不适用。采用以下 **客户端健康检查机制**：

### 10.1 App 内健康状态报告

App 在以下时机将健康状态上报至 Sentry（`lib/core/instrumentation.dart`）：

```dart
// App 启动时（第一帧渲染完成后）
Future<void> reportAppStartupHealth() async {
  final stopwatch = Stopwatch()..start();
  try {
    await db.open();          // SQLite 初始化耗时
    stopwatch.stop();
    Sentry.captureMessage('app_startup_healthy', extra: {
      'db_init_ms': stopwatch.elapsedMilliseconds,
      'db_exists': await db.fileExists(),
    });
  } catch (e) {
    Sentry.captureException(e, stackTrace: stackTrace);
  }
}

// 外部 API 连通性检查（每日首次启动时）
Future<void> checkApiHealth() async {
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));
  try {
    final response = await dio.get('https://push2.eastmoney.com/api/qt/clist/get?pn=1&pz=1&fields=f2');
    final success = response.statusCode == 200;
    Sentry.captureMessage('api_health', extra: {
      'api': 'eastmoney_market',
      'success': success,
      'status_code': response.statusCode,
    });
  } catch (e) {
    Sentry.captureMessage('api_health_failed', extra: {
      'api': 'eastmoney_market',
      'error': e.toString(),
    });
  }
}
```

### 10.2 用户可感知的健康状态

| 状态 | 表现 | 用户操作 |
|------|------|---------|
| 健康 | 正常展示数据 | 无 |
| 数据过期 | 顶部 Banner："数据更新于 {时间}，请下拉刷新" | 下拉刷新 |
| API 不可用 | 缓存数据展示 + Banner："网络异常，显示缓存数据" | 等待网络恢复 |
| SQLite 异常 | 全屏错误页："本地数据异常，请重新安装 App" | 重新安装 |

### 10.3 Crash-free Session 率监控

- **目标**：> 99%（即 Crash-free session rate > 99%）
- **采集**：Sentry 自动统计 `crash-free sessions`
- **告警**：Crash-free rate < 98% → P1 告警；< 95% → P0 告警

---

## 11. SLO 定义

### 11.1 核心 SLO 汇总

| SLO | 目标 | 衡量指标 | 告警阈值 | 错误预算 |
|-----|------|---------|---------|---------|
| **App 稳定性** | 99.5% crash-free sessions（每月）| Sentry crash-free rate | < 99% → P1；< 97% → P0 | 每月 3.6 小时不可用预算 |
| **API 成功率** | 95% 行情 API 成功率（每日）| App 内上报至 Sentry | < 80% 持续 30min → P1 | 每日 72 分钟失败预算 |
| **冷启动性能** | P95 < 2s（中端 Android）| DevTools manual measurement | > 3s → P2 | 按版本验收 |
| **列表滑动流畅度** | P95 >= 55fps | DevTools manual measurement | < 30fps → P2 | 按版本验收 |
| **新闻 API 成功率** | 90%（每日）| App 内上报至 Sentry | < 70% 持续 30min → P1 | 每日 2.4 小时失败预算 |
| **评分算法准确率** | > 40%（月度累计）| 本地 SQLite 统计 | < 40% → 算法重构评审 | -- |

### 11.2 详细 SLO 定义

#### SLO-001: App 稳定性

```markdown
目标：Crash-free session rate >= 99.5%（月度滚动窗口）
衡量：
  sum(session_without_crash) / sum(total_sessions) >= 0.995
告警：
  - P1: 连续 2 天 crash-free rate < 99%
  - P0: 单日 crash-free rate < 97% 或 24h 内 > 50 次 crash
错误预算：
  - 每月允许 0.5% 的 session 有 crash ≈ 约 3.6 小时等效不可用
  - 当月已消耗 > 50% 预算 → 暂停非紧急发布
```

#### SLO-002: 行情 API 成功率

```markdown
目标：东方财富行情 API 成功率 >= 95%（每日）
衡量：
  count(api_market.success == true) / count(api_market.*) >= 0.95
数据来源：
  App 内每次 API 调用后上报 event（采样率 1%，仅失败上报全量）
告警：
  - P1: success_rate < 80% 持续 30 分钟
  - 连续 3 天低于 90% → 启动备用数据源评估
降级：
  success_rate < 70% → 自动切换为缓存优先模式（不再主动拉取）
```

#### SLO-003: 冷启动时间

```markdown
目标：App 冷启动 P95 < 2s（中端 Android 设备，骁龙 778G）
衡量：手动使用 Flutter DevTools profiling 测量（每个版本发布前执行）
验收：热重载不计入，仅计算 `flutter run --release` 的 cold start
告警：P95 > 3s → P2（在下一版本修复）
```

### 11.3 错误预算消耗告警

每月 GitHub Actions 自动检查错误预算：

```yaml
# .github/workflows/slo-budget-check.yml
- name: Check error budget
  run: |
    # 从 Sentry API 获取本月 crash-free rate
    CRASH_FREE=$(curl -s "https://sentry.io/api/0/organizations/stockpilot/releases/stats/" \
      -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" | jq '.[0].crashFreeRate')
    if (( $(echo "$CRASH_FREE < 0.995" | bc -l) )); then
      echo "⚠️ Crash-free rate ${CRASH_FREE} 低于 SLO 目标 99.5%"
      echo "请暂停非紧急发布，优先修复崩溃问题"
    fi
```

---

## 12. 相关文档

| 文档 | 路径 |
|------|------|
| PRD | `docs/prd.md` |
| 架构决策 | `docs/arch-decision.md` |
| 运维手册 | `docs/runbook.md` |
| Sentry 配置 | App 内 `lib/core/instrumentation.dart` |
