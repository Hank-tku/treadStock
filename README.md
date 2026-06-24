# 股势 TrendStock

> A 股波段分析与决策辅助工具 —— 纯客户端，不收集任何用户数据，关注列表和策略配置仅存储在本地设备。

一款帮助 A 股散户快速完成每日选股扫描、策略复盘与个股决策辅助应用。所有计算在本地完成，关注列表持久化在设备 SQLite，无需账号、无云端同步。

## 核心功能

### 📈 推荐
- 按策略分组展示每日推荐标的，维度筛选（全部 / 波段低位 / 重点关注 / 观望）
- 顶部概览：策略统计、市场情绪、复盘告警
- 收盘前后预测文案自动切换（15:00 盘中预测 / 收盘预测下一交易日）

### ⭐ 关注
- 本地关注列表，支持搜索、置顶、滑动删除（含撤销）
- 下跌预警提醒（技术面触发 + 自定义价格阈值）
- 关注列表铃铛实时反映预警状态

### 💡 策略
- 自定义策略参数（MA/布林带/量能/趋势权重）或使用预设模板
- 策略回测（单股历史回测，含止损/止盈/夏普比率）
- 策略调优（网格搜索最优参数组合）
- 策略对比（多策略命中率/健康度/收益率并排）
- 每日自动复盘（后台生成 Checklist + 持久化）
- 使用策略生成模版，复制AI工具，用自然语言生成策略

### 📊 个股详情
- K线图
- 技术面评分与决策信号
- 价格提醒配置
- 最新新闻


## 平台支持

| 平台 | 状态 |
|---|---|
| Android | ✅ 已发布（APK 分包：arm64 / arm / x86_64） |
| macOS | ✅ 可运行 |
| Windows | ✅ CI 自动构建（MSIX + ZIP） |
| iOS | ⏸ 暂未发布（需付费 Apple Developer 账号签名） |

## 快速开始

```bash
# 安装依赖
flutter pub get

# Drift 代码生成（改表结构后执行）
dart run build_runner build --delete-conflicting-outputs

# 运行
flutter run

# 测试
flutter analyze
flutter test
```

## 下载安装

前往 [Releases](../../releases) 页面下载对应平台的安装包：
- **Android**：app-arm64-v8a-release.apk（现代手机推荐）/ app-armeabi-v7a-release.apk（旧设备）
- **Windows**：stockpilot-windows-x64.zip（免安装，解压运行）/ stockpilot-windows-x64.msix（需开发者模式）
- **MacOS**

## 数据与免责声明

- **本应用仅供学习研究，不构成任何投资建议。**

## License

本项目仅用于个人学习与技术研究。
