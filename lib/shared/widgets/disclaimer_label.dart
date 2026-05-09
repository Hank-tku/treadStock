import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';

/// Disclaimer label shown at bottom of recommendation and detail pages.
/// Design: DESIGN.md Disclaimer spec.
class DisclaimerLabel extends StatelessWidget {
  const DisclaimerLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 16,
      ),
      child: Text(
        AppConstants.disclaimer,
        style: AppTextStyles.caption.copyWith(
          color: StockColors.gray400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
