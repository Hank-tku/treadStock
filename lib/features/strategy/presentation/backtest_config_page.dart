import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../stock/domain/stock_models.dart';
import '../../stock/data/stock_api_service.dart';
import '../domain/backtest_models.dart';
import 'backtest_provider.dart';
import 'backtest_result_page.dart';

/// Page to configure and run a strategy backtest.
class BacktestConfigPage extends ConsumerStatefulWidget {
  final String strategyId;
  final String strategyName;

  const BacktestConfigPage({
    super.key,
    required this.strategyId,
    required this.strategyName,
  });

  @override
  ConsumerState<BacktestConfigPage> createState() => _BacktestConfigPageState();
}

class _BacktestConfigPageState extends ConsumerState<BacktestConfigPage> {
  final _searchController = TextEditingController();
  final _apiService = StockApiService();
  List<StockSearchResult> _searchResults = [];
  StockSearchResult? _selectedStock;
  bool _isSearching = false;

  double _initialCapital = 100000;
  double _positionSize = 1.0;
  double _stopLoss = -5.0;
  double _takeProfit = 15.0;
  bool _isRunning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80,
        ),
        children: [
          _buildHeader(),
          _buildStockSelector(),
          if (_selectedStock != null) ...[
            _buildConfigSection(),
            _buildRunButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, AppTheme.pagePadding, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios, size: 20, color: StockColors.gray700),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                ),
                const Spacer(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('策略回测', style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text(
                    '策略：${widget.strategyName}',
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

  Widget _buildStockSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 16, AppTheme.pagePadding, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择股票', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '输入股票代码或名称搜索',
              hintStyle: AppTextStyles.caption.copyWith(color: StockColors.textTertiary),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              filled: true,
              fillColor: StockColors.bgPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: AppTextStyles.body,
            onChanged: _onSearchChanged,
          ),
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._searchResults.take(5).map(_buildSearchResultItem),
          ],
          if (_selectedStock != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: StockColors.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: StockColors.brand, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedStock!.name} (${_selectedStock!.fullCode})',
                    style: AppTextStyles.body.copyWith(color: StockColors.brand),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedStock = null),
                    child: const Icon(Icons.close, size: 16, color: StockColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(StockSearchResult result) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedStock = result;
          _searchResults = [];
          _searchController.clear();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(result.name, style: AppTextStyles.body),
            const Spacer(),
            Text(result.fullCode, style: AppTextStyles.caption.copyWith(color: StockColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 12, AppTheme.pagePadding, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('回测参数', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          _configRow('初始资金', '${(_initialCapital / 10000).toStringAsFixed(1)}万', _initialCapital, 10000, 1000000, (v) => setState(() => _initialCapital = v)),
          _configRow('仓位比例', '${(_positionSize * 100).toStringAsFixed(0)}%', _positionSize, 0.1, 1.0, (v) => setState(() => _positionSize = v), divisions: 9),
          _configRow('止损', '${_stopLoss.toStringAsFixed(1)}%', _stopLoss.abs(), 1, 20, (v) => setState(() => _stopLoss = -v)),
          _configRow('止盈', '${_takeProfit.toStringAsFixed(1)}%', _takeProfit, 1, 50, (v) => setState(() => _takeProfit = v)),
        ],
      ),
    );
  }

  Widget _configRow(
    String label,
    String value,
    double current,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    int? divisions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body),
              Text(value, style: AppTextStyles.numberSm),
            ],
          ),
          Slider(
            value: current,
            min: min,
            max: max,
            divisions: divisions ?? ((max - min).toInt()),
            activeColor: StockColors.brand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRunButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 20, AppTheme.pagePadding, 0),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isRunning ? null : _runBacktest,
          style: ElevatedButton.styleFrom(
            backgroundColor: StockColors.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          child: _isRunning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('开始回测', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _apiService.searchStock(query);
      if (mounted) {
        setState(() {
          _searchResults = results.take(10).toList();
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _runBacktest() async {
    if (_selectedStock == null) return;
    setState(() => _isRunning = true);

    final market = _selectedStock!.market;
    ref.read(backtestProvider.notifier).reset();

    await ref.read(backtestProvider.notifier).runBacktest(
      strategyId: widget.strategyId,
      stockCode: _selectedStock!.code,
      stockName: _selectedStock!.name,
      market: market,
      config: BacktestConfig(
        initialCapital: _initialCapital,
        positionSize: _positionSize,
        stopLossPct: _stopLoss / 100,
        takeProfitPct: _takeProfit / 100,
      ),
    );

    if (!mounted) return;
    setState(() => _isRunning = false);

    final state = ref.read(backtestProvider);
    if (state.status == BacktestStatus.done && state.result != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BacktestResultPage(result: state.result!),
        ),
      );
    } else if (state.status == BacktestStatus.error) {
      if (mounted) {
        ToastHelper.showError(context, state.errorMessage ?? '回测失败');
      }
    }
  }
}
