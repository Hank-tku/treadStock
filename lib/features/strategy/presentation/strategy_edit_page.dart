import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../domain/signal_rule.dart';
import '../domain/strategy_models.dart';
import 'strategy_provider.dart';
import 'widgets/signal_rule_edit_sheet.dart';

const _indicatorLabels = {
  'rsi': 'RSI',
  'macd': 'MACD',
  'macd_signal': 'MACD 信号线',
  'macd_hist': 'MACD 柱状图',
  'k': 'K 值',
  'd': 'D 值',
  'j': 'J 值',
  'boll_position': '布林带位置',
  'ma_alignment': '均线排列度',
  'vol_price_divergence': '量价背离',
  'vol_ratio': '量比',
};

const _conditionLabels = {
  'gt': '大于',
  'lt': '小于',
  'in_range': '区间内',
  'cross_up': '上穿',
  'cross_down': '下穿',
};

/// Strategy create/edit form page.
class StrategyEditPage extends ConsumerStatefulWidget {
  final String? strategyId; // null = create new
  final StrategySuggestion? suggestion; // optional suggestion to prefill

  const StrategyEditPage({super.key, this.strategyId, this.suggestion});

  @override
  ConsumerState<StrategyEditPage> createState() => _StrategyEditPageState();
}

class _StrategyEditPageState extends ConsumerState<StrategyEditPage> {
  late StrategyFormData _form;
  final TextEditingController _jsonImportController = TextEditingController();
  bool _isSaving = false;
  bool _isEdit = false;
  bool _showAdvancedSettings = false;
  String? _selectedTemplateId;
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.strategyId != null;
    _showAdvancedSettings = _isEdit;

    if (_isEdit) {
      final state = ref.read(strategyListProvider);
      final strategy = state.strategies
          .where((s) => s.id == widget.strategyId)
          .firstOrNull;
      _form = strategy != null
          ? StrategyFormData.fromStrategy(strategy)
          : StrategyFormData();
    } else {
      _form = StrategyFormData();
    }

