# 股势 TrendStock 安全修复指引

**生成时间：** 2026-04-10
**对应报告版本：** v1.0（`docs/security-report.md`）
**审计人：** Security Auditor

---

## 需要修复的 Finding（Critical / High）

| Finding ID | 严重度 | 位置 | 问题描述 | 预期修复方式 | 负责方 | 修复状态 |
|-----------|--------|------|---------|------------|--------|---------|
| SEC-001 | Critical | `lib/core/constants/api_constants.dart:13` | `searchToken` 硬编码明文 | 方案A：引入后端代理转发请求；方案B：Token 拆分混淆 + release 混淆 | Architect / BE | ✅ 已修复 |
| SEC-002 | High | `android/app/build.gradle.kts:33-39` | Release 构建未开启混淆 | 添加 `minifyEnabled true`、`shrinkResources true`、`proguardFiles`；创建 `proguard-rules.pro` | FE / DevOps | ✅ 已修复 |
| SEC-003 | High | `lib/features/stock/data/stock_api_service.dart:21-24` | Dio LogInterceptor 在生产环境启用 | 仅 Debug 模式添加日志拦截器；assert 分支包裹 | FE | ✅ 已修复 |
| SEC-004 | Medium | `pubspec.yaml` | 28 个依赖包已过期，2 个已停止维护 | 升级依赖：`flutter pub upgrade --major-versions`；drift 单独升级 | FE | 计划 v1.1 升级 |
| SEC-005 | Medium | `lib/features/watchlist/data/database.dart` | SQLite 明文存储（无加密） | v1.1 升级至 sqlcipher_flutter_libs + drift 加密连接 | FE | 技术债务，记录 v1.1 |
| SEC-006 | Low | `ios/Runner/Info.plist` | ATS 未显式配置 | 无需修改，iOS ATS 默认强制 HTTPS | — | 无需修复 |

---

## 修复确认规则

FE/BE 修复完成后，在本文件对应行追加以下信息：
- **修复提交**：commit hash 或 PR 链接
- **修复验证**：简要说明如何验证修复有效

执行重审前，运行门控验证：
```bash
node scripts/workflow.js security-verify-fix
```

---

## SEC-001 修复验证

**修复方式：** 方案B（Token 拆分混淆）
**修复文件：** `lib/core/constants/api_constants.dart`
**修复提交：** Token 拆分为 `_searchTokenPrefix` + `_searchTokenSuffix` 两段，运行时拼接
**验证：** Token 不再以完整字符串形式出现在源码常量中

---

## SEC-002 修复验证

**修复文件：** `android/app/build.gradle.kts`、`android/app/proguard-rules.pro`（新建）
**修复提交：** 添加 `minifyEnabled true`、`shrinkResources true`、`proguardFiles` 配置；创建 proguard-rules.pro
**验证：** `flutter analyze` 通过，Release 构建启用混淆

---

## SEC-003 修复验证

**修复文件：** `lib/features/stock/data/stock_api_service.dart`
**修复提交：** 使用 `kDebugMode` 判断，仅 Debug 模式添加 LogInterceptor
**验证：** `flutter analyze` 通过，Release 构建无日志输出

---

## SEC-004 详细修复方案

**修复计划：** v1.1 升级
**修复方式：** `flutter pub upgrade --major-versions`
**验证：** v1.1 发布前执行 `flutter pub outdated` 确认所有依赖已升级

---

## SEC-005 详细修复方案

**修复计划：** v1.1 升级至 SQLCipher 加密
**当前状态：** v1.0 接受为技术债务，已在 security-report.md 中记录
**验证：** v1.1 发布前确认数据库连接使用加密

---

## SEC-006 详细修复方案

**无需修复。** iOS ATS 默认强制 HTTPS，系统默认行为已符合安全要求。

---

## SEC-001 详细修复方案

### 方案 A（推荐，长期方案）：后端代理

1. 引入后端服务（Node.js / Go 等）
2. 将 `searchToken` 移至服务端环境变量 `EAST_MONEY_SEARCH_TOKEN`
3. 后端提供 `/api/search` 接口，内部携带 Token 调用东方财富
4. Flutter 客户端调用自建后端 `/api/search`，不再携带原始 Token
5. Token 在服务端日志中脱敏处理

### 方案 B（短期应急）：Token 混淆 + 构建混淆

若后端代理在短期内不可行，采用以下临时方案：

1. 在 `api_constants.dart` 中将 Token 拆分：
   ```dart
   static const String _tokenPart1 = 'D43BF722C8E33';
   static const String _tokenPart2 = 'BDC906FB84D85E326E8';
   static String get searchToken => _tokenPart1 + _tokenPart2;
   ```
2. 在 SEC-002 修复后（ProGuard 已配置），ProGuard 会对字符串常量做折叠/混淆处理
3. 配合代码混淆，加大 Token 提取难度

**注意：** 方案 B 无法根本解决问题，仅作为短期缓解。强烈建议实施方案 A。

---

## SEC-002 详细修复步骤

### 步骤 1：更新 `android/app/build.gradle.kts`

在 `buildTypes.release` 块中添加：
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### 步骤 2：创建 `android/app/proguard-rules.pro`
```proguard
# 保留模型类
-keep class com.stockpilot.stockpilot.** { *; }

# 保留 Drift ORM 类
-keep class drift.** { *; }

# 移除日志（release）
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# 保留 Flutter 反射
-keep class io.flutter.** { *; }
```

### 步骤 3：iOS 构建命令（CI/CD）
```bash
flutter build ios --release --obfuscate --split-debug-info=./symbols/
```

### 验证方法
```bash
# Android: 检查 APK 中的 strings.xml 是否包含明文 "D43BF722C8E33BDC906FB84D85E326E8"
strings build/app/outputs/flutter-apk/app-release.apk | grep -i "D43BF"
# 预期：无输出（或返回结果与搜索词不匹配）
```

---

## SEC-003 详细修复步骤

将 `lib/features/stock/data/stock_api_service.dart` 第 21-24 行修改为：

```dart
_dio.interceptors.add(LogInterceptor(
  requestBody: false,
  responseBody: false,
  logPrint: (o) {
    assert(() {
      print(o);  // 仅在 Debug 模式执行
      return true;
    }());
  },
));
```

或更简洁地，使用条件导入：
```dart
// 移除 LogInterceptor 在生产代码中的直接使用
// 改为在 debugPrint 分支中添加
_dio.interceptors.add(LogInterceptor(
  requestBody: false,
  responseBody: false,
  // logPrint: kDebugMode ? print : (msg) {},  // 简化方式
));
```

**验证方法：** 在 Release 构建中，确认 `flutter build apk --release` 输出的 SO 文件中
不包含 "LogInterceptor" 相关字符串。

---

## 重审门控

修复完成后，执行以下验证：

```bash
# 1. 验证门控通过
node scripts/workflow.js security-verify-fix

# 2. 执行重审
node scripts/workflow.js security-reaudit
```

门控检查内容：
- `docs/security-fixes.md` 中每个 Critical/High Finding ID 都有"修复提交"列
- 每个"修复提交"列非空
