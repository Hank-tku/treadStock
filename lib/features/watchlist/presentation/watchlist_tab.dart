import 'dart:async';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:stockpilot/features/settings/presentation/theme_switcher_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/stock_list_item.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import 'watchlist_provider.dart';

/// Watchlist tab (Tab 2) with search, swipe actions (delete/pin).
/// Design: DESIGN.md Page 2 - Watchlist Page.
class WatchlistTab extends ConsumerStatefulWidget {
  const WatchlistTab({super.key});

  @override
  ConsumerState<WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends ConsumerState<WatchlistTab> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
    Future.microtask(() {
      ref.read(watchlistProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(watchlistProvider.notifier).searchStock(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(watchlistProvider.notifier).searchStock('');
    _searchFocusNode.unfocus();
  }

  /// Handle adding a search result to watchlist.
  /// Does NOT clear search — refreshes in-place so user can continue adding.
  Future<void> _handleAddSearchResult(
    WatchlistNotifier notifier,
    String code,
    String name,
    String market,
  ) async {
    final success = await notifier.addToWatchlist(code, name, market);
    if (!mounted) return;
    if (success) {
      ToastHelper.showSuccess(context, '已添加$name到关注列表');
      // Don't clear search — let user continue adding multiple stocks.
      // The watched status updates reactively via ref.watch(watchedCodesProvider).
    } else {
      ToastHelper.showError(context, '添加失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);
    // Reactive watched codes for search result status
    final watchedCodes = ref.watch(watchedCodesProvider);
    final showSearchPanel =
        _isSearchFocused ||
        _searchController.text.isNotEmpty ||
        state.isSearching ||
        state.hasSearchError;

    return Scaffold(
      backgroundColor: context.sc.bgPrimary,
      body: Column(
        children: [
          // Title + theme switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              12,
              AppTheme.pagePadding,
              8,
            ),
            child: Row(
              children: [
                Text('关注', style: AppTextStyles.h1),
                const Spacer(),
                IconButton(
                  onPressed: () => showThemeSwitcherSheet(context),
                  icon: Icon(
                    Icons.dark_mode_outlined,
                    size: 22,
                    color: context.sc.textTertiary,
                  ),
                  tooltip: '主题',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Search bar
          _buildSearchBar(state, notifier),

          // Watchlist
          Expanded(
            child: showSearchPanel
                ? _buildSearchResults(state, notifier, watchedCodes)
                : state.isEmpty
                ? _buildEmptyState()
                : _buildWatchList(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WatchlistState state, WatchlistNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: AppTheme.searchBarHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: _isSearchFocused
                      ? context.sc.borderActive
                      : context.sc.borderFocus,
                  width: 1,
                ),
                boxShadow: _isSearchFocused
                    ? [
                        const BoxShadow(
                          color: StockColors.shadow,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.text,
                style: TextStyle(
                  fontSize: 14,
                  color: context.sc.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '搜索股票代码或名称',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: context.sc.gray400,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: context.sc.gray500,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: context.sc.gray500,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    WatchlistState state,
    WatchlistNotifier notifier,
    Set<String> watchedCodes,
  ) {
    if (state.isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: StockColors.brand,
          ),
        ),
      );
    }

    if (_searchController.text.isEmpty && !state.hasSearchError) {
      return EmptyState(
        icon: Icons.search,
        title: '搜索股票',
        subtitle: '输入股票代码或名称添加关注',
      );
    }

    if (state.hasSearchError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        alignment: Alignment.center,
        child: Text(
          state.searchError ?? '搜索服务暂不可用，请稍后重试',
          style: AppTextStyles.body.copyWith(color: context.sc.gray500),
        ),
      );
    }

    final results = state.searchResults;
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        alignment: Alignment.center,
        child: Text(
          '未找到匹配股票',
          style: TextStyle(fontSize: 13, color: context.sc.gray500),
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length + 1,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: context.sc.border,
        indent: AppTheme.pagePadding,
        endIndent: AppTheme.pagePadding,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              4,
              AppTheme.pagePadding,
              8,
            ),
            child: Text(
              '点击关注即可添加到关注列表',
              style: AppTextStyles.caption.copyWith(
                color: context.sc.textTertiary,
              ),
            ),
          );
        }

        final result = results[index - 1];
        // Use reactive watchedCodes instead of notifier.isWatched
        final isWatched = watchedCodes.contains(result.code);
        final isAdding = state.isAdding && state.addingCode == result.code;

        return InkWell(
          onTap: isWatched || isAdding
              ? null
              : () => _handleAddSearchResult(
                  notifier,
                  result.code,
                  result.name,
                  result.market,
                ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.sc.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.name, style: AppTextStyles.bodyLg),
                      const SizedBox(height: 2),
                      Text(
                        '${result.code} ${result.market}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isAdding)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StockColors.brand,
                    ),
                  )
                else if (isWatched)
                  AnimatedContainer(
                    duration: AppTheme.fastDuration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: StockColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Text(
                      '✓ 已关注',
                      style: TextStyle(
                        fontSize: 13,
                        color: StockColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: StockColors.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Text(
                      '关注',
                      style: TextStyle(
                        fontSize: 13,
                        color: StockColors.brand,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.search,
      title: '暂无关注的股票',
      subtitle: '搜索添加你感兴趣的股票',
    );
  }

  Widget _buildWatchList(WatchlistState state, WatchlistNotifier notifier) {
    return RefreshIndicator(
      color: StockColors.brand,
      onRefresh: () => notifier.refreshAll(),
      child: ListView.builder(
        itemCount: state.items.length + 1, // +1 for disclaimer
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return const Column(
              children: [DisclaimerLabel(), SizedBox(height: 64)],
            );
          }

          final item = state.items[index];
          final bestStrategy = state.bestStrategies[item.stockCode];
          return Slidable(
            key: ValueKey(item.id),
            startActionPane: ActionPane(
              motion: const BehindMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    await notifier.togglePin(item.id, !item.isPinned);
                    if (!mounted) return;
                    ToastHelper.showSuccess(
                      this.context,
                      item.isPinned
                          ? '已取消置顶${item.stockName}'
                          : '已置顶${item.stockName}',
                    );
                  },
                  backgroundColor: item.isPinned
                      ? context.sc.gray500
                      : StockColors.pin,
                  foregroundColor: Colors.white,
                  label: item.isPinned ? '取消置顶' : '置顶',
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) async {
                    // Snapshot before removal so the user can undo.
                    final snapshot = (
                      id: item.id,
                      code: item.stockCode,
                      name: item.stockName,
                      market: item.market,
                    );
                    await notifier.removeFromWatchlist(item.id);
                    if (!mounted) return;
                    ToastHelper.showWithAction(
                      this.context,
                      '已移除${item.stockName}',
                      actionText: '撤销',
                      onAction: () async {
                        await ref
                            .read(watchlistProvider.notifier)
                            .addToWatchlist(
                              snapshot.code,
                              snapshot.name,
                              snapshot.market,
                            );
                      },
                    );
                  },
                  backgroundColor: StockColors.danger,
                  foregroundColor: Colors.white,
                  label: '移除',
                ),
              ],
            ),
            child: StockListItem(
              name: item.stockName,
              code: item.stockCode,
              market: item.market,
              price: item.currentPrice ?? 0,
              changePct: item.currentChangePct ?? 0,
              score: item.currentScore?.score,
              isBandLow: item.currentScore?.isBandLow ?? false,
              isPinned: item.isPinned,
              isAlertTriggered: item.isAlertTriggered ?? false,
              expectedRange: item.isPinned ? _formatRange(item) : null,
              strategyName: bestStrategy?.strategyName,
              scoreReason: bestStrategy?.displayReason,
              riskText: bestStrategy == null ? null : '仅供参考',
              onTap: () => context.push(
                '/stock/${item.stockCode}',
                extra: {
                  'code': item.stockCode,
                  'name': item.stockName,
                  'market': item.market,
                  'strategyId': bestStrategy?.strategyId,
                  'strategyName': bestStrategy?.strategyName,
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // TODO(stage2): populate once K-line / Bollinger band data is wired into the
  // watchlist item. Currently returns null, so expected range is never shown.
  String? _formatRange(dynamic item) {
    return null;
  }
}
