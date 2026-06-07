// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WatchlistItemsTable extends WatchlistItems
    with TableInfo<$WatchlistItemsTable, WatchlistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchlistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockCodeMeta = const VerificationMeta(
    'stockCode',
  );
  @override
  late final GeneratedColumn<String> stockCode = GeneratedColumn<String>(
    'stock_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockNameMeta = const VerificationMeta(
    'stockName',
  );
  @override
  late final GeneratedColumn<String> stockName = GeneratedColumn<String>(
    'stock_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marketMeta = const VerificationMeta('market');
  @override
  late final GeneratedColumn<String> market = GeneratedColumn<String>(
    'market',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SH'),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _alertEnabledMeta = const VerificationMeta(
    'alertEnabled',
  );
  @override
  late final GeneratedColumn<bool> alertEnabled = GeneratedColumn<bool>(
    'alert_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alert_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    stockCode,
    stockName,
    market,
    isPinned,
    sortOrder,
    alertEnabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watchlist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchlistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('stock_code')) {
      context.handle(
        _stockCodeMeta,
        stockCode.isAcceptableOrUnknown(data['stock_code']!, _stockCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_stockCodeMeta);
    }
    if (data.containsKey('stock_name')) {
      context.handle(
        _stockNameMeta,
        stockName.isAcceptableOrUnknown(data['stock_name']!, _stockNameMeta),
      );
    } else if (isInserting) {
      context.missing(_stockNameMeta);
    }
    if (data.containsKey('market')) {
      context.handle(
        _marketMeta,
        market.isAcceptableOrUnknown(data['market']!, _marketMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('alert_enabled')) {
      context.handle(
        _alertEnabledMeta,
        alertEnabled.isAcceptableOrUnknown(
          data['alert_enabled']!,
          _alertEnabledMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchlistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchlistRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      stockCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_code'],
      )!,
      stockName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_name'],
      )!,
      market: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      alertEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alert_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WatchlistItemsTable createAlias(String alias) {
    return $WatchlistItemsTable(attachedDatabase, alias);
  }
}

class WatchlistRow extends DataClass implements Insertable<WatchlistRow> {
  final String id;
  final String stockCode;
  final String stockName;
  final String market;
  final bool isPinned;
  final int sortOrder;
  final bool alertEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WatchlistRow({
    required this.id,
    required this.stockCode,
    required this.stockName,
    required this.market,
    required this.isPinned,
    required this.sortOrder,
    required this.alertEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['stock_code'] = Variable<String>(stockCode);
    map['stock_name'] = Variable<String>(stockName);
    map['market'] = Variable<String>(market);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['sort_order'] = Variable<int>(sortOrder);
    map['alert_enabled'] = Variable<bool>(alertEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WatchlistItemsCompanion toCompanion(bool nullToAbsent) {
    return WatchlistItemsCompanion(
      id: Value(id),
      stockCode: Value(stockCode),
      stockName: Value(stockName),
      market: Value(market),
      isPinned: Value(isPinned),
      sortOrder: Value(sortOrder),
      alertEnabled: Value(alertEnabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WatchlistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchlistRow(
      id: serializer.fromJson<String>(json['id']),
      stockCode: serializer.fromJson<String>(json['stockCode']),
      stockName: serializer.fromJson<String>(json['stockName']),
      market: serializer.fromJson<String>(json['market']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      alertEnabled: serializer.fromJson<bool>(json['alertEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'stockCode': serializer.toJson<String>(stockCode),
      'stockName': serializer.toJson<String>(stockName),
      'market': serializer.toJson<String>(market),
      'isPinned': serializer.toJson<bool>(isPinned),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'alertEnabled': serializer.toJson<bool>(alertEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WatchlistRow copyWith({
    String? id,
    String? stockCode,
    String? stockName,
    String? market,
    bool? isPinned,
    int? sortOrder,
    bool? alertEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WatchlistRow(
    id: id ?? this.id,
    stockCode: stockCode ?? this.stockCode,
    stockName: stockName ?? this.stockName,
    market: market ?? this.market,
    isPinned: isPinned ?? this.isPinned,
    sortOrder: sortOrder ?? this.sortOrder,
    alertEnabled: alertEnabled ?? this.alertEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WatchlistRow copyWithCompanion(WatchlistItemsCompanion data) {
    return WatchlistRow(
      id: data.id.present ? data.id.value : this.id,
      stockCode: data.stockCode.present ? data.stockCode.value : this.stockCode,
      stockName: data.stockName.present ? data.stockName.value : this.stockName,
      market: data.market.present ? data.market.value : this.market,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      alertEnabled: data.alertEnabled.present
          ? data.alertEnabled.value
          : this.alertEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistRow(')
          ..write('id: $id, ')
          ..write('stockCode: $stockCode, ')
          ..write('stockName: $stockName, ')
          ..write('market: $market, ')
          ..write('isPinned: $isPinned, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('alertEnabled: $alertEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    stockCode,
    stockName,
    market,
    isPinned,
    sortOrder,
    alertEnabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchlistRow &&
          other.id == this.id &&
          other.stockCode == this.stockCode &&
          other.stockName == this.stockName &&
          other.market == this.market &&
          other.isPinned == this.isPinned &&
          other.sortOrder == this.sortOrder &&
          other.alertEnabled == this.alertEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WatchlistItemsCompanion extends UpdateCompanion<WatchlistRow> {
  final Value<String> id;
  final Value<String> stockCode;
  final Value<String> stockName;
  final Value<String> market;
  final Value<bool> isPinned;
  final Value<int> sortOrder;
  final Value<bool> alertEnabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WatchlistItemsCompanion({
    this.id = const Value.absent(),
    this.stockCode = const Value.absent(),
    this.stockName = const Value.absent(),
    this.market = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.alertEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchlistItemsCompanion.insert({
    required String id,
    required String stockCode,
    required String stockName,
    this.market = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.alertEnabled = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       stockCode = Value(stockCode),
       stockName = Value(stockName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WatchlistRow> custom({
    Expression<String>? id,
    Expression<String>? stockCode,
    Expression<String>? stockName,
    Expression<String>? market,
    Expression<bool>? isPinned,
    Expression<int>? sortOrder,
    Expression<bool>? alertEnabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stockCode != null) 'stock_code': stockCode,
      if (stockName != null) 'stock_name': stockName,
      if (market != null) 'market': market,
      if (isPinned != null) 'is_pinned': isPinned,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (alertEnabled != null) 'alert_enabled': alertEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchlistItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? stockCode,
    Value<String>? stockName,
    Value<String>? market,
    Value<bool>? isPinned,
    Value<int>? sortOrder,
    Value<bool>? alertEnabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WatchlistItemsCompanion(
      id: id ?? this.id,
      stockCode: stockCode ?? this.stockCode,
      stockName: stockName ?? this.stockName,
      market: market ?? this.market,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (stockCode.present) {
      map['stock_code'] = Variable<String>(stockCode.value);
    }
    if (stockName.present) {
      map['stock_name'] = Variable<String>(stockName.value);
    }
    if (market.present) {
      map['market'] = Variable<String>(market.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (alertEnabled.present) {
      map['alert_enabled'] = Variable<bool>(alertEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistItemsCompanion(')
          ..write('id: $id, ')
          ..write('stockCode: $stockCode, ')
          ..write('stockName: $stockName, ')
          ..write('market: $market, ')
          ..write('isPinned: $isPinned, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('alertEnabled: $alertEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrategiesTable extends Strategies
    with TableInfo<$StrategiesTable, StrategyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrategiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _maShortPeriodMeta = const VerificationMeta(
    'maShortPeriod',
  );
  @override
  late final GeneratedColumn<int> maShortPeriod = GeneratedColumn<int>(
    'ma_short_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _maLongPeriodMeta = const VerificationMeta(
    'maLongPeriod',
  );
  @override
  late final GeneratedColumn<int> maLongPeriod = GeneratedColumn<int>(
    'ma_long_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _bollPeriodMeta = const VerificationMeta(
    'bollPeriod',
  );
  @override
  late final GeneratedColumn<int> bollPeriod = GeneratedColumn<int>(
    'boll_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(20),
  );
  static const VerificationMeta _bollStdDevMeta = const VerificationMeta(
    'bollStdDev',
  );
  @override
  late final GeneratedColumn<double> bollStdDev = GeneratedColumn<double>(
    'boll_std_dev',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.0),
  );
  static const VerificationMeta _weightMAMeta = const VerificationMeta(
    'weightMA',
  );
  @override
  late final GeneratedColumn<double> weightMA = GeneratedColumn<double>(
    'weight_m_a',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.30),
  );
  static const VerificationMeta _weightBollMeta = const VerificationMeta(
    'weightBoll',
  );
  @override
  late final GeneratedColumn<double> weightBoll = GeneratedColumn<double>(
    'weight_boll',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.30),
  );
  static const VerificationMeta _weightVolMeta = const VerificationMeta(
    'weightVol',
  );
  @override
  late final GeneratedColumn<double> weightVol = GeneratedColumn<double>(
    'weight_vol',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.20),
  );
  static const VerificationMeta _weightTrendMeta = const VerificationMeta(
    'weightTrend',
  );
  @override
  late final GeneratedColumn<double> weightTrend = GeneratedColumn<double>(
    'weight_trend',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.20),
  );
  static const VerificationMeta _recommendThresholdMeta =
      const VerificationMeta('recommendThreshold');
  @override
  late final GeneratedColumn<int> recommendThreshold = GeneratedColumn<int>(
    'recommend_threshold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(7),
  );
  static const VerificationMeta _entryRulesJsonMeta = const VerificationMeta(
    'entryRulesJson',
  );
  @override
  late final GeneratedColumn<String> entryRulesJson = GeneratedColumn<String>(
    'entry_rules_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exitRulesJsonMeta = const VerificationMeta(
    'exitRulesJson',
  );
  @override
  late final GeneratedColumn<String> exitRulesJson = GeneratedColumn<String>(
    'exit_rules_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entryGroupsJsonMeta = const VerificationMeta(
    'entryGroupsJson',
  );
  @override
  late final GeneratedColumn<String> entryGroupsJson = GeneratedColumn<String>(
    'entry_groups_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exitGroupsJsonMeta = const VerificationMeta(
    'exitGroupsJson',
  );
  @override
  late final GeneratedColumn<String> exitGroupsJson = GeneratedColumn<String>(
    'exit_groups_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewAtMeta = const VerificationMeta(
    'lastReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewAt = GeneratedColumn<DateTime>(
    'last_review_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    maShortPeriod,
    maLongPeriod,
    bollPeriod,
    bollStdDev,
    weightMA,
    weightBoll,
    weightVol,
    weightTrend,
    recommendThreshold,
    entryRulesJson,
    exitRulesJson,
    entryGroupsJson,
    exitGroupsJson,
    isEnabled,
    isDefault,
    createdAt,
    updatedAt,
    lastReviewAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strategies';
  @override
  VerificationContext validateIntegrity(
    Insertable<StrategyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('ma_short_period')) {
      context.handle(
        _maShortPeriodMeta,
        maShortPeriod.isAcceptableOrUnknown(
          data['ma_short_period']!,
          _maShortPeriodMeta,
        ),
      );
    }
    if (data.containsKey('ma_long_period')) {
      context.handle(
        _maLongPeriodMeta,
        maLongPeriod.isAcceptableOrUnknown(
          data['ma_long_period']!,
          _maLongPeriodMeta,
        ),
      );
    }
    if (data.containsKey('boll_period')) {
      context.handle(
        _bollPeriodMeta,
        bollPeriod.isAcceptableOrUnknown(data['boll_period']!, _bollPeriodMeta),
      );
    }
    if (data.containsKey('boll_std_dev')) {
      context.handle(
        _bollStdDevMeta,
        bollStdDev.isAcceptableOrUnknown(
          data['boll_std_dev']!,
          _bollStdDevMeta,
        ),
      );
    }
    if (data.containsKey('weight_m_a')) {
      context.handle(
        _weightMAMeta,
        weightMA.isAcceptableOrUnknown(data['weight_m_a']!, _weightMAMeta),
      );
    }
    if (data.containsKey('weight_boll')) {
      context.handle(
        _weightBollMeta,
        weightBoll.isAcceptableOrUnknown(data['weight_boll']!, _weightBollMeta),
      );
    }
    if (data.containsKey('weight_vol')) {
      context.handle(
        _weightVolMeta,
        weightVol.isAcceptableOrUnknown(data['weight_vol']!, _weightVolMeta),
      );
    }
    if (data.containsKey('weight_trend')) {
      context.handle(
        _weightTrendMeta,
        weightTrend.isAcceptableOrUnknown(
          data['weight_trend']!,
          _weightTrendMeta,
        ),
      );
    }
    if (data.containsKey('recommend_threshold')) {
      context.handle(
        _recommendThresholdMeta,
        recommendThreshold.isAcceptableOrUnknown(
          data['recommend_threshold']!,
          _recommendThresholdMeta,
        ),
      );
    }
    if (data.containsKey('entry_rules_json')) {
      context.handle(
        _entryRulesJsonMeta,
        entryRulesJson.isAcceptableOrUnknown(
          data['entry_rules_json']!,
          _entryRulesJsonMeta,
        ),
      );
    }
    if (data.containsKey('exit_rules_json')) {
      context.handle(
        _exitRulesJsonMeta,
        exitRulesJson.isAcceptableOrUnknown(
          data['exit_rules_json']!,
          _exitRulesJsonMeta,
        ),
      );
    }
    if (data.containsKey('entry_groups_json')) {
      context.handle(
        _entryGroupsJsonMeta,
        entryGroupsJson.isAcceptableOrUnknown(
          data['entry_groups_json']!,
          _entryGroupsJsonMeta,
        ),
      );
    }
    if (data.containsKey('exit_groups_json')) {
      context.handle(
        _exitGroupsJsonMeta,
        exitGroupsJson.isAcceptableOrUnknown(
          data['exit_groups_json']!,
          _exitGroupsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_review_at')) {
      context.handle(
        _lastReviewAtMeta,
        lastReviewAt.isAcceptableOrUnknown(
          data['last_review_at']!,
          _lastReviewAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StrategyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrategyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      maShortPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ma_short_period'],
      )!,
      maLongPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ma_long_period'],
      )!,
      bollPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}boll_period'],
      )!,
      bollStdDev: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}boll_std_dev'],
      )!,
      weightMA: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_m_a'],
      )!,
      weightBoll: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_boll'],
      )!,
      weightVol: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_vol'],
      )!,
      weightTrend: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_trend'],
      )!,
      recommendThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommend_threshold'],
      )!,
      entryRulesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_rules_json'],
      ),
      exitRulesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exit_rules_json'],
      ),
      entryGroupsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_groups_json'],
      ),
      exitGroupsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exit_groups_json'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review_at'],
      ),
    );
  }

  @override
  $StrategiesTable createAlias(String alias) {
    return $StrategiesTable(attachedDatabase, alias);
  }
}

class StrategyRow extends DataClass implements Insertable<StrategyRow> {
  final String id;
  final String name;
  final String description;
  final int maShortPeriod;
  final int maLongPeriod;
  final int bollPeriod;
  final double bollStdDev;
  final double weightMA;
  final double weightBoll;
  final double weightVol;
  final double weightTrend;
  final int recommendThreshold;
  final String? entryRulesJson;
  final String? exitRulesJson;
  final String? entryGroupsJson;
  final String? exitGroupsJson;
  final bool isEnabled;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewAt;
  const StrategyRow({
    required this.id,
    required this.name,
    required this.description,
    required this.maShortPeriod,
    required this.maLongPeriod,
    required this.bollPeriod,
    required this.bollStdDev,
    required this.weightMA,
    required this.weightBoll,
    required this.weightVol,
    required this.weightTrend,
    required this.recommendThreshold,
    this.entryRulesJson,
    this.exitRulesJson,
    this.entryGroupsJson,
    this.exitGroupsJson,
    required this.isEnabled,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['ma_short_period'] = Variable<int>(maShortPeriod);
    map['ma_long_period'] = Variable<int>(maLongPeriod);
    map['boll_period'] = Variable<int>(bollPeriod);
    map['boll_std_dev'] = Variable<double>(bollStdDev);
    map['weight_m_a'] = Variable<double>(weightMA);
    map['weight_boll'] = Variable<double>(weightBoll);
    map['weight_vol'] = Variable<double>(weightVol);
    map['weight_trend'] = Variable<double>(weightTrend);
    map['recommend_threshold'] = Variable<int>(recommendThreshold);
    if (!nullToAbsent || entryRulesJson != null) {
      map['entry_rules_json'] = Variable<String>(entryRulesJson);
    }
    if (!nullToAbsent || exitRulesJson != null) {
      map['exit_rules_json'] = Variable<String>(exitRulesJson);
    }
    if (!nullToAbsent || entryGroupsJson != null) {
      map['entry_groups_json'] = Variable<String>(entryGroupsJson);
    }
    if (!nullToAbsent || exitGroupsJson != null) {
      map['exit_groups_json'] = Variable<String>(exitGroupsJson);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastReviewAt != null) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt);
    }
    return map;
  }

  StrategiesCompanion toCompanion(bool nullToAbsent) {
    return StrategiesCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      maShortPeriod: Value(maShortPeriod),
      maLongPeriod: Value(maLongPeriod),
      bollPeriod: Value(bollPeriod),
      bollStdDev: Value(bollStdDev),
      weightMA: Value(weightMA),
      weightBoll: Value(weightBoll),
      weightVol: Value(weightVol),
      weightTrend: Value(weightTrend),
      recommendThreshold: Value(recommendThreshold),
      entryRulesJson: entryRulesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(entryRulesJson),
      exitRulesJson: exitRulesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(exitRulesJson),
      entryGroupsJson: entryGroupsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(entryGroupsJson),
      exitGroupsJson: exitGroupsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(exitGroupsJson),
      isEnabled: Value(isEnabled),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastReviewAt: lastReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewAt),
    );
  }

  factory StrategyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrategyRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      maShortPeriod: serializer.fromJson<int>(json['maShortPeriod']),
      maLongPeriod: serializer.fromJson<int>(json['maLongPeriod']),
      bollPeriod: serializer.fromJson<int>(json['bollPeriod']),
      bollStdDev: serializer.fromJson<double>(json['bollStdDev']),
      weightMA: serializer.fromJson<double>(json['weightMA']),
      weightBoll: serializer.fromJson<double>(json['weightBoll']),
      weightVol: serializer.fromJson<double>(json['weightVol']),
      weightTrend: serializer.fromJson<double>(json['weightTrend']),
      recommendThreshold: serializer.fromJson<int>(json['recommendThreshold']),
      entryRulesJson: serializer.fromJson<String?>(json['entryRulesJson']),
      exitRulesJson: serializer.fromJson<String?>(json['exitRulesJson']),
      entryGroupsJson: serializer.fromJson<String?>(json['entryGroupsJson']),
      exitGroupsJson: serializer.fromJson<String?>(json['exitGroupsJson']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastReviewAt: serializer.fromJson<DateTime?>(json['lastReviewAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'maShortPeriod': serializer.toJson<int>(maShortPeriod),
      'maLongPeriod': serializer.toJson<int>(maLongPeriod),
      'bollPeriod': serializer.toJson<int>(bollPeriod),
      'bollStdDev': serializer.toJson<double>(bollStdDev),
      'weightMA': serializer.toJson<double>(weightMA),
      'weightBoll': serializer.toJson<double>(weightBoll),
      'weightVol': serializer.toJson<double>(weightVol),
      'weightTrend': serializer.toJson<double>(weightTrend),
      'recommendThreshold': serializer.toJson<int>(recommendThreshold),
      'entryRulesJson': serializer.toJson<String?>(entryRulesJson),
      'exitRulesJson': serializer.toJson<String?>(exitRulesJson),
      'entryGroupsJson': serializer.toJson<String?>(entryGroupsJson),
      'exitGroupsJson': serializer.toJson<String?>(exitGroupsJson),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastReviewAt': serializer.toJson<DateTime?>(lastReviewAt),
    };
  }

  StrategyRow copyWith({
    String? id,
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
    Value<String?> entryRulesJson = const Value.absent(),
    Value<String?> exitRulesJson = const Value.absent(),
    Value<String?> entryGroupsJson = const Value.absent(),
    Value<String?> exitGroupsJson = const Value.absent(),
    bool? isEnabled,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastReviewAt = const Value.absent(),
  }) => StrategyRow(
    id: id ?? this.id,
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
    entryRulesJson: entryRulesJson.present
        ? entryRulesJson.value
        : this.entryRulesJson,
    exitRulesJson: exitRulesJson.present
        ? exitRulesJson.value
        : this.exitRulesJson,
    entryGroupsJson: entryGroupsJson.present
        ? entryGroupsJson.value
        : this.entryGroupsJson,
    exitGroupsJson: exitGroupsJson.present
        ? exitGroupsJson.value
        : this.exitGroupsJson,
    isEnabled: isEnabled ?? this.isEnabled,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastReviewAt: lastReviewAt.present ? lastReviewAt.value : this.lastReviewAt,
  );
  StrategyRow copyWithCompanion(StrategiesCompanion data) {
    return StrategyRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      maShortPeriod: data.maShortPeriod.present
          ? data.maShortPeriod.value
          : this.maShortPeriod,
      maLongPeriod: data.maLongPeriod.present
          ? data.maLongPeriod.value
          : this.maLongPeriod,
      bollPeriod: data.bollPeriod.present
          ? data.bollPeriod.value
          : this.bollPeriod,
      bollStdDev: data.bollStdDev.present
          ? data.bollStdDev.value
          : this.bollStdDev,
      weightMA: data.weightMA.present ? data.weightMA.value : this.weightMA,
      weightBoll: data.weightBoll.present
          ? data.weightBoll.value
          : this.weightBoll,
      weightVol: data.weightVol.present ? data.weightVol.value : this.weightVol,
      weightTrend: data.weightTrend.present
          ? data.weightTrend.value
          : this.weightTrend,
      recommendThreshold: data.recommendThreshold.present
          ? data.recommendThreshold.value
          : this.recommendThreshold,
      entryRulesJson: data.entryRulesJson.present
          ? data.entryRulesJson.value
          : this.entryRulesJson,
      exitRulesJson: data.exitRulesJson.present
          ? data.exitRulesJson.value
          : this.exitRulesJson,
      entryGroupsJson: data.entryGroupsJson.present
          ? data.entryGroupsJson.value
          : this.entryGroupsJson,
      exitGroupsJson: data.exitGroupsJson.present
          ? data.exitGroupsJson.value
          : this.exitGroupsJson,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastReviewAt: data.lastReviewAt.present
          ? data.lastReviewAt.value
          : this.lastReviewAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrategyRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('maShortPeriod: $maShortPeriod, ')
          ..write('maLongPeriod: $maLongPeriod, ')
          ..write('bollPeriod: $bollPeriod, ')
          ..write('bollStdDev: $bollStdDev, ')
          ..write('weightMA: $weightMA, ')
          ..write('weightBoll: $weightBoll, ')
          ..write('weightVol: $weightVol, ')
          ..write('weightTrend: $weightTrend, ')
          ..write('recommendThreshold: $recommendThreshold, ')
          ..write('entryRulesJson: $entryRulesJson, ')
          ..write('exitRulesJson: $exitRulesJson, ')
          ..write('entryGroupsJson: $entryGroupsJson, ')
          ..write('exitGroupsJson: $exitGroupsJson, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReviewAt: $lastReviewAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    description,
    maShortPeriod,
    maLongPeriod,
    bollPeriod,
    bollStdDev,
    weightMA,
    weightBoll,
    weightVol,
    weightTrend,
    recommendThreshold,
    entryRulesJson,
    exitRulesJson,
    entryGroupsJson,
    exitGroupsJson,
    isEnabled,
    isDefault,
    createdAt,
    updatedAt,
    lastReviewAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrategyRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.maShortPeriod == this.maShortPeriod &&
          other.maLongPeriod == this.maLongPeriod &&
          other.bollPeriod == this.bollPeriod &&
          other.bollStdDev == this.bollStdDev &&
          other.weightMA == this.weightMA &&
          other.weightBoll == this.weightBoll &&
          other.weightVol == this.weightVol &&
          other.weightTrend == this.weightTrend &&
          other.recommendThreshold == this.recommendThreshold &&
          other.entryRulesJson == this.entryRulesJson &&
          other.exitRulesJson == this.exitRulesJson &&
          other.entryGroupsJson == this.entryGroupsJson &&
          other.exitGroupsJson == this.exitGroupsJson &&
          other.isEnabled == this.isEnabled &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastReviewAt == this.lastReviewAt);
}

class StrategiesCompanion extends UpdateCompanion<StrategyRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<int> maShortPeriod;
  final Value<int> maLongPeriod;
  final Value<int> bollPeriod;
  final Value<double> bollStdDev;
  final Value<double> weightMA;
  final Value<double> weightBoll;
  final Value<double> weightVol;
  final Value<double> weightTrend;
  final Value<int> recommendThreshold;
  final Value<String?> entryRulesJson;
  final Value<String?> exitRulesJson;
  final Value<String?> entryGroupsJson;
  final Value<String?> exitGroupsJson;
  final Value<bool> isEnabled;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastReviewAt;
  final Value<int> rowid;
  const StrategiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.maShortPeriod = const Value.absent(),
    this.maLongPeriod = const Value.absent(),
    this.bollPeriod = const Value.absent(),
    this.bollStdDev = const Value.absent(),
    this.weightMA = const Value.absent(),
    this.weightBoll = const Value.absent(),
    this.weightVol = const Value.absent(),
    this.weightTrend = const Value.absent(),
    this.recommendThreshold = const Value.absent(),
    this.entryRulesJson = const Value.absent(),
    this.exitRulesJson = const Value.absent(),
    this.entryGroupsJson = const Value.absent(),
    this.exitGroupsJson = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastReviewAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrategiesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.maShortPeriod = const Value.absent(),
    this.maLongPeriod = const Value.absent(),
    this.bollPeriod = const Value.absent(),
    this.bollStdDev = const Value.absent(),
    this.weightMA = const Value.absent(),
    this.weightBoll = const Value.absent(),
    this.weightVol = const Value.absent(),
    this.weightTrend = const Value.absent(),
    this.recommendThreshold = const Value.absent(),
    this.entryRulesJson = const Value.absent(),
    this.exitRulesJson = const Value.absent(),
    this.entryGroupsJson = const Value.absent(),
    this.exitGroupsJson = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastReviewAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StrategyRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? maShortPeriod,
    Expression<int>? maLongPeriod,
    Expression<int>? bollPeriod,
    Expression<double>? bollStdDev,
    Expression<double>? weightMA,
    Expression<double>? weightBoll,
    Expression<double>? weightVol,
    Expression<double>? weightTrend,
    Expression<int>? recommendThreshold,
    Expression<String>? entryRulesJson,
    Expression<String>? exitRulesJson,
    Expression<String>? entryGroupsJson,
    Expression<String>? exitGroupsJson,
    Expression<bool>? isEnabled,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastReviewAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (maShortPeriod != null) 'ma_short_period': maShortPeriod,
      if (maLongPeriod != null) 'ma_long_period': maLongPeriod,
      if (bollPeriod != null) 'boll_period': bollPeriod,
      if (bollStdDev != null) 'boll_std_dev': bollStdDev,
      if (weightMA != null) 'weight_m_a': weightMA,
      if (weightBoll != null) 'weight_boll': weightBoll,
      if (weightVol != null) 'weight_vol': weightVol,
      if (weightTrend != null) 'weight_trend': weightTrend,
      if (recommendThreshold != null) 'recommend_threshold': recommendThreshold,
      if (entryRulesJson != null) 'entry_rules_json': entryRulesJson,
      if (exitRulesJson != null) 'exit_rules_json': exitRulesJson,
      if (entryGroupsJson != null) 'entry_groups_json': entryGroupsJson,
      if (exitGroupsJson != null) 'exit_groups_json': exitGroupsJson,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastReviewAt != null) 'last_review_at': lastReviewAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrategiesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<int>? maShortPeriod,
    Value<int>? maLongPeriod,
    Value<int>? bollPeriod,
    Value<double>? bollStdDev,
    Value<double>? weightMA,
    Value<double>? weightBoll,
    Value<double>? weightVol,
    Value<double>? weightTrend,
    Value<int>? recommendThreshold,
    Value<String?>? entryRulesJson,
    Value<String?>? exitRulesJson,
    Value<String?>? entryGroupsJson,
    Value<String?>? exitGroupsJson,
    Value<bool>? isEnabled,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastReviewAt,
    Value<int>? rowid,
  }) {
    return StrategiesCompanion(
      id: id ?? this.id,
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
      entryRulesJson: entryRulesJson ?? this.entryRulesJson,
      exitRulesJson: exitRulesJson ?? this.exitRulesJson,
      entryGroupsJson: entryGroupsJson ?? this.entryGroupsJson,
      exitGroupsJson: exitGroupsJson ?? this.exitGroupsJson,
      isEnabled: isEnabled ?? this.isEnabled,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReviewAt: lastReviewAt ?? this.lastReviewAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (maShortPeriod.present) {
      map['ma_short_period'] = Variable<int>(maShortPeriod.value);
    }
    if (maLongPeriod.present) {
      map['ma_long_period'] = Variable<int>(maLongPeriod.value);
    }
    if (bollPeriod.present) {
      map['boll_period'] = Variable<int>(bollPeriod.value);
    }
    if (bollStdDev.present) {
      map['boll_std_dev'] = Variable<double>(bollStdDev.value);
    }
    if (weightMA.present) {
      map['weight_m_a'] = Variable<double>(weightMA.value);
    }
    if (weightBoll.present) {
      map['weight_boll'] = Variable<double>(weightBoll.value);
    }
    if (weightVol.present) {
      map['weight_vol'] = Variable<double>(weightVol.value);
    }
    if (weightTrend.present) {
      map['weight_trend'] = Variable<double>(weightTrend.value);
    }
    if (recommendThreshold.present) {
      map['recommend_threshold'] = Variable<int>(recommendThreshold.value);
    }
    if (entryRulesJson.present) {
      map['entry_rules_json'] = Variable<String>(entryRulesJson.value);
    }
    if (exitRulesJson.present) {
      map['exit_rules_json'] = Variable<String>(exitRulesJson.value);
    }
    if (entryGroupsJson.present) {
      map['entry_groups_json'] = Variable<String>(entryGroupsJson.value);
    }
    if (exitGroupsJson.present) {
      map['exit_groups_json'] = Variable<String>(exitGroupsJson.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastReviewAt.present) {
      map['last_review_at'] = Variable<DateTime>(lastReviewAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrategiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('maShortPeriod: $maShortPeriod, ')
          ..write('maLongPeriod: $maLongPeriod, ')
          ..write('bollPeriod: $bollPeriod, ')
          ..write('bollStdDev: $bollStdDev, ')
          ..write('weightMA: $weightMA, ')
          ..write('weightBoll: $weightBoll, ')
          ..write('weightVol: $weightVol, ')
          ..write('weightTrend: $weightTrend, ')
          ..write('recommendThreshold: $recommendThreshold, ')
          ..write('entryRulesJson: $entryRulesJson, ')
          ..write('exitRulesJson: $exitRulesJson, ')
          ..write('entryGroupsJson: $entryGroupsJson, ')
          ..write('exitGroupsJson: $exitGroupsJson, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastReviewAt: $lastReviewAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrategyHitRecordsTable extends StrategyHitRecords
    with TableInfo<$StrategyHitRecordsTable, StrategyHitRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrategyHitRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strategyIdMeta = const VerificationMeta(
    'strategyId',
  );
  @override
  late final GeneratedColumn<String> strategyId = GeneratedColumn<String>(
    'strategy_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockCodeMeta = const VerificationMeta(
    'stockCode',
  );
  @override
  late final GeneratedColumn<String> stockCode = GeneratedColumn<String>(
    'stock_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockNameMeta = const VerificationMeta(
    'stockName',
  );
  @override
  late final GeneratedColumn<String> stockName = GeneratedColumn<String>(
    'stock_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendDateMeta = const VerificationMeta(
    'recommendDate',
  );
  @override
  late final GeneratedColumn<String> recommendDate = GeneratedColumn<String>(
    'recommend_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendScoreMeta = const VerificationMeta(
    'recommendScore',
  );
  @override
  late final GeneratedColumn<int> recommendScore = GeneratedColumn<int>(
    'recommend_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recommendPriceMeta = const VerificationMeta(
    'recommendPrice',
  );
  @override
  late final GeneratedColumn<double> recommendPrice = GeneratedColumn<double>(
    'recommend_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualChange5dMeta = const VerificationMeta(
    'actualChange5d',
  );
  @override
  late final GeneratedColumn<double> actualChange5d = GeneratedColumn<double>(
    'actual_change5d',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHitMeta = const VerificationMeta('isHit');
  @override
  late final GeneratedColumn<bool> isHit = GeneratedColumn<bool>(
    'is_hit',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hit" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    strategyId,
    stockCode,
    stockName,
    recommendDate,
    recommendScore,
    recommendPrice,
    actualChange5d,
    isHit,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strategy_hit_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<StrategyHitRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('strategy_id')) {
      context.handle(
        _strategyIdMeta,
        strategyId.isAcceptableOrUnknown(data['strategy_id']!, _strategyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_strategyIdMeta);
    }
    if (data.containsKey('stock_code')) {
      context.handle(
        _stockCodeMeta,
        stockCode.isAcceptableOrUnknown(data['stock_code']!, _stockCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_stockCodeMeta);
    }
    if (data.containsKey('stock_name')) {
      context.handle(
        _stockNameMeta,
        stockName.isAcceptableOrUnknown(data['stock_name']!, _stockNameMeta),
      );
    } else if (isInserting) {
      context.missing(_stockNameMeta);
    }
    if (data.containsKey('recommend_date')) {
      context.handle(
        _recommendDateMeta,
        recommendDate.isAcceptableOrUnknown(
          data['recommend_date']!,
          _recommendDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendDateMeta);
    }
    if (data.containsKey('recommend_score')) {
      context.handle(
        _recommendScoreMeta,
        recommendScore.isAcceptableOrUnknown(
          data['recommend_score']!,
          _recommendScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendScoreMeta);
    }
    if (data.containsKey('recommend_price')) {
      context.handle(
        _recommendPriceMeta,
        recommendPrice.isAcceptableOrUnknown(
          data['recommend_price']!,
          _recommendPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recommendPriceMeta);
    }
    if (data.containsKey('actual_change5d')) {
      context.handle(
        _actualChange5dMeta,
        actualChange5d.isAcceptableOrUnknown(
          data['actual_change5d']!,
          _actualChange5dMeta,
        ),
      );
    }
    if (data.containsKey('is_hit')) {
      context.handle(
        _isHitMeta,
        isHit.isAcceptableOrUnknown(data['is_hit']!, _isHitMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StrategyHitRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrategyHitRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      strategyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strategy_id'],
      )!,
      stockCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_code'],
      )!,
      stockName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_name'],
      )!,
      recommendDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recommend_date'],
      )!,
      recommendScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recommend_score'],
      )!,
      recommendPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}recommend_price'],
      )!,
      actualChange5d: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}actual_change5d'],
      ),
      isHit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hit'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StrategyHitRecordsTable createAlias(String alias) {
    return $StrategyHitRecordsTable(attachedDatabase, alias);
  }
}

class StrategyHitRecordRow extends DataClass
    implements Insertable<StrategyHitRecordRow> {
  final String id;
  final String strategyId;
  final String stockCode;
  final String stockName;
  final String recommendDate;
  final int recommendScore;
  final double recommendPrice;
  final double? actualChange5d;
  final bool? isHit;
  final DateTime createdAt;
  const StrategyHitRecordRow({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['strategy_id'] = Variable<String>(strategyId);
    map['stock_code'] = Variable<String>(stockCode);
    map['stock_name'] = Variable<String>(stockName);
    map['recommend_date'] = Variable<String>(recommendDate);
    map['recommend_score'] = Variable<int>(recommendScore);
    map['recommend_price'] = Variable<double>(recommendPrice);
    if (!nullToAbsent || actualChange5d != null) {
      map['actual_change5d'] = Variable<double>(actualChange5d);
    }
    if (!nullToAbsent || isHit != null) {
      map['is_hit'] = Variable<bool>(isHit);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StrategyHitRecordsCompanion toCompanion(bool nullToAbsent) {
    return StrategyHitRecordsCompanion(
      id: Value(id),
      strategyId: Value(strategyId),
      stockCode: Value(stockCode),
      stockName: Value(stockName),
      recommendDate: Value(recommendDate),
      recommendScore: Value(recommendScore),
      recommendPrice: Value(recommendPrice),
      actualChange5d: actualChange5d == null && nullToAbsent
          ? const Value.absent()
          : Value(actualChange5d),
      isHit: isHit == null && nullToAbsent
          ? const Value.absent()
          : Value(isHit),
      createdAt: Value(createdAt),
    );
  }

  factory StrategyHitRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrategyHitRecordRow(
      id: serializer.fromJson<String>(json['id']),
      strategyId: serializer.fromJson<String>(json['strategyId']),
      stockCode: serializer.fromJson<String>(json['stockCode']),
      stockName: serializer.fromJson<String>(json['stockName']),
      recommendDate: serializer.fromJson<String>(json['recommendDate']),
      recommendScore: serializer.fromJson<int>(json['recommendScore']),
      recommendPrice: serializer.fromJson<double>(json['recommendPrice']),
      actualChange5d: serializer.fromJson<double?>(json['actualChange5d']),
      isHit: serializer.fromJson<bool?>(json['isHit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'strategyId': serializer.toJson<String>(strategyId),
      'stockCode': serializer.toJson<String>(stockCode),
      'stockName': serializer.toJson<String>(stockName),
      'recommendDate': serializer.toJson<String>(recommendDate),
      'recommendScore': serializer.toJson<int>(recommendScore),
      'recommendPrice': serializer.toJson<double>(recommendPrice),
      'actualChange5d': serializer.toJson<double?>(actualChange5d),
      'isHit': serializer.toJson<bool?>(isHit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StrategyHitRecordRow copyWith({
    String? id,
    String? strategyId,
    String? stockCode,
    String? stockName,
    String? recommendDate,
    int? recommendScore,
    double? recommendPrice,
    Value<double?> actualChange5d = const Value.absent(),
    Value<bool?> isHit = const Value.absent(),
    DateTime? createdAt,
  }) => StrategyHitRecordRow(
    id: id ?? this.id,
    strategyId: strategyId ?? this.strategyId,
    stockCode: stockCode ?? this.stockCode,
    stockName: stockName ?? this.stockName,
    recommendDate: recommendDate ?? this.recommendDate,
    recommendScore: recommendScore ?? this.recommendScore,
    recommendPrice: recommendPrice ?? this.recommendPrice,
    actualChange5d: actualChange5d.present
        ? actualChange5d.value
        : this.actualChange5d,
    isHit: isHit.present ? isHit.value : this.isHit,
    createdAt: createdAt ?? this.createdAt,
  );
  StrategyHitRecordRow copyWithCompanion(StrategyHitRecordsCompanion data) {
    return StrategyHitRecordRow(
      id: data.id.present ? data.id.value : this.id,
      strategyId: data.strategyId.present
          ? data.strategyId.value
          : this.strategyId,
      stockCode: data.stockCode.present ? data.stockCode.value : this.stockCode,
      stockName: data.stockName.present ? data.stockName.value : this.stockName,
      recommendDate: data.recommendDate.present
          ? data.recommendDate.value
          : this.recommendDate,
      recommendScore: data.recommendScore.present
          ? data.recommendScore.value
          : this.recommendScore,
      recommendPrice: data.recommendPrice.present
          ? data.recommendPrice.value
          : this.recommendPrice,
      actualChange5d: data.actualChange5d.present
          ? data.actualChange5d.value
          : this.actualChange5d,
      isHit: data.isHit.present ? data.isHit.value : this.isHit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrategyHitRecordRow(')
          ..write('id: $id, ')
          ..write('strategyId: $strategyId, ')
          ..write('stockCode: $stockCode, ')
          ..write('stockName: $stockName, ')
          ..write('recommendDate: $recommendDate, ')
          ..write('recommendScore: $recommendScore, ')
          ..write('recommendPrice: $recommendPrice, ')
          ..write('actualChange5d: $actualChange5d, ')
          ..write('isHit: $isHit, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    strategyId,
    stockCode,
    stockName,
    recommendDate,
    recommendScore,
    recommendPrice,
    actualChange5d,
    isHit,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrategyHitRecordRow &&
          other.id == this.id &&
          other.strategyId == this.strategyId &&
          other.stockCode == this.stockCode &&
          other.stockName == this.stockName &&
          other.recommendDate == this.recommendDate &&
          other.recommendScore == this.recommendScore &&
          other.recommendPrice == this.recommendPrice &&
          other.actualChange5d == this.actualChange5d &&
          other.isHit == this.isHit &&
          other.createdAt == this.createdAt);
}

class StrategyHitRecordsCompanion
    extends UpdateCompanion<StrategyHitRecordRow> {
  final Value<String> id;
  final Value<String> strategyId;
  final Value<String> stockCode;
  final Value<String> stockName;
  final Value<String> recommendDate;
  final Value<int> recommendScore;
  final Value<double> recommendPrice;
  final Value<double?> actualChange5d;
  final Value<bool?> isHit;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StrategyHitRecordsCompanion({
    this.id = const Value.absent(),
    this.strategyId = const Value.absent(),
    this.stockCode = const Value.absent(),
    this.stockName = const Value.absent(),
    this.recommendDate = const Value.absent(),
    this.recommendScore = const Value.absent(),
    this.recommendPrice = const Value.absent(),
    this.actualChange5d = const Value.absent(),
    this.isHit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrategyHitRecordsCompanion.insert({
    required String id,
    required String strategyId,
    required String stockCode,
    required String stockName,
    required String recommendDate,
    required int recommendScore,
    required double recommendPrice,
    this.actualChange5d = const Value.absent(),
    this.isHit = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       strategyId = Value(strategyId),
       stockCode = Value(stockCode),
       stockName = Value(stockName),
       recommendDate = Value(recommendDate),
       recommendScore = Value(recommendScore),
       recommendPrice = Value(recommendPrice),
       createdAt = Value(createdAt);
  static Insertable<StrategyHitRecordRow> custom({
    Expression<String>? id,
    Expression<String>? strategyId,
    Expression<String>? stockCode,
    Expression<String>? stockName,
    Expression<String>? recommendDate,
    Expression<int>? recommendScore,
    Expression<double>? recommendPrice,
    Expression<double>? actualChange5d,
    Expression<bool>? isHit,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (strategyId != null) 'strategy_id': strategyId,
      if (stockCode != null) 'stock_code': stockCode,
      if (stockName != null) 'stock_name': stockName,
      if (recommendDate != null) 'recommend_date': recommendDate,
      if (recommendScore != null) 'recommend_score': recommendScore,
      if (recommendPrice != null) 'recommend_price': recommendPrice,
      if (actualChange5d != null) 'actual_change5d': actualChange5d,
      if (isHit != null) 'is_hit': isHit,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrategyHitRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? strategyId,
    Value<String>? stockCode,
    Value<String>? stockName,
    Value<String>? recommendDate,
    Value<int>? recommendScore,
    Value<double>? recommendPrice,
    Value<double?>? actualChange5d,
    Value<bool?>? isHit,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StrategyHitRecordsCompanion(
      id: id ?? this.id,
      strategyId: strategyId ?? this.strategyId,
      stockCode: stockCode ?? this.stockCode,
      stockName: stockName ?? this.stockName,
      recommendDate: recommendDate ?? this.recommendDate,
      recommendScore: recommendScore ?? this.recommendScore,
      recommendPrice: recommendPrice ?? this.recommendPrice,
      actualChange5d: actualChange5d ?? this.actualChange5d,
      isHit: isHit ?? this.isHit,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (strategyId.present) {
      map['strategy_id'] = Variable<String>(strategyId.value);
    }
    if (stockCode.present) {
      map['stock_code'] = Variable<String>(stockCode.value);
    }
    if (stockName.present) {
      map['stock_name'] = Variable<String>(stockName.value);
    }
    if (recommendDate.present) {
      map['recommend_date'] = Variable<String>(recommendDate.value);
    }
    if (recommendScore.present) {
      map['recommend_score'] = Variable<int>(recommendScore.value);
    }
    if (recommendPrice.present) {
      map['recommend_price'] = Variable<double>(recommendPrice.value);
    }
    if (actualChange5d.present) {
      map['actual_change5d'] = Variable<double>(actualChange5d.value);
    }
    if (isHit.present) {
      map['is_hit'] = Variable<bool>(isHit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrategyHitRecordsCompanion(')
          ..write('id: $id, ')
          ..write('strategyId: $strategyId, ')
          ..write('stockCode: $stockCode, ')
          ..write('stockName: $stockName, ')
          ..write('recommendDate: $recommendDate, ')
          ..write('recommendScore: $recommendScore, ')
          ..write('recommendPrice: $recommendPrice, ')
          ..write('actualChange5d: $actualChange5d, ')
          ..write('isHit: $isHit, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StrategyReviewsTable extends StrategyReviews
    with TableInfo<$StrategyReviewsTable, StrategyReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StrategyReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strategyIdMeta = const VerificationMeta(
    'strategyId',
  );
  @override
  late final GeneratedColumn<String> strategyId = GeneratedColumn<String>(
    'strategy_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewDateMeta = const VerificationMeta(
    'reviewDate',
  );
  @override
  late final GeneratedColumn<DateTime> reviewDate = GeneratedColumn<DateTime>(
    'review_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _healthScoreMeta = const VerificationMeta(
    'healthScore',
  );
  @override
  late final GeneratedColumn<double> healthScore = GeneratedColumn<double>(
    'health_score',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hitRate30dMeta = const VerificationMeta(
    'hitRate30d',
  );
  @override
  late final GeneratedColumn<double> hitRate30d = GeneratedColumn<double>(
    'hit_rate30d',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgChange30dMeta = const VerificationMeta(
    'avgChange30d',
  );
  @override
  late final GeneratedColumn<double> avgChange30d = GeneratedColumn<double>(
    'avg_change30d',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxLoss30dMeta = const VerificationMeta(
    'maxLoss30d',
  );
  @override
  late final GeneratedColumn<double> maxLoss30d = GeneratedColumn<double>(
    'max_loss30d',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hitRateTrendMeta = const VerificationMeta(
    'hitRateTrend',
  );
  @override
  late final GeneratedColumn<String> hitRateTrend = GeneratedColumn<String>(
    'hit_rate_trend',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avgDailyCount30dMeta = const VerificationMeta(
    'avgDailyCount30d',
  );
  @override
  late final GeneratedColumn<int> avgDailyCount30d = GeneratedColumn<int>(
    'avg_daily_count30d',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checklistResultMeta = const VerificationMeta(
    'checklistResult',
  );
  @override
  late final GeneratedColumn<String> checklistResult = GeneratedColumn<String>(
    'checklist_result',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 200),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    strategyId,
    reviewDate,
    healthScore,
    hitRate30d,
    avgChange30d,
    maxLoss30d,
    hitRateTrend,
    avgDailyCount30d,
    checklistResult,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'strategy_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<StrategyReviewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('strategy_id')) {
      context.handle(
        _strategyIdMeta,
        strategyId.isAcceptableOrUnknown(data['strategy_id']!, _strategyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_strategyIdMeta);
    }
    if (data.containsKey('review_date')) {
      context.handle(
        _reviewDateMeta,
        reviewDate.isAcceptableOrUnknown(data['review_date']!, _reviewDateMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewDateMeta);
    }
    if (data.containsKey('health_score')) {
      context.handle(
        _healthScoreMeta,
        healthScore.isAcceptableOrUnknown(
          data['health_score']!,
          _healthScoreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_healthScoreMeta);
    }
    if (data.containsKey('hit_rate30d')) {
      context.handle(
        _hitRate30dMeta,
        hitRate30d.isAcceptableOrUnknown(data['hit_rate30d']!, _hitRate30dMeta),
      );
    } else if (isInserting) {
      context.missing(_hitRate30dMeta);
    }
    if (data.containsKey('avg_change30d')) {
      context.handle(
        _avgChange30dMeta,
        avgChange30d.isAcceptableOrUnknown(
          data['avg_change30d']!,
          _avgChange30dMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgChange30dMeta);
    }
    if (data.containsKey('max_loss30d')) {
      context.handle(
        _maxLoss30dMeta,
        maxLoss30d.isAcceptableOrUnknown(data['max_loss30d']!, _maxLoss30dMeta),
      );
    }
    if (data.containsKey('hit_rate_trend')) {
      context.handle(
        _hitRateTrendMeta,
        hitRateTrend.isAcceptableOrUnknown(
          data['hit_rate_trend']!,
          _hitRateTrendMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_hitRateTrendMeta);
    }
    if (data.containsKey('avg_daily_count30d')) {
      context.handle(
        _avgDailyCount30dMeta,
        avgDailyCount30d.isAcceptableOrUnknown(
          data['avg_daily_count30d']!,
          _avgDailyCount30dMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_avgDailyCount30dMeta);
    }
    if (data.containsKey('checklist_result')) {
      context.handle(
        _checklistResultMeta,
        checklistResult.isAcceptableOrUnknown(
          data['checklist_result']!,
          _checklistResultMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_checklistResultMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StrategyReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StrategyReviewRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      strategyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strategy_id'],
      )!,
      reviewDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}review_date'],
      )!,
      healthScore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}health_score'],
      )!,
      hitRate30d: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}hit_rate30d'],
      )!,
      avgChange30d: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}avg_change30d'],
      )!,
      maxLoss30d: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_loss30d'],
      ),
      hitRateTrend: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hit_rate_trend'],
      )!,
      avgDailyCount30d: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avg_daily_count30d'],
      )!,
      checklistResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checklist_result'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StrategyReviewsTable createAlias(String alias) {
    return $StrategyReviewsTable(attachedDatabase, alias);
  }
}

class StrategyReviewRow extends DataClass
    implements Insertable<StrategyReviewRow> {
  final String id;
  final String strategyId;
  final DateTime reviewDate;
  final double healthScore;
  final double hitRate30d;
  final double avgChange30d;
  final double? maxLoss30d;
  final String hitRateTrend;
  final int avgDailyCount30d;
  final String checklistResult;
  final String? note;
  final DateTime createdAt;
  const StrategyReviewRow({
    required this.id,
    required this.strategyId,
    required this.reviewDate,
    required this.healthScore,
    required this.hitRate30d,
    required this.avgChange30d,
    this.maxLoss30d,
    required this.hitRateTrend,
    required this.avgDailyCount30d,
    required this.checklistResult,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['strategy_id'] = Variable<String>(strategyId);
    map['review_date'] = Variable<DateTime>(reviewDate);
    map['health_score'] = Variable<double>(healthScore);
    map['hit_rate30d'] = Variable<double>(hitRate30d);
    map['avg_change30d'] = Variable<double>(avgChange30d);
    if (!nullToAbsent || maxLoss30d != null) {
      map['max_loss30d'] = Variable<double>(maxLoss30d);
    }
    map['hit_rate_trend'] = Variable<String>(hitRateTrend);
    map['avg_daily_count30d'] = Variable<int>(avgDailyCount30d);
    map['checklist_result'] = Variable<String>(checklistResult);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StrategyReviewsCompanion toCompanion(bool nullToAbsent) {
    return StrategyReviewsCompanion(
      id: Value(id),
      strategyId: Value(strategyId),
      reviewDate: Value(reviewDate),
      healthScore: Value(healthScore),
      hitRate30d: Value(hitRate30d),
      avgChange30d: Value(avgChange30d),
      maxLoss30d: maxLoss30d == null && nullToAbsent
          ? const Value.absent()
          : Value(maxLoss30d),
      hitRateTrend: Value(hitRateTrend),
      avgDailyCount30d: Value(avgDailyCount30d),
      checklistResult: Value(checklistResult),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory StrategyReviewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StrategyReviewRow(
      id: serializer.fromJson<String>(json['id']),
      strategyId: serializer.fromJson<String>(json['strategyId']),
      reviewDate: serializer.fromJson<DateTime>(json['reviewDate']),
      healthScore: serializer.fromJson<double>(json['healthScore']),
      hitRate30d: serializer.fromJson<double>(json['hitRate30d']),
      avgChange30d: serializer.fromJson<double>(json['avgChange30d']),
      maxLoss30d: serializer.fromJson<double?>(json['maxLoss30d']),
      hitRateTrend: serializer.fromJson<String>(json['hitRateTrend']),
      avgDailyCount30d: serializer.fromJson<int>(json['avgDailyCount30d']),
      checklistResult: serializer.fromJson<String>(json['checklistResult']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'strategyId': serializer.toJson<String>(strategyId),
      'reviewDate': serializer.toJson<DateTime>(reviewDate),
      'healthScore': serializer.toJson<double>(healthScore),
      'hitRate30d': serializer.toJson<double>(hitRate30d),
      'avgChange30d': serializer.toJson<double>(avgChange30d),
      'maxLoss30d': serializer.toJson<double?>(maxLoss30d),
      'hitRateTrend': serializer.toJson<String>(hitRateTrend),
      'avgDailyCount30d': serializer.toJson<int>(avgDailyCount30d),
      'checklistResult': serializer.toJson<String>(checklistResult),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StrategyReviewRow copyWith({
    String? id,
    String? strategyId,
    DateTime? reviewDate,
    double? healthScore,
    double? hitRate30d,
    double? avgChange30d,
    Value<double?> maxLoss30d = const Value.absent(),
    String? hitRateTrend,
    int? avgDailyCount30d,
    String? checklistResult,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => StrategyReviewRow(
    id: id ?? this.id,
    strategyId: strategyId ?? this.strategyId,
    reviewDate: reviewDate ?? this.reviewDate,
    healthScore: healthScore ?? this.healthScore,
    hitRate30d: hitRate30d ?? this.hitRate30d,
    avgChange30d: avgChange30d ?? this.avgChange30d,
    maxLoss30d: maxLoss30d.present ? maxLoss30d.value : this.maxLoss30d,
    hitRateTrend: hitRateTrend ?? this.hitRateTrend,
    avgDailyCount30d: avgDailyCount30d ?? this.avgDailyCount30d,
    checklistResult: checklistResult ?? this.checklistResult,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  StrategyReviewRow copyWithCompanion(StrategyReviewsCompanion data) {
    return StrategyReviewRow(
      id: data.id.present ? data.id.value : this.id,
      strategyId: data.strategyId.present
          ? data.strategyId.value
          : this.strategyId,
      reviewDate: data.reviewDate.present
          ? data.reviewDate.value
          : this.reviewDate,
      healthScore: data.healthScore.present
          ? data.healthScore.value
          : this.healthScore,
      hitRate30d: data.hitRate30d.present
          ? data.hitRate30d.value
          : this.hitRate30d,
      avgChange30d: data.avgChange30d.present
          ? data.avgChange30d.value
          : this.avgChange30d,
      maxLoss30d: data.maxLoss30d.present
          ? data.maxLoss30d.value
          : this.maxLoss30d,
      hitRateTrend: data.hitRateTrend.present
          ? data.hitRateTrend.value
          : this.hitRateTrend,
      avgDailyCount30d: data.avgDailyCount30d.present
          ? data.avgDailyCount30d.value
          : this.avgDailyCount30d,
      checklistResult: data.checklistResult.present
          ? data.checklistResult.value
          : this.checklistResult,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StrategyReviewRow(')
          ..write('id: $id, ')
          ..write('strategyId: $strategyId, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('healthScore: $healthScore, ')
          ..write('hitRate30d: $hitRate30d, ')
          ..write('avgChange30d: $avgChange30d, ')
          ..write('maxLoss30d: $maxLoss30d, ')
          ..write('hitRateTrend: $hitRateTrend, ')
          ..write('avgDailyCount30d: $avgDailyCount30d, ')
          ..write('checklistResult: $checklistResult, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    strategyId,
    reviewDate,
    healthScore,
    hitRate30d,
    avgChange30d,
    maxLoss30d,
    hitRateTrend,
    avgDailyCount30d,
    checklistResult,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StrategyReviewRow &&
          other.id == this.id &&
          other.strategyId == this.strategyId &&
          other.reviewDate == this.reviewDate &&
          other.healthScore == this.healthScore &&
          other.hitRate30d == this.hitRate30d &&
          other.avgChange30d == this.avgChange30d &&
          other.maxLoss30d == this.maxLoss30d &&
          other.hitRateTrend == this.hitRateTrend &&
          other.avgDailyCount30d == this.avgDailyCount30d &&
          other.checklistResult == this.checklistResult &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class StrategyReviewsCompanion extends UpdateCompanion<StrategyReviewRow> {
  final Value<String> id;
  final Value<String> strategyId;
  final Value<DateTime> reviewDate;
  final Value<double> healthScore;
  final Value<double> hitRate30d;
  final Value<double> avgChange30d;
  final Value<double?> maxLoss30d;
  final Value<String> hitRateTrend;
  final Value<int> avgDailyCount30d;
  final Value<String> checklistResult;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StrategyReviewsCompanion({
    this.id = const Value.absent(),
    this.strategyId = const Value.absent(),
    this.reviewDate = const Value.absent(),
    this.healthScore = const Value.absent(),
    this.hitRate30d = const Value.absent(),
    this.avgChange30d = const Value.absent(),
    this.maxLoss30d = const Value.absent(),
    this.hitRateTrend = const Value.absent(),
    this.avgDailyCount30d = const Value.absent(),
    this.checklistResult = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StrategyReviewsCompanion.insert({
    required String id,
    required String strategyId,
    required DateTime reviewDate,
    required double healthScore,
    required double hitRate30d,
    required double avgChange30d,
    this.maxLoss30d = const Value.absent(),
    required String hitRateTrend,
    required int avgDailyCount30d,
    required String checklistResult,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       strategyId = Value(strategyId),
       reviewDate = Value(reviewDate),
       healthScore = Value(healthScore),
       hitRate30d = Value(hitRate30d),
       avgChange30d = Value(avgChange30d),
       hitRateTrend = Value(hitRateTrend),
       avgDailyCount30d = Value(avgDailyCount30d),
       checklistResult = Value(checklistResult),
       createdAt = Value(createdAt);
  static Insertable<StrategyReviewRow> custom({
    Expression<String>? id,
    Expression<String>? strategyId,
    Expression<DateTime>? reviewDate,
    Expression<double>? healthScore,
    Expression<double>? hitRate30d,
    Expression<double>? avgChange30d,
    Expression<double>? maxLoss30d,
    Expression<String>? hitRateTrend,
    Expression<int>? avgDailyCount30d,
    Expression<String>? checklistResult,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (strategyId != null) 'strategy_id': strategyId,
      if (reviewDate != null) 'review_date': reviewDate,
      if (healthScore != null) 'health_score': healthScore,
      if (hitRate30d != null) 'hit_rate30d': hitRate30d,
      if (avgChange30d != null) 'avg_change30d': avgChange30d,
      if (maxLoss30d != null) 'max_loss30d': maxLoss30d,
      if (hitRateTrend != null) 'hit_rate_trend': hitRateTrend,
      if (avgDailyCount30d != null) 'avg_daily_count30d': avgDailyCount30d,
      if (checklistResult != null) 'checklist_result': checklistResult,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StrategyReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? strategyId,
    Value<DateTime>? reviewDate,
    Value<double>? healthScore,
    Value<double>? hitRate30d,
    Value<double>? avgChange30d,
    Value<double?>? maxLoss30d,
    Value<String>? hitRateTrend,
    Value<int>? avgDailyCount30d,
    Value<String>? checklistResult,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StrategyReviewsCompanion(
      id: id ?? this.id,
      strategyId: strategyId ?? this.strategyId,
      reviewDate: reviewDate ?? this.reviewDate,
      healthScore: healthScore ?? this.healthScore,
      hitRate30d: hitRate30d ?? this.hitRate30d,
      avgChange30d: avgChange30d ?? this.avgChange30d,
      maxLoss30d: maxLoss30d ?? this.maxLoss30d,
      hitRateTrend: hitRateTrend ?? this.hitRateTrend,
      avgDailyCount30d: avgDailyCount30d ?? this.avgDailyCount30d,
      checklistResult: checklistResult ?? this.checklistResult,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (strategyId.present) {
      map['strategy_id'] = Variable<String>(strategyId.value);
    }
    if (reviewDate.present) {
      map['review_date'] = Variable<DateTime>(reviewDate.value);
    }
    if (healthScore.present) {
      map['health_score'] = Variable<double>(healthScore.value);
    }
    if (hitRate30d.present) {
      map['hit_rate30d'] = Variable<double>(hitRate30d.value);
    }
    if (avgChange30d.present) {
      map['avg_change30d'] = Variable<double>(avgChange30d.value);
    }
    if (maxLoss30d.present) {
      map['max_loss30d'] = Variable<double>(maxLoss30d.value);
    }
    if (hitRateTrend.present) {
      map['hit_rate_trend'] = Variable<String>(hitRateTrend.value);
    }
    if (avgDailyCount30d.present) {
      map['avg_daily_count30d'] = Variable<int>(avgDailyCount30d.value);
    }
    if (checklistResult.present) {
      map['checklist_result'] = Variable<String>(checklistResult.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StrategyReviewsCompanion(')
          ..write('id: $id, ')
          ..write('strategyId: $strategyId, ')
          ..write('reviewDate: $reviewDate, ')
          ..write('healthScore: $healthScore, ')
          ..write('hitRate30d: $hitRate30d, ')
          ..write('avgChange30d: $avgChange30d, ')
          ..write('maxLoss30d: $maxLoss30d, ')
          ..write('hitRateTrend: $hitRateTrend, ')
          ..write('avgDailyCount30d: $avgDailyCount30d, ')
          ..write('checklistResult: $checklistResult, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WatchlistItemsTable watchlistItems = $WatchlistItemsTable(this);
  late final $StrategiesTable strategies = $StrategiesTable(this);
  late final $StrategyHitRecordsTable strategyHitRecords =
      $StrategyHitRecordsTable(this);
  late final $StrategyReviewsTable strategyReviews = $StrategyReviewsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    watchlistItems,
    strategies,
    strategyHitRecords,
    strategyReviews,
  ];
}

typedef $$WatchlistItemsTableCreateCompanionBuilder =
    WatchlistItemsCompanion Function({
      required String id,
      required String stockCode,
      required String stockName,
      Value<String> market,
      Value<bool> isPinned,
      Value<int> sortOrder,
      Value<bool> alertEnabled,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WatchlistItemsTableUpdateCompanionBuilder =
    WatchlistItemsCompanion Function({
      Value<String> id,
      Value<String> stockCode,
      Value<String> stockName,
      Value<String> market,
      Value<bool> isPinned,
      Value<int> sortOrder,
      Value<bool> alertEnabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WatchlistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $WatchlistItemsTable> {
  $$WatchlistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockCode => $composableBuilder(
    column: $table.stockCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockName => $composableBuilder(
    column: $table.stockName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alertEnabled => $composableBuilder(
    column: $table.alertEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchlistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchlistItemsTable> {
  $$WatchlistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockCode => $composableBuilder(
    column: $table.stockCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockName => $composableBuilder(
    column: $table.stockName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alertEnabled => $composableBuilder(
    column: $table.alertEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchlistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchlistItemsTable> {
  $$WatchlistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stockCode =>
      $composableBuilder(column: $table.stockCode, builder: (column) => column);

  GeneratedColumn<String> get stockName =>
      $composableBuilder(column: $table.stockName, builder: (column) => column);

  GeneratedColumn<String> get market =>
      $composableBuilder(column: $table.market, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get alertEnabled => $composableBuilder(
    column: $table.alertEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WatchlistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchlistItemsTable,
          WatchlistRow,
          $$WatchlistItemsTableFilterComposer,
          $$WatchlistItemsTableOrderingComposer,
          $$WatchlistItemsTableAnnotationComposer,
          $$WatchlistItemsTableCreateCompanionBuilder,
          $$WatchlistItemsTableUpdateCompanionBuilder,
          (
            WatchlistRow,
            BaseReferences<_$AppDatabase, $WatchlistItemsTable, WatchlistRow>,
          ),
          WatchlistRow,
          PrefetchHooks Function()
        > {
  $$WatchlistItemsTableTableManager(
    _$AppDatabase db,
    $WatchlistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchlistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchlistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchlistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> stockCode = const Value.absent(),
                Value<String> stockName = const Value.absent(),
                Value<String> market = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> alertEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchlistItemsCompanion(
                id: id,
                stockCode: stockCode,
                stockName: stockName,
                market: market,
                isPinned: isPinned,
                sortOrder: sortOrder,
                alertEnabled: alertEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String stockCode,
                required String stockName,
                Value<String> market = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> alertEnabled = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WatchlistItemsCompanion.insert(
                id: id,
                stockCode: stockCode,
                stockName: stockName,
                market: market,
                isPinned: isPinned,
                sortOrder: sortOrder,
                alertEnabled: alertEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchlistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchlistItemsTable,
      WatchlistRow,
      $$WatchlistItemsTableFilterComposer,
      $$WatchlistItemsTableOrderingComposer,
      $$WatchlistItemsTableAnnotationComposer,
      $$WatchlistItemsTableCreateCompanionBuilder,
      $$WatchlistItemsTableUpdateCompanionBuilder,
      (
        WatchlistRow,
        BaseReferences<_$AppDatabase, $WatchlistItemsTable, WatchlistRow>,
      ),
      WatchlistRow,
      PrefetchHooks Function()
    >;
typedef $$StrategiesTableCreateCompanionBuilder =
    StrategiesCompanion Function({
      required String id,
      required String name,
      Value<String> description,
      Value<int> maShortPeriod,
      Value<int> maLongPeriod,
      Value<int> bollPeriod,
      Value<double> bollStdDev,
      Value<double> weightMA,
      Value<double> weightBoll,
      Value<double> weightVol,
      Value<double> weightTrend,
      Value<int> recommendThreshold,
      Value<String?> entryRulesJson,
      Value<String?> exitRulesJson,
      Value<String?> entryGroupsJson,
      Value<String?> exitGroupsJson,
      Value<bool> isEnabled,
      Value<bool> isDefault,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastReviewAt,
      Value<int> rowid,
    });
typedef $$StrategiesTableUpdateCompanionBuilder =
    StrategiesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<int> maShortPeriod,
      Value<int> maLongPeriod,
      Value<int> bollPeriod,
      Value<double> bollStdDev,
      Value<double> weightMA,
      Value<double> weightBoll,
      Value<double> weightVol,
      Value<double> weightTrend,
      Value<int> recommendThreshold,
      Value<String?> entryRulesJson,
      Value<String?> exitRulesJson,
      Value<String?> entryGroupsJson,
      Value<String?> exitGroupsJson,
      Value<bool> isEnabled,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastReviewAt,
      Value<int> rowid,
    });

class $$StrategiesTableFilterComposer
    extends Composer<_$AppDatabase, $StrategiesTable> {
  $$StrategiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maShortPeriod => $composableBuilder(
    column: $table.maShortPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maLongPeriod => $composableBuilder(
    column: $table.maLongPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bollPeriod => $composableBuilder(
    column: $table.bollPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bollStdDev => $composableBuilder(
    column: $table.bollStdDev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightMA => $composableBuilder(
    column: $table.weightMA,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightBoll => $composableBuilder(
    column: $table.weightBoll,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightVol => $composableBuilder(
    column: $table.weightVol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightTrend => $composableBuilder(
    column: $table.weightTrend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendThreshold => $composableBuilder(
    column: $table.recommendThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryRulesJson => $composableBuilder(
    column: $table.entryRulesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exitRulesJson => $composableBuilder(
    column: $table.exitRulesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryGroupsJson => $composableBuilder(
    column: $table.entryGroupsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exitGroupsJson => $composableBuilder(
    column: $table.exitGroupsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StrategiesTableOrderingComposer
    extends Composer<_$AppDatabase, $StrategiesTable> {
  $$StrategiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maShortPeriod => $composableBuilder(
    column: $table.maShortPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maLongPeriod => $composableBuilder(
    column: $table.maLongPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bollPeriod => $composableBuilder(
    column: $table.bollPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bollStdDev => $composableBuilder(
    column: $table.bollStdDev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightMA => $composableBuilder(
    column: $table.weightMA,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightBoll => $composableBuilder(
    column: $table.weightBoll,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightVol => $composableBuilder(
    column: $table.weightVol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightTrend => $composableBuilder(
    column: $table.weightTrend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendThreshold => $composableBuilder(
    column: $table.recommendThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryRulesJson => $composableBuilder(
    column: $table.entryRulesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exitRulesJson => $composableBuilder(
    column: $table.exitRulesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryGroupsJson => $composableBuilder(
    column: $table.entryGroupsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exitGroupsJson => $composableBuilder(
    column: $table.exitGroupsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StrategiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrategiesTable> {
  $$StrategiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maShortPeriod => $composableBuilder(
    column: $table.maShortPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maLongPeriod => $composableBuilder(
    column: $table.maLongPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bollPeriod => $composableBuilder(
    column: $table.bollPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bollStdDev => $composableBuilder(
    column: $table.bollStdDev,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightMA =>
      $composableBuilder(column: $table.weightMA, builder: (column) => column);

  GeneratedColumn<double> get weightBoll => $composableBuilder(
    column: $table.weightBoll,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightVol =>
      $composableBuilder(column: $table.weightVol, builder: (column) => column);

  GeneratedColumn<double> get weightTrend => $composableBuilder(
    column: $table.weightTrend,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendThreshold => $composableBuilder(
    column: $table.recommendThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryRulesJson => $composableBuilder(
    column: $table.entryRulesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exitRulesJson => $composableBuilder(
    column: $table.exitRulesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entryGroupsJson => $composableBuilder(
    column: $table.entryGroupsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exitGroupsJson => $composableBuilder(
    column: $table.exitGroupsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewAt => $composableBuilder(
    column: $table.lastReviewAt,
    builder: (column) => column,
  );
}

class $$StrategiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrategiesTable,
          StrategyRow,
          $$StrategiesTableFilterComposer,
          $$StrategiesTableOrderingComposer,
          $$StrategiesTableAnnotationComposer,
          $$StrategiesTableCreateCompanionBuilder,
          $$StrategiesTableUpdateCompanionBuilder,
          (
            StrategyRow,
            BaseReferences<_$AppDatabase, $StrategiesTable, StrategyRow>,
          ),
          StrategyRow,
          PrefetchHooks Function()
        > {
  $$StrategiesTableTableManager(_$AppDatabase db, $StrategiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrategiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrategiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrategiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> maShortPeriod = const Value.absent(),
                Value<int> maLongPeriod = const Value.absent(),
                Value<int> bollPeriod = const Value.absent(),
                Value<double> bollStdDev = const Value.absent(),
                Value<double> weightMA = const Value.absent(),
                Value<double> weightBoll = const Value.absent(),
                Value<double> weightVol = const Value.absent(),
                Value<double> weightTrend = const Value.absent(),
                Value<int> recommendThreshold = const Value.absent(),
                Value<String?> entryRulesJson = const Value.absent(),
                Value<String?> exitRulesJson = const Value.absent(),
                Value<String?> entryGroupsJson = const Value.absent(),
                Value<String?> exitGroupsJson = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastReviewAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrategiesCompanion(
                id: id,
                name: name,
                description: description,
                maShortPeriod: maShortPeriod,
                maLongPeriod: maLongPeriod,
                bollPeriod: bollPeriod,
                bollStdDev: bollStdDev,
                weightMA: weightMA,
                weightBoll: weightBoll,
                weightVol: weightVol,
                weightTrend: weightTrend,
                recommendThreshold: recommendThreshold,
                entryRulesJson: entryRulesJson,
                exitRulesJson: exitRulesJson,
                entryGroupsJson: entryGroupsJson,
                exitGroupsJson: exitGroupsJson,
                isEnabled: isEnabled,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastReviewAt: lastReviewAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> description = const Value.absent(),
                Value<int> maShortPeriod = const Value.absent(),
                Value<int> maLongPeriod = const Value.absent(),
                Value<int> bollPeriod = const Value.absent(),
                Value<double> bollStdDev = const Value.absent(),
                Value<double> weightMA = const Value.absent(),
                Value<double> weightBoll = const Value.absent(),
                Value<double> weightVol = const Value.absent(),
                Value<double> weightTrend = const Value.absent(),
                Value<int> recommendThreshold = const Value.absent(),
                Value<String?> entryRulesJson = const Value.absent(),
                Value<String?> exitRulesJson = const Value.absent(),
                Value<String?> entryGroupsJson = const Value.absent(),
                Value<String?> exitGroupsJson = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastReviewAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrategiesCompanion.insert(
                id: id,
                name: name,
                description: description,
                maShortPeriod: maShortPeriod,
                maLongPeriod: maLongPeriod,
                bollPeriod: bollPeriod,
                bollStdDev: bollStdDev,
                weightMA: weightMA,
                weightBoll: weightBoll,
                weightVol: weightVol,
                weightTrend: weightTrend,
                recommendThreshold: recommendThreshold,
                entryRulesJson: entryRulesJson,
                exitRulesJson: exitRulesJson,
                entryGroupsJson: entryGroupsJson,
                exitGroupsJson: exitGroupsJson,
                isEnabled: isEnabled,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastReviewAt: lastReviewAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StrategiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrategiesTable,
      StrategyRow,
      $$StrategiesTableFilterComposer,
      $$StrategiesTableOrderingComposer,
      $$StrategiesTableAnnotationComposer,
      $$StrategiesTableCreateCompanionBuilder,
      $$StrategiesTableUpdateCompanionBuilder,
      (
        StrategyRow,
        BaseReferences<_$AppDatabase, $StrategiesTable, StrategyRow>,
      ),
      StrategyRow,
      PrefetchHooks Function()
    >;
typedef $$StrategyHitRecordsTableCreateCompanionBuilder =
    StrategyHitRecordsCompanion Function({
      required String id,
      required String strategyId,
      required String stockCode,
      required String stockName,
      required String recommendDate,
      required int recommendScore,
      required double recommendPrice,
      Value<double?> actualChange5d,
      Value<bool?> isHit,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$StrategyHitRecordsTableUpdateCompanionBuilder =
    StrategyHitRecordsCompanion Function({
      Value<String> id,
      Value<String> strategyId,
      Value<String> stockCode,
      Value<String> stockName,
      Value<String> recommendDate,
      Value<int> recommendScore,
      Value<double> recommendPrice,
      Value<double?> actualChange5d,
      Value<bool?> isHit,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$StrategyHitRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $StrategyHitRecordsTable> {
  $$StrategyHitRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strategyId => $composableBuilder(
    column: $table.strategyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockCode => $composableBuilder(
    column: $table.stockCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockName => $composableBuilder(
    column: $table.stockName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recommendDate => $composableBuilder(
    column: $table.recommendDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recommendScore => $composableBuilder(
    column: $table.recommendScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get recommendPrice => $composableBuilder(
    column: $table.recommendPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get actualChange5d => $composableBuilder(
    column: $table.actualChange5d,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHit => $composableBuilder(
    column: $table.isHit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StrategyHitRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $StrategyHitRecordsTable> {
  $$StrategyHitRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategyId => $composableBuilder(
    column: $table.strategyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockCode => $composableBuilder(
    column: $table.stockCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockName => $composableBuilder(
    column: $table.stockName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recommendDate => $composableBuilder(
    column: $table.recommendDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recommendScore => $composableBuilder(
    column: $table.recommendScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get recommendPrice => $composableBuilder(
    column: $table.recommendPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get actualChange5d => $composableBuilder(
    column: $table.actualChange5d,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHit => $composableBuilder(
    column: $table.isHit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StrategyHitRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrategyHitRecordsTable> {
  $$StrategyHitRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get strategyId => $composableBuilder(
    column: $table.strategyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stockCode =>
      $composableBuilder(column: $table.stockCode, builder: (column) => column);

  GeneratedColumn<String> get stockName =>
      $composableBuilder(column: $table.stockName, builder: (column) => column);

  GeneratedColumn<String> get recommendDate => $composableBuilder(
    column: $table.recommendDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recommendScore => $composableBuilder(
    column: $table.recommendScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get recommendPrice => $composableBuilder(
    column: $table.recommendPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get actualChange5d => $composableBuilder(
    column: $table.actualChange5d,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHit =>
      $composableBuilder(column: $table.isHit, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StrategyHitRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrategyHitRecordsTable,
          StrategyHitRecordRow,
          $$StrategyHitRecordsTableFilterComposer,
          $$StrategyHitRecordsTableOrderingComposer,
          $$StrategyHitRecordsTableAnnotationComposer,
          $$StrategyHitRecordsTableCreateCompanionBuilder,
          $$StrategyHitRecordsTableUpdateCompanionBuilder,
          (
            StrategyHitRecordRow,
            BaseReferences<
              _$AppDatabase,
              $StrategyHitRecordsTable,
              StrategyHitRecordRow
            >,
          ),
          StrategyHitRecordRow,
          PrefetchHooks Function()
        > {
  $$StrategyHitRecordsTableTableManager(
    _$AppDatabase db,
    $StrategyHitRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrategyHitRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrategyHitRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrategyHitRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> strategyId = const Value.absent(),
                Value<String> stockCode = const Value.absent(),
                Value<String> stockName = const Value.absent(),
                Value<String> recommendDate = const Value.absent(),
                Value<int> recommendScore = const Value.absent(),
                Value<double> recommendPrice = const Value.absent(),
                Value<double?> actualChange5d = const Value.absent(),
                Value<bool?> isHit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrategyHitRecordsCompanion(
                id: id,
                strategyId: strategyId,
                stockCode: stockCode,
                stockName: stockName,
                recommendDate: recommendDate,
                recommendScore: recommendScore,
                recommendPrice: recommendPrice,
                actualChange5d: actualChange5d,
                isHit: isHit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String strategyId,
                required String stockCode,
                required String stockName,
                required String recommendDate,
                required int recommendScore,
                required double recommendPrice,
                Value<double?> actualChange5d = const Value.absent(),
                Value<bool?> isHit = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StrategyHitRecordsCompanion.insert(
                id: id,
                strategyId: strategyId,
                stockCode: stockCode,
                stockName: stockName,
                recommendDate: recommendDate,
                recommendScore: recommendScore,
                recommendPrice: recommendPrice,
                actualChange5d: actualChange5d,
                isHit: isHit,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StrategyHitRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrategyHitRecordsTable,
      StrategyHitRecordRow,
      $$StrategyHitRecordsTableFilterComposer,
      $$StrategyHitRecordsTableOrderingComposer,
      $$StrategyHitRecordsTableAnnotationComposer,
      $$StrategyHitRecordsTableCreateCompanionBuilder,
      $$StrategyHitRecordsTableUpdateCompanionBuilder,
      (
        StrategyHitRecordRow,
        BaseReferences<
          _$AppDatabase,
          $StrategyHitRecordsTable,
          StrategyHitRecordRow
        >,
      ),
      StrategyHitRecordRow,
      PrefetchHooks Function()
    >;
typedef $$StrategyReviewsTableCreateCompanionBuilder =
    StrategyReviewsCompanion Function({
      required String id,
      required String strategyId,
      required DateTime reviewDate,
      required double healthScore,
      required double hitRate30d,
      required double avgChange30d,
      Value<double?> maxLoss30d,
      required String hitRateTrend,
      required int avgDailyCount30d,
      required String checklistResult,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$StrategyReviewsTableUpdateCompanionBuilder =
    StrategyReviewsCompanion Function({
      Value<String> id,
      Value<String> strategyId,
      Value<DateTime> reviewDate,
      Value<double> healthScore,
      Value<double> hitRate30d,
      Value<double> avgChange30d,
      Value<double?> maxLoss30d,
      Value<String> hitRateTrend,
      Value<int> avgDailyCount30d,
      Value<String> checklistResult,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$StrategyReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $StrategyReviewsTable> {
  $$StrategyReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strategyId => $composableBuilder(
    column: $table.strategyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get hitRate30d => $composableBuilder(
    column: $table.hitRate30d,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get avgChange30d => $composableBuilder(
    column: $table.avgChange30d,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxLoss30d => $composableBuilder(
    column: $table.maxLoss30d,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hitRateTrend => $composableBuilder(
    column: $table.hitRateTrend,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avgDailyCount30d => $composableBuilder(
    column: $table.avgDailyCount30d,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checklistResult => $composableBuilder(
    column: $table.checklistResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StrategyReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $StrategyReviewsTable> {
  $$StrategyReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strategyId => $composableBuilder(
    column: $table.strategyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get hitRate30d => $composableBuilder(
    column: $table.hitRate30d,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get avgChange30d => $composableBuilder(
    column: $table.avgChange30d,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxLoss30d => $composableBuilder(
    column: $table.maxLoss30d,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hitRateTrend => $composableBuilder(
    column: $table.hitRateTrend,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avgDailyCount30d => $composableBuilder(
    column: $table.avgDailyCount30d,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checklistResult => $composableBuilder(
    column: $table.checklistResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StrategyReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StrategyReviewsTable> {
  $$StrategyReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get strategyId => $composableBuilder(
    column: $table.strategyId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewDate => $composableBuilder(
    column: $table.reviewDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get healthScore => $composableBuilder(
    column: $table.healthScore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get hitRate30d => $composableBuilder(
    column: $table.hitRate30d,
    builder: (column) => column,
  );

  GeneratedColumn<double> get avgChange30d => $composableBuilder(
    column: $table.avgChange30d,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxLoss30d => $composableBuilder(
    column: $table.maxLoss30d,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hitRateTrend => $composableBuilder(
    column: $table.hitRateTrend,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avgDailyCount30d => $composableBuilder(
    column: $table.avgDailyCount30d,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checklistResult => $composableBuilder(
    column: $table.checklistResult,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StrategyReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StrategyReviewsTable,
          StrategyReviewRow,
          $$StrategyReviewsTableFilterComposer,
          $$StrategyReviewsTableOrderingComposer,
          $$StrategyReviewsTableAnnotationComposer,
          $$StrategyReviewsTableCreateCompanionBuilder,
          $$StrategyReviewsTableUpdateCompanionBuilder,
          (
            StrategyReviewRow,
            BaseReferences<
              _$AppDatabase,
              $StrategyReviewsTable,
              StrategyReviewRow
            >,
          ),
          StrategyReviewRow,
          PrefetchHooks Function()
        > {
  $$StrategyReviewsTableTableManager(
    _$AppDatabase db,
    $StrategyReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StrategyReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StrategyReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StrategyReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> strategyId = const Value.absent(),
                Value<DateTime> reviewDate = const Value.absent(),
                Value<double> healthScore = const Value.absent(),
                Value<double> hitRate30d = const Value.absent(),
                Value<double> avgChange30d = const Value.absent(),
                Value<double?> maxLoss30d = const Value.absent(),
                Value<String> hitRateTrend = const Value.absent(),
                Value<int> avgDailyCount30d = const Value.absent(),
                Value<String> checklistResult = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StrategyReviewsCompanion(
                id: id,
                strategyId: strategyId,
                reviewDate: reviewDate,
                healthScore: healthScore,
                hitRate30d: hitRate30d,
                avgChange30d: avgChange30d,
                maxLoss30d: maxLoss30d,
                hitRateTrend: hitRateTrend,
                avgDailyCount30d: avgDailyCount30d,
                checklistResult: checklistResult,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String strategyId,
                required DateTime reviewDate,
                required double healthScore,
                required double hitRate30d,
                required double avgChange30d,
                Value<double?> maxLoss30d = const Value.absent(),
                required String hitRateTrend,
                required int avgDailyCount30d,
                required String checklistResult,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StrategyReviewsCompanion.insert(
                id: id,
                strategyId: strategyId,
                reviewDate: reviewDate,
                healthScore: healthScore,
                hitRate30d: hitRate30d,
                avgChange30d: avgChange30d,
                maxLoss30d: maxLoss30d,
                hitRateTrend: hitRateTrend,
                avgDailyCount30d: avgDailyCount30d,
                checklistResult: checklistResult,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StrategyReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StrategyReviewsTable,
      StrategyReviewRow,
      $$StrategyReviewsTableFilterComposer,
      $$StrategyReviewsTableOrderingComposer,
      $$StrategyReviewsTableAnnotationComposer,
      $$StrategyReviewsTableCreateCompanionBuilder,
      $$StrategyReviewsTableUpdateCompanionBuilder,
      (
        StrategyReviewRow,
        BaseReferences<_$AppDatabase, $StrategyReviewsTable, StrategyReviewRow>,
      ),
      StrategyReviewRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WatchlistItemsTableTableManager get watchlistItems =>
      $$WatchlistItemsTableTableManager(_db, _db.watchlistItems);
  $$StrategiesTableTableManager get strategies =>
      $$StrategiesTableTableManager(_db, _db.strategies);
  $$StrategyHitRecordsTableTableManager get strategyHitRecords =>
      $$StrategyHitRecordsTableTableManager(_db, _db.strategyHitRecords);
  $$StrategyReviewsTableTableManager get strategyReviews =>
      $$StrategyReviewsTableTableManager(_db, _db.strategyReviews);
}
