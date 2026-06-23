import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/toast_helper.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/strategy_models.dart';
import 'strategy_provider.dart';

/// Page for browsing pre-built strategy templates and applying one.
class StrategyTemplatePage extends ConsumerStatefulWidget {
  const StrategyTemplatePage({super.key});

  @override
  ConsumerState<StrategyTemplatePage> createState() =>
      _StrategyTemplatePageState();
}

class _StrategyTemplatePageState extends ConsumerState<StrategyTemplatePage> {
  bool _applying = false;

  Future<void> _applyTemplate(StrategyFormData formData) async {
    if (_applying) return;
    setState(() => _applying = true);

    final detachedForm = StrategyFormData.fromForm(formData);
    final success =
        await ref.read(strategyListProvider.notifier).createStrategy(detachedForm);

    if (!mounted) return;
    setState(() => _applying = false);

    if (success) {
      ToastHelper.showSuccess(context, '策略已创建');
      context.pop();
    } else {
      ToastHelper.showError(context, '创建失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final learningGoals = StrategyLearningGoals.all;
    final classicTemplates = ApiStrategyTemplates.all;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('策略模板'),
      ),
      body: _applying
          ? const Center(
              child: CircularProgressIndicator(color: StockColors.brand),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
                vertical: AppTheme.space4,
              ),
              children: [
                // ── 学习目标模板 ──
                _SectionHeader(title: '学习目标模板'),
                const SizedBox(height: AppTheme.space3),
                if (learningGoals.isEmpty)
                  const EmptyState(
                    icon: Icons.school_outlined,
                    title: '暂无学习目标',
                    subtitle: '还没有可用的学习目标模板',
                  )
                else
                  ...learningGoals.map(
                    (goal) => _LearningGoalCard(
                      goal: goal,
                      onApply: () => _applyTemplate(goal.formData),
                    ),
                  ),

                const SizedBox(height: AppTheme.space7),

                // ── 经典策略模板 ──
                _SectionHeader(title: '经典策略模板'),
                const SizedBox(height: AppTheme.space3),
                if (classicTemplates.isEmpty)
                  const EmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: '暂无经典策略',
                    subtitle: '还没有可用的经典策略模板',
                  )
                else
                  ...classicTemplates.map(
                    (template) => _ClassicTemplateCard(
                      template: template,
                      onApply: () => _applyTemplate(template.formData),
                    ),
                  ),

                // Bottom safe area
                const SizedBox(height: AppTheme.space7),
              ],
            ),
    );
  }
}

/// Section header with a bold title.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        title,
        style: AppTextStyles.h2.copyWith(
          color: context.sc.textPrimary,
        ),
      ),
    );
  }
}

/// Card for a learning goal template.
class _LearningGoalCard extends StatelessWidget {
  final StrategyLearningGoal goal;
  final VoidCallback onApply;

  const _LearningGoalCard({
    required this.goal,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: context.sc.bgPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.sc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 20,
                color: StockColors.brand,
              ),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Text(
                  goal.title,
                  style: AppTextStyles.h3.copyWith(
                    color: context.sc.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),

          // Subtitle / description
          Text(
            goal.subtitle,
            style: AppTextStyles.body.copyWith(
              color: context.sc.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space3),

          // Learning point
          _InfoRow(
            icon: Icons.lightbulb_outline,
            iconColor: StockColors.warning,
            label: '学习要点',
            content: goal.learningPoint,
          ),
          const SizedBox(height: AppTheme.space2),

          // Watch point
          _InfoRow(
            icon: Icons.visibility_outlined,
            iconColor: StockColors.info,
            label: '观察要点',
            content: goal.watchPoint,
          ),
          const SizedBox(height: AppTheme.space4),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: StockColors.brand,
                foregroundColor: context.sc.textOnPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: const Text(
                '应用',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for a classic strategy template.
class _ClassicTemplateCard extends StatelessWidget {
  final ApiStrategyTemplate template;
  final VoidCallback onApply;

  const _ClassicTemplateCard({
    required this.template,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: context.sc.bgPrimary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.sc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 20,
                color: StockColors.brand,
              ),
              const SizedBox(width: AppTheme.space2),
              Expanded(
                child: Text(
                  template.name,
                  style: AppTextStyles.h3.copyWith(
                    color: context.sc.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),

          // Description
          Text(
            template.description,
            style: AppTextStyles.body.copyWith(
              color: context.sc.textSecondary,
            ),
          ),

          // API capabilities chips (if any)
          if (template.apiCapabilities.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space3),
            Wrap(
              spacing: AppTheme.space2,
              runSpacing: AppTheme.space1,
              children: template.apiCapabilities.map((cap) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.sc.bgTertiary,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: Text(
                    cap,
                    style: AppTextStyles.caption.copyWith(
                      color: context.sc.textTertiary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: AppTheme.space4),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                backgroundColor: StockColors.brand,
                foregroundColor: context.sc.textOnPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: const Text(
                '应用',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small info row with icon, label, and content text.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String content;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: AppTheme.space1),
        Text(
          '$label：',
          style: AppTextStyles.caption.copyWith(
            color: context.sc.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            content,
            style: AppTextStyles.caption.copyWith(
              color: context.sc.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
