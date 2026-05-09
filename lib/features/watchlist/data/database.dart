import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

/// Drift database for StockPilot local storage.
@DriftDatabase(tables: [WatchlistItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Create index on stockCode for faster lookups.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_watchlist_stock_code ON watchlist_items (stock_code);',
          );
        },
      );
}

/// Opens a SQLite database connection at the app's document directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'stockpilot.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
