import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_colors.dart';
import 'package:stockpilot/core/theme/app_text_styles.dart';
import 'package:stockpilot/core/theme/app_theme.dart';

/// Indicator type for each strategy dimension the user can select.
enum IndicatorType {
  maTrend('MA趋势', Icons.trending_up, '均线多头/空头结构'),
  bollinger('布林带', Icons.show_chart, '布林带下轨偏移程度'),
  volume('成交量', Icons.bar_chart, '成交量放大倍数'),
  composite('综合评分', Icons.star_outline, '多维度综合加权');

  const IndicatorType(this.label, this.icon, this.description);

  final String label;
  final IconData icon;
  final String description;
}

/// Callback type for when the guide completes with strategy parameters.
typedef StrategyGuideComplete = void Function(StrategyGuideResult result);

/// Result data from the strategy creation guide.
class StrategyGuideResult {
  final String name;
  final Set<IndicatorType> selectedIndicators;
  final double maWeight; // 0.0 - 1.0
  final double bollOffset; // -0.05 to +0.05
  final double volMultiplier; // 1.0 - 5.0
  final double compositeWeight; // 0.0 - 1.0

  const StrategyGuideResult({
    required this.name,
    required this.selectedIndicators,
    required this.maWeight,
    required this.bollOffset,
    required this.volMultiplier,
    required this.compositeWeight,
  });
}

/// Guided strategy creation wizard with 3 steps.
class StrategyCreationGuide extends StatefulWidget {
  final StrategyGuideComplete onComplete;

  const StrategyCreationGuide({
    super.key,
    required this.onComplete,
  });

  @override
  State<StrategyCreationGuide> createState() => _StrategyCreationGuideState();
}

class _StrategyCreationGuideState extends State<StrategyCreationGuide> {
  int _currentStep = 0; // 0, 1, 2

  // Step 1: Selected indicators
  final Set<IndicatorType> _selectedIndicators = {};

  // Step 2: Thresholds
  double _maWeight = 0.30;
  double _bollOffset = 0.0;
  double _volMultiplier = 2.0;
  double _compositeWeight = 0.20;

  // Step 3: Strategy name
  final _nameController = TextEditingController(text: '我的策略');

