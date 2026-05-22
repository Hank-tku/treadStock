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
import '../../../shared/utils/formatters.dart';
import '../../strategy/presentation/strategy_provider.dart';

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
        title: '暂无推荐数据',
        subtitle: state.groups.isEmpty
            ? '暂无启用的策略，请前往策略管理启用至少一个策略'
            : '当前市场无符合条件的股票',
      );
    }

    return RefreshIndicator(
      color: StockColors.brand,
      onRefresh: () =>
          ref.read(strategyRecommendationProvider.notifier).refresh(),
      child: ListView(
        children: [
          // Strategy groups
          for (final group in state.groups) ...[
            _buildSectionHeader(
              group.strategy.id,
              group.strategy.name,
              '${group.recommendations.length}只 · 观察阈值 ${group.strategy.recommendThreshold}',
              group.strategy.description,
            ),
            if (!_collapsedStrategyIds.contains(group.strategy.id))
              if (group.recommendations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                    vertical: 10,
                  ),
                  child: Text(
                    '当前策略暂无匹配标的',
                    style: AppTextStyles.body.copyWith(
                      color: StockColors.textTertiary,
                    ),
                  ),
                )
              else
                ...group.recommendations.map(
                  (item) => StockListItem(
                    name: item.name,
                    code: item.code,
                    market: item.market,
                    price: item.closePrice,
                    changePct: item.changePct,
                    score: item.score?.score,
                    isBandLow: item.isBandLow,
                    strategyName: group.strategy.name,
                    scoreReason: item.score?.reason,
                    riskText: '仅供参考',
                    onTap: () => _navigateToDetail(
                      context,
                      item.code,
                      item.name,
                      item.market,
                      group.strategy.id,
                      group.strategy.name,
                    ),
                  ),
                ),
          ],

          // Disclaimer
          const SizedBox(height: 16),
          const DisclaimerLabel(),
          const SizedBox(height: 64), // space above tab bar
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String strategyId,
    String title,
    String meta,
    String description,
  ) {
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
          ],
        ),
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
