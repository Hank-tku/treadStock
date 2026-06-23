# 更新日志

本项目所有重要变更记录于此文件。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/)。

## [0.1.3] - 2026-06-22

### 新增
- **合并看板到推荐**：底部导航从 4 tab 精简为 3 tab（推荐/关注/策略）。推荐页顶部新增"概览 header"，含策略统计、市场情绪、复盘告警
- **每日自动复盘**：新增 ReviewScheduler + workmanager 后台任务，每个启用策略每日自动生成复盘（Checklist + 持久化），完成时推送本地通知。前台 resumed 时也触发一次（按日去重）
- **策略调优股票选择**：调优页支持选择/更换调优标的（此前入口传空 stockCode 导致功能不可用）
- **详情页策略对比入口**：策略详情页 header 新增"对比"按钮，可直接跳转对比页

### 修复
- **详情页新闻为空**：修正东方财富 search-api 响应解析（顶层 key `Data` → `result`；date 字段从毫秒 int 改为字符串解析），并移除静默 catch 吞错改为 debugPrint
- **FakeStockApiService 测试债**：补全 fetchStockKline 覆盖（此前缺失导致推荐页作为初始页时触发真实网络请求）

### 变更
- 底部导航移除"看板"tab，其策略统计/情绪/复盘告警迁移至推荐页 header
- DashboardNotifier 改为构造时 autoLoad（默认 true），测试可传 autoLoad: false

### 文档
- 新增 CHANGELOG.md（此前无）
- 更新 prd.md / interaction-spec.md：tab 结构从 4 tab 更正为 3 tab
- 修正 api-spec.md 新闻接口描述（删除不存在的 NewsService/news_cache，补正 endpoint 与字段映射）

---

## [0.2.0] - 2026-06-22

### 新增
- **提醒功能接通**：flutter_local_notifications + workmanager 后台调度，技术面预警（跌破MA20/布林下轨/连续放量下跌）+ 用户可配价格阈值提醒 + 免打扰时段（22:00-08:00）+ 每日去重 + 关注列表铃铛激活
- **详情页 K 线图**：k_chart_plus 蜡烛图 + MA20/MA60 + 布林带 + 成交量副图 + 长按 tooltip + 周期切换（60/120/250 天），A 股红涨绿跌色适配
- **暗色模式**：SemanticColors ThemeExtension（light/dark），~400 处消费点迁移到 context.sc，默认跟随系统 + 手动切换（跟随/浅色/深色），A 股固定色保持不变
- **StockFilter 市值/行业筛选**：扩东财 fields 带 f20(总市值)/f100(行业)，筛选编辑卡加市值 Range + 行业多选，null 放行（新浪回退兼容）

### 修复
- **命中率定义收紧**：isHit 从 `> 0%` 改为 `> 0.5%`（覆盖交易成本 + 小幅正向 margin），避免涨 0.01% 虚高命中率
- **规则策略子分映射**：规则策略四因子全置 0（不再把 MACD/RSI 错误塞进 maScore/bollScore），reason 加 [规则信号] 前缀
- **环境降权记录一致性**：recordRecommendations 改用降权后分数，与 UI 展示一致
- **详情页 alert 假开关**：未关注时提示先加关注，不再误导
- **详情页主数据错误态**：不再静默吞错，新增错误态 + 重试按钮
- **统一红涨绿跌色**：_PredictionTag 涨跌色统一到 StockColors
- **情绪色统一**：DecisionLabelChip 内联色板删除，复用 StockColors
- **右滑删关注 Undo**：删除后 5 秒内可撤销
- **死代码清理**：stock_detail_route.dart + 2 个死 provider + 旧 RecommendationNotifier

---

## [0.1.2] - 2026-06

### 新增
- 15:00 前预测功能（StockPrediction 模型 + 推荐列表展示）
- 策略独立股票池 + 市场环境感知 + 关注体验优化（E501-E503）
- F104 信任评级 + F105 回测摘要 + F106 命中率趋势 + F108 创建引导 + F109 决策气泡
- M1 决策信号引擎 + 新手引导 + 决策看板
- F006-F009 策略功能完善 + API 重试增强
