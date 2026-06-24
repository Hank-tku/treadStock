import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stock_list_item.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/app_menu_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/cache_banner.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../../shared/utils/formatters.dart';
import '../../strategy/domain/decision_engine.dart';
import '../../strategy/domain/strategy_models.dart';
import '../../strategy/presentation/strategy_provider.dart';
import '../../dashboard/presentation/dashboard_provider.dart';
import '../../watchlist/presentation/watchlist_provider.dart';

/// Recommendation filter dimensions.
enum RecommendFilter {
  all('全部'),
  bandLow('波段低位'),
  focus('重点关注'),
  watch('观望');

  final String label;
  const RecommendFilter(this.label);
}

/// A flattened recommendation item with its strategy context.
class _FlatItem {
  final DailyRecommendation rec;
  final Strategy strategy;
  final StockScore? score;
  final DecisionResult decision;
  final StockPrediction? prediction;

  const _FlatItem({
    required this.rec,
    required this.strategy,
    required this.score,
    required this.decision,
    this.prediction,
  });

  String get code => rec.code;
  double get sortScore => score?.score.toDouble() ?? 0;
  bool get isBandLow => rec.isBandLow;
  bool get isPredictionUp => prediction?.direction == PredictionDirection.up;
}

/// Recommendation list tab (Tab 1).
/// Flat list with dimension switching: 全部 | 波段低位 | 重点关注 | 观望.
class RecommendationTab extends ConsumerStatefulWidget {
  const RecommendationTab({super.key});

  @override
  ConsumerState<RecommendationTab> createState() => _RecommendationTabState();
}

