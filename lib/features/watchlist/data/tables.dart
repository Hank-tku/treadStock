import 'package:drift/drift.dart';

/// Drift table definition for watchlist items.
@DataClassName('WatchlistRow')
class WatchlistItems extends Table {
  TextColumn get id => text()();
  TextColumn get stockCode => text()();
  TextColumn get stockName => text()();
  TextColumn get market => text().withDefault(const Constant('SH'))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get alertEnabled =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
