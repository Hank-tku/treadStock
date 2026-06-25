import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
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
  final TextEditingController _jsonImportController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _jsonImportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.sc.bgPrimary,
        appBar: AppBar(
          title: const Text('创建策略'),
          backgroundColor: context.sc.bgPrimary,
          bottom: TabBar(
            labelColor: StockColors.brand,
            unselectedLabelColor: context.sc.textTertiary,
            indicatorColor: StockColors.brand,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: '目标创建'),
              Tab(text: 'AI 辅助生成'),
            ],
          ),
        ),
        body: IgnorePointer(
          ignoring: _isCreating,
          child: Stack(
            children: [
              TabBarView(
                children: [_buildTargetCreationTab(), _buildAiAssistTab()],
              ),
              if (_isCreating)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetCreationTab() {
    return Column(
      children: [
        _TemplateEntryCard(onTap: () => context.push('/strategy/templates')),
        Expanded(child: StrategyCreationGuide(onComplete: _handleComplete)),
      ],
    );
  }

  Widget _buildAiAssistTab() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      children: [
        Text('AI 辅助生成', style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Text(
          '复制规则给任意大模型，让它生成策略 JSON，再粘贴回来创建。App 不会调用模型或上传数据。',
          style: AppTextStyles.caption.copyWith(
            color: context.sc.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: context.sc.brandLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: context.sc.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: StockColors.brand,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '先复制生成规则',
                      style: AppTextStyles.body.copyWith(
                        color: context.sc.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '把规则和你的自然语言想法一起发给大模型，例如“找低位修复、波动不要太大的观察策略”。',
                style: AppTextStyles.caption.copyWith(
                  color: context.sc.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyGenerationRules,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制生成规则'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space5),
        Text('粘贴策略 JSON', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        TextField(
          controller: _jsonImportController,
          minLines: 8,
          maxLines: 12,
          decoration: InputDecoration(
            hintText: '粘贴大模型生成的策略 JSON',
            hintStyle: TextStyle(color: context.sc.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(color: context.sc.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: const BorderSide(color: StockColors.brand),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _createFromJson,
            icon: const Icon(Icons.input, size: 18),
            label: const Text('导入并创建策略'),
            style: ElevatedButton.styleFrom(
              backgroundColor: StockColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        Text(
          '生成内容仅用于本机创建策略，保存前请确认名称、参数和阈值符合你的观察目标。',
          style: AppTextStyles.caption.copyWith(color: context.sc.textTertiary),
        ),
      ],
    );
  }

  Future<void> _handleComplete(StrategyGuideResult result) async {
    try {
      // Map guide selections to StrategyFormData weights.
      // The guide lets users pick indicators and set relative weights/multipliers.
      // We distribute weight proportionally based on selected indicators.
      final selected = result.selectedIndicators;
      final weightMA = selected.contains(IndicatorType.maTrend)
          ? result.maWeight
          : 0.0;
      final weightBoll = selected.contains(IndicatorType.bollinger)
          ? 0.30
          : 0.0;
      final weightVol = selected.contains(IndicatorType.volume) ? 0.20 : 0.0;
      final weightTrend = selected.contains(IndicatorType.composite)
          ? result.compositeWeight
          : 0.0;

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

      await _createStrategy(form);
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, '创建失败，请重试');
      setState(() => _isCreating = false);
    }
  }

  Future<void> _copyGenerationRules() async {
    await Clipboard.setData(
      const ClipboardData(text: StrategyImportHelper.generationPrompt),
    );
    if (!mounted) return;
    ToastHelper.showSuccess(context, '已复制生成规则');
  }

  Future<void> _createFromJson() async {
    try {
      final form = StrategyImportHelper.fromJsonText(
        _jsonImportController.text.trim(),
      );
      await _createStrategy(form);
    } on FormatException catch (e) {
      if (!mounted) return;
      ToastHelper.showError(context, e.message);
    } catch (_) {
      if (!mounted) return;
      ToastHelper.showError(context, 'JSON 格式不正确');
    }
  }

  Future<void> _createStrategy(StrategyFormData form) async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

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
  }

  String _buildDescription(StrategyGuideResult result) {
    final parts = <String>[];
    for (final indicator in result.selectedIndicators) {
      parts.add(indicator.label);
    }
    return '基于${parts.join("、")}的策略';
  }
}

class _TemplateEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _TemplateEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        AppTheme.space4,
        AppTheme.pagePadding,
        0,
      ),
      child: Material(
        color: context.sc.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.sc.brandLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: StockColors.brand,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '从模板快速开始',
                        style: AppTextStyles.body.copyWith(
                          color: context.sc.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '低位修复、趋势延续等现成策略，可直接创建后再微调。',
                        style: AppTextStyles.caption.copyWith(
                          color: context.sc.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.sc.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
