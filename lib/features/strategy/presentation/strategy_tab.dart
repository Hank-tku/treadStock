import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:stockpilot/shared/widgets/app_menu_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import '../domain/strategy_models.dart';
import 'strategy_provider.dart';

/// Strategy list tab (Tab 3).
class StrategyTab extends ConsumerStatefulWidget {
  const StrategyTab({super.key});

  @override
  ConsumerState<StrategyTab> createState() => _StrategyTabState();
}

class _StrategyTabState extends ConsumerState<StrategyTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(strategyListProvider.notifier).loadStrategies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(strategyListProvider);

    return Scaffold(
      backgroundColor: context.sc.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTitleBar(),
            Expanded(
              child: state.isLoading
                  ? _buildLoadingList()
                  : state.hasError
                  ? _buildErrorState()
                  : _buildContentList(state),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/strategy/create'),
        backgroundColor: StockColors.brand,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTitleBar() {
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
            children: [
              const Expanded(child: Text('策略', style: AppTextStyles.h1)),
              const AppMenuButton(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HeaderActionButton(
                  icon: Icons.compare_arrows,
                  label: '对比',
                  onPressed: () => context.push('/strategy/compare'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderActionButton(
                  icon: Icons.school_outlined,
                  label: '关于策略',
                  onPressed: () => context.push('/strategy/knowledge'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return const SingleChildScrollView(
      child: Column(
        children: [
          _StrategyCardSkeleton(),
          _StrategyCardSkeleton(),
          _StrategyCardSkeleton(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const EmptyState(
      icon: Icons.error_outline,
      title: '策略数据加载失败',
      subtitle: '请重启应用重试',
    );
  }

  Widget _buildContentList(StrategyListState state) {
    if (state.strategies.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb_outline,
        title: '暂无策略',
        subtitle: '点击 + 创建你的第一个策略',
      );
    }

    return RefreshIndicator(
      color: StockColors.brand,
      onRefresh: () => ref.read(strategyListProvider.notifier).loadStrategies(),
      child: ListView(
        children: [
          ...state.strategies.map(
            (strategy) => _StrategyCard(
              strategy: strategy,
              onToggle: () => _handleToggle(strategy),
              onTap: () => context.push('/strategy/${strategy.id}'),
            ),
          ),
          const SizedBox(height: 16),
          const DisclaimerLabel(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _handleToggle(Strategy strategy) async {
    await ref
        .read(strategyListProvider.notifier)
        .toggleEnabled(strategy.id, !strategy.isEnabled);
    if (mounted) {
      ToastHelper.showSuccess(
        context,
        strategy.isEnabled ? '已停用${strategy.name}' : '已启用${strategy.name}',
      );
    }
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: TextButton.styleFrom(
          foregroundColor: StockColors.brand,
          backgroundColor: StockColors.brandLight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ),
      ),
    );
  }
}

/// Strategy card widget.
class _StrategyCard extends StatelessWidget {
  final Strategy strategy;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _StrategyCard({
    required this.strategy,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stats = strategy.stats;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: 6,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.sc.bgSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: name + switch
            Row(
              children: [
                Expanded(
                  child: Text(
                    strategy.name,
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (strategy.isDefault)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: StockColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '默认',
                      style: TextStyle(fontSize: 10, color: StockColors.info),
                    ),
                  ),
                Switch(
                  value: strategy.isEnabled,
                  onChanged: (_) => onToggle(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (strategy.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                strategy.description,
                style: AppTextStyles.caption.copyWith(
                  color: context.sc.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            // Stats row
            Row(
              children: [
                _buildStatChip('命中率', stats?.hitRateDisplay ?? '--'),
                const SizedBox(width: 12),
                _buildStatChip('健康度', stats?.healthScoreDisplay ?? '--'),
                const SizedBox(width: 12),
                _buildStatChip('平均差', stats?.avgChangeDisplay ?? '--'),
              ],
            ),
            // Review banner
            if (strategy.needsReview && strategy.isEnabled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.sc.bgWarning,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active,
                      size: 14,
                      color: StockColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '建议进行复盘',
                      style: AppTextStyles.caption.copyWith(
                        color: context.sc.cacheBannerText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.numberSm),
      ],
    );
  }
}

/// Skeleton loading for strategy card.
class _StrategyCardSkeleton extends StatelessWidget {
  const _StrategyCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailSectionSkeleton(height: 20),
          SizedBox(height: 8),
          DetailSectionSkeleton(height: 14),
        ],
      ),
    );
  }
}
