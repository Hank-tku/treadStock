// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kline_cache.dart';

// ignore_for_file: type=lint
class $KlineCachesTable extends KlineCaches
    with TableInfo<$KlineCachesTable, KlineCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KlineCachesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _daysMeta = const VerificationMeta('days');
  @override
  late final GeneratedColumn<int> days = GeneratedColumn<int>(
    'days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(120),
  );
  static const VerificationMeta _klinesJsonMeta = const VerificationMeta(
    'klinesJson',
  );
  @override
  late final GeneratedColumn<String> klinesJson = GeneratedColumn<String>(
    'klines_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    stockCode,
    market,
    days,
    klinesJson,
    fetchedAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kline_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<KlineCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stock_code')) {
      context.handle(
        _stockCodeMeta,
        stockCode.isAcceptableOrUnknown(data['stock_code']!, _stockCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_stockCodeMeta);
    }
    if (data.containsKey('market')) {
      context.handle(
        _marketMeta,
        market.isAcceptableOrUnknown(data['market']!, _marketMeta),
      );
    }
    if (data.containsKey('days')) {
      context.handle(
        _daysMeta,
        days.isAcceptableOrUnknown(data['days']!, _daysMeta),
      );
    }
    if (data.containsKey('klines_json')) {
      context.handle(
        _klinesJsonMeta,
        klinesJson.isAcceptableOrUnknown(data['klines_json']!, _klinesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_klinesJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stockCode, market, days};
  @override
  KlineCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KlineCacheRow(
      stockCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_code'],
      )!,
      market: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market'],
      )!,
      days: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days'],
      )!,
      klinesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}klines_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $KlineCachesTable createAlias(String alias) {
    return $KlineCachesTable(attachedDatabase, alias);
  }
}

