import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/strategy_models.dart';
import 'strategy_provider.dart';

/// Strategy detail page showing stats, hit records, and review.
class StrategyDetailPage extends ConsumerStatefulWidget {
  final String strategyId;

  const StrategyDetailPage({super.key, required this.strategyId});

  @override
  ConsumerState<StrategyDetailPage> createState() => _StrategyDetailPageState();
}

class _StrategyDetailPageState extends ConsumerState<StrategyDetailPage> {
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(strategyDetailProvider.notifier).loadDetail(widget.strategyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(strategyDetailProvider);

    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: RefreshIndicator(
        color: StockColors.brand,
        onRefresh: () => ref
            .read(strategyDetailProvider.notifier)
            .loadDetail(widget.strategyId),
        child: ListView(
          children: [
            _buildHeader(state),
            if (state.isLoading)
              const Column(
                children: [
                  DetailSectionSkeleton(height: 120),
                  SizedBox(height: 8),
                  DetailSectionSkeleton(height: 80),
                ],
              )
            else if (state.hasError)
              _buildErrorState()
            else ...[
              _buildReviewBanner(state),
              _buildStatsCards(state),
              _buildStrategyCoreSection(state),
              _buildHitRecords(state),
              if (state.suggestions.isNotEmpty) _buildSuggestions(state),
              _buildReviewSection(state),
            ],
            const DisclaimerLabel(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(StrategyDetailState state) {
    final strategy = state.strategy;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, AppTheme.pagePadding, 0),
        child: Column(
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
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                const Spacer(),
                if (strategy != null && !strategy.isDefault)
                  IconButton(
                    onPressed: _isDeleting ? null : _handleDelete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: StockColors.danger,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: StockColors.danger,
                          ),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                IconButton(
                  onPressed: () =>
                      context.push('/strategy/${widget.strategyId}/edit'),
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: StockColors.brand,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strategy?.name ?? '策略详情', style: AppTextStyles.h1),
                  if (strategy?.description.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(strategy!.description, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32, color: StockColors.gray400),
          const SizedBox(height: 8),
          const Text(
            '统计计算失败',
            style: TextStyle(fontSize: 13, color: StockColors.textSecondary),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => ref
                .read(strategyDetailProvider.notifier)
                .loadDetail(widget.strategyId),
            child: const Text(
              '重新计算',
              style: TextStyle(fontSize: 13, color: StockColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBanner(StrategyDetailState state) {
    final strategy = state.strategy;
    if (strategy == null || !strategy.needsReview || !strategy.isEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.all(AppTheme.pagePadding),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgWarning,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active,
            color: StockColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('该策略已运行满30个交易日，建议进行复盘', style: AppTextStyles.body),
          ),
          TextButton(
            onPressed: () => _showReviewDialog(state),
            child: const Text('立即复盘'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(StrategyDetailState state) {
    final stats = state.stats;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          _buildStatCard(
            '命中率',
            stats.hitRateDisplay,
            getScoreColor(_hitRateToScore(stats.hitRate)),
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            '极限分值',
            stats.extremeScoreDisplay,
            StockColors.textPrimary,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            '健康度',
            stats.healthScoreDisplay,
            getScoreColor(stats.healthScore.round()),
          ),
        ],
      ),
    );
  }

  int _hitRateToScore(double hitRate) {
    if (hitRate >= 0.6) return 8;
    if (hitRate >= 0.4) return 5;
    return 3;
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
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
            Text(
              value,
              style: AppTextStyles.numberSm.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCoreSection(StrategyDetailState state) {
    final strategy = state.strategy;
    if (strategy == null) return const SizedBox.shrink();

    final weights = [
      'MA ${(strategy.weightMA * 100).round()}%',
      '布林 ${(strategy.weightBoll * 100).round()}%',
      '量价 ${(strategy.weightVol * 100).round()}%',
      '趋势 ${(strategy.weightTrend * 100).round()}%',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('策略核心', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            '观察阈值 ${strategy.recommendThreshold} 分，${strategy.maShortPeriod}/${strategy.maLongPeriod} 日均线，布林带 ${strategy.bollPeriod} 日。',
            style: AppTextStyles.body.copyWith(
              color: StockColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            weights,
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHitRecords(StrategyDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            16,
            AppTheme.pagePadding,
            8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('推荐记录', style: AppTextStyles.h2),
              Text(
                '共 ${state.hitRecords.length} 条',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        if (state.hitRecords.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppTheme.pagePadding),
            child: Text(
              '暂无推荐记录',
              style: TextStyle(fontSize: 13, color: StockColors.gray500),
            ),
          )
        else
          ...state.hitRecords
              .take(20)
              .map((record) => _buildHitRecordItem(record)),
      ],
    );
  }

  Widget _buildHitRecordItem(StrategyHitRecord record) {
    final changeColor = record.actualChange5d != null
        ? getPriceColor(record.actualChange5d!)
        : StockColors.textTertiary;
    return InkWell(
      onTap: () => context.push(
        '/stock/${record.stockCode}',
        extra: {
          'code': record.stockCode,
          'name': record.stockName,
          'market': 'SH',
        },
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: 10,
        ),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: StockColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.stockName, style: AppTextStyles.bodyLg),
                  Text(
                    '${record.stockCode}  ${record.recommendDate}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text('评分 ${record.recommendScore}', style: AppTextStyles.numberSm),
            const SizedBox(width: 12),
            Text(
              record.actualChangeDisplay,
              style: AppTextStyles.numberSm.copyWith(color: changeColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(StrategyDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            16,
            AppTheme.pagePadding,
            8,
          ),
          child: Text('迭代建议', style: AppTextStyles.h2),
        ),
        ...state.suggestions.map(
          (s) => Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
              vertical: 4,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StockColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.condition,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(s.suggestion, style: AppTextStyles.caption),
                if (s.parameterKey != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push(
                          '/strategy/${widget.strategyId}/edit',
                          extra: {'suggestion': s},
                        );
                      },
                      child: const Text('采纳并编辑'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(StrategyDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            16,
            AppTheme.pagePadding,
            8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('历史复盘', style: AppTextStyles.h2),
              if (state.reviewHistory.isNotEmpty)
                Text(
                  '${state.reviewHistory.length} 次',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ),
        if (state.reviewHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppTheme.pagePadding),
            child: Text(
              '暂无复盘记录',
              style: TextStyle(fontSize: 13, color: StockColors.gray500),
            ),
          )
        else
          ...state.reviewHistory.map((review) => _buildReviewItem(review)),
      ],
    );
  }

  Widget _buildReviewItem(StrategyReview review) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 4,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatDate(review.reviewDate),
                  style: AppTextStyles.body,
                ),
                if (review.note != null && review.note!.isNotEmpty)
                  Text(
                    review.note!,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '健康度 ${review.healthScore.toStringAsFixed(1)}',
            style: AppTextStyles.numberSm,
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final strategy = ref.read(strategyDetailProvider).strategy;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确认删除策略 ${strategy?.name ?? ''}？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '删除',
              style: TextStyle(color: StockColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final success = await ref
        .read(strategyListProvider.notifier)
        .deleteStrategy(widget.strategyId);
    if (!mounted) return;

    if (success) {
      context.pop();
      ToastHelper.showSuccess(context, '策略已删除');
    } else {
      setState(() => _isDeleting = false);
      ToastHelper.showError(context, '删除失败，请重试');
    }
  }

  void _showReviewDialog(StrategyDetailState state) {
    final noteController = TextEditingController();
    ref
        .read(strategyDetailProvider.notifier)
        .generateChecklist(widget.strategyId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final detailState = ref.watch(strategyDetailProvider);
            return AlertDialog(
              title: const Text('策略复盘'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detailState.checklist.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      if (detailState.reviewPeriod != null) ...[
                        _buildReviewPeriodInfo(detailState.reviewPeriod!),
                        const SizedBox(height: 12),
                      ],
                      ...detailState.checklist.map(
                        (item) => _buildChecklistItem(item),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          hintText: '本次复盘备注（选填）',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: detailState.checklist.isEmpty
                      ? null
                      : () async {
                          final success = await ref
                              .read(strategyDetailProvider.notifier)
                              .submitReview(
                                widget.strategyId,
                                detailState.checklist,
                                note: noteController.text.trim().isEmpty
                                    ? null
                                    : noteController.text.trim(),
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ToastHelper.showSuccess(context, '复盘记录已保存');
                              final failCount = detailState.checklist
                                  .where((i) => i.result == CheckResult.fail)
                                  .length;
                              if (failCount >= 3) {
                                _showDisableSuggestionDialog();
                              }
                            } else {
                              ToastHelper.showError(context, '保存失败');
                            }
                          }
                        },
                  child: const Text('确认复盘结果'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDisableSuggestionDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('策略表现异常'),
          content: const Text('该策略表现异常，建议考虑停用或调整参数。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: StockColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref
                    .read(strategyListProvider.notifier)
                    .toggleEnabled(widget.strategyId, false);
                await ref
                    .read(strategyDetailProvider.notifier)
                    .loadDetail(widget.strategyId);
                if (mounted) {
                  ToastHelper.showSuccess(context, '策略已停用');
                }
              },
              child: const Text('停用策略'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    final Color color;
    final IconData icon;
    switch (item.result) {
      case CheckResult.pass:
        color = StockColors.success;
        icon = Icons.check_circle;
      case CheckResult.warning:
        color = StockColors.warning;
        icon = Icons.warning;
      case CheckResult.fail:
        color = StockColors.danger;
        icon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.body),
                Text(item.detail, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPeriodInfo(ReviewPeriodInfo period) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('复盘周期：${period.requestedLabel}', style: AppTextStyles.body),
          const SizedBox(height: 2),
          Text(
            '数据周期：${period.dataLabel}，样本 ${period.evaluatedCount} 条',
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textSecondary,
            ),
          ),
          if (period.sourceNote.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              period.sourceNote,
              style: AppTextStyles.caption.copyWith(
                color: period.usedFallback
                    ? StockColors.warning
                    : StockColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
