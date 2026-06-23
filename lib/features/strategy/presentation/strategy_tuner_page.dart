import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/providers.dart';
import '../domain/strategy_tuner.dart';
import '../domain/strategy_models.dart';
import '../domain/backtest_models.dart';
import 'strategy_provider.dart';

/// Page that runs the Strategy Tuner and displays ranked parameter combinations.
class StrategyTunerPage extends ConsumerStatefulWidget {
  final String strategyId;
  final String stockCode;

  const StrategyTunerPage({
    super.key,
    required this.strategyId,
    required this.stockCode,
  });

  @override
  ConsumerState<StrategyTunerPage> createState() => _StrategyTunerPageState();
}

class _StrategyTunerPageState extends ConsumerState<StrategyTunerPage> {
  List<TunerResult>? _results;
  bool _isLoading = true;
  String? _errorMessage;
  String? _applyingLabel;

  @override
  void initState() {
    super.initState();
    Future.microtask(_runTuner);
  }

  Future<void> _runTuner() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch strategy
      final strategyService = ref.read(strategyServiceProvider);
      await strategyService.init();
      final strategy = strategyService.getStrategy(widget.strategyId);
      if (strategy == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = '未找到该策略';
        });
        return;
      }

      // Determine market from stock code
      final market = _detectMarket(widget.stockCode);

      // Fetch kline data
      final apiService = ref.read(stockApiServiceProvider);
      final klines = await apiService.fetchStockKline(
        widget.stockCode,
        market: market,
        days: 250,
      );

      if (klines.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = '无法获取K线数据';
        });
        return;
      }

      // Run tuner
      final analysisEngine = ref.read(analysisEngineProvider);
      final tuner = StrategyTuner();
      final results = tuner.tune(
        strategy: strategy,
        klines: klines,
        config: const BacktestConfig(),
        stockCode: widget.stockCode,
        analysisEngine: analysisEngine,
      );

      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '参数调优失败: $e';
      });
    }
  }

  /// Detect SH/SZ market from stock code (A-share convention).
  String _detectMarket(String code) {
    if (code.startsWith('6') || code.startsWith('9')) return 'SH';
    return 'SZ';
  }

  Future<void> _applyParams(TunerResult result) async {
    setState(() => _applyingLabel = result.label);

    try {
      final strategy = result.strategyVariant;
      final form = StrategyFormData(
        name: strategy.name,
        description: strategy.description,
        maShortPeriod: strategy.maShortPeriod,
        maLongPeriod: strategy.maLongPeriod,
        bollPeriod: strategy.bollPeriod,
        bollStdDev: strategy.bollStdDev,
        weightMA: strategy.weightMA,
        weightBoll: strategy.weightBoll,
        weightVol: strategy.weightVol,
        weightTrend: strategy.weightTrend,
        recommendThreshold: strategy.recommendThreshold,
        isRuleBased: strategy.isRuleBased,
        entryRules: strategy.entryRules?.toList(),
        exitRules: strategy.exitRules?.toList(),
        entryGroups: strategy.entryGroups?.toList(),
        exitGroups: strategy.exitGroups?.toList(),
      );

      final success = await ref
          .read(strategyListProvider.notifier)
          .updateStrategy(widget.strategyId, form);

      if (!mounted) return;

      if (success) {
        ToastHelper.showSuccess(context, '参数已应用');
      } else {
        ToastHelper.showError(context, '应用参数失败');
      }
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, '应用参数失败');
    } finally {
      if (mounted) setState(() => _applyingLabel = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('参数调优'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.space6),
            Text(
              '正在遍历参数组合，请稍候…',
              style: AppTextStyles.body.copyWith(color: context.sc.textSecondary),
            ),
            const SizedBox(height: AppTheme.space4),
            const StockListSkeleton(count: 5),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: StockColors.error),
              const SizedBox(height: AppTheme.space3),
              Text(
                _errorMessage!,
                style: AppTextStyles.body.copyWith(color: context.sc.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space5),
              ElevatedButton(
                onPressed: _runTuner,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final results = _results!;
    final baseline = results.firstWhere(
      (r) => r.isBaseline,
      orElse: () => results.first,
    );

    return Column(
      children: [
        // Summary header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.pagePadding),
          color: context.sc.bgSecondary,
          child: Text(
            '共测试 ${results.length} 种参数组合，按收益率降序排列',
            style: AppTextStyles.caption.copyWith(color: context.sc.textSecondary),
          ),
        ),
        // Results list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(
              top: AppTheme.space3,
              bottom: AppTheme.space8,
            ),
            itemCount: results.length,
            separatorBuilder: (context, index) => const SizedBox.shrink(),
            itemBuilder: (context, index) {
              return _TunerResultCard(
                result: results[index],
                baselineResult: baseline.backtestResult,
                onApply: _applyingLabel == null ? _applyParams : null,
                isApplying: _applyingLabel == results[index].label,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A single card displaying a tuning result.
class _TunerResultCard extends StatelessWidget {
  final TunerResult result;
  final BacktestResult baselineResult;
  final ValueChanged<TunerResult>? onApply;
  final bool isApplying;

  const _TunerResultCard({
    required this.result,
    required this.baselineResult,
    this.onApply,
    this.isApplying = false,
  });

  bool get _isBetter => !result.isBaseline &&
      result.backtestResult.totalReturnPct > baselineResult.totalReturnPct;

  @override
  Widget build(BuildContext context) {
    final bt = result.backtestResult;
    final highlightColor =
        _isBetter ? StockColors.up : context.sc.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: AppTheme.space1,
      ),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: _isBetter ? StockColors.upBg : context.sc.bgPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: result.isBaseline
              ? StockColors.brand
              : _isBetter
                  ? StockColors.up.withValues(alpha: 0.3)
                  : context.sc.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  result.isBaseline
                      ? '📊 ${result.label}'
                      : _isBetter
                          ? '✅ ${result.label}'
                          : result.label,
                  style: AppTextStyles.h3.copyWith(
                    color: result.isBaseline
                        ? StockColors.brand
                        : _isBetter
                            ? StockColors.up
                            : context.sc.textPrimary,
                  ),
                ),
              ),
              if (result.isBaseline)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: StockColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: Text(
                    '基线',
                    style: AppTextStyles.caption.copyWith(
                      color: StockColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          // Metrics row
          Row(
            children: [
              _MetricChip(
                label: '胜率',
                value: '${(bt.winRate * 100).toStringAsFixed(1)}%',
                color: highlightColor,
              ),
              const SizedBox(width: AppTheme.space3),
              _MetricChip(
                label: '收益率',
                value: '${bt.totalReturnPct >= 0 ? '+' : ''}'
                    '${bt.totalReturnPct.toStringAsFixed(2)}%',
                color: highlightColor,
              ),
              const SizedBox(width: AppTheme.space3),
              _MetricChip(
                label: '盈亏比',
                value: bt.profitFactor.toStringAsFixed(2),
                color: highlightColor,
              ),
              const SizedBox(width: AppTheme.space3),
              _MetricChip(
                label: '最大回撤',
                value: '${bt.maxDrawdownPct.toStringAsFixed(2)}%',
                color: context.sc.textTertiary,
              ),
            ],
          ),
          // Apply button (not for baseline)
          if (!result.isBaseline) ...[
            const SizedBox(height: AppTheme.space3),
            SizedBox(
              width: double.infinity,
              child: _ApplyButton(
                onApply: onApply != null ? () => onApply!(result) : null,
                isApplying: isApplying,
                isBetter: _isBetter,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact metric display chip.
class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: context.sc.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.numberSm.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Apply button for a parameter variant.
class _ApplyButton extends StatelessWidget {
  final VoidCallback? onApply;
  final bool isApplying;
  final bool isBetter;

  const _ApplyButton({
    this.onApply,
    this.isApplying = false,
    this.isBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isApplying ? null : onApply,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: BorderSide(
          color: isBetter
              ? StockColors.up
              : context.sc.borderActive,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
      child: isApplying
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              '应用此参数',
              style: AppTextStyles.body.copyWith(
                color: isBetter
                    ? StockColors.up
                    : context.sc.borderActive,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}
