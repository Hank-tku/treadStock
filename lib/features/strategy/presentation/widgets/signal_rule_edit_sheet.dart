import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/signal_rule.dart';

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

/// Bottom sheet for adding/editing a single SignalRule.
/// Returns SignalRule? when user confirms, null on cancel.
class SignalRuleEditSheet extends StatefulWidget {
  final SignalRule? initialRule; // null = add new, non-null = edit existing

  const SignalRuleEditSheet({super.key, this.initialRule});

  @override
  State<SignalRuleEditSheet> createState() => _SignalRuleEditSheetState();

  static Future<SignalRule?> show(BuildContext context,
      {SignalRule? initialRule}) {
    return showModalBottomSheet<SignalRule>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SignalRuleEditSheet(initialRule: initialRule),
    );
  }
}

class _SignalRuleEditSheetState extends State<SignalRuleEditSheet> {
  late String _indicator;
  late String _condition;
  late TextEditingController _valueController;
  late TextEditingController _value2Controller;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    _indicator = rule?.indicator ?? 'rsi';
    _condition = rule?.condition ?? 'gt';
    _valueController = TextEditingController(
      text: rule != null ? rule.value.toString() : '',
    );
    _value2Controller = TextEditingController(
      text: rule?.value2 != null ? rule!.value2.toString() : '',
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _value2Controller.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.initialRule != null;

  void _handleConfirm() {
    final value = double.tryParse(_valueController.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效的阈值')),
      );
      return;
    }

    double? value2;
    if (_condition == 'in_range') {
      value2 = double.tryParse(_value2Controller.text.trim());
      if (value2 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入有效的区间上限')),
        );
        return;
      }
    }

    final rule = SignalRule(
      indicator: _indicator,
      condition: _condition,
      value: value,
      value2: value2,
    );
    Navigator.of(context).pop(rule);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.pagePadding,
        right: AppTheme.pagePadding,
        top: AppTheme.pagePadding,
        bottom: bottomInset.bottom + AppTheme.pagePadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            _isEditMode ? '编辑规则' : '添加规则',
            style: AppTextStyles.h2,
          ),
          const SizedBox(height: 20),

          // Indicator selector
          Text(
            '指标',
            style: AppTextStyles.body.copyWith(color: StockColors.textSecondary),
          ),
          const SizedBox(height: 4),
          _buildDropdown(
            value: _indicator,
            items: _indicatorLabels,
            onChanged: (v) => setState(() => _indicator = v!),
          ),
          const SizedBox(height: 16),

          // Condition selector
          Text(
            '条件',
            style: AppTextStyles.body.copyWith(color: StockColors.textSecondary),
          ),
          const SizedBox(height: 4),
          _buildDropdown(
            value: _condition,
            items: _conditionLabels,
            onChanged: (v) => setState(() => _condition = v!),
          ),
          const SizedBox(height: 16),

          // Threshold input
          Text(
            _condition == 'in_range' ? '下限值' : '阈值',
            style: AppTextStyles.body.copyWith(color: StockColors.textSecondary),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '输入数值',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),

          // Second threshold for in_range
          if (_condition == 'in_range') ...[
            const SizedBox(height: 16),
            Text(
              '上限值',
              style:
                  AppTextStyles.body.copyWith(color: StockColors.textSecondary),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _value2Controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '输入上限数值',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _handleConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: StockColors.brand,
                  ),
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: StockColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
        ),
      ),
    );
  }
}
