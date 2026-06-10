import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'strategy_models.dart';

/// 信任度等级
enum TrustLevel {
  excellent, // A级：可信度高
  good, // B级：较可信
  fair, // C级：参考为主
  limited; // D级：数据不足

  String get label {
    switch (this) {
      case TrustLevel.excellent:
        return 'A级';
      case TrustLevel.good:
        return 'B级';
      case TrustLevel.fair:
        return 'C级';
      case TrustLevel.limited:
        return 'D级';
    }
  }

  /// 徽章上显示的单字母
  String get badgeLabel {
    switch (this) {
      case TrustLevel.excellent:
        return 'A';
      case TrustLevel.good:
        return 'B';
      case TrustLevel.fair:
        return 'C';
      case TrustLevel.limited:
        return 'D';
    }
  }
}

/// 信任度计算结果
class TrustResult {
  final TrustLevel level;
  final double score; // 0-1
  final String label; // "A级" / "B级" 等
  final String description; // 大白话说明

  const TrustResult({
    required this.level,
    required this.score,
    required this.label,
    required this.description,
  });
}

/// 策略信任度计算引擎
class StrategyTrustEngine {
  /// 根据策略统计数据计算信任度
  static TrustResult evaluate(StrategyStats stats) {
    final sampleSize = stats.evaluatedCount;
    final hitRate = stats.hitRate;
    final tradingDaysRun = stats.tradingDaysRun;

    // 样本量不足 → D级
    if (sampleSize < 20) {
      return const TrustResult(
        level: TrustLevel.limited,
        score: 0,
        label: 'D级',
        description: '数据还在积累中，结果仅供参考',
      );
    }

    // 综合分 = hitRate × 0.4 + min(sampleSize/100, 1) × 0.3 + min(tradingDaysRun/30, 1) × 0.3
    final composite = hitRate * 0.4 +
        min(sampleSize / 100, 1.0) * 0.3 +
        min(tradingDaysRun / 30, 1.0) * 0.3;

    if (composite >= 0.7) {
      return TrustResult(
        level: TrustLevel.excellent,
        score: composite,
        label: 'A级',
        description: '策略表现优秀，历史数据充分',
      );
    } else if (composite >= 0.5) {
      return TrustResult(
        level: TrustLevel.good,
        score: composite,
        label: 'B级',
        description: '策略表现良好，可作参考',
      );
    } else if (composite >= 0.3) {
      return TrustResult(
        level: TrustLevel.fair,
        score: composite,
        label: 'C级',
        description: '策略表现一般，建议谨慎参考',
      );
    } else {
      return TrustResult(
        level: TrustLevel.limited,
        score: composite,
        label: 'D级',
        description: '策略表现较弱，需要调整',
      );
    }
  }

  /// 返回信任度等级对应的颜色
  static Color trustColor(TrustLevel level) {
    switch (level) {
      case TrustLevel.excellent:
        return StockColors.success;
      case TrustLevel.good:
        return StockColors.brand;
      case TrustLevel.fair:
        return StockColors.warning;
      case TrustLevel.limited:
        return StockColors.flat;
    }
  }

  /// 返回信任度等级对应的浅背景色
  static Color trustBgColor(TrustLevel level) {
    switch (level) {
      case TrustLevel.excellent:
        return StockColors.downBg;
      case TrustLevel.good:
        return StockColors.brandLight;
      case TrustLevel.fair:
        return StockColors.bandLowBg;
      case TrustLevel.limited:
        return StockColors.gray100;
    }
  }
}
