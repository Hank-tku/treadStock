import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../watchlist/data/tables.dart';
import 'tables.dart';

export '../../watchlist/data/tables.dart' show WatchlistItems;
export 'tables.dart' show Strategies, StrategyHitRecords, StrategyReviews;

part 'database.g.dart';

/// Drift database for StockPilot local storage.
/// Schema v2: added Strategies, StrategyHitRecords, StrategyReviews tables.
@DriftDatabase(
  tables: [
    WatchlistItems,
    Strategies,
    StrategyHitRecords,
    StrategyReviews,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // v1 -> v2: add strategy tables
            await m.createTable(strategies);
            await m.createTable(strategyHitRecords);
            await m.createTable(strategyReviews);
            await _createIndexes();
            await _ensureDefaultStrategy();
          }
          if (from < 3) {
            // v2 -> v3: add signal rules JSON columns to strategies
            await customStatement(
              'ALTER TABLE strategies ADD COLUMN entry_rules_json TEXT',
            );
            await customStatement(
              'ALTER TABLE strategies ADD COLUMN exit_rules_json TEXT',
            );
          }
          if (from < 4) {
            // v3 -> v4: add rule groups JSON columns
            await customStatement(
              'ALTER TABLE strategies ADD COLUMN entry_groups_json TEXT',
            );
            await customStatement(
              'ALTER TABLE strategies ADD COLUMN exit_groups_json TEXT',
            );
          }
        },
      );

  /// Create database indexes for performance.
  Future<void> _createIndexes() async {
    // Watchlist index
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_watchlist_stock_code ON watchlist_items (stock_code);',
    );
    // Strategy hit records indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_hit_record_strategy_date ON strategy_hit_records (strategy_id, recommend_date);',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_hit_record_strategy_unfilled ON strategy_hit_records (strategy_id) WHERE is_hit IS NULL;',
    );
    // Strategy reviews index
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_review_strategy_date ON strategy_reviews (strategy_id, review_date);',
    );
  }

  /// Ensure a default strategy exists (auto-created for v1 -> v2 migration).
  Future<void> _ensureDefaultStrategy() async {
    final existing = await select(strategies).get();
    final hasDefault = existing.any((s) => s.isDefault);
    if (!hasDefault) {
      await _insertDefaultStrategy();
    }
  }

  Future<void> _insertDefaultStrategy() async {
    final now = DateTime.now();
    await into(strategies).insert(
      StrategiesCompanion.insert(
        id: const Uuid().v4(),
        name: '默认波段策略',
        description: const Value('MA20/60 + 布林带 + 量比 + 趋势评分'),
        maShortPeriod: const Value(20),
        maLongPeriod: const Value(60),
        bollPeriod: const Value(20),
        bollStdDev: const Value(2.0),
        weightMA: const Value(0.30),
        weightBoll: const Value(0.30),
        weightVol: const Value(0.20),
        weightTrend: const Value(0.20),
        recommendThreshold: const Value(7),
        isEnabled: const Value(true),
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Initialize default strategy if none exists (for fresh installs).
  Future<void> ensureDefaultStrategy() async {
    await _ensureDefaultStrategy();
  }
}

/// Opens a SQLite database connection at the app's document directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'stockpilot.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