    // Apply suggestion if provided
    _applySuggestion(widget.suggestion);
  }

  @override
  void dispose() {
    _jsonImportController.dispose();
    super.dispose();
  }

  /// Apply a suggestion's parameter override to the form.
  void _applySuggestion(StrategySuggestion? suggestion) {
    if (suggestion == null || suggestion.parameterKey == null) return;
    final key = suggestion.parameterKey!;
    final value = suggestion.suggestedValue;
    switch (key) {
      case 'maShortPeriod':
        if (value is int) _form.maShortPeriod = value;
      case 'maLongPeriod':
        if (value is int) _form.maLongPeriod = value;
      case 'bollPeriod':
        if (value is int) _form.bollPeriod = value;
      case 'bollStdDev':
        if (value is double) _form.bollStdDev = value;
      case 'weightMA':
        if (value is double) _form.weightMA = value;
      case 'weightBoll':
        if (value is double) _form.weightBoll = value;
      case 'weightVol':
        if (value is double) _form.weightVol = value;
      case 'weightTrend':
        if (value is double) _form.weightTrend = value;
      case 'recommendThreshold':
        if (value is int) _form.recommendThreshold = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StockColors.bgPrimary,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: StockColors.gray700,
          ),
        ),
        title: Text(_isEdit ? '编辑策略' : '创建策略'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StockColors.brand,
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          if (!_isEdit) ...[
            _buildLearningGoalSection(),
            const SizedBox(height: 24),
            _buildAiAssistSection(),
            const SizedBox(height: 24),
            _buildApiTemplateSection(),
            const SizedBox(height: 24),
          ],
          _buildSection('基本信息'),
          _buildTextField(
            label: '策略名称 *',
            hint: '如：短线打板策略',
            value: _form.name,
            maxLength: 20,
            onChanged: (v) => setState(() => _form.name = v),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            label: '策略描述',
            hint: '可选，简要描述策略逻辑',
            value: _form.description,
            maxLength: 100,
            onChanged: (v) => setState(() => _form.description = v),
          ),
          const SizedBox(height: 24),
          _buildAdvancedToggle(),
          if (_showAdvancedSettings) _buildAdvancedSettings(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTextStyles.h3),
    );
  }

  Widget _buildAdvancedToggle() {
    return InkWell(
      onTap: () =>
          setState(() => _showAdvancedSettings = !_showAdvancedSettings),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              _showAdvancedSettings
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: StockColors.textTertiary,
            ),
            const SizedBox(width: 4),
            const Text('高级参数', style: AppTextStyles.h3),
            const Spacer(),
            Text(
              _showAdvancedSettings ? '收起' : '可选',
              style: AppTextStyles.caption.copyWith(
                color: StockColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '新手可以先使用系统生成的参数，运行几天后再根据复盘结果微调。',
          style: AppTextStyles.caption.copyWith(
            color: StockColors.textTertiary,
          ),
        ),
        const SizedBox(height: 16),
        _buildSection('分析参数'),
        _buildNumberField(
          label: 'MA 短期周期',
          value: _form.maShortPeriod,
          min: 5,
          max: 60,
          onChanged: (v) => setState(() => _form.maShortPeriod = v),
        ),
        if (_form.hasMAWarning) _buildWarning('MA 短期周期通常小于长期周期'),
        const SizedBox(height: 12),
        _buildNumberField(
          label: 'MA 长期周期',
          value: _form.maLongPeriod,
          min: 20,
          max: 120,
          onChanged: (v) => setState(() => _form.maLongPeriod = v),
        ),
        const SizedBox(height: 12),
        _buildNumberField(
          label: '布林带周期',
          value: _form.bollPeriod,
          min: 10,
          max: 40,
          onChanged: (v) => setState(() => _form.bollPeriod = v),
        ),
        const SizedBox(height: 24),
        _buildSection('评分权重'),
        _buildWeightField(
          'MA 权重',
          _form.weightMA,
          (v) => setState(() => _form.weightMA = v),
        ),
        _buildWeightField(
          '布林带权重',
          _form.weightBoll,
          (v) => setState(() => _form.weightBoll = v),
        ),
        _buildWeightField(
          '量比权重',
          _form.weightVol,
          (v) => setState(() => _form.weightVol = v),
        ),
        _buildWeightField(
          '趋势权重',
          _form.weightTrend,
          (v) => setState(() => _form.weightTrend = v),
        ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _form.isWeightSumValid
                ? StockColors.success.withValues(alpha: 0.1)
                : StockColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            '权重合计: ${_form.weightSum.toStringAsFixed(2)} ${_form.isWeightSumValid ? '✓' : '(必须等于1.0)'}',
            style: AppTextStyles.body.copyWith(
              color: _form.isWeightSumValid
                  ? StockColors.success
                  : StockColors.danger,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSection('推荐设置'),
        _buildNumberField(
          label: '推荐阈值分数',
          value: _form.recommendThreshold,
          min: 1,
          max: 10,
          onChanged: (v) => setState(() => _form.recommendThreshold = v),
        ),
        const SizedBox(height: 24),
        _buildSection('信号规则'),
        Text(
          '开启后，策略将使用信号规则替代加权评分模式进行判断。',
          style: AppTextStyles.caption.copyWith(color: StockColors.textTertiary),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('启用信号规则模式'),
          value: _form.isRuleBased,
          activeThumbColor: StockColors.brand,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _form.isRuleBased = v),
        ),
        if (_form.isRuleBased) ...[
          const SizedBox(height: 12),
          _buildRulesSection(
            '入场规则',
            _form.entryRules,
            (rules) => setState(() => _form.entryRules = rules),
          ),
          const SizedBox(height: 16),
          _buildRulesSection(
            '出场规则',
            _form.exitRules,
            (rules) => setState(() => _form.exitRules = rules),
          ),
        ],
      ],
    );
  }

  Widget _buildRulesSection(
    String title,
    List<SignalRule> rules,
    ValueChanged<List<SignalRule>> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTextStyles.h3),
            const Spacer(),
            Text(
              '${rules.length} 条规则',
              style:
                  AppTextStyles.caption.copyWith(color: StockColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rules.isEmpty)
          Text(
            '暂无规则，点击下方添加',
            style:
                AppTextStyles.caption.copyWith(color: StockColors.textTertiary),
          )
        else
          ...rules.asMap().entries.map(
                (entry) => _buildRuleCard(entry.key, entry.value, rules, onChanged),
              ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final rule = await SignalRuleEditSheet.show(context);
            if (rule != null) onChanged([...rules, rule]);
          },
          icon: const Icon(Icons.add, size: 16),
          label: const Text('添加规则'),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
    int index,
    SignalRule rule,
    List<SignalRule> rules,
    ValueChanged<List<SignalRule>> onChanged,
  ) {
    final indLabel = _indicatorLabels[rule.indicator] ?? rule.indicator;
    final condLabel = _conditionLabels[rule.condition] ?? rule.condition;
    String valueText = rule.value.toStringAsFixed(1);
    if (rule.condition == 'in_range' && rule.value2 != null) {
      valueText =
          '${rule.value.toStringAsFixed(1)} ~ ${rule.value2!.toStringAsFixed(1)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('$indLabel $condLabel $valueText', style: AppTextStyles.body),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: StockColors.textTertiary),
            onPressed: () {
              final newRules = List<SignalRule>.from(rules)..removeAt(index);
              onChanged(newRules);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApiTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('API 生成基础策略'),
        Text(
          '根据当前可用行情与日K字段生成策略草稿，生成后可继续编辑参数。',
          style: AppTextStyles.caption.copyWith(
            color: StockColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        ...ApiStrategyTemplates.all.map(_buildTemplateCard),
      ],
    );
  }

  Widget _buildLearningGoalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('新手策略向导'),
        Text(
          '先选择一个你能理解的观察目标，系统会生成可编辑的策略草稿。',
          style: AppTextStyles.caption.copyWith(
            color: StockColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        ...StrategyLearningGoals.all.map(_buildLearningGoalCard),
      ],
    );
  }

  Widget _buildLearningGoalCard(StrategyLearningGoal goal) {
    final isSelected = _selectedGoalId == goal.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? StockColors.brand.withValues(alpha: 0.06)
            : StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isSelected ? StockColors.brand : StockColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: isSelected ? StockColors.brand : StockColors.gray400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(
                      goal.subtitle,
                      style: AppTextStyles.body.copyWith(
                        color: StockColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _applyLearningGoal(goal),
                child: Text(isSelected ? '已选择' : '选择'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGuideLine(Icons.school_outlined, goal.learningPoint),
          const SizedBox(height: 4),
          _buildGuideLine(Icons.visibility_outlined, goal.watchPoint),
        ],
      ),
    );
  }

  Widget _buildGuideLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: StockColors.textTertiary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiAssistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('AI 生成辅助'),
        Text(
          '复制规则到任意大模型生成策略 JSON，再粘贴回来导入。App 不会调用模型或上传数据。',
          style: AppTextStyles.caption.copyWith(
            color: StockColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyGenerationRules,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('复制生成规则'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _importJsonStrategy,
                icon: const Icon(Icons.input, size: 18),
                label: const Text('粘贴导入'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _jsonImportController,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '粘贴外部大模型生成的策略 JSON',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(ApiStrategyTemplate template) {
    final isSelected = _selectedTemplateId == template.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StockColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isSelected ? StockColors.brand : StockColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name, style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      style: AppTextStyles.body.copyWith(
                        color: StockColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _applyTemplate(template),
                child: Text(isSelected ? '已生成' : '生成'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final capability in template.apiCapabilities)
                _buildMiniTag(capability),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '字段：${template.requiredFields.join(' / ')}',
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            template.apiSource,
            style: AppTextStyles.caption.copyWith(
              color: StockColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: StockColors.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: StockColors.brand),
      ),
    );
  }

  void _applyTemplate(ApiStrategyTemplate template) {
    setState(() {
      _form = StrategyFormData.fromTemplate(template);
      _selectedTemplateId = template.id;
      _selectedGoalId = null;
    });
    ToastHelper.showSuccess(context, '已生成${template.name}策略草稿');
  }

  void _applyLearningGoal(StrategyLearningGoal goal) {
    setState(() {
      _form = StrategyFormData.fromLearningGoal(goal);
      _selectedGoalId = goal.id;
      _selectedTemplateId = null;
    });
    ToastHelper.showSuccess(context, '已生成${goal.formData.name}策略草稿');
  }

  Future<void> _copyGenerationRules() async {
    await Clipboard.setData(
      const ClipboardData(text: StrategyImportHelper.generationPrompt),
    );
    if (!mounted) return;
    ToastHelper.showSuccess(context, '已复制生成规则');
  }

  void _importJsonStrategy() {
    try {
      final imported = StrategyImportHelper.fromJsonText(
        _jsonImportController.text.trim(),
      );
      setState(() {
        _form = imported;
        _selectedTemplateId = null;
      });
      ToastHelper.showSuccess(context, '已导入策略草稿，请确认后保存');
    } on FormatException catch (e) {
      ToastHelper.showError(context, e.message);
    } catch (_) {
      ToastHelper.showError(context, 'JSON 格式不正确');
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    required int maxLength,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: StockColors.textSecondary),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: StockColors.textSecondary,
            ),
          ),
        ),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, size: 24),
          color: StockColors.brand,
        ),
        Text('$value', style: AppTextStyles.number),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline, size: 24),
          color: StockColors.brand,
        ),
      ],
    );
  }

  Widget _buildWeightField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: StockColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              label: value.toStringAsFixed(2),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              value.toStringAsFixed(2),
              style: AppTextStyles.numberSm,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarning(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 16, color: StockColors.warning),
          const SizedBox(width: 4),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(color: StockColors.warning),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final error = _form.validate();
    if (error != null) {
      ToastHelper.showError(context, error);
      return;
    }

    setState(() => _isSaving = true);

    bool success;
    if (_isEdit) {
      success = await ref
          .read(strategyListProvider.notifier)
          .updateStrategy(widget.strategyId!, _form);
    } else {
      success = await ref
          .read(strategyListProvider.notifier)
          .createStrategy(_form);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ToastHelper.showSuccess(context, _isEdit ? '策略已更新' : '策略创建成功');
      context.pop();
    } else {
      ToastHelper.showError(context, '保存失败，请重试');
    }
  }
}
