import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../domain/strategy_models.dart';
import 'strategy_provider.dart';

/// Page for selecting 2–4 strategies and comparing their stats side-by-side.
class StrategyComparePage extends ConsumerStatefulWidget {
  const StrategyComparePage({super.key});

  @override
  ConsumerState<StrategyComparePage> createState() =>
      _StrategyComparePageState();
}

class _StrategyComparePageState extends ConsumerState<StrategyComparePage> {
  /// IDs of the currently selected strategies.
  final Set<String> _selectedIds = {};

  /// Whether the comparison table is visible.
  bool _showComparison = false;

  static const int _minSelect = 2;
  static const int _maxSelect = 4;

  @override
  void initState() {
    super.initState();
    // Ensure the strategy list is fresh when entering the compare page.
    // strategyListProvider auto-loads on first creation, but if the user
    // navigates here without first visiting the Strategy tab (e.g. from a
    // strategy detail page), we refresh explicitly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(strategyListProvider.notifier).loadStrategies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(strategyListProvider);

    return Scaffold(
      backgroundColor: context.sc.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('策略对比'),
      ),
      body: listState.isLoading
          ? _buildLoading()
          : listState.hasError
              ? _buildError(listState.errorMessage)
              : listState.strategies.isEmpty
                  ? _buildEmpty()
                  : Stack(
                      children: [
                        // Main selectable list
                        Positioned.fill(
                          child: _buildContent(listState.strategies),
                        ),
                        // Sticky bottom bar with comparison
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child:
                              _buildBottomBar(listState.strategies) ??
                                  const SizedBox.shrink(),
                        ),
                      ],
                    ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(List<Strategy> strategies) {
    return Column(
      children: [
        // Selection hint
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding,
            vertical: AppTheme.space3,
          ),
          color: context.sc.bgSecondary,
          child: Text(
            '选择 $_minSelect–$_maxSelect 个策略进行对比（已选 ${_selectedIds.length}）',
            style: AppTextStyles.caption.copyWith(
              color: context.sc.textSecondary,
            ),
          ),
        ),

        // Strategy list with checkboxes
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: strategies.length,
            separatorBuilder: (_, _) => const Divider(height: 0),
            itemBuilder: (_, index) {
              final s = strategies[index];
              return _buildStrategyTile(s);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyTile(Strategy strategy) {
    final isSelected = _selectedIds.contains(strategy.id);
    return InkWell(
      onTap: () => _toggleSelect(strategy.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: AppTheme.space4,
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelect(strategy.id),
                activeColor: StockColors.brand,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space3),

            // Strategy info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy.name,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: context.sc.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (strategy.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      strategy.description,
                      style: AppTextStyles.caption.copyWith(
                        color: context.sc.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Status tag
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: strategy.isEnabled
                    ? StockColors.upBg
                    : context.sc.bgTertiary,
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: Text(
                strategy.isEnabled ? '启用' : '停用',
                style: AppTextStyles.caption.copyWith(
                  color: strategy.isEnabled
                      ? StockColors.up
                      : context.sc.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Comparison Table
  // ---------------------------------------------------------------------------

  Widget _buildComparisonTable(List<Strategy> strategies) {
    final selected = strategies
        .where((s) => _selectedIds.contains(s.id))
        .toList();

    if (selected.isEmpty) return const SizedBox.shrink();

    // Metric rows: label + builder per strategy
    final metrics = <_CompareRow>[
      _CompareRow(
        label: '命中率',
        buildValue: (s) {
          final st = s.stats;
          if (st == null || st.evaluatedCount == 0) return _dash;
          return st.hitRateDisplay;
        },
      ),
      _CompareRow(
        label: '平均涨跌',
        buildValue: (s) {
          final st = s.stats;
          if (st == null || st.evaluatedCount == 0) return _dash;
          return st.avgChangeDisplay;
        },
        valueColor: (s) {
          final st = s.stats;
          if (st == null || st.evaluatedCount == 0) return null;
          if (st.avgChange > 0) return StockColors.up;
          if (st.avgChange < 0) return StockColors.down;
          return StockColors.flat;
        },
      ),
      _CompareRow(
        label: '健康度',
        buildValue: (s) {
          final st = s.stats;
          if (st == null || st.evaluatedCount == 0) return _dash;
          return st.healthScoreDisplay;
        },
      ),
      _CompareRow(
        label: '最大收益 / 最大亏损',
        labelShort: '极值',
        buildValue: (s) {
          final st = s.stats;
          if (st == null || st.evaluatedCount == 0) return _dash;
          if (st.maxGain == null && st.maxLoss == null) return _dash;
          return st.extremeScoreDisplay;
        },
      ),
      _CompareRow(
        label: '总推荐次数',
        buildValue: (s) {
          final st = s.stats;
          if (st == null) return _dash;
          return '${st.totalRecommendations}';
        },
      ),
      _CompareRow(
        label: '运行交易日',
        buildValue: (s) {
          final st = s.stats;
          if (st == null) return _dash;
          return '${st.tradingDaysRun}';
        },
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(top: AppTheme.space4),
      decoration: BoxDecoration(
        color: context.sc.bgPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.sc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(AppTheme.space4),
            decoration: BoxDecoration(
              color: context.sc.bgSecondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMd),
                topRight: Radius.circular(AppTheme.radiusMd),
              ),
            ),
            child: Row(
              children: [
                // Label column header
                const SizedBox(
                  width: _labelWidth,
                  child: Text(
                    '指标',
                    style: AppTextStyles.caption,
                  ),
                ),
                // Strategy name headers
                ...selected.map(
                  (s) => Expanded(
                    child: Text(
                      s.name,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.sc.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...metrics.map((row) => _buildCompareRow(row, selected)),

          // Bottom radius
          const SizedBox(height: AppTheme.space2),
        ],
      ),
    );
  }

  static const double _labelWidth = 80;
  static const String _dash = '--';

  Widget _buildCompareRow(_CompareRow row, List<Strategy> selected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.sc.divider, width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: _labelWidth,
            child: Text(
              row.labelShort ?? row.label,
              style: AppTextStyles.caption.copyWith(
                color: context.sc.textSecondary,
              ),
            ),
          ),
          // Values
          ...selected.map(
            (s) {
              final value = row.buildValue(s);
              final color = row.valueColor?.call(s);
              return Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.numberSm.copyWith(
                    color: color ?? context.sc.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  Widget? _buildBottomBar(List<Strategy> strategies) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        AppTheme.space3,
        AppTheme.pagePadding,
        AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: context.sc.bgPrimary,
        border: Border(
          top: BorderSide(color: context.sc.divider),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Comparison table (scrollable area above buttons)
            if (_showComparison)
              _buildComparisonTable(strategies),

            const SizedBox(height: AppTheme.space3),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _selectedIds.length >= _minSelect
                    ? () {
                        setState(() {
                          _showComparison = !_showComparison;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StockColors.brand,
                  foregroundColor: context.sc.textOnPrimary,
                  disabledBackgroundColor: context.sc.bgTertiary,
                  disabledForegroundColor: context.sc.textDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _showComparison ? '收起对比' : '开始对比',
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= _maxSelect) {
          ToastHelper.showError(context, '最多选择 $_maxSelect 个策略');
          return;
        }
        _selectedIds.add(id);
      }
      // Hide comparison when selection changes
      _showComparison = false;
    });
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: StockColors.brand),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: StockColors.error),
            const SizedBox(height: AppTheme.space3),
            Text(
              message ?? '策略数据加载失败',
              style: AppTextStyles.body.copyWith(
                color: context.sc.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space4),
            OutlinedButton(
              onPressed: () =>
                  ref.read(strategyListProvider.notifier).loadStrategies(),
              style: OutlinedButton.styleFrom(
                foregroundColor: StockColors.brand,
                side: const BorderSide(color: StockColors.brand),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_outlined,
                size: 48, color: context.sc.gray400),
            const SizedBox(height: AppTheme.space3),
            Text(
              '暂无策略可对比',
              style: AppTextStyles.bodyLg.copyWith(
                color: context.sc.textTertiary,
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Text(
              '请先创建至少 2 个策略',
              style: AppTextStyles.caption.copyWith(
                color: context.sc.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Data helper for comparison rows
// -----------------------------------------------------------------------------

class _CompareRow {
  final String label;
  final String? labelShort;
  final String Function(Strategy) buildValue;
  final Color? Function(Strategy)? valueColor;

  const _CompareRow({
    required this.label,
    this.labelShort,
    required this.buildValue,
    this.valueColor,
  });
}
