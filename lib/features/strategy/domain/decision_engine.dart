import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 决策信号枚举
enum DecisionSignal {
  strongWatch,    // 强烈关注
  watch,          // 可以关注
  observe,        // 继续观望
  notRecommended; // 暂不建议
}

/// 决策结果
class DecisionResult {
  final DecisionSignal signal;
  final double score; // 0-1
  final String reason; // 大白话理由

  const DecisionResult({
    required this.signal,
    required this.score,
    required this.reason,
  });
}

class DecisionEngine {
  /// 计算决策信号
  static DecisionResult evaluate({
    required double strategyScore,    // 0-10
    required double hitRate,          // 0-1
    required int sampleSize,
    required bool isEnabled,
  }) {
    // 未启用或样本不足 → notRecommended
    if (!isEnabled || sampleSize < 10) {
      return const DecisionResult(
        signal: DecisionSignal.notRecommended,
        score: 0,
        reason: '数据不足，暂无参考信号',
      );
    }

    // 综合分 = score/10 × 0.5 + hitRate × 0.3 + min(sampleSize/50, 1) × 0.2
    final normalizedScore = strategyScore / 10;
    final sampleFactor = (sampleSize / 50).clamp(0.0, 1.0);
    final composite = normalizedScore * 0.5 + hitRate * 0.3 + sampleFactor * 0.2;

    // 四档判定
    if (composite >= 0.7) {
      return DecisionResult(
        signal: DecisionSignal.strongWatch,
        score: composite,
        reason: '多个指标表现良好，值得重点关注',
      );
    } else if (composite >= 0.5) {
      return DecisionResult(
        signal: DecisionSignal.watch,
        score: composite,
        reason: '部分指标符合条件，可以关注',
      );
    } else if (composite >= 0.3) {
      return DecisionResult(
        signal: DecisionSignal.observe,
        score: composite,
        reason: '信号偏弱，建议继续观望',
      );
    } else {
      return DecisionResult(
        signal: DecisionSignal.notRecommended,
        score: composite,
        reason: '当前不满足策略条件，暂不建议关注',
      );
    }
  }

  /// 信号颜色
  static Color signalColor(DecisionSignal signal) {
    switch (signal) {
      case DecisionSignal.strongWatch:
        return StockColors.scoreHigh;
      case DecisionSignal.watch:
        return StockColors.scoreMid;
      case DecisionSignal.observe:
        return StockColors.brand;
      case DecisionSignal.notRecommended:
        return StockColors.flat;
    }
  }

  /// 信号浅色背景
  static Color signalBgColor(DecisionSignal signal) {
    switch (signal) {
      case DecisionSignal.strongWatch:
        return StockColors.upBg;
      case DecisionSignal.watch:
        return StockColors.bandLowBg;
      case DecisionSignal.observe:
        return StockColors.brandLight;
      case DecisionSignal.notRecommended:
        return StockColors.gray100;
    }
  }

  /// 信号文字
  static String signalLabel(DecisionSignal signal) {
    switch (signal) {
      case DecisionSignal.strongWatch:
        return '强烈关注';
      case DecisionSignal.watch:
        return '可以关注';
      case DecisionSignal.observe:
        return '继续观望';
      case DecisionSignal.notRecommended:
        return '暂不建议';
    }
  }
}