  // Recommended values
  static const double _maWeightRecommended = 0.30;
  static const double _bollOffsetRecommended = 0.0;
  static const double _volMultiplierRecommended = 2.0;
  static const double _compositeWeightRecommended = 0.20;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canGoNext {
    switch (_currentStep) {
      case 0:
        return _selectedIndicators.isNotEmpty;
      case 1:
        return true;
      case 2:
        return _nameController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _goNext() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Final step - submit
      widget.onComplete(StrategyGuideResult(
        name: _nameController.text.trim(),
        selectedIndicators: Set.from(_selectedIndicators),
        maWeight: _maWeight,
        bollOffset: _bollOffset,
        volMultiplier: _volMultiplier,
        compositeWeight: _compositeWeight,
      ));
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: AppTheme.fastDuration,
            child: _buildStep(),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepSelectIndicators();
      case 1:
        return _buildStepSetThresholds();
      case 2:
        return _buildStepConfirm();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1: Select indicators ──────────────────────────────────

  Widget _buildStepSelectIndicators() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选择关注的指标', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            '可多选，至少选1个。这些指标将用于筛选和评估标的。',
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: IndicatorType.values.map((type) {
              final selected = _selectedIndicators.contains(type);
              return _IndicatorCard(
                type: type,
                selected: selected,
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedIndicators.remove(type);
                    } else {
                      _selectedIndicators.add(type);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Set thresholds ─────────────────────────────────────

  Widget _buildStepSetThresholds() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        key: const ValueKey('step2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置参数阈值', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            '根据选中的指标调整参数。点击"推荐值"可恢复默认。',
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedIndicators.contains(IndicatorType.maTrend))
            _buildSliderTile(
              title: 'MA趋势权重',
              value: _maWeight,
              min: 0.0,
              max: 1.0,
              displayText: '${(_maWeight * 100).round()}%',
              recommended: _maWeightRecommended,
              onChanged: (v) => setState(() => _maWeight = v),
              recommendedLabel: '推荐值 ${(_maWeightRecommended * 100).round()}%',
            ),
          if (_selectedIndicators.contains(IndicatorType.bollinger))
            _buildSliderTile(
              title: '布林带下轨偏移',
              value: _bollOffset,
              min: -0.05,
              max: 0.05,
              displayText: '${(_bollOffset * 100).toStringAsFixed(1)}%',
              recommended: _bollOffsetRecommended,
              onChanged: (v) => setState(() => _bollOffset = v),
              recommendedLabel: '推荐值 ${(_bollOffsetRecommended * 100).toStringAsFixed(1)}%',
            ),
          if (_selectedIndicators.contains(IndicatorType.volume))
            _buildSliderTile(
              title: '成交量放大倍数',
              value: _volMultiplier,
              min: 1.0,
              max: 5.0,
              displayText: '${_volMultiplier.toStringAsFixed(1)}x',
              recommended: _volMultiplierRecommended,
              onChanged: (v) => setState(() => _volMultiplier = v),
              recommendedLabel: '推荐值 ${_volMultiplierRecommended.toStringAsFixed(1)}x',
            ),
          if (_selectedIndicators.contains(IndicatorType.composite))
            _buildSliderTile(
              title: '综合评分权重',
              value: _compositeWeight,
              min: 0.0,
              max: 1.0,
              displayText: '${(_compositeWeight * 100).round()}%',
              recommended: _compositeWeightRecommended,
              onChanged: (v) => setState(() => _compositeWeight = v),
              recommendedLabel: '推荐值 ${(_compositeWeightRecommended * 100).round()}%',
            ),
          if (_selectedIndicators.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text(
                '请先选择至少一个指标',
                style: AppTextStyles.body.copyWith(
                  color: StockColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required String displayText,
    required double recommended,
    required ValueChanged<double> onChanged,
    required String recommendedLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppTextStyles.body)),
              Text(
                displayText,
                style: AppTextStyles.numberSm.copyWith(
                  color: StockColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: StockColors.brand,
            inactiveColor: StockColors.gray200,
            onChanged: onChanged,
          ),
          GestureDetector(
            onTap: () => onChanged(recommended),
            child: Text(
              '📌 $recommendedLabel',
              style: AppTextStyles.caption.copyWith(
                color: StockColors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3: Confirm ────────────────────────────────────────────

  Widget _buildStepConfirm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        key: const ValueKey('step3'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确认策略信息', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          // Strategy name input
          Text('策略名称', style: AppTextStyles.body),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: '输入策略名称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: StockColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: StockColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                borderSide: const BorderSide(color: StockColors.brand),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StockColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('策略摘要', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedIndicators.map((type) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: StockColors.brand.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.label,
                        style: AppTextStyles.caption.copyWith(
                          color: StockColors.brand,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                if (_selectedIndicators.contains(IndicatorType.maTrend))
                  Text(
                    'MA趋势权重：${(_maWeight * 100).round()}%',
                    style: AppTextStyles.caption,
                  ),
                if (_selectedIndicators.contains(IndicatorType.bollinger))
                  Text(
                    '布林带偏移：${(_bollOffset * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.caption,
                  ),
                if (_selectedIndicators.contains(IndicatorType.volume))
                  Text(
                    '量比倍数：${_volMultiplier.toStringAsFixed(1)}x',
                    style: AppTextStyles.caption,
                  ),
                if (_selectedIndicators.contains(IndicatorType.composite))
                  Text(
                    '综合评分权重：${(_compositeWeight * 100).round()}%',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        12,
        AppTheme.pagePadding,
        16,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: StockColors.border)),
        color: StockColors.bgPrimary,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final isActive = i == _currentStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? StockColors.brand
                      : StockColors.gray300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentStep + 1}/3',
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          // Buttons
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goBack,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                    child: const Text('上一步'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canGoNext ? _goNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StockColors.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: StockColors.gray300,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                  ),
                  child: Text(
                    _currentStep == 2 ? '创建策略' : '下一步',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single indicator card widget for step 1.
class _IndicatorCard extends StatelessWidget {
  final IndicatorType type;
  final bool selected;
  final VoidCallback onTap;

  const _IndicatorCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fastDuration,
        width: (MediaQuery.of(context).size.width - AppTheme.pagePadding * 2 - 12) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? StockColors.brand.withValues(alpha: 0.08)
              : StockColors.bgSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? StockColors.brand : StockColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type.icon,
                  size: 20,
                  color: selected ? StockColors.brand : StockColors.gray500,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    type.label,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: selected ? StockColors.brand : StockColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: StockColors.brand,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              type.description,
              style: AppTextStyles.caption.copyWith(
                color: StockColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
