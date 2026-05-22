import 'dart:async';
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
  String? _selectedSearchCode;

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
    if (_selectedSearchCode != null) {
      setState(() => _selectedSearchCode = null);
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(watchlistProvider.notifier).searchStock(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _selectedSearchCode = null;
    ref.read(watchlistProvider.notifier).searchStock('');
    _searchFocusNode.unfocus();
  }

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
      _clearSearch();
    } else {
      ToastHelper.showError(context, '添加失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(watchlistProvider);
    final notifier = ref.read(watchlistProvider.notifier);
    final showSearchPanel =
        _isSearchFocused ||
        _searchController.text.isNotEmpty ||
        state.isSearching ||
        state.hasSearchError;

    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: Column(
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              12,
              AppTheme.pagePadding,
              8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('关注', style: AppTextStyles.h1),
            ),
          ),

          // Search bar
          _buildSearchBar(state, notifier),

          // Watchlist
          Expanded(
            child: showSearchPanel
                ? _buildSearchResults(state, notifier)
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
                      ? StockColors.borderActive
                      : StockColors.borderFocus,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: StockColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '搜索股票代码或名称',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: StockColors.gray400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: StockColors.gray500,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: StockColors.gray500,
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

  Widget _buildSearchResults(WatchlistState state, WatchlistNotifier notifier) {
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
          style: AppTextStyles.body.copyWith(color: StockColors.gray500),
        ),
      );
    }

    final results = state.searchResults;
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        alignment: Alignment.center,
        child: const Text(
          '未找到匹配股票',
          style: TextStyle(fontSize: 13, color: StockColors.gray500),
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length + 1,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        color: StockColors.border,
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
              '选择一只股票后添加关注',
              style: AppTextStyles.caption.copyWith(
                color: StockColors.textTertiary,
              ),
            ),
          );
        }

        final result = results[index - 1];
        final isWatched = notifier.isWatched(result.code);
        final isAdding = state.isAdding && state.addingCode == result.code;
        final isSelected = _selectedSearchCode == result.code;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding,
            vertical: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isWatched || isAdding
                      ? null
                      : () => setState(() => _selectedSearchCode = result.code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? StockColors.brand.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected
                              ? StockColors.brand
                              : StockColors.gray400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(result.name, style: AppTextStyles.bodyLg),
                              Text(
                                '${result.code} ${result.market}',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                const Text(
                  '已关注',
                  style: TextStyle(fontSize: 14, color: StockColors.gray400),
                )
              else
                TextButton(
                  onPressed: isSelected
                      ? () => _handleAddSearchResult(
                          notifier,
                          result.code,
                          result.name,
                          result.market,
                        )
                      : () => setState(() => _selectedSearchCode = result.code),
                  child: Text(isSelected ? '关注所选' : '选择'),
                ),
            ],
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
                      ? StockColors.gray500
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
                    await notifier.removeFromWatchlist(item.id);
                    if (!mounted) return;
                    ToastHelper.showSuccess(
                      this.context,
                      '已移除${item.stockName}',
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

  String? _formatRange(dynamic item) {
    // Will be populated when Bollinger band data is fetched
    return null;
  }
}
