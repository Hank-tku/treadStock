# S1: 策略回测引擎 BacktestEngine

## 目标
用历史K线数据模拟策略运行，输出胜率/累计收益/最大回撤/夏普比等关键指标。

## 架构设计

### 新增文件
1. `lib/features/strategy/domain/backtest_engine.dart` — 核心回测引擎
2. `lib/features/strategy/domain/backtest_models.dart` — 回测数据模型
3. `lib/features/strategy/presentation/backtest_page.dart` — 回测UI页面
4. `lib/features/strategy/presentation/backtest_provider.dart` — 回测状态管理
5. `test/unit/backtest_engine_test.dart` — 单元测试

### 修改文件
1. `lib/core/router/app_router.dart` — 添加回测页路由
2. `lib/features/strategy/presentation/strategy_detail_page.dart` — 添加"回测"入口按钮

## 数据模型

### BacktestConfig
```
- strategyId: String
- stockCode: String
- startDate: DateTime (回测起始日)
- endDate: DateTime (回测结束日)
- initialCapital: double (初始资金，默认 100000)
- positionSize: double (每次买入比例，默认 0.3 = 30%)
- holdingDays: int (默认持仓天数，5天)
- stopLossPct: double? (止损百分比，默认 null 不止损)
- takeProfitPct: double? (止盈百分比，默认 null 不止盈)
```

### BacktestTrade
```
- entryDate: DateTime
- entryPrice: double
- exitDate: DateTime?
- exitPrice: double?
- exitReason: ExitReason (holding_expired / stop_loss / take_profit / signal_exit)
- pnlPct: double? (盈亏百分比)
- holdingDays: int?
```

### BacktestResult
```
- config: BacktestConfig
- trades: List<BacktestTrade>
- totalReturn: double (总收益率 %)
- annualizedReturn: double (年化收益率 %)
- winRate: double (胜率 0.0-1.0)
- profitFactor: double (盈亏比)
- maxDrawdown: double (最大回撤 %)
- maxDrawdownDuration: int (最大回撤持续天数)
- sharpeRatio: double (夏普比率)
- totalTrades: int
- winCount: int
- lossCount: int
- avgWinPct: double (平均盈利 %)
- avgLossPct: double (平均亏损 %)
- bestTrade: double (最佳单笔收益 %)
- worstTrade: double (最差单笔收益 %)
- equityCurve: List<EquityPoint> (权益曲线)
```

### EquityPoint
```
- date: DateTime
- equity: double
- drawdown: double (当前回撤 %)
```

## 核心算法 (BacktestEngine)

### run() 流程
1. 从 API 获取 stockCode 的 startDate→endDate 日K线
2. 需要至少 maLongPeriod + buffer 条K线作为预热期
3. 逐日遍历K线（从预热期后开始）
4. 对每个交易日：
   a. 计算当前指标值（MA/BOLL/RSI/KDJ 等）
   b. 如果当前无持仓 → 检查入场规则是否触发
      - 规则型策略：RuleEngine.evaluate()
      - 权重型策略：ScoringService.scoreStock() >= threshold
   c. 如果当前有持仓 → 检查退出条件
      - 持仓天数 >= holdingDays → 平仓
      - stopLoss 触发 → 止损平仓
      - takeProfit 触发 → 止盈平仓
      - 退出规则触发（如有）→ 平仓
   d. 记录权益曲线点
5. 如果最后仍有持仓 → 用最后一日收盘价强制平仓
6. 计算统计指标

### 指标计算
复用已有的 `IndicatorCalculator`：
- MA(short/long)
- BOLL(period, stdDev)
- RSI(14)
- KDJ(9,3,3)
- 成交量指标

### 统计计算
- **胜率** = 盈利次数 / 总交易次数
- **盈亏比** = 平均盈利 / 平均亏损绝对值
- **最大回撤** = max((peak - trough) / peak)
- **夏普比率** = (平均日收益 - 无风险利率) / 日收益标准差 × sqrt(252)
- **年化收益** = (1 + 总收益率) ^ (252/交易天数) - 1

## UI 设计

### BacktestPage
- 顶部：策略名 + 股票代码
- 配置区：日期范围选择 + 资金/仓位/持仓天数/止损止盈
- 结果区（回测完成后）：
  - 核心指标卡片（总收益率/胜率/最大回撤/夏普比率）
  - 权益曲线图（CustomPainter 绘制）
  - 交易记录列表（可展开每笔交易详情）

### 入口
策略详情页 → 右上角"回测"按钮 → 选择股票 → 开始回测

## 约束
- 不引入新依赖，图表用 CustomPainter
- 回测是同步计算（数据量不大），不需要 isolate
- K线数据用已有的 `StockApiService.fetchStockKline()`
- 复用已有的 `RuleEngine` 和 `StrategyScoringService`

## 测试计划
- 纯计算逻辑的单元测试（不需要 widget 测试）
- 用固定K线数据验证统计计算正确性
- 边界情况：0 trades / 1 trade / 全胜 / 全亏
- 权益曲线回撤计算验证
