// Domain models for the strategy management feature.

/// A trading strategy with configurable analysis parameters.
class Strategy {
  final String id;
  final String name;
  final String description;

  // Analysis parameters
  final int maShortPeriod;
  final int maLongPeriod;
  final int bollPeriod;
  final double bollStdDev;
  final double weightMA;
  final double weightBoll;
  final double weightVol;
  final double weightTrend;
  final int recommendThreshold;

  // Status
  final bool isEnabled;
  final bool isDefault;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewAt;

  // Computed stats (populated from DB queries, not persisted)
  final StrategyStats? stats;

  const Strategy({
    required this.id,
    required this.name,
    this.description = '',
    this.maShortPeriod = 20,
    this.maLongPeriod = 60,
    this.bollPeriod = 20,
    this.bollStdDev = 2.0,
    this.weightMA = 0.30,
    this.weightBoll = 0.30,
    this.weightVol = 0.20,
    this.weightTrend = 0.20,
    this.recommendThreshold = 7,
    this.isEnabled = true,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewAt,
    this.stats,
  });

  /// Validate that weights sum to 1.0 (with tolerance +/- 0.01).
  bool get isWeightSumValid {
    final sum = weightMA + weightBoll + weightVol + weightTrend;
    return (sum - 1.0).abs() <= 0.01;
  }

  /// Get the actual weight sum (for display purposes).
  double get weightSum => weightMA + weightBoll + weightVol + weightTrend;

  /// Check if review is needed (30+ days since last review).
  bool get needsReview {
    if (lastReviewAt == null) {
      final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
      return daysSinceCreation >= 30;
    }
    final daysSinceReview = DateTime.now().difference(lastReviewAt!).inDays;
    return daysSinceReview >= 30;
  }

  Strategy copyWith({
    String? name,
    String? description,
    int? maShortPeriod,
    int? maLongPeriod,
    int? bollPeriod,
    double? bollStdDev,
    double? weightMA,
    double? weightBoll,
    double? weightVol,
    double? weightTrend,
    int? recommendThreshold,
    bool? isEnabled,
    DateTime? updatedAt,
    DateTime? lastReviewAt,
    StrategyStats? stats,
  }) {
    return Strategy(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      maShortPeriod: maShortPeriod ?? this.maShortPeriod,
      maLongPeriod: maLongPeriod ?? this.maLongPeriod,
      bollPeriod: bollPeriod ?? this.bollPeriod,
      bollStdDev: bollStdDev ?? this.bollStdDev,
      weightMA: weightMA ?? this.weightMA,
      weightBoll: weightBoll ?? this.weightBoll,
      weightVol: weightVol ?? this.weightVol,
      weightTrend: weightTrend ?? this.weightTrend,
      recommendThreshold: recommendThreshold ?? this.recommendThreshold,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      stats: stats ?? this.stats,
    );
  }
}

/// Statistics for a strategy, computed from hit records.
class StrategyStats {
  final double hitRate; // 0.0 - 1.0
  final double? maxGain; // Maximum positive 5-day change (%)
  final double? maxLoss; // Maximum negative 5-day change (%)
  final double avgChange; // Average 5-day change (%)
  final int totalRecommendations;
  final int hitCount;
  final int evaluatedCount; // Records with actual_change_5d filled
  final double healthScore; // 0.0 - 10.0
  final int tradingDaysRun; // Days since strategy creation

  const StrategyStats({
    this.hitRate = 0.0,
    this.maxGain,
    this.maxLoss,
    this.avgChange = 0.0,
    this.totalRecommendations = 0,
    this.hitCount = 0,
    this.evaluatedCount = 0,
    this.healthScore = 0.0,
    this.tradingDaysRun = 0,
  });

  /// Whether we have enough data for meaningful stats (20+ trading days).
  bool get hasEnoughData => tradingDaysRun >= 20;

  /// Formatted hit rate string, e.g. "62.5%".
  String get hitRateDisplay {
    if (evaluatedCount == 0) return '--';
    return '${(hitRate * 100).toStringAsFixed(1)}%';
  }

  /// Formatted extreme scores string, e.g. "+15.2% / -8.3%".
  String get extremeScoreDisplay {
    if (maxGain == null && maxLoss == null) return '-- / --';
    final gain = maxGain != null ? '+${maxGain!.toStringAsFixed(1)}%' : '--';
    final loss = maxLoss != null ? '${maxLoss!.toStringAsFixed(1)}%' : '--';
    return '$gain / $loss';
  }

  /// Formatted average change string, e.g. "+1.35%".
  String get avgChangeDisplay {
    if (evaluatedCount == 0) return '--';
    final prefix = avgChange >= 0 ? '+' : '';
    return '$prefix${avgChange.toStringAsFixed(2)}%';
  }

  /// Formatted health score string, e.g. "7.2".
  String get healthScoreDisplay {
    if (evaluatedCount == 0) return '--';
    return healthScore.toStringAsFixed(1);
  }
}

