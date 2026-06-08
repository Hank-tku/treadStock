import 'dart:math';

import '../../analysis/domain/analysis_engine.dart';
import '../../stock/domain/stock_models.dart';
import 'rule_engine.dart';
import 'strategy_models.dart';
import 'backtest_models.dart';

/// Core backtest engine that simulates strategy execution over historical kline data.
///
/// Supports both rule-based strategies (SignalRule) and weighted strategies (AnalysisEngine scoring).
/// Produces a [BacktestResult] with comprehensive performance metrics.
class BacktestEngine {
  /// Run a backtest simulation.
  ///
  /// [klines] - Historical daily kline data (caller is responsible for fetching).
  /// [strategy] - The strategy to simulate.
  /// [config] - Backtest configuration parameters.
  /// [stockCode] - Stock code for labeling results.
  /// [analysisEngine] - Required for weighted strategy scoring.
  BacktestResult run({
    required List<DailyKline> klines,
    required Strategy strategy,
    required BacktestConfig config,
    required String stockCode,
    required AnalysisEngine analysisEngine,
  }) {
    if (klines.isEmpty) {
      return BacktestResult(
        strategyName: strategy.name,
        stockCode: stockCode,
        trades: const [],
        startDate: null,
        endDate: null,
        barsProcessed: 0,
      );
    }

    // Determine warmup period
    final warmup = max(config.warmupBars, strategy.maLongPeriod);
    if (klines.length <= warmup) {
      return BacktestResult(
        strategyName: strategy.name,
        stockCode: stockCode,
        trades: const [],
        startDate: klines.first.date,
        endDate: klines.last.date,
        barsProcessed: klines.length,
      );
    }

    // State tracking
    final trades = <BacktestTrade>[];
    double cash = config.initialCapital;
    int? entryBarIndex;
    double? entryPrice;
    DateTime? entryDate;

    // Trailing stop state
    double trailingPeak = 0.0;
    bool trailingActivated = false;

    // Equity curve tracking
    double peakEquity = config.initialCapital;
    double maxDrawdown = 0.0;

    // Iterate from warmup to end
    for (var i = warmup; i < klines.length; i++) {
      final currentPrice = klines[i].close;
      final currentDate = klines[i].date;

      if (entryBarIndex != null) {
        // ── IN POSITION: check exit conditions ──
        // entryPrice and entryDate are guaranteed non-null when entryBarIndex != null
        final ep = entryPrice!;
        final ed = entryDate!;
        final pnlPct = (currentPrice - ep) / ep;
        ExitReason? exitReason;

        // Update trailing stop peak
        if (config.hasTrailingStop) {
          if (!trailingActivated) {
            // Check if activation threshold reached
            if (pnlPct >= config.trailingStopActivationPct!) {
              trailingActivated = true;
              trailingPeak = currentPrice;
            }
          } else {
            // Update peak
            if (currentPrice > trailingPeak) {
              trailingPeak = currentPrice;
            }
          }
        }

        // Stop loss
        if (config.stopLossPct != null && pnlPct <= config.stopLossPct!) {
          exitReason = ExitReason.stopLoss;
        }
        // Trailing stop
        if (exitReason == null && trailingActivated && config.hasTrailingStop) {
          final dropFromPeak = (trailingPeak - currentPrice) / trailingPeak;
          if (dropFromPeak >= config.trailingStopDistancePct!) {
            exitReason = ExitReason.trailingStop;
          }
        }
        // Take profit
        if (exitReason == null &&
            config.takeProfitPct != null &&
            pnlPct >= config.takeProfitPct!) {
          exitReason = ExitReason.takeProfit;
        }
        // Exit rules (rule-based strategies)
        if (exitReason == null &&
            strategy.exitRules != null &&
            strategy.exitRules!.isNotEmpty) {
          final subKlines = klines.sublist(0, i + 1);
          final result = RuleEngine.evaluate(
            klines: subKlines,
            entryRules: const [],
            exitRules: strategy.exitRules!,
            exitGroups: strategy.exitGroups,
          );
          if (result.exitTriggered) {
            exitReason = ExitReason.signalExit;
          }
        }
        // Force close at end of data
        if (exitReason == null && i == klines.length - 1) {
          exitReason = ExitReason.endOfData;
        }

        if (exitReason != null) {
          // Close the trade
          final shares = _calcShares(
            config.initialCapital * config.positionSize,
            ep,
            config,
          );
          final exitSlippage = config.slippage;
          final exitPrice = currentPrice - exitSlippage;
          final grossProfit = (exitPrice - ep) * shares;
          final entryCost = ep * shares;
          final entryCommission = entryCost * config.commissionRate;
          final exitCommission = exitPrice * shares * config.commissionRate;
          final stampTax = exitPrice * shares * config.stampTaxRate;
          final netProfit =
              grossProfit - entryCommission - exitCommission - stampTax;
          final returnPct = netProfit / entryCost;

          trades.add(BacktestTrade(
            direction: TradeDirection.long,
            entryBarIndex: entryBarIndex,
            entryDate: ed,
            entryPrice: ep,
            exitBarIndex: i,
            exitDate: currentDate,
            exitPrice: exitPrice,
            shares: shares,
            grossProfit: grossProfit,
            commission: entryCommission + exitCommission,
            stampTax: stampTax,
            netProfit: netProfit,
            returnPct: returnPct,
            exitReason: exitReason,
          ));

          cash += netProfit;
          entryBarIndex = null;
          entryPrice = null;
          entryDate = null;
          trailingActivated = false;
          trailingPeak = 0.0;
        }
      } else {
        // ── NO POSITION: check entry conditions ──
        bool shouldEnter = false;

        if (strategy.isRuleBased) {
          // Rule-based: all entry rules must pass (flat OR groups)
          final subKlines = klines.sublist(0, i + 1);
          final result = RuleEngine.evaluate(
            klines: subKlines,
            entryRules: strategy.entryRules ?? [],
            entryGroups: strategy.entryGroups,
            exitRules: const [],
          );
          shouldEnter = result.entryTriggered;
        } else {
          // Weighted strategy: score >= threshold
          final subKlines = klines.sublist(0, i + 1);
          final score =
              analysisEngine.calculateScoreForStrategy(subKlines, strategy);
          shouldEnter = score.score >= strategy.recommendThreshold;
        }

        if (shouldEnter && (config.maxTrades == 0 || trades.length < config.maxTrades)) {
          entryBarIndex = i;
          entryPrice = klines[i].close + config.slippage;
          entryDate = currentDate;
          trailingPeak = klines[i].close;
          trailingActivated = false;
        }
      }

      // Track equity curve peak/drawdown
      final currentEquity = cash +
          (entryBarIndex != null && entryPrice != null
              ? (currentPrice - entryPrice) *
                  _calcShares(
                    config.initialCapital * config.positionSize,
                    entryPrice,
                    config,
                  )
              : 0);
      if (currentEquity > peakEquity) peakEquity = currentEquity;
      final dd = peakEquity > 0
          ? (currentEquity - peakEquity) / peakEquity
          : 0.0;
      if (dd < maxDrawdown) maxDrawdown = dd;
    }

    return _computeStats(
      trades: trades,
      config: config,
      maxDrawdown: maxDrawdown,
      strategyName: strategy.name,
      stockCode: stockCode,
      startDate: klines[warmup].date,
      endDate: klines.last.date,
      barsProcessed: klines.length - warmup,
    );
  }

