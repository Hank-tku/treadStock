import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../domain/stock_models.dart';

part 'kline_cache.g.dart';

/// Drift table definition for K-line cache entries.
@DataClassName('KlineCacheRow')
class KlineCaches extends Table {
  TextColumn get stockCode => text()();
  TextColumn get market => text().withDefault(const Constant('SH'))();
  TextColumn get klinesJson => text()();
  IntColumn get fetchedAt => integer()(); // Unix timestamp ms
  IntColumn get expiresAt => integer()(); // Unix timestamp ms

  @override
  Set<Column> get primaryKey => {stockCode};
}

/// Drift database for K-line cache storage.
@DriftDatabase(tables: [KlineCaches])
class KlineCacheDatabase extends _$KlineCacheDatabase {
  KlineCacheDatabase() : super(_openConnection());

  KlineCacheDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
      );

  /// Retrieve cached K-lines for [code] if they haven't expired.
  /// Returns null on cache miss or if the entry has expired.
  Future<List<DailyKline>?> getCachedKlines(String code) async {
    final row = await (select(klineCaches)
          ..where((t) => t.stockCode.equals(code)))
        .getSingleOrNull();
    if (row == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (row.expiresAt <= now) return null;

    return _parseKlinesJson(row.klinesJson);
  }

  /// Save K-line data to cache with a configurable TTL.
  Future<void> saveKlines(
    String code,
    String market,
    List<DailyKline> klines, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final jsonStr = _encodeKlines(klines);
    await into(klineCaches).insertOnConflictUpdate(
      KlineCachesCompanion.insert(
        stockCode: code,
        market: Value(market),
        klinesJson: jsonStr,
        fetchedAt: now,
        expiresAt: now + ttl.inMilliseconds,
      ),
    );
  }

  /// Remove all expired cache entries.
  Future<void> clearExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (delete(klineCaches)..where((t) => t.expiresAt.isSmallerThanValue(now)))
        .go();
  }

  /// Remove all cache entries.
  Future<void> clearAll() async {
    await delete(klineCaches).go();
  }

  // ---------------------------------------------------------------------------
  // JSON helpers for DailyKline (no toJson/fromJson on the model itself)
  // ---------------------------------------------------------------------------

  static String _encodeKlines(List<DailyKline> klines) {
    final list = klines.map((k) => _klineToMap(k)).toList();
    return jsonEncode(list);
  }

  static List<DailyKline> _parseKlinesJson(String jsonStr) {
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => _klineFromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _klineToMap(DailyKline k) {
    return {
      'date': k.date.toIso8601String(),
      'open': k.open,
      'close': k.close,
      'high': k.high,
      'low': k.low,
      'volume': k.volume,
      'amount': k.amount,
      'preClose': k.preClose,
    };
  }

  static DailyKline _klineFromMap(Map<String, dynamic> m) {
    return DailyKline(
      date: DateTime.parse(m['date'] as String),
      open: (m['open'] as num).toDouble(),
      close: (m['close'] as num).toDouble(),
      high: (m['high'] as num).toDouble(),
      low: (m['low'] as num).toDouble(),
      volume: (m['volume'] as num).toDouble(),
      amount: (m['amount'] as num).toDouble(),
      preClose: (m['preClose'] as num).toDouble(),
    );
  }
}

/// Opens a SQLite database connection for the K-line cache.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'kline_cache.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
