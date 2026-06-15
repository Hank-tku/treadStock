import 'dart:convert';

import 'signal_rule.dart';
import 'stock_filter.dart';

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

  // Optional signal rules for rule-based strategies
  final List<SignalRule>? entryRules;
  final List<SignalRule>? exitRules;

  // Optional rule groups: OR of ANDs (supersedes flat rules when non-null)
  final List<RuleGroup>? entryGroups;
  final List<RuleGroup>? exitGroups;

  /// Stock filter for strategy-specific candidate pool.
  /// When null or inactive, the strategy scans all stocks (default behavior).
  final StockFilter? stockFilter;

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
    this.entryRules,
    this.exitRules,
    this.entryGroups,
    this.exitGroups,
    this.stockFilter,
    this.stats,
  });

  /// Validate that weights sum to 1.0 (with tolerance +/- 0.01).
  bool get isWeightSumValid {
    final sum = weightMA + weightBoll + weightVol + weightTrend;
    return (sum - 1.0).abs() <= 0.01;
  }

  /// Get the actual weight sum (for display purposes).
  double get weightSum => weightMA + weightBoll + weightVol + weightTrend;

  /// Whether this strategy uses the new rule-based signal system.
  bool get isRuleBased =>
      (entryRules != null && entryRules!.isNotEmpty) ||
      (entryGroups != null && entryGroups!.isNotEmpty);

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
    List<SignalRule>? entryRules,
    List<SignalRule>? exitRules,
    List<RuleGroup>? entryGroups,
    List<RuleGroup>? exitGroups,
    StockFilter? stockFilter,
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
      entryRules: entryRules ?? this.entryRules,
      exitRules: exitRules ?? this.exitRules,
      entryGroups: entryGroups ?? this.entryGroups,
      exitGroups: exitGroups ?? this.exitGroups,
      stockFilter: stockFilter ?? this.stockFilter,
      stats: stats ?? this.stats,
    );
  }

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'maShortPeriod': maShortPeriod,
      'maLongPeriod': maLongPeriod,
      'bollPeriod': bollPeriod,
      'bollStdDev': bollStdDev,
      'weightMA': weightMA,
      'weightBoll': weightBoll,
      'weightVol': weightVol,
      'weightTrend': weightTrend,
      'recommendThreshold': recommendThreshold,
      'isEnabled': isEnabled,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
    if (lastReviewAt != null) data['lastReviewAt'] = lastReviewAt!.toIso8601String();
    if (entryRules != null) data['entryRules'] = entryRules!.map((r) => r.toJson()).toList();
    if (exitRules != null) data['exitRules'] = exitRules!.map((r) => r.toJson()).toList();
    if (entryGroups != null) data['entryGroups'] = entryGroups!.map((g) => g.toJson()).toList();
    if (exitGroups != null) data['exitGroups'] = exitGroups!.map((g) => g.toJson()).toList();
    if (stockFilter != null && stockFilter!.isActive) {
      data['stockFilter'] = stockFilter!.toJson();
    }
    return data;
  }

  /// Deserialize from JSON map.
  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      maShortPeriod: json['maShortPeriod'] as int,
      maLongPeriod: json['maLongPeriod'] as int,
      bollPeriod: json['bollPeriod'] as int,
      bollStdDev: (json['bollStdDev'] as num).toDouble(),
      weightMA: (json['weightMA'] as num).toDouble(),
      weightBoll: (json['weightBoll'] as num).toDouble(),
      weightVol: (json['weightVol'] as num).toDouble(),
      weightTrend: (json['weightTrend'] as num).toDouble(),
      recommendThreshold: json['recommendThreshold'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastReviewAt: json['lastReviewAt'] != null
          ? DateTime.parse(json['lastReviewAt'] as String)
          : null,
      entryRules: json['entryRules'] != null
          ? (json['entryRules'] as List).map((e) => SignalRule.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      exitRules: json['exitRules'] != null
          ? (json['exitRules'] as List).map((e) => SignalRule.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      entryGroups: json['entryGroups'] != null
          ? (json['entryGroups'] as List).map((e) => RuleGroup.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      exitGroups: json['exitGroups'] != null
          ? (json['exitGroups'] as List).map((e) => RuleGroup.fromJson(e as Map<String, dynamic>)).toList()
          : null,
      stockFilter: json['stockFilter'] != null
          ? StockFilter.fromJson(json['stockFilter'] as Map<String, dynamic>)
          : null,
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

/// Metadata describing which period was used to generate a review.
class ReviewPeriodInfo {
  final DateTime requestedStart;
  final DateTime requestedEnd;
  final DateTime dataStart;
  final DateTime dataEnd;
  final int evaluatedCount;
  final String sourceNote;

  const ReviewPeriodInfo({
    required this.requestedStart,
    required this.requestedEnd,
    required this.dataStart,
    required this.dataEnd,
    required this.evaluatedCount,
    required this.sourceNote,
  });

  bool get usedFallback =>
      dataStart.year != requestedStart.year ||
      dataStart.month != requestedStart.month ||
      dataStart.day != requestedStart.day ||
      dataEnd.year != requestedEnd.year ||
      dataEnd.month != requestedEnd.month ||
      dataEnd.day != requestedEnd.day;

  String get requestedLabel =>
      '${_formatDate(requestedStart)} 至 ${_formatDate(requestedEnd)}';

  String get dataLabel => '${_formatDate(dataStart)} 至 ${_formatDate(dataEnd)}';

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class ReviewChecklistResult {
  final List<ChecklistItem> items;
  final ReviewPeriodInfo period;

  const ReviewChecklistResult({required this.items, required this.period});
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

/// Plain-language goals for users who do not want to tune indicators first.
class StrategyLearningGoal {
  final String id;
  final String title;
  final String subtitle;
  final String learningPoint;
  final String watchPoint;
  final StrategyFormData formData;

  const StrategyLearningGoal({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.learningPoint,
    required this.watchPoint,
    required this.formData,
  });
}

class StrategyLearningGoals {
  StrategyLearningGoals._();

  static final List<StrategyLearningGoal> all = [
    StrategyLearningGoal(
      id: 'beginner_band_low',
      title: '我想观察低位修复',
      subtitle: '适合学习“价格接近低位，但还没有明显破位”的波段观察。',
      learningPoint: '先学会看布林带下沿、MA20/60 和成交量是否配合。',
      watchPoint: '后续重点观察是否重新站上 MA20；跌破近期低点时应停止观察。',
      formData: StrategyFormData(
        name: '新手低位修复',
        description: '低位观察 + 布林带下沿 + 均线未破坏',
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
    StrategyLearningGoal(
      id: 'beginner_trend',
      title: '我想观察趋势延续',
      subtitle: '适合学习“走势已经变强，观察能否继续沿趋势运行”。',
      learningPoint: '先学会看短期均线、长期均线和近期涨跌节奏是否一致。',
      watchPoint: '后续重点观察是否维持在 MA20 上方；连续走弱时降低关注。',
      formData: StrategyFormData(
        name: '新手趋势延续',
        description: '均线趋势 + 近期节奏 + 观察延续性',
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
    StrategyLearningGoal(
      id: 'beginner_stable',
      title: '我想少一点噪声',
      subtitle: '适合刚开始使用，只看更严格、更少量的观察结果。',
      learningPoint: '先学会用更高阈值控制数量，避免一次看太多标的。',
      watchPoint: '如果连续几天没有结果，再考虑降低阈值或换成低位修复目标。',
      formData: StrategyFormData(
        name: '新手稳健过滤',
        description: '更高阈值 + 均线和趋势共同过滤',
        maShortPeriod: 20,
        maLongPeriod: 80,
        bollPeriod: 20,
        bollStdDev: 2.0,
        weightMA: 0.35,
        weightBoll: 0.25,
        weightVol: 0.15,
        weightTrend: 0.25,
        recommendThreshold: 8,
      ),
    ),
  ];
}

/// Helpers for copying external-AI instructions and importing generated JSON.
class StrategyImportHelper {
  StrategyImportHelper._();

  static const generationPrompt = '''
你是股势 TrendStock 的策略配置助手。请根据用户的自然语言想法，生成一个严格 JSON 对象，不要输出 Markdown。

当前 App 是纯客户端，不接大模型、不接后端。可用数据只有：
- 实时行情：最新价、涨跌幅、成交量、换手率、开盘价、最高价、最低价、昨收价
- 日 K 线：open、close、high、low、volume、amount、changePct
- 技术指标：MA 短期/长期、布林带、成交量评分、趋势评分

JSON schema：
{
  "name": "1-20 字符策略名",
  "description": "最多 100 字符策略说明",
  "maShortPeriod": 5-60 的整数,
  "maLongPeriod": 20-120 的整数,
  "bollPeriod": 10-40 的整数,
  "bollStdDev": 1.0-3.0 的数字,
  "weightMA": 0.0-1.0,
  "weightBoll": 0.0-1.0,
  "weightVol": 0.0-1.0,
  "weightTrend": 0.0-1.0,
  "recommendThreshold": 1-10 的整数,
  "notes": "可选，说明映射依据，不参与评分"
}

约束：
- 四个权重之和必须等于 1.0。
- 不要输出买入、卖出、保证收益等投资建议。
- 如果用户提到行业/概念，例如芯片股，只能写入 name、description 或 notes；当前版本不支持真实行业筛选。
- 如果用户提到排行前十，只能在 notes 中说明“按观察分排序取前十”，不作为策略参数。

示例用户想法：“三十天低谷，排行前十的芯片股”
推荐映射：偏低位修复，可提高布林带权重，适度降低 MA 长期周期；芯片股作为描述关键词保留。
''';

  static StrategyFormData fromJsonText(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('策略 JSON 必须是对象');
    }
    return fromJson(decoded);
  }

  static StrategyFormData fromJson(Map<String, dynamic> json) {
    final form = StrategyFormData(
      name: _string(json, 'name'),
      description: _string(json, 'description', required: false),
      maShortPeriod: _int(json, 'maShortPeriod'),
      maLongPeriod: _int(json, 'maLongPeriod'),
      bollPeriod: _int(json, 'bollPeriod'),
      bollStdDev: _double(json, 'bollStdDev'),
      weightMA: _double(json, 'weightMA'),
      weightBoll: _double(json, 'weightBoll'),
      weightVol: _double(json, 'weightVol'),
      weightTrend: _double(json, 'weightTrend'),
      recommendThreshold: _int(json, 'recommendThreshold'),
    );

    final error = form.validate();
    if (error != null) {
      throw FormatException(error);
    }
    return form;
  }

  static String _string(
    Map<String, dynamic> json,
    String key, {
    bool required = true,
  }) {
    final value = json[key];
    if (value == null) {
      if (!required) return '';
      throw FormatException('缺少字段 $key');
    }
    if (value is! String) throw FormatException('字段 $key 必须是文本');
    return value.trim();
  }

  static int _int(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.round();
    throw FormatException('字段 $key 必须是数字');
  }

  static double _double(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw FormatException('字段 $key 必须是数字');
  }
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

  /// Whether the strategy uses signal rules instead of weighted scoring.
  bool isRuleBased;

  /// Entry signal rules (used when isRuleBased is true).
  List<SignalRule> entryRules;

  /// Exit signal rules (used when isRuleBased is true).
  List<SignalRule> exitRules;

  /// Entry rule groups (OR of ANDs).
  List<RuleGroup> entryGroups;

  /// Exit rule groups (OR of ANDs).
  List<RuleGroup> exitGroups;

  /// Stock filter for strategy-specific candidate pool.
  StockFilter? stockFilter;

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
    this.isRuleBased = false,
    List<SignalRule>? entryRules,
    List<SignalRule>? exitRules,
    List<RuleGroup>? entryGroups,
    List<RuleGroup>? exitGroups,
    this.stockFilter,
  })  : entryRules = entryRules ?? [],
        exitRules = exitRules ?? [],
        entryGroups = entryGroups ?? [],
        exitGroups = exitGroups ?? [];

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
      isRuleBased: strategy.isRuleBased,
      entryRules: strategy.entryRules?.toList(),
      exitRules: strategy.exitRules?.toList(),
      entryGroups: strategy.entryGroups?.toList(),
      exitGroups: strategy.exitGroups?.toList(),
      stockFilter: strategy.stockFilter,
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
      isRuleBased: form.isRuleBased,
      entryRules: form.entryRules.toList(),
      exitRules: form.exitRules.toList(),
      entryGroups: form.entryGroups.toList(),
      exitGroups: form.exitGroups.toList(),
      stockFilter: form.stockFilter,
    );
  }

  /// Apply an API-based template to the editable form.
  factory StrategyFormData.fromTemplate(ApiStrategyTemplate template) {
    return StrategyFormData.fromForm(template.formData);
  }

  /// Apply a plain-language learning goal to the editable form.
  factory StrategyFormData.fromLearningGoal(StrategyLearningGoal goal) {
    return StrategyFormData.fromForm(goal.formData);
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
