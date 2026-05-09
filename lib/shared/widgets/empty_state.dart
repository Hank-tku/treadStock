import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Empty state widget with icon, title, subtitle, and optional CTA.
/// Design: DESIGN.md EmptyState component spec.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: StockColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.bodyLg.copyWith(
                color: StockColors.gray800,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: StockColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionText!,
                  style: const TextStyle(
                    color: StockColors.brand,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
