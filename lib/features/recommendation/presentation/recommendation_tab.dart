import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stock_list_item.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/cache_banner.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../strategy/domain/strategy_explanation.dart';
import '../../strategy/domain/strategy_models.dart';
import '../../strategy/domain/decision_engine.dart';
import '../../strategy/domain/strategy_trust_engine.dart';
import '../../strategy/presentation/strategy_provider.dart';
import '../../strategy/presentation/widgets/decision_summary_bar.dart';
import '../../strategy/presentation/widgets/trust_badge.dart';

/// Recommendation list tab (Tab 1).
/// Design: DESIGN.md Page 1 - Recommend List Page.
class RecommendationTab extends ConsumerStatefulWidget {
  const RecommendationTab({super.key});

  @override
  ConsumerState<RecommendationTab> createState() => _RecommendationTabState();
}

class _RecommendationTabState extends ConsumerState<RecommendationTab> {
  bool _showBanner = true;
  final Set<String> _collapsedStrategyIds = {};

  @override
  void initState() {
    super.initState();
    // Load recommendations on first build
    Future.microtask(() {
      ref.read(strategyRecommendationProvider.notifier).loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(strategyRecommendationProvider);

    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title bar
            _buildTitleBar(state),

            // Cache/Offline banner
            if (state.hasError && state.lastUpdated != null && _showBanner)
              CacheBanner(
                message: state.errorMessage ?? '数据更新失败，显示缓存数据',
                timestamp: '数据更新于 ${Formatters.formatTime(state.lastUpdated!)}',
                onClose: () => setState(() => _showBanner = false),
              ),

            // List content
            Expanded(
              child: state.isLoading
                  ? _buildLoadingList()
                  : state.hasError && state.lastUpdated == null
                  ? _buildErrorState()
                  : _buildContentList(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(StrategyRecommendationState state) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('推荐', style: AppTextStyles.h1),
              Text(
                Formatters.formatDate(now),
                style: AppTextStyles.caption.copyWith(
                  color: StockColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '今日全市场波段分析结果',
            style: TextStyle(
              fontFamily: AppTheme.textFont,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: StockColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return RefreshIndicator(
      color: StockColors.brand,
      onRefresh: () =>
          ref.read(strategyRecommendationProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Skeleton for section headers
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_skeletonBox(80, 16), _skeletonBox(40, 16)],
              ),
            ),
            StockListSkeleton(count: 8),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: StockColors.bgTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildErrorState() {
    return EmptyState(
      icon: Icons.signal_wifi_off,
      title: '暂无推荐数据',
      subtitle: '检查网络后下拉刷新',
    );
  }

  Widget _buildContentList(StrategyRecommendationState state) {
    if (state.groups.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: state.hasEnabledStrategies ? '暂无匹配标的' : '暂无启用策略',
        subtitle: state.hasEnabledStrategies
            ? '当前策略可能较严格，或行情数据暂不可用。可下拉刷新，或前往策略页降低阈值。'
            : '请前往策略管理启用至少一个策略',
      );
    }

    return RefreshIndicator(
      color: StockColors.brand,
      onRefresh: () =>
          ref.read(strategyRecommendationProvider.notifier).refresh(),
      child: ListView(
        children: [
          // Decision summary bar
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
            child: _buildDecisionSummaryBar(state),
          ),

          // Strategy groups
          for (final group in state.groups) ...[
            _buildSectionHeader(
              group.strategy.id,
              group.strategy.name,
              '${group.recommendations.length}只 · 观察阈值 ${group.strategy.recommendThreshold}',
              group.strategy.description,
              stats: group.strategy.stats,
            ),
            if (!_collapsedStrategyIds.contains(group.strategy.id))
              if (group.recommendations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                    vertical: 10,
                  ),
                  child: _buildStrategyEmptyDiagnosis(group.strategy),
                )
              else
                ...group.recommendations.map((item) {
                  final insight = item.score == null
                      ? null
                      : StrategyExplanation.recommendationInsight(
                          strategy: group.strategy,
                          score: item.score!,
                        );
                  return StockListItem(
                    name: item.name,
                    code: item.code,
                    market: item.market,
                    price: item.closePrice,
                    changePct: item.changePct,
                    score: item.score?.score,
                    isBandLow: item.isBandLow,
                    strategyName: group.strategy.name,
                    scoreReason: insight?.compact ?? item.score?.reason,
                    riskText: '仅供参考',
                    decisionResult: _evaluateDecision(group.strategy, item.score),
                    onTap: () => _navigateToDetail(
                      context,
                      item.code,
                      item.name,
                      item.market,
                      group.strategy.id,
                      group.strategy.name,
                    ),
                  );
                }),
          ],

          // Disclaimer
          const SizedBox(height: 16),
          const DisclaimerLabel(),
          const SizedBox(height: 64), // space above tab bar
        ],
      ),
    );
  }

  Widget _buildStrategyEmptyDiagnosis(Strategy strategy) {
    final diagnosis = StrategyExplanation.emptyDiagnosis(strategy);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.manage_search_outlined,
            size: 18,
            color: StockColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(diagnosis.title, style: AppTextStyles.body),
                const SizedBox(height: 2),
                Text(
                  diagnosis.body,
                  style: AppTextStyles.caption.copyWith(
                    color: StockColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  diagnosis.actionLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: StockColors.brand,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String strategyId,
    String title,
    String meta,
    String description, {
    StrategyStats? stats,
  }) {
    final isCollapsed = _collapsedStrategyIds.contains(strategyId);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 8,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isCollapsed) {
              _collapsedStrategyIds.remove(strategyId);
            } else {
              _collapsedStrategyIds.add(strategyId);
            }
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  isCollapsed
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_down,
                  size: 20,
                  color: StockColors.textTertiary,
                ),
                const SizedBox(width: 2),
                Expanded(child: Text(title, style: AppTextStyles.h3)),
                if (stats != null) ...[
                  const SizedBox(width: 4),
                  TrustBadge(
                    trustResult: StrategyTrustEngine.evaluate(stats),
                    isSmall: true,
                  ),
                ],
                const SizedBox(width: 4),
                Text(meta, style: AppTextStyles.caption),
              ],
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: StockColors.textTertiary,
                ),
                maxLines: isCollapsed ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (!isCollapsed) ...[
              const SizedBox(height: 4),
              Text(
                '按该策略观察分排序，只作为学习和观察线索。',
                style: AppTextStyles.caption.copyWith(
                  color: StockColors.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  DecisionResult _evaluateDecision(Strategy strategy, StockScore? score) {
    return DecisionEngine.evaluate(
      strategyScore: (score?.score ?? 0).toDouble(),
      hitRate: strategy.stats?.hitRate ?? 0,
      sampleSize: strategy.stats?.totalRecommendations ?? 0,
      isEnabled: strategy.isEnabled,
    );
  }

  Widget _buildDecisionSummaryBar(StrategyRecommendationState state) {
    final results = <DecisionResult>[];
    for (final group in state.groups) {
      for (final item in group.recommendations) {
        results.add(_evaluateDecision(group.strategy, item.score));
      }
    }
    if (results.isEmpty) return const SizedBox.shrink();
    return DecisionSummaryBar.fromResults(results);
  }

  void _navigateToDetail(
    BuildContext context,
    String code,
    String name,
    String market,
    String strategyId,
    String strategyName,
  ) {
    context.push(
      '/stock/$code',
      extra: {
        'code': code,
        'name': name,
        'market': market,
        'strategyId': strategyId,
        'strategyName': strategyName,
      },
    );
  }
}
