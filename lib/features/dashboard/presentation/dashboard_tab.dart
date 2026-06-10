import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import '../../../shared/widgets/stock_list_item.dart';
import '../../strategy/presentation/strategy_provider.dart';
import 'dashboard_provider.dart';

/// Decision Dashboard — the landing page that gives users a quick
/// overview of strategy performance, today's top picks, and market sentiment.
///
/// Layout:
///   [Title bar with date]
///   [Market sentiment card]
///   [Strategy summary row] (enabled count / best health / avg hit rate)
///   [Review alert banner] (if any strategies need review)
///   [Top recommendations section] (up to 5 items)
///   [Watchlist quick link]
///   [Disclaimer]
class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).loadDashboard();
      ref.read(strategyRecommendationProvider.notifier).loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final recState = ref.watch(strategyRecommendationProvider);

    // Enrich dashboard data with recommendation data
    final data = dashState.isLoading
        ? dashState.data
        : ref
            .read(dashboardProvider.notifier)
            .enrichWithRecommendations(dashState.data, recState);

    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTitleBar(),
            Expanded(
              child: dashState.isLoading
                  ? _buildLoadingSkeleton()
                  : dashState.hasError
                      ? _buildErrorState(dashState.errorMessage)
                      : RefreshIndicator(
                          color: StockColors.brand,
                          onRefresh: _refresh,
                          child: _buildContent(data),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Title bar ──────────────────────────────────────────────────
  Widget _buildTitleBar() {
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
              const Text('决策看板', style: AppTextStyles.h1),
              Text(
                _formatDate(now),
                style: AppTextStyles.caption.copyWith(
                  color: StockColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '策略概览与市场观察',
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

  // ── Loading skeleton ───────────────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Shimmer.fromColors(
        baseColor: StockColors.bgTertiary,
        highlightColor: StockColors.gray100,
        child: Column(
          children: [
            // Sentiment card skeleton
            _skeletonCard(80),
            const SizedBox(height: 12),
            // Strategy summary skeleton
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding),
              child: Row(
                children: [
                  _skeletonBox(MediaQuery.of(context).size.width / 3 - 20, 72),
                  const SizedBox(width: 8),
                  _skeletonBox(MediaQuery.of(context).size.width / 3 - 20, 72),
                  const SizedBox(width: 8),
                  _skeletonBox(MediaQuery.of(context).size.width / 3 - 20, 72),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Top recs skeleton
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding),
              child: _skeletonBox(double.infinity, 20),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < 3; i++) _skeletonCard(64),
          ],
        ),
      ),
    );
  }

  Widget _skeletonCard(double height) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 4),
      height: height,
      decoration: BoxDecoration(
        color: StockColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }

  Widget _skeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: StockColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────
  Widget _buildErrorState(String? message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: StockColors.textDisabled),
          const SizedBox(height: 12),
          Text(
            message ?? '数据加载失败',
            style: AppTextStyles.body.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _refresh,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────
  Widget _buildContent(DashboardData data) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 64),
      children: [
        // 1. Market sentiment card
        _buildSentimentCard(data),

        const SizedBox(height: 12),

        // 2. Strategy summary row
        _buildStrategySummaryRow(data),

        // 3. Review alert banner
        if (data.strategiesNeedingReview.isNotEmpty)
          _buildReviewAlert(data.strategiesNeedingReview.length),

        const SizedBox(height: 20),

        // 4. Top recommendations section
        _buildTopRecommendations(data),

        const SizedBox(height: 16),

        // 5. Quick links row
        _buildQuickLinks(data),

        const SizedBox(height: 16),

        // 6. Disclaimer
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
          child: DisclaimerLabel(),
        ),
      ],
    );
  }

  // ── 1. Sentiment card ──────────────────────────────────────────
  Widget _buildSentimentCard(DashboardData data) {
    final (icon, label, color, bgColor, desc) = _sentimentDetails(
        data.sentiment, data.totalRecommendations);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(desc,
                    style: AppTextStyles.caption
                        .copyWith(color: StockColors.textSecondary)),
              ],
            ),
          ),
          // Recommendation count badge
          if (data.totalRecommendations > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '${data.totalRecommendations}只观察',
                style: AppTextStyles.micro.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  (IconData, String, Color, Color, String) _sentimentDetails(
      MarketSentiment s, int total) {
    switch (s) {
      case MarketSentiment.strong:
        return (
          Icons.trending_up,
          '观察信号较多',
          StockColors.up,
          StockColors.upLight,
          '今日多个策略产生观察结果，可关注高分标的。'
        );
      case MarketSentiment.neutral:
        return (
          Icons.remove_outlined,
          '信号中等',
          StockColors.warning,
          StockColors.bgWarning,
          '今日有 $total 只标的进入观察范围。'
        );
      case MarketSentiment.cautious:
        return (
          Icons.trending_down,
          '信号偏少',
          StockColors.down,
          StockColors.downLight,
          '今日观察结果较少，建议保持耐心或调整策略。'
        );
      case MarketSentiment.unknown:
        return (
          Icons.help_outline,
          '暂无信号',
          StockColors.gray500,
          StockColors.bgTertiary,
          '未启用策略或数据未加载，请检查策略设置。'
        );
    }
  }

  // ── 2. Strategy summary row ────────────────────────────────────
  Widget _buildStrategySummaryRow(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          _buildMetricCard(
            '${data.enabledStrategies}/${data.totalStrategies}',
            '启用策略',
            Icons.lightbulb_outline,
            StockColors.brand,
            StockColors.brandLight,
          ),
          const SizedBox(width: 8),
          _buildMetricCard(
            data.bestHealthScore != null
                ? data.bestHealthScore!.toStringAsFixed(1)
                : '--',
            '最佳健康度',
            Icons.favorite_outline,
            StockColors.up,
            StockColors.upLight,
          ),
          const SizedBox(width: 8),
          _buildMetricCard(
            data.strategiesWithStats > 0
                ? '${(data.avgHitRate * 100).toStringAsFixed(0)}%'
                : '--',
            '平均命中率',
            Icons.track_changes_outlined,
            data.avgHitRate >= 0.5 ? StockColors.up : StockColors.warning,
            data.avgHitRate >= 0.5 ? StockColors.upLight : StockColors.bgWarning,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String value,
    String label,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.numberSm.copyWith(
                color: StockColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.micro.copyWith(
                color: StockColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Review alert banner ─────────────────────────────────────
  Widget _buildReviewAlert(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding, 12, AppTheme.pagePadding, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StockColors.bgWarning,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: StockColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note_outlined,
              size: 18, color: StockColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count 个策略超过 30 天未复盘',
              style: AppTextStyles.caption.copyWith(
                color: StockColors.cacheBannerText,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/strategies'),
            child: Text(
              '查看',
              style: AppTextStyles.caption.copyWith(
                color: StockColors.brand,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Top recommendations ─────────────────────────────────────
  Widget _buildTopRecommendations(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('今日重点观察', style: AppTextStyles.h2),
              if (data.totalRecommendations > 0)
                GestureDetector(
                  onTap: () => context.go('/recommend'),
                  child: Text(
                    '全部 ${data.totalRecommendations} 只',
                    style: AppTextStyles.caption.copyWith(
                      color: StockColors.brand,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (data.topRecommendations.isEmpty)
          _buildEmptyRecommendations()
        else
          ...data.topRecommendations.map(
            (item) => StockListItem(
              name: item.name,
              code: item.code,
              market: item.market,
              price: item.closePrice,
              changePct: item.changePct,
              score: item.score?.score,
              isBandLow: item.isBandLow,
              strategyName: null,
              scoreReason: item.score?.reason,
              riskText: '仅供参考',
              onTap: () => context.push(
                '/stock/${item.code}',
                extra: {
                  'code': item.code,
                  'name': item.name,
                  'market': item.market,
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_outlined,
              size: 32, color: StockColors.textDisabled),
          const SizedBox(height: 8),
          Text(
            '今日暂无观察结果',
            style: AppTextStyles.body.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '下拉刷新或前往推荐页查看详情',
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Quick links ─────────────────────────────────────────────
  Widget _buildQuickLinks(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickLinkCard(
              icon: Icons.star_outline,
              label: '关注 ${data.watchlistCount}',
              subtitle: '自选标的',
              onTap: () => context.go('/watchlist'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickLinkCard(
              icon: Icons.trending_up_outlined,
              label: '推荐列表',
              subtitle: '按策略分组',
              onTap: () => context.go('/recommend'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickLinkCard(
              icon: Icons.lightbulb_outline,
              label: '策略管理',
              subtitle: '${data.totalStrategies} 个策略',
              onTap: () => context.go('/strategies'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: StockColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: StockColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: StockColors.brand),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
            )),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.micro.copyWith(
              color: StockColors.textTertiary,
            )),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Future<void> _refresh() async {
    await Future.wait([
      ref.read(dashboardProvider.notifier).loadDashboard(),
      ref.read(strategyRecommendationProvider.notifier).refresh(),
    ]);
  }

  String _formatDate(DateTime date) {
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final w = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日 周$w';
  }
}
