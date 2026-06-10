import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// 决策解读气泡
/// 显示在信号标签/徽章旁边，提供大白话解读
class DecisionBubble extends StatefulWidget {
  /// 主要解读文字（一行摘要）
  final String summaryText;

  /// 展开后的详细说明
  final String detailText;

  /// 信号颜色（用于圆点和背景）
  final Color signalColor;

  const DecisionBubble({
    super.key,
    required this.summaryText,
    required this.detailText,
    required this.signalColor,
  });

  @override
  State<DecisionBubble> createState() => _DecisionBubbleState();
}

class _DecisionBubbleState extends State<DecisionBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // 浅色背景 = 信号色 10% 透明度
    final bgColor = widget.signalColor.withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧小圆点
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.signalColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 解读文字
              Expanded(
                child: Text(
                  widget.summaryText,
                  style: AppTextStyles.caption.copyWith(
                    color: StockColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              // 右上角问号图标
              if (widget.detailText.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.help_outline,
                      size: 14,
                      color: StockColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          // 展开详情
          if (widget.detailText.isNotEmpty)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: 14,
                        top: 6,
                      ),
                      child: Text(
                        widget.detailText,
                        style: AppTextStyles.caption.copyWith(
                          color: StockColors.textTertiary,
                          height: 1.4,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
