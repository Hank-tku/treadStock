import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stockpilot/core/theme/app_colors.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../strategy/domain/strategy_models.dart';
import 'strategy_provider.dart';
import 'widgets/strategy_creation_guide.dart';

/// Standalone page for guided strategy creation.
class StrategyCreationGuidePage extends ConsumerStatefulWidget {
  const StrategyCreationGuidePage({super.key});

  @override
  ConsumerState<StrategyCreationGuidePage> createState() =>
      _StrategyCreationGuidePageState();
}

class _StrategyCreationGuidePageState
    extends ConsumerState<StrategyCreationGuidePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      appBar: AppBar(
        title: const Text('创建策略'),
        backgroundColor: StockColors.bgPrimary,
      ),
      body: StrategyCreationGuide(
        onComplete: _handleComplete,
      ),
    );
  }

  Future<void> _handleComplete(StrategyGuideResult result) async {
    setState(() => _isCreating = true);

    try {
      // Map guide selections to StrategyFormData weights.
      // The guide lets users pick indicators and set relative weights/multipliers.
      // We distribute weight proportionally based on selected indicators.
      final selected = result.selectedIndicators;
      final weightMA = selected.contains(IndicatorType.maTrend) ? result.maWeight : 0.0;
      final weightBoll = selected.contains(IndicatorType.bollinger) ? 0.30 : 0.0;
      final weightVol = selected.contains(IndicatorType.volume) ? 0.20 : 0.0;
      final weightTrend = selected.contains(IndicatorType.composite) ? result.compositeWeight : 0.0;

      // Normalize weights to sum to 1.0
      final rawSum = weightMA + weightBoll + weightVol + weightTrend;
      final normalizedMA = rawSum > 0 ? weightMA / rawSum : 0.25;
      final normalizedBoll = rawSum > 0 ? weightBoll / rawSum : 0.25;
      final normalizedVol = rawSum > 0 ? weightVol / rawSum : 0.25;
      final normalizedTrend = rawSum > 0 ? weightTrend / rawSum : 0.25;

      // Adjust bollStdDev based on offset
      final bollStdDev = 2.0 + result.bollOffset;

      final form = StrategyFormData(
        name: result.name,
        description: _buildDescription(result),
        maShortPeriod: 20,
        maLongPeriod: 60,
        bollPeriod: 20,
        bollStdDev: bollStdDev.clamp(1.0, 3.0),
        weightMA: normalizedMA,
        weightBoll: normalizedBoll,
        weightVol: normalizedVol,
        weightTrend: normalizedTrend,
        recommendThreshold: 7,
      );

      final success = await ref
          .read(strategyListProvider.notifier)
          .createStrategy(form);

      if (!mounted) return;

      if (success) {
        ToastHelper.showSuccess(context, '策略已创建');
        context.pop();
      } else {
        ToastHelper.showError(context, '创建失败，请重试');
        setState(() => _isCreating = false);
      }
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, '创建失败，请重试');
      setState(() => _isCreating = false);
    }
  }

  String _buildDescription(StrategyGuideResult result) {
    final parts = <String>[];
    for (final indicator in result.selectedIndicators) {
      parts.add(indicator.label);
    }
    return '基于${parts.join("、")}的策略';
  }
}
