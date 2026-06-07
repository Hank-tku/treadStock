import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import '../domain/backtest_models.dart';

/// Page to display backtest results for a strategy.
class BacktestResultPage extends StatelessWidget {
  final BacktestResult result;

  const BacktestResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: ListView(
        children: [
          _buildHeader(context),
          _buildHealthBanner(),
          _buildCoreStats(),
          _buildPerformanceGrid(),
          if (result.trades.isNotEmpty) _buildTradeList(),
          const DisclaimerLabel(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, AppTheme.pagePadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: StockColors.gray700,
                  ),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                const Spacer(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('回测报告', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text(
                    '${result.strategyName} · ${result.stockCode}',
                    style: AppTextStyles.caption,
                  ),
                  if (result.startDate != null && result.endDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _dateRange,
                      style: AppTextStyles.caption.copyWith(
                        color: StockColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _dateRange {
    final start = '${result.startDate!.year}-${_two(result.startDate!.month)}-${_two(result.startDate!.day)}';
    final end = '${result.endDate!.year}-${_two(result.endDate!.month)}-${_two(result.endDate!.day)}';
    return '$start 至 $end';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _buildHealthBanner() {
    final color = _healthColor;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 12, AppTheme.pagePadding, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(_healthIcon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.healthLabel, style: AppTextStyles.h3),
                if (result.totalTrades > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '共 ${result.totalTrades} 笔交易，处理 ${result.barsProcessed} 根K线',
                    style: AppTextStyles.caption.copyWith(color: StockColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _healthColor {
    if (result.totalTrades == 0) return StockColors.textTertiary;
    if (result.winRate >= 0.6 && result.profitFactor >= 1.5) return StockColors.success;
    if (result.winRate >= 0.45 && result.profitFactor >= 1.0) return StockColors.warning;
    return StockColors.danger;
  }

  IconData get _healthIcon {
    if (result.totalTrades == 0) return Icons.info_outline;
    if (result.winRate >= 0.6 && result.profitFactor >= 1.5) return Icons.task_alt;
    if (result.winRate >= 0.45 && result.profitFactor >= 1.0) return Icons.trending_flat;
    return Icons.trending_down;
  }

  Widget _buildCoreStats() {
    if (result.totalTrades == 0) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Text(
          '回测期间无交易产生，策略条件未触发。',
          style: AppTextStyles.body.copyWith(color: StockColors.textSecondary),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 12, AppTheme.pagePadding, 0),
      child: Row(
        children: [
          _statCard('胜率', _pct(result.winRate), _winRateColor),
          const SizedBox(width: 8),
          _statCard('总收益', '${result.totalReturnPct.toStringAsFixed(1)}%', _returnColor),
          const SizedBox(width: 8),
          _statCard('最大回撤', '${result.maxDrawdownPct.toStringAsFixed(1)}%', StockColors.danger),
        ],
      ),
    );
  }

  Color get _winRateColor {
    if (result.winRate >= 0.6) return StockColors.success;
    if (result.winRate >= 0.4) return StockColors.warning;
    return StockColors.danger;
  }

  Color get _returnColor {
    if (result.totalReturnPct > 0) return StockColors.up;
    if (result.totalReturnPct < 0) return StockColors.down;
    return StockColors.textPrimary;
  }

  String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

  Widget _statCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: StockColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.numberSm.copyWith(color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceGrid() {
    if (result.totalTrades == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 12, AppTheme.pagePadding, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('详细指标', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _gridRow('盈利次数', '${result.winCount}'),
          _gridRow('亏损次数', '${result.loseCount}'),
          _gridRow('盈亏比', result.profitFactor.toStringAsFixed(2)),
          _gridRow('年均收益', '${result.annualizedReturn.toStringAsFixed(1)}%'),
          _gridRow('平均持仓', '${result.avgHoldingDays.toStringAsFixed(1)} 天'),
          _gridRow('夏普比率', result.sharpeRatio.toStringAsFixed(2)),
          _gridRow('最大连赢', '${result.maxConsecutiveWins} 次'),
          _gridRow('最大连亏', '${result.maxConsecutiveLosses} 次'),
          _gridRow('平均盈利', '+${result.avgWinPct.toStringAsFixed(1)}%'),
          _gridRow('平均亏损', '${result.avgLossPct.toStringAsFixed(1)}%'),
          _gridRow('最佳交易', '+${result.bestTradePct.toStringAsFixed(1)}%'),
          _gridRow('最差交易', '${result.worstTradePct.toStringAsFixed(1)}%'),
          _gridRow('净利(元)', result.totalNetProfit.toStringAsFixed(0)),
        ],
      ),
    );
  }

  Widget _gridRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(color: StockColors.textSecondary)),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildTradeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 16, AppTheme.pagePadding, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('交易记录', style: AppTextStyles.h2),
              Text('共 ${result.trades.length} 笔', style: AppTextStyles.caption),
            ],
          ),
        ),
        ...result.trades.take(30).map(_buildTradeItem),
      ],
    );
  }

  Widget _buildTradeItem(BacktestTrade trade) {
    final color = trade.isWin ? StockColors.up : StockColors.down;
    final icon = trade.isWin ? Icons.arrow_upward : Icons.arrow_downward;
    final exitLabel = switch (trade.exitReason) {
      ExitReason.signalExit => '信号出场',
      ExitReason.stopLoss => '止损',
      ExitReason.takeProfit => '止盈',
      ExitReason.endOfData => '期末平仓',
    };

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 3,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmtDate(trade.entryDate)} → ${_fmtDate(trade.exitDate)}',
                  style: AppTextStyles.caption,
                ),
                Text(
                  '${trade.shares}股 · $exitLabel · ${trade.exitBarIndex - trade.entryBarIndex}天',
                  style: AppTextStyles.caption.copyWith(color: StockColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${trade.returnPct >= 0 ? '+' : ''}${(trade.returnPct * 100).toStringAsFixed(1)}%',
                style: AppTextStyles.numberSm.copyWith(color: color),
              ),
              Text(
                '${trade.netProfit >= 0 ? '+' : ''}${trade.netProfit.toStringAsFixed(0)}',
                style: AppTextStyles.caption.copyWith(color: color, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}
