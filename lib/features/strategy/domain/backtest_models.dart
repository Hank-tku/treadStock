// Data models for the strategy backtest engine.
//
// Backtest runs a strategy over historical kline data, simulating entry/exit
// signals on each bar and tracking PnL for every completed trade.

/// Configuration for a backtest run.
class BacktestConfig {
  /// Initial capital in yuan.
  final double initialCapital;

  /// Position size per trade as a fraction (0 < size <= 1.0).
  final double positionSize;

  /// Commission rate per trade (single-sided).
  final double commissionRate;

  /// Stamp tax rate (sell side only, A-share convention).
  final double stampTaxRate;

  /// Slippage in yuan per share.
  final double slippage;

  /// Number of bars used as the warm-up window before signals are evaluated.
  final int warmupBars;

  /// Maximum number of trades to keep (0 = unlimited).
  final int maxTrades;

  /// Stop-loss threshold as a fraction (e.g. -0.05 = -5%). null = no stop-loss.
  final double? stopLossPct;

  /// Take-profit threshold as a fraction (e.g. 0.10 = +10%). null = no take-profit.
  final double? takeProfitPct;

  /// Trailing stop activation threshold as a fraction (e.g. 0.05 = +5%).
  /// Once profit reaches this level, the trailing stop is activated.
  /// null = no trailing stop.
  final double? trailingStopActivationPct;

  /// Trailing stop distance as a fraction from peak (e.g. 0.03 = 3%).
  /// Once activated, exit when price drops this % from the peak.
  final double? trailingStopDistancePct;

  const BacktestConfig({
    this.initialCapital = 100000,
    this.positionSize = 1.0,
    this.commissionRate = 0.0003,
    this.stampTaxRate = 0.001,
    this.slippage = 0.0,
    this.warmupBars = 60,
    this.maxTrades = 0,
    this.stopLossPct,
    this.takeProfitPct,
    this.trailingStopActivationPct,
    this.trailingStopDistancePct,
  });

  /// Whether trailing stop is configured.
  bool get hasTrailingStop =>
      trailingStopActivationPct != null &&
      trailingStopDistancePct != null;
}

/// Represents a single simulated trade within a backtest.
class BacktestTrade {
  /// Trade direction.
  final TradeDirection direction;

  /// Bar index at which entry occurred.
  final int entryBarIndex;

  /// Entry date.
  final DateTime entryDate;

  /// Entry price (after slippage).
  final double entryPrice;

  /// Bar index at which exit occurred.
  final int exitBarIndex;

  /// Exit date.
  final DateTime exitDate;

  /// Exit price (after slippage).
  final double exitPrice;

  /// Number of shares.
  final int shares;

  /// Gross profit (exit - entry) × shares.
  final double grossProfit;

  /// Commission paid (entry + exit).
  final double commission;

  /// Stamp tax paid (sell side).
  final double stampTax;

  /// Net profit after costs.
  final double netProfit;

  /// Return percentage = netProfit / (entryPrice × shares).
  final double returnPct;

  /// Reason the trade was closed.
  final ExitReason exitReason;

  const BacktestTrade({
    required this.direction,
    required this.entryBarIndex,
    required this.entryDate,
    required this.entryPrice,
    required this.exitBarIndex,
    required this.exitDate,
    required this.exitPrice,
    required this.shares,
    required this.grossProfit,
    required this.commission,
    required this.stampTax,
    required this.netProfit,
    required this.returnPct,
    required this.exitReason,
  });

  /// Whether this trade was profitable.
  bool get isWin => netProfit > 0;
}

/// Aggregated performance statistics for a backtest run.
class BacktestResult {
  /// The strategy name that was backtested.
  final String strategyName;

  /// Stock code.
  final String stockCode;

  /// All completed trades.
  final List<BacktestTrade> trades;

  /// Total number of completed trades.
  final int totalTrades;

  /// Number of winning trades.
  final int winCount;

  /// Number of losing trades.
  final int loseCount;

  /// Win rate (0.0 – 1.0).
  final double winRate;

  /// Total net profit across all trades.
  final double totalNetProfit;

  /// Cumulative return percentage.
  final double totalReturnPct;

  /// Maximum drawdown percentage (always ≤ 0).
  final double maxDrawdownPct;

  /// Annualized return (0.0 if not enough data to annualize).
  final double annualizedReturn;

  /// Average holding period in trading days.
  final double avgHoldingDays;

  /// Profit factor = totalWins / |totalLosses| (inf if no losses).
  final double profitFactor;

  /// Sharpe ratio (0.0 if fewer than 2 trades).
  final double sharpeRatio;

  /// Maximum consecutive wins.
  final int maxConsecutiveWins;

  /// Maximum consecutive losses.
  final int maxConsecutiveLosses;

  /// Average win return percentage.
  final double avgWinPct;

  /// Average loss return percentage (negative number).
  final double avgLossPct;

  /// Best single-trade return percentage.
  final double bestTradePct;

  /// Worst single-trade return percentage.
  final double worstTradePct;

  /// Start date of the data window used.
  final DateTime? startDate;

  /// End date of the data window used.
  final DateTime? endDate;

  /// Number of kline bars processed.
  final int barsProcessed;

  const BacktestResult({
    required this.strategyName,
    required this.stockCode,
    required this.trades,
    this.totalTrades = 0,
    this.winCount = 0,
    this.loseCount = 0,
    this.winRate = 0.0,
    this.totalNetProfit = 0.0,
    this.totalReturnPct = 0.0,
    this.maxDrawdownPct = 0.0,
    this.annualizedReturn = 0.0,
    this.avgHoldingDays = 0.0,
    this.profitFactor = 0.0,
    this.sharpeRatio = 0.0,
    this.maxConsecutiveWins = 0,
    this.maxConsecutiveLosses = 0,
    this.avgWinPct = 0.0,
    this.avgLossPct = 0.0,
    this.bestTradePct = 0.0,
    this.worstTradePct = 0.0,
    this.startDate,
    this.endDate,
    this.barsProcessed = 0,
  });

  /// Quick health assessment string.
  String get healthLabel {
    if (totalTrades == 0) return '无交易';
    if (winRate >= 0.6 && profitFactor >= 1.5) return '策略表现良好';
    if (winRate >= 0.45 && profitFactor >= 1.0) return '策略表现中性';
    return '策略表现偏弱';
  }
}

/// Trade direction enum.
enum TradeDirection { long, short }

/// Exit reason enum.
enum ExitReason {
  /// Strategy exit signal triggered.
  signalExit,

  /// Stop-loss hit.
  stopLoss,

  /// Take-profit hit.
  takeProfit,

  /// Trailing stop hit.
  trailingStop,

  /// End of data reached; forced close.
  endOfData,
}