/// A single hit record for a strategy recommendation.
class StrategyHitRecord {
  final String id;
  final String strategyId;
  final String stockCode;
  final String stockName;
  final String recommendDate; // "2026-05-05" format
  final int recommendScore;
  final double recommendPrice;
  final double? actualChange5d;
  final bool? isHit;
  final DateTime createdAt;

  const StrategyHitRecord({
    required this.id,
    required this.strategyId,
    required this.stockCode,
    required this.stockName,
    required this.recommendDate,
    required this.recommendScore,
    required this.recommendPrice,
    this.actualChange5d,
    this.isHit,
    required this.createdAt,
  });

  /// Whether this record has been evaluated (5-day data filled in).
  bool get isEvaluated => actualChange5d != null;

  /// Formatted actual change, e.g. "+2.35%" or "--".
  String get actualChangeDisplay {
    if (actualChange5d == null) return '--';
    final prefix = actualChange5d! >= 0 ? '+' : '';
    return '$prefix${actualChange5d!.toStringAsFixed(2)}%';
  }
}

/// A single review record for a strategy.
class StrategyReview {
  final String id;
  final String strategyId;
  final DateTime reviewDate;
  final double healthScore;

  // Check list metrics
  final double hitRate30d;
  final double avgChange30d;
  final double? maxLoss30d;
  final String hitRateTrend; // "up" / "flat" / "down"
  final int avgDailyCount30d;

  // Detailed results
  final List<ChecklistItem> checklistItems;
  final String? note;
  final DateTime createdAt;

  const StrategyReview({
    required this.id,
    required this.strategyId,
    required this.reviewDate,
    required this.healthScore,
    required this.hitRate30d,
    required this.avgChange30d,
    this.maxLoss30d,
    required this.hitRateTrend,
    required this.avgDailyCount30d,
    required this.checklistItems,
    this.note,
    required this.createdAt,
  });
}

/// A single item in the review checklist.
class ChecklistItem {
  final String title;
  final CheckResult result;
  final String detail;

  const ChecklistItem({
    required this.title,
    required this.result,
    required this.detail,
  });
}

/// Result of a checklist item evaluation.
enum CheckResult {
  pass, // Green - condition met
  warning, // Yellow - needs attention
  fail, // Red - abnormal
}

/// Iteration suggestion for strategy improvement.
class StrategySuggestion {
  final String condition;
  final String suggestion;
  final String? parameterKey;
  final dynamic suggestedValue;

  const StrategySuggestion({
    required this.condition,
    required this.suggestion,
    this.parameterKey,
    this.suggestedValue,
  });
}

/// A built-in strategy template generated from available market API fields.
class ApiStrategyTemplate {
  final String id;
  final String name;
  final String description;
  final String apiSource;
  final List<String> apiCapabilities;
  final List<String> requiredFields;
  final StrategyFormData formData;

  const ApiStrategyTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.apiSource,
    required this.apiCapabilities,
    required this.requiredFields,
    required this.formData,
  });
}

/// Local API-based templates for the initial no-LLM strategy generation flow.
class ApiStrategyTemplates {
  ApiStrategyTemplates._();

  static final List<ApiStrategyTemplate> all = [
    ApiStrategyTemplate(
      id: 'band_low',
      name: '波段低位修复',
      description: '结合日K、MA、布林带和缩量状态，寻找下轨附近但趋势未明显破坏的标的。',
      apiSource:
          '东方财富行情与日K接口，可迁移到 AKShare stock_zh_a_spot_em / stock_zh_a_hist',
      apiCapabilities: ['实时行情', '日K线', '成交量', '涨跌幅'],
      requiredFields: ['close', 'high', 'low', 'volume', 'changePct'],
      formData: StrategyFormData(
        name: '波段低位修复',
        description: '日K + MA20/60 + 布林带低位 + 缩量修复',
        maShortPeriod: 20,
        maLongPeriod: 60,
        bollPeriod: 20,
        bollStdDev: 2.0,
        weightMA: 0.25,
        weightBoll: 0.40,
        weightVol: 0.20,
        weightTrend: 0.15,
        recommendThreshold: 7,
      ),
    ),
    ApiStrategyTemplate(
      id: 'trend_follow',
      name: '均线趋势跟随',
      description: '偏重 MA20/60 多头结构和近期趋势，用于筛选趋势延续型标的。',
      apiSource:
          '东方财富行情与日K接口，可迁移到 AKShare stock_zh_a_spot_em / stock_zh_a_hist',
      apiCapabilities: ['实时行情', '日K线', '涨跌幅'],
      requiredFields: ['close', 'open', 'changePct'],
      formData: StrategyFormData(
        name: '均线趋势跟随',
        description: 'MA20/60 趋势结构 + 近期涨跌节奏',
        maShortPeriod: 20,
        maLongPeriod: 60,
        bollPeriod: 20,
        bollStdDev: 2.0,
        weightMA: 0.45,
        weightBoll: 0.15,
        weightVol: 0.10,
        weightTrend: 0.30,
        recommendThreshold: 7,
      ),
    ),
    ApiStrategyTemplate(
      id: 'volume_reversal',
      name: '量价反转观察',
      description: '提高量比和趋势权重，观察放量企稳或缩量调整后的反转机会。',
      apiSource:
          '东方财富行情与日K接口，可迁移到 AKShare stock_zh_a_spot_em / stock_zh_a_hist',
      apiCapabilities: ['实时行情', '日K线', '成交量', '涨跌幅'],
      requiredFields: ['open', 'close', 'volume', 'changePct'],
      formData: StrategyFormData(
        name: '量价反转观察',
        description: '量比变化 + 趋势企稳 + 基础均线过滤',
        maShortPeriod: 10,
        maLongPeriod: 40,
        bollPeriod: 20,
        bollStdDev: 2.0,
        weightMA: 0.20,
        weightBoll: 0.20,
        weightVol: 0.35,
        weightTrend: 0.25,
        recommendThreshold: 6,
      ),
    ),
  ];
}

