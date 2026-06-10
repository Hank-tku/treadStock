import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/utils/formatters.dart';
import '../domain/strategy_explanation.dart';
import '../domain/strategy_models.dart';
import '../domain/strategy_trust_engine.dart';
import '../domain/signal_rule.dart';
import 'strategy_provider.dart';
import 'widgets/trust_badge.dart';
import 'widgets/backtest_summary_card.dart';
import 'widgets/decision_bubble.dart';
import 'widgets/hit_rate_trend_chart.dart';
import 'providers/hit_rate_trend_provider.dart';

/// Strategy detail page showing stats, hit records, and review.
class StrategyDetailPage extends ConsumerStatefulWidget {
  final String strategyId;

  const StrategyDetailPage({super.key, required this.strategyId});

  @override
  ConsumerState<StrategyDetailPage> createState() => _StrategyDetailPageState();
}

class _StrategyDetailPageState extends ConsumerState<StrategyDetailPage> {
  bool _isDeleting = false;
  String? _expandedReviewId;

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
              _buildErrorState(state)
            else ...[
              _buildReviewBanner(state),
              _buildReviewSummaryCard(state),
              if (state.isAccumulatingData) _buildDataAccumulationNotice(state),
              if (!state.isLoading && state.strategy != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    12,
                    AppTheme.pagePadding,
                    0,
                  ),
                  child: TrustDescriptionText(
                    trustResult: StrategyTrustEngine.evaluate(state.stats),
                  ),
                ),
                if (state.stats.evaluatedCount > 0)
                  DecisionBubble(
                    summaryText: StrategyTrustEngine.evaluate(state.stats).description,
                    detailText: '综合分由命中率（40%权重）、样本量（30%权重）和运行天数（30%权重）计算得出，仅供参考，不构成投资建议。',
                    signalColor: StrategyTrustEngine.trustColor(
                      StrategyTrustEngine.evaluate(state.stats).level,
                    ),
                  ),
              ],
              _buildStatsCards(state),
              BacktestSummaryCard(stats: state.stats),
              _buildSampleNotice(state),
              _buildStrategyCoreSection(state),
              _buildRuleVisualization(state),
              _buildHitRateTrend(state),
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

  Widget _buildReviewSummaryCard(StrategyDetailState state) {
    if (state.strategy == null) return const SizedBox.shrink();
    final summary = StrategyExplanation.reviewSummary(
      stats: state.stats,
      suggestions: state.suggestions,
    );
    final color = summary.needsAttention
        ? StockColors.warning
        : StockColors.success;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            summary.needsAttention
                ? Icons.report_problem_outlined
                : Icons.task_alt,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.title, style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text(
                  summary.conclusion,
                  style: AppTextStyles.body.copyWith(
                    color: StockColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary.nextStep,
                  style: AppTextStyles.caption.copyWith(
                    color: StockColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                if (strategy != null)
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
                if (strategy != null)
                  IconButton(
                    onPressed: () => context.push(
                      '/strategy/${widget.strategyId}/backtest',
                      extra: {'strategyName': strategy.name},
                    ),
                    icon: const Icon(
                      Icons.query_stats_outlined,
                      size: 20,
                      color: StockColors.brand,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
                if (strategy != null)
                  IconButton(
                    onPressed: () => context.push(
                      '/strategy/${widget.strategyId}/tuner',
                      extra: {'stockCode': ''},
                    ),
                    icon: const Icon(
                      Icons.tune,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(strategy?.name ?? '策略详情', style: AppTextStyles.h1),
                      ),
                      if (strategy != null && !state.isLoading)
                        TrustBadge(
                          trustResult: StrategyTrustEngine.evaluate(state.stats),
                        ),
                    ],
                  ),
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

  Widget _buildErrorState(StrategyDetailState state) {
    final isNotFound = state.errorType == StrategyDetailErrorType.notFound;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        children: [
          EmptyState(
            icon: isNotFound
                ? Icons.manage_search_outlined
                : Icons.query_stats_outlined,
            title: isNotFound ? '未找到该策略' : '统计暂不可用',
            subtitle: isNotFound
                ? '这条策略可能已被删除，或当前链接不是有效策略。'
                : '策略已加载，但本地统计暂时计算失败。可重新计算，或先查看策略参数。',
          ),
          const SizedBox(height: 8),
          if (isNotFound)
            ElevatedButton(
              onPressed: () => context.go('/strategies'),
              child: const Text('返回策略列表'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => ref
                      .read(strategyDetailProvider.notifier)
                      .loadDetail(widget.strategyId),
                  child: const Text('重新计算'),
                ),
                if (state.strategy != null)
                  TextButton(
                    onPressed: () =>
                        context.push('/strategy/${widget.strategyId}/edit'),
                    child: const Text('查看策略参数'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSampleNotice(StrategyDetailState state) {
    if (!state.hasInsufficientSample) return const SizedBox.shrink();
    final evaluatedCount = state.stats.evaluatedCount;
    final totalCount = state.stats.totalRecommendations;
    final message = evaluatedCount == 0
        ? '这条策略还没有可复盘样本。先运行几天，系统会在推荐记录满足周期后回填 5 日表现。'
        : '已评估 $evaluatedCount 条，少于 20 条样本。当前统计只适合观察趋势，不适合判断策略好坏。';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: StockColors.info.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_outlined, color: StockColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('复盘样本不足', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(
                  totalCount == 0 ? message : '$message 当前累计推荐 $totalCount 条。',
                  style: AppTextStyles.caption.copyWith(
                    color: StockColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataAccumulationNotice(StrategyDetailState state) {
    final days = state.stats.tradingDaysRun;
    final recCount = state.stats.totalRecommendations;
    final detail = days <= 0
        ? '策略刚启用，先积累几天推荐记录，再看命中率、极限涨跌和平均差。'
        : '策略已启用 $days 个交易日，当前仅积累了 $recCount 条推荐记录；满 5 个交易日后再看统计更稳妥。';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: StockColors.info.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.hourglass_bottom, color: StockColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('数据积累中', style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: AppTextStyles.caption.copyWith(
                    color: StockColors.textSecondary,
                  ),
                ),
              ],
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
    final avgChangeColor = stats.evaluatedCount == 0
        ? StockColors.textPrimary
        : (stats.avgChange >= 0 ? StockColors.up : StockColors.down);
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
            '极限涨跌',
            stats.extremeScoreDisplay,
            StockColors.textPrimary,
          ),
          const SizedBox(width: 8),
          _buildStatCard('平均差', stats.avgChangeDisplay, avgChangeColor),
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

  Widget _buildHitRateTrend(StrategyDetailState state) {
    final trendAsync = ref.watch(hitRateTrendProvider(widget.strategyId));
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
          child: const Text('命中率趋势', style: AppTextStyles.h2),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: StockColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: trendAsync.when(
            data: (data) => HitRateTrendChart(data: data),
            loading: () => const SizedBox(
              height: 200,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox(
              height: 200,
              child: Center(
                child: Text('加载失败', style: TextStyle(fontSize: 13, color: StockColors.gray500)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHitRecords(StrategyDetailState state) {
    final isAccumulating = state.isAccumulatingData;
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
          Padding(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: Text(
              isAccumulating ? '数据积累中，满 5 个交易日后再查看命中率和平均差。' : '暂无推荐记录',
              style: const TextStyle(fontSize: 13, color: StockColors.gray500),
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
    final isExpanded = _expandedReviewId == review.id;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () {
            setState(() {
              _expandedReviewId = isExpanded ? null : review.id;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: AppTextStyles.caption.color,
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: isExpanded && review.checklistItems.isNotEmpty
                      ? _buildChecklistContent(review.checklistItems)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistContent(List<ChecklistItem> items) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: AppTextStyles.caption.color?.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          ...items.map((item) => _buildChecklistItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildChecklistItemRow(ChecklistItem item) {
    final icon = switch (item.result) {
      CheckResult.pass => '✅',
      CheckResult.warning => '⚠️',
      CheckResult.fail => '❌',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
                if (item.detail.isNotEmpty)
                  Text(
                    item.detail,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
              ],
            ),
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

  /// S5: Rule visualization section — shows entry/exit rules and groups visually.
  Widget _buildRuleVisualization(StrategyDetailState state) {
    final strategy = state.strategy;
    if (strategy == null || !strategy.isRuleBased) {
      return const SizedBox.shrink();
    }

    final hasEntryRules =
        (strategy.entryRules?.isNotEmpty ?? false) ||
        (strategy.entryGroups?.isNotEmpty ?? false);
    final hasExitRules =
        (strategy.exitRules?.isNotEmpty ?? false) ||
        (strategy.exitGroups?.isNotEmpty ?? false);

    if (!hasEntryRules && !hasExitRules) return const SizedBox.shrink();

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
          const Text('信号规则', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          if (hasEntryRules) ...[
            _buildRuleSection(
              '入场规则',
              StockColors.up,
              strategy.entryRules ?? [],
              strategy.entryGroups ?? [],
            ),
          ],
          if (hasExitRules) ...[
            const SizedBox(height: 12),
            _buildRuleSection(
              '离场规则',
              StockColors.down,
              strategy.exitRules ?? [],
              strategy.exitGroups ?? [],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleSection(
    String title,
    Color color,
    List<SignalRule> flatRules,
    List<RuleGroup> groups,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Flat rules (AND)
        if (flatRules.isNotEmpty)
          _buildRuleGroupCard(
            flatRules.map((r) => _ruleLabel(r)).toList(),
            logic: 'AND',
            color: color,
          ),
        // Groups (OR of ANDs)
        for (var i = 0; i < groups.length; i++) ...[
          if (flatRules.isNotEmpty || i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Center(
                child: Text(
                  'OR',
                  style: AppTextStyles.caption.copyWith(
                    color: StockColors.textTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          _buildRuleGroupCard(
            groups[i].rules.map((r) => _ruleLabel(r)).toList(),
            logic: 'AND',
            color: color,
            groupIndex: groups.length > 1 ? i + 1 : null,
          ),
        ],
      ],
    );
  }

  Widget _buildRuleGroupCard(
    List<String> labels, {
    required String logic,
    required Color color,
    int? groupIndex,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groupIndex != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '组 $groupIndex',
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '  AND',
                  style: TextStyle(
                    fontSize: 10,
                    color: StockColors.textTertiary,
                  ),
                ),
              ),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(child: Text(labels[i], style: AppTextStyles.caption)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _ruleLabel(SignalRule rule) {
    final indicatorNames = {
      'rsi': 'RSI',
      'macd': 'MACD',
      'macd_signal': 'MACD信号线',
      'macd_hist': 'MACD柱',
      'k': 'K值',
      'd': 'D值',
      'j': 'J值',
      'boll_position': '布林位置',
      'ma_alignment': '均线排列',
      'vol_price_divergence': '量价背离',
      'vol_ratio': '量比',
    };
    final conditionNames = {
      'gt': '>',
      'lt': '<',
      'in_range': '∈',
      'cross_up': '上穿',
      'cross_down': '下穿',
    };
    final name = indicatorNames[rule.indicator] ?? rule.indicator;
    final cond = conditionNames[rule.condition] ?? rule.condition;
    if (rule.condition == 'in_range' && rule.value2 != null) {
      return '$name $cond [${rule.value.toStringAsFixed(1)}, ${rule.value2!.toStringAsFixed(1)}]';
    }
    return '$name $cond ${rule.value.toStringAsFixed(1)}';
  }
}
