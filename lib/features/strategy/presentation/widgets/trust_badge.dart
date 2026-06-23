import 'package:flutter/material.dart';
import 'package:stockpilot/core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/strategy_trust_engine.dart';

/// 信任度等级徽章，显示 "A" / "B" / "C" / "D"
class TrustBadge extends StatelessWidget {
  final TrustResult trustResult;
  final bool isSmall;

  const TrustBadge({
    super.key,
    required this.trustResult,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = StrategyTrustEngine.trustColor(trustResult.level);
    final bgColor = StrategyTrustEngine.trustBgColor(trustResult.level);

    if (isSmall) {
      // 小号：紧凑的圆角矩形，用于列表页
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          trustResult.level.badgeLabel,
          style: AppTextStyles.micro.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    // 大号：圆形，用于详情页
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        trustResult.level.badgeLabel,
        style: AppTextStyles.h3.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

/// 紧凑版：仅显示等级文字标签 + 描述（用于详情页说明区域）
class TrustDescriptionText extends StatelessWidget {
  final TrustResult trustResult;

  const TrustDescriptionText({super.key, required this.trustResult});

  @override
  Widget build(BuildContext context) {
    final color = StrategyTrustEngine.trustColor(trustResult.level);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          trustResult.label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            trustResult.description,
            style: AppTextStyles.caption.copyWith(
              color: context.sc.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
