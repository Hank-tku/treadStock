# 产品方向优化计划

## 目标
基于 gstack 产品分析，持续优化股势 TrendStock，直到用户喊停。

## Phase 3: 产品级优化

### P1: K线图表可视化 ⭐ 最高优先级
- **问题**: 股票APP没有K线图，用户无法直观看到走势
- **方案**: CustomPainter 实现 K线图 widget，支持：
  - 蜡烛图 (OHLCV)
  - MA5/MA20/MA60 均线叠加
  - 布林带叠加
  - 成交量柱状图
  - 手势：双指缩放、拖拽平移、点击显示十字光标
  - 暗色/亮色主题适配
- **文件**: 
  - `lib/features/stock/presentation/widgets/kline_chart.dart` (新建)
  - `lib/features/stock/presentation/stock_detail_page.dart` (修改)
- **测试**: widget test for chart rendering

### P2: 策略回测引擎
- **问题**: 用户创建策略但无法验证历史表现
- **方案**: BacktestEngine 用历史K线数据模拟运行策略，输出收益率/胜率/最大回撤
- **文件**:
  - `lib/features/strategy/domain/backtest_engine.dart` (新建)
  - `lib/features/strategy/presentation/backtest_result_page.dart` (新建)
- **测试**: unit test for backtest calculations

### P3: 深色模式
- **问题**: 只有亮色主题
- **方案**: 扩展 AppTheme 添加 dark theme，StockColors 增加 dark 变体
- **文件**:
  - `lib/core/theme/app_colors.dart` (修改)
  - `lib/core/theme/app_theme.dart` (修改)
  - `lib/main.dart` (添加主题切换)

### P4: 下拉刷新
- **问题**: 列表页无 pull-to-refresh
- **方案**: 在 RecommendationTab、WatchlistTab、StrategyTab 添加 RefreshIndicator

### P5: 新手引导
- **问题**: 首次打开空列表，用户困惑
- **方案**: 添加 OnboardingPage，3步引导

### P6-P10: 后续迭代
- P6: 关注分组
- P7: 策略表现追踪统计
- P8: 板块热力图
- P9: 增强搜索（历史+热门）
- P10: 个股对比
