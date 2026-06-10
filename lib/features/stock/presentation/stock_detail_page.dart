import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/score_badge.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/disclaimer_label.dart';
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
  bool _newsLoading = true;
  bool _newsError = false;
  bool _alertEnabled = false;
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
    if (item != null && mounted) {
      setState(() => _alertEnabled = item.alertEnabled);
    }
  }

  Future<void> _loadData() async {
    final apiService = ref.read(stockApiServiceProvider);
    final engine = ref.read(analysisEngineProvider);
    final strategyService = ref.read(strategyServiceProvider);
    final scoringService = ref.read(strategyScoringServiceProvider);

    try {
      // Fetch kline data
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
          strategies: selectedStrategy != null ? [selectedStrategy] : strategies,
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
    } catch (_) {
      // Score calculation failed, show what we can
    }

    setState(() => _isLoading = false);

    // Fetch news in parallel
    _loadNews();
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

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: RefreshIndicator(
        color: StockColors.brand,
        onRefresh: _loadData,
        child: ListView(
          children: [
            // Navigation bar + header
            _buildHeader(),

            // Price section
            _isLoading
                ? const DetailSectionSkeleton(height: 120)
                : _buildPriceSection(),

            // Score + indicators section
            _isLoading
                ? const DetailSectionSkeleton(height: 80)
                : _buildScoreSection(),

            _isLoading ? const SizedBox.shrink() : _buildStrategyScoreSection(),

            // Signal cards
            _isLoading ? const SizedBox.shrink() : _buildSignalCardsSection(),

            // Decision signal card
            _isLoading ? const SizedBox.shrink() : _buildDecisionSignalOverviewSection(),

            // Decision labels
            _isLoading ? const SizedBox.shrink() : DecisionLabelsPanel(score: _score),

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
                // Alert toggle switch
                Switch(
                  value: _alertEnabled,
                  onChanged: (value) async {
                    setState(() => _alertEnabled = value);

                    // Persist alert toggle to watchlist service.
                    final watchlistService = ref.read(watchlistServiceProvider);
                    await watchlistService.init();
                    final item = watchlistService.findByCode(widget.code);
                    if (item != null) {
                      await watchlistService.toggleAlert(item.id, value);
                      // Also update provider state so other screens see the change.
                      ref.read(watchlistProvider.notifier).reload();
                    }

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
          ],
        ),
      ),
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
                color: StockColors.bgSecondary,
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
                color: StockColors.bgSecondary,
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
        color: StockColors.bgSecondary,
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
        color: StockColors.bgSecondary,
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
                    color: StockColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '策略数：${allScores.length} · 信号强度 ${(signalScore * 100).toStringAsFixed(0)}%',
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

  Widget _buildCompanyInfoSection() {
    final quote = _quote;
    if (quote == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.pagePadding),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
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
            style: AppTextStyles.body.copyWith(
              color: StockColors.textSecondary,
            ),
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
        color: StockColors.bgSecondary,
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
                color: StockColors.textSecondary,
                height: 1.6,
              ),
            )
          else
            Text(
              '数据不足，暂无摘要',
              style: AppTextStyles.body.copyWith(
                color: StockColors.textTertiary,
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
            child: const Text(
              '暂无相关新闻',
              style: TextStyle(fontSize: 13, color: StockColors.gray500),
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
          const Icon(Icons.wifi_off, size: 32, color: StockColors.gray400),
          const SizedBox(height: 8),
          const Text(
            '新闻加载失败',
            style: TextStyle(fontSize: 13, color: StockColors.textSecondary),
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
            const Divider(height: 16, color: StockColors.border),
          ],
        ),
      ),
    );
  }
}