  /// Calculate number of shares (rounded down to 100-lot).
  int _calcShares(double capital, double price, BacktestConfig config) {
    if (price <= 0) return 0;
    final adjustedCapital = capital - capital * config.commissionRate;
    final rawShares = (adjustedCapital / price).floor();
    return (rawShares ~/ 100) * 100; // A-share 100-share lots
  }

  /// Compute all statistics from completed trades.
  BacktestResult _computeStats({
    required List<BacktestTrade> trades,
    required BacktestConfig config,
    required double maxDrawdown,
    required String strategyName,
    required String stockCode,
    required DateTime startDate,
    required DateTime endDate,
    required int barsProcessed,
  }) {
    if (trades.isEmpty) {
      return BacktestResult(
        strategyName: strategyName,
        stockCode: stockCode,
        trades: const [],
        startDate: startDate,
        endDate: endDate,
        barsProcessed: barsProcessed,
      );
    }

    final totalTrades = trades.length;
    final wins = trades.where((t) => t.isWin).toList();
    final losses = trades.where((t) => !t.isWin).toList();
    final winCount = wins.length;
    final loseCount = losses.length;
    final winRate = totalTrades > 0 ? winCount / totalTrades : 0.0;

    final totalNetProfit = trades.fold(0.0, (sum, t) => sum + t.netProfit);
    final totalReturnPct =
        totalNetProfit / config.initialCapital * 100;

    // Annualized return
    final calendarDays = endDate.difference(startDate).inDays;
    final years = calendarDays / 365.0;
    final annualizedReturn = years > 0
        ? (pow(1 + totalReturnPct / 100, 1 / years) - 1) * 100
        : 0.0;

    // Profit factor
    final totalWins = wins.fold(0.0, (sum, t) => sum + t.netProfit);
    final totalLosses = losses.fold(0.0, (sum, t) => sum + t.netProfit.abs());
    final profitFactor = totalLosses > 0 ? totalWins / totalLosses : double.infinity;

    // Average holding days
    final avgHoldingDays = trades
            .map((t) => t.exitBarIndex - t.entryBarIndex)
            .fold(0.0, (sum, d) => sum + d) /
        totalTrades;

    // Sharpe ratio (simplified: using trade returns)
    final returns = trades.map((t) => t.returnPct).toList();
    final sharpeRatio = _calcSharpe(returns);

    // Consecutive wins/losses
    int maxConsecWins = 0, maxConsecLosses = 0;
    int consecWins = 0, consecLosses = 0;
    for (final t in trades) {
      if (t.isWin) {
        consecWins++;
        consecLosses = 0;
        if (consecWins > maxConsecWins) maxConsecWins = consecWins;
      } else {
        consecLosses++;
        consecWins = 0;
        if (consecLosses > maxConsecLosses) maxConsecLosses = consecLosses;
      }
    }

    // Best/worst trade
    final bestTradePct = trades
        .map((t) => t.returnPct)
        .reduce((a, b) => a > b ? a : b);
    final worstTradePct = trades
        .map((t) => t.returnPct)
        .reduce((a, b) => a < b ? a : b);

    // Average win/loss percentage
    final avgWinPct =
        wins.isNotEmpty ? wins.map((t) => t.returnPct).reduce((a, b) => a + b) / wins.length : 0.0;
    final avgLossPct =
        losses.isNotEmpty ? losses.map((t) => t.returnPct).reduce((a, b) => a + b) / losses.length : 0.0;

    return BacktestResult(
      strategyName: strategyName,
      stockCode: stockCode,
      trades: trades,
      totalTrades: totalTrades,
      winCount: winCount,
      loseCount: loseCount,
      winRate: winRate,
      totalNetProfit: totalNetProfit,
      totalReturnPct: totalReturnPct,
      maxDrawdownPct: maxDrawdown * 100,
      annualizedReturn: annualizedReturn.toDouble(),
      avgHoldingDays: avgHoldingDays,
      profitFactor: profitFactor.isFinite ? profitFactor : 999.99,
      sharpeRatio: sharpeRatio,
      maxConsecutiveWins: maxConsecWins,
      maxConsecutiveLosses: maxConsecLosses,
      avgWinPct: avgWinPct * 100,
      avgLossPct: avgLossPct * 100,
      bestTradePct: bestTradePct * 100,
      worstTradePct: worstTradePct * 100,
      startDate: startDate,
      endDate: endDate,
      barsProcessed: barsProcessed,
    );
  }

  /// Simplified Sharpe ratio from a list of trade returns.
  double _calcSharpe(List<double> returns) {
    if (returns.length < 2) return 0.0;
    final n = returns.length;
    final mean = returns.fold(0.0, (s, r) => s + r) / n;
    final variance =
        returns.fold(0.0, (s, r) => s + pow(r - mean, 2)) / n;
    final stdDev = sqrt(variance);
    if (stdDev == 0) return 0.0;
    // Annualize: assume ~50 trades/year
    return (mean / stdDev) * sqrt(50);
  }
}
