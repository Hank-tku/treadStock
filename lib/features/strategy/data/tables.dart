import 'package:drift/drift.dart';

/// Drift table definition for strategies.
@DataClassName('StrategyRow')
class Strategies extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 20)();
  TextColumn get description =>
      text().withLength(max: 100).withDefault(const Constant(''))();

  // Analysis parameters
  IntColumn get maShortPeriod => integer().withDefault(const Constant(20))();
  IntColumn get maLongPeriod => integer().withDefault(const Constant(60))();
  IntColumn get bollPeriod => integer().withDefault(const Constant(20))();
  RealColumn get bollStdDev => real().withDefault(const Constant(2.0))();
  RealColumn get weightMA => real().withDefault(const Constant(0.30))();
  RealColumn get weightBoll => real().withDefault(const Constant(0.30))();
  RealColumn get weightVol => real().withDefault(const Constant(0.20))();
  RealColumn get weightTrend => real().withDefault(const Constant(0.20))();
  IntColumn get recommendThreshold =>
      integer().withDefault(const Constant(7))();

  // Status
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  // Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastReviewAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table definition for strategy hit records.
/// Tracks each recommendation and its actual 5-day performance.
@DataClassName('StrategyHitRecordRow')
class StrategyHitRecords extends Table {
  TextColumn get id => text()();
  TextColumn get strategyId => text()();
  TextColumn get stockCode => text()();
  TextColumn get stockName => text()();
  TextColumn get recommendDate => text()(); // "2026-05-05" format
  IntColumn get recommendScore => integer()();
  RealColumn get recommendPrice => real()();
  RealColumn get actualChange5d => real().nullable()();
  BoolColumn get isHit => boolean().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table definition for strategy reviews.
/// Stores periodic review checklists and health scores.
@DataClassName('StrategyReviewRow')
class StrategyReviews extends Table {
  TextColumn get id => text()();
  TextColumn get strategyId => text()();
  DateTimeColumn get reviewDate => dateTime()();
  RealColumn get healthScore => real()();

  // Check list metrics
  RealColumn get hitRate30d => real()();
  RealColumn get avgChange30d => real()();
  RealColumn get maxLoss30d => real().nullable()();
  TextColumn get hitRateTrend => text()(); // "up" / "flat" / "down"
  IntColumn get avgDailyCount30d => integer()();

  // Detailed check list results (JSON)
  TextColumn get checklistResult => text()();
  TextColumn get note => text().withLength(max: 200).nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