class KlineCacheRow extends DataClass implements Insertable<KlineCacheRow> {
  final String stockCode;
  final String market;
  final int days;
  final String klinesJson;
  final int fetchedAt;
  final int expiresAt;
  const KlineCacheRow({
    required this.stockCode,
    required this.market,
    required this.days,
    required this.klinesJson,
    required this.fetchedAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stock_code'] = Variable<String>(stockCode);
    map['market'] = Variable<String>(market);
    map['days'] = Variable<int>(days);
    map['klines_json'] = Variable<String>(klinesJson);
    map['fetched_at'] = Variable<int>(fetchedAt);
    map['expires_at'] = Variable<int>(expiresAt);
    return map;
  }

  KlineCachesCompanion toCompanion(bool nullToAbsent) {
    return KlineCachesCompanion(
      stockCode: Value(stockCode),
      market: Value(market),
      days: Value(days),
      klinesJson: Value(klinesJson),
      fetchedAt: Value(fetchedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory KlineCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KlineCacheRow(
      stockCode: serializer.fromJson<String>(json['stockCode']),
      market: serializer.fromJson<String>(json['market']),
      days: serializer.fromJson<int>(json['days']),
      klinesJson: serializer.fromJson<String>(json['klinesJson']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stockCode': serializer.toJson<String>(stockCode),
      'market': serializer.toJson<String>(market),
      'days': serializer.toJson<int>(days),
      'klinesJson': serializer.toJson<String>(klinesJson),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
    };
  }

  KlineCacheRow copyWith({
    String? stockCode,
    String? market,
    int? days,
    String? klinesJson,
    int? fetchedAt,
    int? expiresAt,
  }) => KlineCacheRow(
    stockCode: stockCode ?? this.stockCode,
    market: market ?? this.market,
    days: days ?? this.days,
    klinesJson: klinesJson ?? this.klinesJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  KlineCacheRow copyWithCompanion(KlineCachesCompanion data) {
    return KlineCacheRow(
      stockCode: data.stockCode.present ? data.stockCode.value : this.stockCode,
      market: data.market.present ? data.market.value : this.market,
      days: data.days.present ? data.days.value : this.days,
      klinesJson: data.klinesJson.present
          ? data.klinesJson.value
          : this.klinesJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KlineCacheRow(')
          ..write('stockCode: $stockCode, ')
          ..write('market: $market, ')
          ..write('days: $days, ')
          ..write('klinesJson: $klinesJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(stockCode, market, days, klinesJson, fetchedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KlineCacheRow &&
          other.stockCode == this.stockCode &&
          other.market == this.market &&
          other.days == this.days &&
          other.klinesJson == this.klinesJson &&
          other.fetchedAt == this.fetchedAt &&
          other.expiresAt == this.expiresAt);
}

class KlineCachesCompanion extends UpdateCompanion<KlineCacheRow> {
  final Value<String> stockCode;
  final Value<String> market;
  final Value<int> days;
  final Value<String> klinesJson;
  final Value<int> fetchedAt;
  final Value<int> expiresAt;
  final Value<int> rowid;
  const KlineCachesCompanion({
    this.stockCode = const Value.absent(),
    this.market = const Value.absent(),
    this.days = const Value.absent(),
    this.klinesJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KlineCachesCompanion.insert({
    required String stockCode,
    this.market = const Value.absent(),
    this.days = const Value.absent(),
    required String klinesJson,
    required int fetchedAt,
    required int expiresAt,
    this.rowid = const Value.absent(),
  }) : stockCode = Value(stockCode),
       klinesJson = Value(klinesJson),
       fetchedAt = Value(fetchedAt),
       expiresAt = Value(expiresAt);
  static Insertable<KlineCacheRow> custom({
    Expression<String>? stockCode,
    Expression<String>? market,
    Expression<int>? days,
    Expression<String>? klinesJson,
    Expression<int>? fetchedAt,
    Expression<int>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stockCode != null) 'stock_code': stockCode,
      if (market != null) 'market': market,
      if (days != null) 'days': days,
      if (klinesJson != null) 'klines_json': klinesJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KlineCachesCompanion copyWith({
    Value<String>? stockCode,
    Value<String>? market,
    Value<int>? days,
    Value<String>? klinesJson,
    Value<int>? fetchedAt,
    Value<int>? expiresAt,
    Value<int>? rowid,
  }) {
    return KlineCachesCompanion(
      stockCode: stockCode ?? this.stockCode,
      market: market ?? this.market,
      days: days ?? this.days,
      klinesJson: klinesJson ?? this.klinesJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stockCode.present) {
      map['stock_code'] = Variable<String>(stockCode.value);
    }
    if (market.present) {
      map['market'] = Variable<String>(market.value);
    }
    if (days.present) {
      map['days'] = Variable<int>(days.value);
    }
    if (klinesJson.present) {
      map['klines_json'] = Variable<String>(klinesJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KlineCachesCompanion(')
          ..write('stockCode: $stockCode, ')
          ..write('market: $market, ')
          ..write('days: $days, ')
          ..write('klinesJson: $klinesJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$KlineCacheDatabase extends GeneratedDatabase {
  _$KlineCacheDatabase(QueryExecutor e) : super(e);
  $KlineCacheDatabaseManager get managers => $KlineCacheDatabaseManager(this);
  late final $KlineCachesTable klineCaches = $KlineCachesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [klineCaches];
}

typedef $$KlineCachesTableCreateCompanionBuilder =
    KlineCachesCompanion Function({
      required String stockCode,
      Value<String> market,
      Value<int> days,
      required String klinesJson,
      required int fetchedAt,
      required int expiresAt,
      Value<int> rowid,
    });
typedef $$KlineCachesTableUpdateCompanionBuilder =
    KlineCachesCompanion Function({
      Value<String> stockCode,
      Value<String> market,
      Value<int> days,
      Value<String> klinesJson,
      Value<int> fetchedAt,
      Value<int> expiresAt,
      Value<int> rowid,
    });

class $$KlineCachesTableFilterComposer
    extends Composer<_$KlineCacheDatabase, $KlineCachesTable> {
  $$KlineCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stockCode => $composableBuilder(
    column: $table.stockCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get klinesJson => $composableBuilder(
    column: $table.klinesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KlineCachesTableOrderingComposer
    extends Composer<_$KlineCacheDatabase, $KlineCachesTable> {
  $$KlineCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stockCode => $composableBuilder(
    column: $table.stockCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get market => $composableBuilder(
    column: $table.market,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get days => $composableBuilder(
    column: $table.days,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get klinesJson => $composableBuilder(
    column: $table.klinesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KlineCachesTableAnnotationComposer
    extends Composer<_$KlineCacheDatabase, $KlineCachesTable> {
  $$KlineCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stockCode =>
      $composableBuilder(column: $table.stockCode, builder: (column) => column);

  GeneratedColumn<String> get market =>
      $composableBuilder(column: $table.market, builder: (column) => column);

  GeneratedColumn<int> get days =>
      $composableBuilder(column: $table.days, builder: (column) => column);

  GeneratedColumn<String> get klinesJson => $composableBuilder(
    column: $table.klinesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$KlineCachesTableTableManager
    extends
        RootTableManager<
          _$KlineCacheDatabase,
          $KlineCachesTable,
          KlineCacheRow,
          $$KlineCachesTableFilterComposer,
          $$KlineCachesTableOrderingComposer,
          $$KlineCachesTableAnnotationComposer,
          $$KlineCachesTableCreateCompanionBuilder,
          $$KlineCachesTableUpdateCompanionBuilder,
          (
            KlineCacheRow,
            BaseReferences<
              _$KlineCacheDatabase,
              $KlineCachesTable,
              KlineCacheRow
            >,
          ),
          KlineCacheRow,
          PrefetchHooks Function()
        > {
  $$KlineCachesTableTableManager(
    _$KlineCacheDatabase db,
    $KlineCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KlineCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KlineCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KlineCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> stockCode = const Value.absent(),
                Value<String> market = const Value.absent(),
                Value<int> days = const Value.absent(),
                Value<String> klinesJson = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KlineCachesCompanion(
                stockCode: stockCode,
                market: market,
                days: days,
                klinesJson: klinesJson,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stockCode,
                Value<String> market = const Value.absent(),
                Value<int> days = const Value.absent(),
                required String klinesJson,
                required int fetchedAt,
                required int expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => KlineCachesCompanion.insert(
                stockCode: stockCode,
                market: market,
                days: days,
                klinesJson: klinesJson,
                fetchedAt: fetchedAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KlineCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$KlineCacheDatabase,
      $KlineCachesTable,
      KlineCacheRow,
      $$KlineCachesTableFilterComposer,
      $$KlineCachesTableOrderingComposer,
      $$KlineCachesTableAnnotationComposer,
      $$KlineCachesTableCreateCompanionBuilder,
      $$KlineCachesTableUpdateCompanionBuilder,
      (
        KlineCacheRow,
        BaseReferences<_$KlineCacheDatabase, $KlineCachesTable, KlineCacheRow>,
      ),
      KlineCacheRow,
      PrefetchHooks Function()
    >;

class $KlineCacheDatabaseManager {
  final _$KlineCacheDatabase _db;
  $KlineCacheDatabaseManager(this._db);
  $$KlineCachesTableTableManager get klineCaches =>
      $$KlineCachesTableTableManager(_db, _db.klineCaches);
}