class _RecommendationTabState extends ConsumerState<RecommendationTab> {
  bool _showBanner = true;
  RecommendFilter _activeFilter = RecommendFilter.all;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback so the first build completes before we kick
    // off async data loads; this avoids pending-timer assertions in widget
    // tests where the tree is disposed right after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(strategyRecommendationProvider.notifier).loadRecommendations();
    });
  }

  /// Flatten all strategy groups into a deduplicated, sorted list.
  List<_FlatItem> _buildFlatItems(StrategyRecommendationState state) {
    final byCode = <String, _FlatItem>{};

    for (final group in state.groups) {
      for (final rec in group.recommendations) {
        final decision = DecisionEngine.evaluate(
          strategyScore: (rec.score?.score ?? 0).toDouble(),
          hitRate: group.strategy.stats?.hitRate ?? 0,
          sampleSize: group.strategy.stats?.totalRecommendations ?? 0,
          isEnabled: group.strategy.isEnabled,
        );
        final item = _FlatItem(
          rec: rec,
          strategy: group.strategy,
          score: rec.score,
          decision: decision,
          prediction: rec.prediction,
        );

        // Deduplicate: keep the one with the highest score.
        final existing = byCode[rec.code];
        if (existing == null || item.sortScore > existing.sortScore) {
          byCode[rec.code] = item;
        }
      }
    }

    final items = byCode.values.toList();
    items.sort((a, b) => b.sortScore.compareTo(a.sortScore));
    return items;
  }

  /// Count items per filter dimension.
  Map<RecommendFilter, int> _countByFilter(List<_FlatItem> items) {
    return {
      RecommendFilter.all: items.length,
      RecommendFilter.bandLow:
          items.where((i) => i.isBandLow).length,
      RecommendFilter.focus: items
          .where((i) => i.decision.signal == DecisionSignal.strongWatch)
          .length,
      RecommendFilter.watch: items
          .where((i) => i.decision.signal == DecisionSignal.watch)
          .length,
    };
  }

  List<_FlatItem> _applyFilter(List<_FlatItem> items) {
    switch (_activeFilter) {
      case RecommendFilter.all:
        return items;
      case RecommendFilter.bandLow:
        return items.where((i) => i.isBandLow).toList();
      case RecommendFilter.focus:
        return items
            .where((i) => i.decision.signal == DecisionSignal.strongWatch)
            .toList();
      case RecommendFilter.watch:
        return items
            .where((i) => i.decision.signal == DecisionSignal.watch)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(strategyRecommendationProvider);
    final watchedCodes = ref.watch(watchedCodesProvider);
    // Dashboard overview data (merged in from the former Dashboard tab).
    // We watch it so the header updates when strategy stats load; the
    // sentiment is computed during loadDashboard (not re-enriched here to
    // avoid side effects inside build).
    final overview = ref.watch(dashboardProvider).data;

    return Scaffold(
      backgroundColor: context.sc.bgPrimary,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // Title bar
            _buildTitleBar(),

            // Merged overview header: strategy stats + sentiment + review alert.
            // Always render once the dashboard has attempted a load; while
            // loading the header shows default/empty values which is fine.
            _buildOverviewHeader(overview),

            // Cache/Offline banner: show when an error/empty-data occurred but
            // we still have previously cached groups (lastUpdated != null).
            if (state.showErrorState &&
                state.lastUpdated != null &&
                _showBanner)
              CacheBanner(
                message: state.errorMessage ?? '数据更新失败，显示缓存数据',
                timestamp:
                    '数据更新于 ${Formatters.formatTime(state.lastUpdated!)}',
                onClose: () => setState(() => _showBanner = false),
              ),

            // Content
            Expanded(
              child: state.isLoading
                  ? _buildLoadingList()
                  : state.showErrorState && state.lastUpdated == null
                      ? _buildErrorState(state)
                      : _buildContent(state, watchedCodes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    final state = ref.watch(strategyRecommendationProvider);
    final predictionTime = state.lastUpdated;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding, 12, AppTheme.pagePadding, 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('推荐', style: AppTextStyles.h1),
              Row(
                children: [
                  Text(
                    Formatters.formatDate(DateTime.now()),
                    style: AppTextStyles.caption.copyWith(
                      color: context.sc.textTertiary,
                    ),
                  ),
                  const AppMenuButton(),
                ],
              ),
            ],
          ),
          if (predictionTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${DateTime.now().hour < AppConstants.marketCloseHour ? "今日盘中预测" : "收盘预测(下一交易日)"} · ${Formatters.formatTime(predictionTime)}',
                style: AppTextStyles.caption.copyWith(
                  color: StockColors.brand,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Merged overview header (formerly the Dashboard tab's summary). Shows a
  /// compact strategy-stats row + market sentiment chip + a review-needed
  /// banner. Tap a metric navigates to the strategy page.
  Widget _buildOverviewHeader(DashboardData data) {
    final sentimentLabel = switch (data.sentiment) {
      MarketSentiment.strong => '强势',
      MarketSentiment.neutral => '中性',
      MarketSentiment.cautious => '谨慎',
      MarketSentiment.unknown => '暂无',
    };
    final sentimentColor = switch (data.sentiment) {
      MarketSentiment.strong => StockColors.up,
      MarketSentiment.neutral => context.sc.textSecondary,
      MarketSentiment.cautious => StockColors.warning,
      MarketSentiment.unknown => context.sc.textTertiary,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Strategy stats row (3 compact metric cards).
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding,
            vertical: 4,
          ),
          child: Row(
            children: [
              _buildMetricCard(
                '${data.enabledStrategies}/${data.totalStrategies}',
                '启用策略',
                Icons.lightbulb_outline,
                StockColors.brand,
                context.sc.brandLight,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                data.strategiesWithStats > 0
                    ? '${(data.avgHitRate * 100).toStringAsFixed(0)}%'
                    : '--',
                '平均命中率',
                Icons.track_changes_outlined,
                data.avgHitRate >= 0.5 ? StockColors.up : StockColors.warning,
                data.avgHitRate >= 0.5
                    ? StockColors.upLight
                    : context.sc.bgWarning,
              ),
              const SizedBox(width: 8),
              _buildMetricCard(
                sentimentLabel,
                '市场情绪',
                Icons.trending_up,
                sentimentColor,
                context.sc.bgTertiary,
              ),
            ],
          ),
        ),
        // Review-needed banner (only when some strategy needs review).
        if (data.strategiesNeedingReview.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
            ),
            child: GestureDetector(
              onTap: () => context.push('/strategies'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.sc.bgWarning,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment_late_outlined,
                      size: 16,
                      color: StockColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data.strategiesNeedingReview.length} 个策略建议复盘',
                        style: AppTextStyles.caption.copyWith(
                          color: StockColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: StockColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.numberSm.copyWith(
                color: context.sc.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.micro.copyWith(
                color: context.sc.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dimension filter bar ──────────────────────────────────────

  Widget _buildFilterBar(Map<RecommendFilter, int> counts) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding, vertical: 6,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: RecommendFilter.values.map((f) {
            final active = f == _activeFilter;
            final count = counts[f] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _activeFilter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? StockColors.brand
                        : context.sc.bgSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: active
                        ? null
                        : Border.all(
                            color: context.sc.borderLight,
                            width: 0.5,
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          color: active
                              ? Colors.white
                              : context.sc.textSecondary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 0.5,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white.withValues(alpha: 0.25)
                                : context.sc.bgTertiary,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: active
                                  ? Colors.white
                                  : context.sc.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────

  Widget _buildLoadingList() {
    return RefreshIndicator(
      color: StockColors.brand,
      onRefresh: () =>
          ref.read(strategyRecommendationProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding, vertical: 8,
              ),
              child: Row(
                children: [_skeletonBox(80, 28), const SizedBox(width: 8)],
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
        color: context.sc.bgTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Error / Empty ─────────────────────────────────────────────

  Widget _buildErrorState(StrategyRecommendationState state) {
    // Distinguish quote-source-empty from a real load/network error.
    // isEmptyData  → 行情源返回空（非网络问题）
    // hasError     → 请求异常（通常是网络或服务端问题）
    if (state.isEmptyData) {
      return EmptyState(
        icon: Icons.cloud_off,
        title: '暂无行情数据',
        subtitle: '行情源暂未返回数据，请稍后下拉刷新',
      );
    }
    return EmptyState(
      icon: Icons.signal_wifi_off,
      title: '数据更新失败',
      subtitle: '检查网络后下拉刷新，或稍后再试',
    );
  }

  // ── Main content ──────────────────────────────────────────────

  Widget _buildContent(
    StrategyRecommendationState state,
    Set<String> watchedCodes,
  ) {
    if (state.groups.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: state.hasEnabledStrategies ? '暂无匹配标的' : '暂无启用策略',
        subtitle: state.hasEnabledStrategies
            ? '当前策略可能较严格，或行情数据暂不可用。\n可下拉刷新，或前往策略页降低阈值。'
            : '请前往策略管理启用至少一个策略',
      );
    }

    final allItems = _buildFlatItems(state);
    if (allItems.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: '暂无匹配标的',
        subtitle: '可下拉刷新，或前往策略页调整参数',
      );
    }

    final counts = _countByFilter(allItems);
    final filtered = _applyFilter(allItems);

    return RefreshIndicator(
      color: StockColors.brand,
      onRefresh: () =>
          ref.read(strategyRecommendationProvider.notifier).refresh(),
      child: ListView(
        children: [
          // Dimension filter bar
          _buildFilterBar(counts),

          // Empty filter result
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: EmptyState(
                icon: Icons.filter_alt_off_outlined,
                title: '${_activeFilter.label}暂无标的',
                subtitle: '当前维度没有匹配的标的，可清除筛选查看全部',
                actionText: _activeFilter == RecommendFilter.all ? null : '清除筛选',
                onAction: _activeFilter == RecommendFilter.all
                    ? null
                    : () => setState(() => _activeFilter = RecommendFilter.all),
              ),
            )
          else
            // Flat list
            ...filtered.map((item) {
              final isWatched = watchedCodes.contains(item.code);
              return StockListItem(
                name: item.rec.name,
                code: item.rec.code,
                market: item.rec.market,
                price: item.rec.closePrice,
                changePct: item.rec.changePct,
                score: item.score?.score,
                isBandLow: item.isBandLow,
                prediction: item.prediction,
                expectedRange: item.prediction?.rangeText,
                isWatched: isWatched,
                onWatchToggle: isWatched
                    ? null
                    : () async {
                        final ok = await ref
                            .read(watchlistProvider.notifier)
                            .addToWatchlist(
                              item.rec.code,
                              item.rec.name,
                              item.rec.market,
                            );
                        if (ok && mounted) {
                          ToastHelper.showSuccess(
                            context,
                            '已添加${item.rec.name}到关注列表',
                          );
                        }
                      },
                onTap: () => _navigateToDetail(
                  context,
                  item.rec.code,
                  item.rec.name,
                  item.rec.market,
                  item.strategy.id,
                  item.strategy.name,
                ),
              );
            }),

          // Footer
          const SizedBox(height: 16),
          const DisclaimerLabel(),
          const SizedBox(height: 64),
        ],
      ),
    );
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
