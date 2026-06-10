import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/decision_engine.dart';

/// 决策信号胶囊标签。
/// 支持两种尺寸：normal（默认）和 small（紧凑模式）。
class DecisionSignalBadge extends StatelessWidget {
  final DecisionSignal signal;
  final bool isSmall;

  const DecisionSignalBadge({
    super.key,
    required this.signal,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = DecisionEngine.signalColor(signal);
    final bgColor = DecisionEngine.signalBgColor(signal);
    final label = DecisionEngine.signalLabel(signal);

    final fontSize = isSmall ? 10.0 : 11.0;
    final height = isSmall ? 18.0 : 20.0;
    final horizontalPadding = isSmall ? 6.0 : 8.0;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.textFont,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1,
          color: color,
        ),
      ),
    );
  }
}
