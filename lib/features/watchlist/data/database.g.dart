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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WatchlistItemsTable watchlistItems = $WatchlistItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [watchlistItems];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WatchlistItemsTableTableManager get watchlistItems =>
      $$WatchlistItemsTableTableManager(_db, _db.watchlistItems);
}
