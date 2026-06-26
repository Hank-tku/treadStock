import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/score_badge.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/disclaimer_label.dart';
import 'kline_chart/stock_kline_chart.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/utils/formatters.dart';
import '../../stock/domain/stock_models.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../strategy/domain/strategy_scoring_service.dart';
import '../../../shared/providers.dart';
import '../../watchlist/presentation/watchlist_provider.dart';
import '../../../shared/widgets/decision_labels/decision_labels_panel.dart';
import '../../strategy/domain/decision_engine.dart';
import '../../strategy/domain/decision_signal_engine.dart';
import '../../strategy/domain/signal_card.dart';
import '../../strategy/presentation/widgets/signal_card_widget.dart';
import '../../strategy/presentation/widgets/decision_signal_badge.dart';
import '../../strategy/presentation/widgets/decision_bubble.dart';

/// Stock detail page.
/// Design: DESIGN.md Page 3 - Stock Detail Page.
class StockDetailPage extends ConsumerStatefulWidget {
  final String code;
  final String name;
  final String market;
  final String? strategyId;
  final String? strategyName;

  const StockDetailPage({
    super.key,
    required this.code,
    required this.name,
    required this.market,
    this.strategyId,
    this.strategyName,
  });

  @override
  ConsumerState<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends ConsumerState<StockDetailPage> {
  List<DailyKline>? _klines;
  StockQuote? _quote;
  StockScore? _score;
  List<StockNews>? _news;
  bool _isLoading = true;
  bool _loadError = false;
  bool _newsLoading = true;
  bool _newsError = false;
  bool _alertEnabled = false;
  bool _isWatched = false;
  final TextEditingController _alertThresholdController =
      TextEditingController();
  int _klineDays = 120;
  bool _klineLoading = false;
  double? _ma20;
  double? _ma60;
  StrategyScoreResult? _strategyScore;
  List<StrategyScoreResult>? _allStrategyScores;
  List<SignalCard>? _signalCards;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Initialize alert state from persisted watchlist.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAlertState();
    });
  }

  Future<void> _initAlertState() async {
    final watchlistService = ref.read(watchlistServiceProvider);
    await watchlistService.init();
    final item = watchlistService.findByCode(widget.code);
    if (!mounted) return;
    setState(() {
      _isWatched = item != null;
      _alertEnabled = item?.alertEnabled ?? false;
    });
    _syncThresholdController(item?.alertPriceThreshold);
  }

  void _syncThresholdController(double? threshold) {
    _alertThresholdController.text = threshold == null
        ? ''
        : threshold.toStringAsFixed(2);
  }

  /// Save the price-threshold field. Empty / invalid input clears the
  /// threshold (disables price-based alerts, keeps the technical check).
  Future<void> _saveAlertThreshold() async {
    final raw = _alertThresholdController.text.trim();
    double? parsed;
    if (raw.isNotEmpty) {
      parsed = double.tryParse(raw);
      if (parsed == null || parsed <= 0) {
        if (!mounted) return;
        ToastHelper.showError(context, '请输入有效的正数价格');
        return;
      }
    }
    final watchlistService = ref.read(watchlistServiceProvider);
    await watchlistService.init();
    await watchlistService.setAlertThreshold(widget.code, parsed);
    if (!mounted) return;
    ref.read(watchlistProvider.notifier).reload();
    ToastHelper.showSuccess(
      context,
      parsed == null ? '已清除价格提醒' : '已设置价格提醒 ¥${parsed.toStringAsFixed(2)}',
    );
  }

  /// Toggle this stock in / out of the watchlist.
  /// The star icon and the alert switch both depend on watch state, so we
  /// refresh it here and reload the watchlist provider so other screens stay
  /// in sync.
  Future<void> _toggleWatch() async {
    final watchlistService = ref.read(watchlistServiceProvider);
    await watchlistService.init();
    final existing = watchlistService.findByCode(widget.code);

    if (existing != null) {
      await watchlistService.removeFromWatchlist(existing.id);
      if (!mounted) return;
      setState(() {
        _isWatched = false;
        _alertEnabled = false;
      });
      ref.read(watchlistProvider.notifier).reload();
      ToastHelper.showSuccess(context, '已取消关注${widget.name}');
    } else {
      await watchlistService.addToWatchlist(
        widget.code,
        widget.name,
        widget.market,
      );
      if (!mounted) return;
      setState(() => _isWatched = true);
      ref.read(watchlistProvider.notifier).reload();
      ToastHelper.showSuccess(context, '已加入关注${widget.name}');
    }
  }

  Future<void> _loadData() async {
    final apiService = ref.read(cachedStockApiServiceProvider);
    final engine = ref.read(analysisEngineProvider);
    final strategyService = ref.read(strategyServiceProvider);
    final scoringService = ref.read(strategyScoringServiceProvider);

    setState(() {
      _isLoading = true;
      _loadError = false;
    });
    try {
      // P0/P1: price, chart and score should use cached K-lines first.
      final klines = await apiService.fetchStockKline(
        widget.code,
        market: widget.market,
      );
      if (klines.isNotEmpty) {
        setState(() => _klines = klines);
        await strategyService.init();
        final strategies = strategyService.getEnabledStrategies();
        final selectedStrategy = widget.strategyId == null
            ? null
            : strategies
                  .where((strategy) => strategy.id == widget.strategyId)
                  .firstOrNull;
        final lastKline = klines.last;
        final quote = StockQuote(
          code: widget.code,
          name: widget.name,
          market: widget.market,
          price: lastKline.close,
          changePct: lastKline.changePct,
          changeAmt: lastKline.close - lastKline.preClose,
          openPrice: lastKline.open,
          highPrice: lastKline.high,
          lowPrice: lastKline.low,
          preClose: lastKline.preClose,
          volume: lastKline.volume,
          turnover: 0,
        );
        setState(() => _quote = quote);
        final strategyScore = selectedStrategy != null
            ? scoringService.scoreStock(
                quote: quote,
                klines: klines,
                strategy: selectedStrategy,
              )
            : scoringService.bestScore(
                quote: quote,
                klines: klines,
                strategies: strategies,
              );
        final score = strategyScore?.score ?? engine.calculateScore(klines);
        setState(() => _score = score);
        setState(() => _strategyScore = strategyScore);

        // Score all strategies for decision signal
        final allScores = <StrategyScoreResult>[];
        for (final s in strategies) {
          final result = scoringService.scoreStock(
            quote: quote,
            klines: klines,
            strategy: s,
          );
          allScores.add(result);
        }
        allScores.sort((a, b) => b.score.score.compareTo(a.score.score));
        setState(() => _allStrategyScores = allScores);

        final signalCards = DecisionSignalEngine.evaluateMultiple(
          klines: klines,
          strategies: selectedStrategy != null
              ? [selectedStrategy]
              : strategies,
          stockCode: widget.code,
          stockName: widget.name,
          currentPrice: lastKline.close,
          changePct: lastKline.changePct,
        );
        setState(() => _signalCards = signalCards);

        final closes = klines.map((k) => k.close).toList();
        final ma20List = engine.calculateMA(closes, 20);
        final ma60List = engine.calculateMA(closes, 60);
        setState(() {
          _ma20 = ma20List.isNotEmpty ? ma20List.last : null;
          _ma60 = ma60List.isNotEmpty ? ma60List.last : null;
        });
      }
    } catch (e, st) {
      // K-line / score load failed. Unlike the previous silent swallow, mark
      // the page as load-error so the UI can surface a retry affordance
      // instead of showing a blank price section.
      debugPrint('[StockDetail] load failed for ${widget.code}: $e\n$st');
      if (mounted) setState(() => _loadError = true);
    }

    if (mounted) setState(() => _isLoading = false);

    // P3: news is useful context, but it should never block the decision
    // surface. Schedule it after the primary chart/score path has settled.
    Future.microtask(_loadNews);
  }

  Future<void> _loadNews() async {
    setState(() => _newsLoading = true);
    setState(() => _newsError = false);
    try {
      final apiService = ref.read(stockApiServiceProvider);
      final news = await apiService.fetchStockNews(widget.code);
      setState(() {
        _news = news;
        _newsLoading = false;
      });
    } catch (_) {
      setState(() {
        _newsLoading = false;
        _newsError = true;
      });
    }
  }

  /// Re-fetch K-line data for a different period (60/120/250 days) without
  /// recomputing scores. Used by the chart's period switcher. Failures are
  /// surfaced as a toast but never block the page — the previous period's
  /// data stays visible.
  Future<void> _fetchKlines(int days) async {
    if (_klineLoading) return;
    final apiService = ref.read(cachedStockApiServiceProvider);
    setState(() => _klineLoading = true);
    try {
      final klines = await apiService.fetchStockKline(
        widget.code,
        market: widget.market,
        days: days,
      );
      if (!mounted) return;
      setState(() {
        _klines = klines;
        _klineDays = days;
      });
    } catch (e, st) {
      debugPrint('[StockDetail] _fetchKlines($days) failed: $e\n$st');
      if (!mounted) return;
      ToastHelper.showError(context, 'K线数据加载失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _klineLoading = false);
    }
  }

  Widget _buildKlineSection() {
    const periods = [(60, '60天'), (120, '120天'), (250, '250天')];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Period switcher row.
          Row(
            children: periods.map((p) {
              final selected = _klineDays == p.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: _klineLoading ? null : () => _fetchKlines(p.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? StockColors.brand
                          : context.sc.bgSecondary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: selected ? StockColors.brand : context.sc.border,
                      ),
                    ),
                    child: Text(
                      p.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? Colors.white
                            : context.sc.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Chart area: fixed height (k_chart needs bounded height inside a
          // ListView). Stack a loading overlay over the previous chart while a
          // period switch is in flight so the UI does not collapse.
          Stack(
            children: [
              if (_klines != null && _klines!.isNotEmpty)
                StockKlineChart(
                  key: ValueKey(
                    '${_klineDays}_${_klines!.length}_${_klines!.last.close}',
                  ),
                  klines: _klines!,
                )
              else
                const SizedBox(height: StockKlineChart.defaultHeight),
              if (_klineLoading)
                Positioned.fill(
                  child: Container(
                    color: context.sc.bgPrimary.withValues(alpha: 0.6),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StockColors.brand,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }
  }

  @override
  void dispose() {
    _alertThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.sc.bgPrimary,
      body: RefreshIndicator(
        color: StockColors.brand,
        onRefresh: _loadData,
        child: ListView(
          children: [
            // Navigation bar + header
            _buildHeader(),

            // When the main data load failed (and we have no klines at all),
            // surface a retry affordance instead of a blank price section.
            if (_loadError && _klines == null) ...[
              _buildLoadErrorState(),
              const DisclaimerLabel(),
              const SizedBox(height: 80),
            ] else ...[
              // Price section
              _isLoading
                  ? const DetailSectionSkeleton(height: 120)
                  : _buildPriceSection(),

              // K-line chart section (candles + MA + BOLL + volume).
              _isLoading
                  ? const DetailSectionSkeleton(
                      height: StockKlineChart.defaultHeight,
                    )
                  : _buildKlineSection(),

              // Score + indicators section
              _isLoading
                  ? const DetailSectionSkeleton(height: 80)
                  : _buildScoreSection(),

              _isLoading
                  ? const SizedBox.shrink()
                  : _buildStrategyScoreSection(),

              // Signal cards
              _isLoading ? const SizedBox.shrink() : _buildSignalCardsSection(),

              // Decision signal card
              _isLoading
                  ? const SizedBox.shrink()
                  : _buildDecisionSignalOverviewSection(),

              // Decision bubble for signal explanation
              _isLoading ? const SizedBox.shrink() : _buildDecisionBubble(),

              // Decision labels
              _isLoading
                  ? const SizedBox.shrink()
                  : DecisionLabelsPanel(score: _score),

              // Company info section
              _isLoading
                  ? const DetailSectionSkeleton(height: 80)
                  : _buildCompanyInfoSection(),

              // Daily summary section
              _isLoading
                  ? const DetailSectionSkeleton(height: 80)
                  : _buildSummarySection(),

              // News section
              const SizedBox(height: 8),
              _buildNewsSection(),

              // Disclaimer
              const DisclaimerLabel(),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, AppTheme.pagePadding, 0),
        child: Column(
          children: [
            // Nav row
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    size: 20,
                    color: context.sc.gray700,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                const Spacer(),
                // Watch toggle (add / remove from watchlist). Placed before the
                // alert switch because enabling alerts requires being watched.
                IconButton(
                  onPressed: _toggleWatch,
                  icon: Icon(
                    _isWatched
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 26,
                    color: _isWatched
                        ? const Color(0xFFF5A623)
                        : context.sc.gray700,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  tooltip: _isWatched ? '取消关注' : '加入关注',
                ),
                // Alert toggle switch.
                Switch(
                  value: _alertEnabled,
                  onChanged: (value) async {
                    final watchlistService = ref.read(watchlistServiceProvider);
                    await watchlistService.init();
                    final item = watchlistService.findByCode(widget.code);

                    // Guard: alerts require the stock to be in the watchlist.
                    // Without this, the switch would visually toggle but the
                    // flag is never persisted (silent no-op).
                    if (item == null) {
                      if (!mounted) return;
                      setState(() => _alertEnabled = false);
                      ToastHelper.showError(context, '请先加入关注后再开启提醒');
                      return;
                    }

                    setState(() => _alertEnabled = value);
                    await watchlistService.toggleAlert(item.id, value);
                    ref.read(watchlistProvider.notifier).reload();

                    if (!mounted) return;

                    if (value) {
                      ToastHelper.showSuccess(context, '已开启${widget.name}下跌预警');
                    } else {
                      ToastHelper.showSuccess(context, '已关闭${widget.name}下跌预警');
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Stock name + code
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.name, style: AppTextStyles.h1),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.code}.${widget.market}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            // Price-threshold alert config — only when watched & alert on.
            // Lets the user set a "notify when price drops at or below X".
            if (_isWatched && _alertEnabled) _buildAlertThresholdRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertThresholdRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        8,
        AppTheme.pagePadding,
        4,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _alertThresholdController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                hintText: '价格提醒（选填）',
                prefixText: '¥ ',
                prefixStyle: AppTextStyles.body.copyWith(
                  color: context.sc.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(color: context.sc.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: BorderSide(color: context.sc.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  borderSide: const BorderSide(color: StockColors.brand),
                ),
              ),
              style: AppTextStyles.body,
              onSubmitted: (_) => _saveAlertThreshold(),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: _saveAlertThreshold, child: const Text('保存')),
        ],
      ),
    );
  }

  /// Full-width error state shown when the main data load fails and we have
  /// no klines to display. Mirrors the news-section error handling by offering
  /// a retry button (alongside pull-to-refresh).
  Widget _buildLoadErrorState() {
    return EmptyState(
      icon: Icons.cloud_off,
      title: '数据加载失败',
      subtitle: '行情数据暂时无法获取，请检查网络后重试',
      actionText: '重试',
      onAction: _loadData,
    );
  }

  Widget _buildPriceSection() {
    if (_klines == null || _klines!.isEmpty) {
      return const SizedBox.shrink();
    }

    final lastKline = _klines!.last;
    final price = lastKline.close;
    final changePct = lastKline.changePct;
    final changeAmt = price - lastKline.open;
    final priceColor = getPriceColor(changePct);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Large price
          Text(
            Formatters.formatPriceLarge(price),
            style: AppTextStyles.displayLg.copyWith(color: priceColor),
          ),
          const SizedBox(height: 4),
          // Change amount + percentage
          Text(
            '${Formatters.formatChangeAmt(changeAmt)}  ${Formatters.formatChangePct(changePct)}',
            style: AppTextStyles.numberLg.copyWith(color: priceColor),
          ),
          const SizedBox(height: 12),
          // Today's stats: open, high, low, volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('今开', Formatters.formatPriceLarge(lastKline.open)),
              _buildStatItem('最高', Formatters.formatPriceLarge(lastKline.high)),
              _buildStatItem('最低', Formatters.formatPriceLarge(lastKline.low)),
              _buildStatItem('成交量', Formatters.formatVolume(lastKline.volume)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.numberSm),
      ],
    );
  }

  Widget _buildScoreSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Row(
        children: [
          // Score card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: getScoreBgColor(_score?.score),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  ScoreBadge(score: _score?.score),
                  const SizedBox(height: 4),
                  Text(
                    _score?.label ?? '数据不足',
                    style: AppTextStyles.caption.copyWith(
                      color: getScoreColor(_score?.score),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // MA20 card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.sc.bgSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  const Text('MA20', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    _ma20 != null ? '¥${_ma20!.toStringAsFixed(1)}' : '--',
                    style: AppTextStyles.numberSm,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // MA60 card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.sc.bgSecondary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  const Text('MA60', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    _ma60 != null ? '¥${_ma60!.toStringAsFixed(1)}' : '--',
                    style: AppTextStyles.numberSm,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyScoreSection() {
    final strategyScore = _strategyScore;
    final routeStrategyName = widget.strategyName;
    if (strategyScore == null && routeStrategyName == null) {
      return const SizedBox.shrink();
    }

    final strategyName =
        strategyScore?.strategyName ?? routeStrategyName ?? '--';
    final score = strategyScore?.score.score ?? _score?.score;
    final reason =
        strategyScore?.displayReason ?? _score?.reason ?? '数据不足，暂无策略评分';

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          ScoreBadge(score: score),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前策略：$strategyName', style: AppTextStyles.h3),
                const SizedBox(height: 3),
                Text(
                  '该标的评分：${score?.toString() ?? '--'} · $reason',
                  style: AppTextStyles.caption.copyWith(
                    color: context.sc.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalCardsSection() {
    final cards = _signalCards;
    if (cards == null || cards.isEmpty) {
      return const SizedBox.shrink();
    }

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
          child: Text('信号卡片', style: AppTextStyles.h2),
        ),
        ...cards.map(
          (card) => SignalCardWidget(
            card: card,
            onTap: () {
              // Keep current behavior simple: signal card is informational.
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDecisionSignalOverviewSection() {
    final strategyScore = _strategyScore;
    final allScores = _allStrategyScores ?? const <StrategyScoreResult>[];
    if (strategyScore == null) {
      return const SizedBox.shrink();
    }

    final signal = _decisionSignalFor(strategyScore);
    final signalScore = strategyScore.score.score / 10.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecisionSignalBadge(signal: signal, isSmall: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strategyScore.displayTitle, style: AppTextStyles.h3),
                const SizedBox(height: 3),
                Text(
                  strategyScore.displayReason,
                  style: AppTextStyles.caption.copyWith(
                    color: context.sc.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '策略数：${allScores.length} · 信号强度 ${(signalScore * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: context.sc.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DecisionSignal _decisionSignalFor(StrategyScoreResult result) {
    final score = result.score.score;
    if (score >= result.recommendThreshold + 1) {
      return DecisionSignal.strongWatch;
    }
    if (score >= result.recommendThreshold) {
      return DecisionSignal.watch;
    }
    if (score >= 5) {
      return DecisionSignal.observe;
    }
    return DecisionSignal.notRecommended;
  }

  Widget _buildDecisionBubble() {
    final strategyScore = _strategyScore;
    if (strategyScore == null) return const SizedBox.shrink();

    final signal = _decisionSignalFor(strategyScore);
    final signalColor = DecisionEngine.signalColor(signal);
    final reason = strategyScore.displayReason;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        6,
        AppTheme.pagePadding,
        0,
      ),
      child: DecisionBubble(
        summaryText: reason,
        detailText: '该信号由策略评分、历史命中率和样本量综合计算，仅作观察参考，不构成任何投资建议。',
        signalColor: signalColor,
      ),
    );
  }

  Widget _buildCompanyInfoSection() {
    final quote = _quote;
    if (quote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.pagePadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('基础信息', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _buildInfoRow('代码', quote.fullCode),
          _buildInfoRow('今开', Formatters.formatPriceLarge(quote.openPrice)),
          _buildInfoRow('昨收', Formatters.formatPriceLarge(quote.preClose)),
          _buildInfoRow('最高', Formatters.formatPriceLarge(quote.highPrice)),
          _buildInfoRow('最低', Formatters.formatPriceLarge(quote.lowPrice)),
          _buildInfoRow('成交量', Formatters.formatVolume(quote.volume)),
          _buildInfoRow('换手率', '${quote.turnover.toStringAsFixed(2)}%'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(color: context.sc.textSecondary),
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final engine = ref.read(analysisEngineProvider);
    final summary = _klines != null && _klines!.isNotEmpty
        ? engine.generateSummary(_klines!, widget.code)
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('每日跟踪摘要', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          if (summary != null)
            Text(
              summary.summaryText,
              style: AppTextStyles.bodyLg.copyWith(
                color: context.sc.textSecondary,
                height: 1.6,
              ),
            )
          else
            Text(
              '数据不足，暂无摘要',
              style: AppTextStyles.body.copyWith(
                color: context.sc.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            16,
            AppTheme.pagePadding,
            8,
          ),
          child: const Text('最新新闻', style: AppTextStyles.h2),
        ),

        if (_newsLoading)
          const Column(
            children: [
              NewsItemSkeleton(),
              NewsItemSkeleton(),
              NewsItemSkeleton(),
            ],
          )
        else if (_newsError)
          _buildNewsError()
        else if (_news == null || _news!.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: Text(
              '暂无相关新闻',
              style: TextStyle(fontSize: 13, color: context.sc.gray500),
            ),
          )
        else
          ..._news!.take(10).map((news) => _buildNewsItem(news)),
      ],
    );
  }

  Widget _buildNewsError() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        children: [
          Icon(Icons.wifi_off, size: 32, color: context.sc.gray400),
          const SizedBox(height: 8),
          Text(
            '新闻加载失败',
            style: TextStyle(fontSize: 13, color: context.sc.textSecondary),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _loadNews,
            child: const Text(
              '点击重试',
              style: TextStyle(fontSize: 13, color: StockColors.brand),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(StockNews news) {
    return InkWell(
      onTap: news.sourceUrl.isNotEmpty
          ? () => _launchUrl(news.sourceUrl)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pagePadding,
          vertical: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.title,
              style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w400),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${news.source.isNotEmpty ? news.source : ""}  ${Formatters.formatRelativeTime(news.publishedAt)}',
              style: AppTextStyles.caption,
            ),
            Divider(height: 16, color: context.sc.border),
          ],
        ),
      ),
    );
  }
}