/// Strategy form data for create/edit operations.
class StrategyFormData {
  String name;
  String description;
  int maShortPeriod;
  int maLongPeriod;
  int bollPeriod;
  double bollStdDev;
  double weightMA;
  double weightBoll;
  double weightVol;
  double weightTrend;
  int recommendThreshold;

  StrategyFormData({
    this.name = '',
    this.description = '',
    this.maShortPeriod = 20,
    this.maLongPeriod = 60,
    this.bollPeriod = 20,
    this.bollStdDev = 2.0,
    this.weightMA = 0.30,
    this.weightBoll = 0.30,
    this.weightVol = 0.20,
    this.weightTrend = 0.20,
    this.recommendThreshold = 7,
  });

  /// Create from an existing Strategy (for editing).
  factory StrategyFormData.fromStrategy(Strategy strategy) {
    return StrategyFormData(
      name: strategy.name,
      description: strategy.description,
      maShortPeriod: strategy.maShortPeriod,
      maLongPeriod: strategy.maLongPeriod,
      bollPeriod: strategy.bollPeriod,
      bollStdDev: strategy.bollStdDev,
      weightMA: strategy.weightMA,
      weightBoll: strategy.weightBoll,
      weightVol: strategy.weightVol,
      weightTrend: strategy.weightTrend,
      recommendThreshold: strategy.recommendThreshold,
    );
  }

  /// Create a detached copy so template edits do not mutate the template.
  factory StrategyFormData.fromForm(StrategyFormData form) {
    return StrategyFormData(
      name: form.name,
      description: form.description,
      maShortPeriod: form.maShortPeriod,
      maLongPeriod: form.maLongPeriod,
      bollPeriod: form.bollPeriod,
      bollStdDev: form.bollStdDev,
      weightMA: form.weightMA,
      weightBoll: form.weightBoll,
      weightVol: form.weightVol,
      weightTrend: form.weightTrend,
      recommendThreshold: form.recommendThreshold,
    );
  }

  /// Apply an API-based template to the editable form.
  factory StrategyFormData.fromTemplate(ApiStrategyTemplate template) {
    return StrategyFormData.fromForm(template.formData);
  }

  /// Validate that weights sum to 1.0 (with tolerance +/- 0.01).
  bool get isWeightSumValid {
    final sum = weightMA + weightBoll + weightVol + weightTrend;
    return (sum - 1.0).abs() <= 0.01;
  }

  /// Get the actual weight sum.
  double get weightSum => weightMA + weightBoll + weightVol + weightTrend;

  /// Validate all form fields.
  String? validate() {
    if (name.trim().isEmpty) {
      return '请输入策略名称';
    }
    if (name.trim().length > 20) {
      return '策略名称不能超过20个字符';
    }
    if (description.length > 100) {
      return '策略描述不能超过100个字符';
    }
    if (maShortPeriod < 5 || maShortPeriod > 60) {
      return 'MA短期周期范围为5-60';
    }
    if (maLongPeriod < 20 || maLongPeriod > 120) {
      return 'MA长期周期范围为20-120';
    }
    if (bollPeriod < 10 || bollPeriod > 40) {
      return '布林带周期范围为10-40';
    }
    if (bollStdDev < 1.0 || bollStdDev > 3.0) {
      return '布林带标准差范围为1.0-3.0';
    }
    if (!isWeightSumValid) {
      return '权重之和必须等于1.0，当前合计${weightSum.toStringAsFixed(2)}';
    }
    if (recommendThreshold < 1 || recommendThreshold > 10) {
      return '推荐阈值范围为1-10';
    }
    return null;
  }

  /// Check if MA short >= MA long (warning, not blocking).
  bool get hasMAWarning => maShortPeriod >= maLongPeriod;
}
