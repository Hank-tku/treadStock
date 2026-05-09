import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../strategy/data/database.dart';

/// Local watchlist management service backed by Drift (SQLite).
class WatchlistService {
  final AppDatabase _db;
  final _uuid = const Uuid();
  Future<void>? _initFuture;

  /// Cache for domain watchlist items (includes real-time data not persisted).
  final List<WatchlistItem> _cache = [];

  WatchlistService({AppDatabase? db}) : _db = db ?? AppDatabase();

  /// Initialize: load all items from DB into cache.
  Future<void> init() async {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    final rows = await _db.select(_db.watchlistItems).get();
    _cache.clear();
    _cache.addAll(rows.map(_rowToDomain));
  }

  /// Returns sorted watchlist items from cache.
  List<WatchlistItem> getWatchlist() {
    final sorted = List<WatchlistItem>.from(_cache);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      if (a.isPinned && b.isPinned) {
        return b.sortOrder.compareTo(a.sortOrder);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  Future<void> addToWatchlist(
    String stockCode,
    String stockName,
    String market,
  ) async {
    final exists = _cache.any((item) => item.stockCode == stockCode);
    if (exists) {
      throw Exception('ALREADY_EXISTS');
    }

    final now = DateTime.now();
    final id = _uuid.v4();

    final maxSortOrder = _cache.isEmpty
        ? 0
        : _cache
              .where((item) => item.isPinned)
              .map((item) => item.sortOrder)
              .fold(0, (max, order) => order > max ? order : max);

    await _db
        .into(_db.watchlistItems)
        .insert(
          WatchlistItemsCompanion.insert(
            id: id,
            stockCode: stockCode,
            stockName: stockName,
            market: Value(market),
            isPinned: const Value(false),
            sortOrder: Value(maxSortOrder),
            alertEnabled: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    _cache.add(
      WatchlistItem(
        id: id,
        stockCode: stockCode,
        stockName: stockName,
        market: market,
        isPinned: false,
        sortOrder: maxSortOrder,
        alertEnabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> removeFromWatchlist(String id) async {
    await (_db.delete(_db.watchlistItems)..where((t) => t.id.equals(id))).go();
    _cache.removeWhere((item) => item.id == id);
  }

  Future<void> togglePin(String id, bool isPinned) async {
    final index = _cache.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final item = _cache[index];
    int newSortOrder;
    if (isPinned) {
      final maxOrder = _cache.isEmpty
          ? 0
          : _cache
                .where((i) => i.isPinned)
                .map((i) => i.sortOrder)
                .fold(0, (max, order) => order > max ? order : max);
      newSortOrder = maxOrder + 1;
    } else {
      newSortOrder = 0;
    }

    final now = DateTime.now();
    await (_db.update(_db.watchlistItems)..where((t) => t.id.equals(id))).write(
      WatchlistItemsCompanion(
        isPinned: Value(isPinned),
        sortOrder: Value(newSortOrder),
        updatedAt: Value(now),
      ),
    );

    _cache[index] = item.copyWith(isPinned: isPinned, sortOrder: newSortOrder);
  }

  Future<void> toggleAlert(String id, bool enabled) async {
    final index = _cache.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final now = DateTime.now();
    await (_db.update(_db.watchlistItems)..where((t) => t.id.equals(id))).write(
      WatchlistItemsCompanion(
        alertEnabled: Value(enabled),
        updatedAt: Value(now),
      ),
    );

    _cache[index] = _cache[index].copyWith(alertEnabled: enabled);
  }

  bool isWatched(String stockCode) {
    return _cache.any((item) => item.stockCode == stockCode);
  }

  /// Find watchlist item by stock code.
  WatchlistItem? findByCode(String stockCode) {
    try {
      return _cache.firstWhere((item) => item.stockCode == stockCode);
    } catch (_) {
      return null;
    }
  }

  /// Update real-time data for a watchlist item (in-memory cache only).
  void updateQuote(String stockCode, double price, double changePct) {
    final index = _cache.indexWhere((item) => item.stockCode == stockCode);
    if (index < 0) return;
    _cache[index] = _cache[index].copyWith(
      currentPrice: price,
      currentChangePct: changePct,
    );
  }

  /// Update score for a watchlist item (in-memory cache only).
  void updateScore(String stockCode, dynamic score) {
    final index = _cache.indexWhere((item) => item.stockCode == stockCode);
    if (index < 0) return;
    _cache[index] = _cache[index].copyWith(currentScore: score);
  }

  /// Convert a Drift DB row to domain WatchlistItem.
  WatchlistItem _rowToDomain(WatchlistRow row) {
    return WatchlistItem(
      id: row.id,
      stockCode: row.stockCode,
      stockName: row.stockName,
      market: row.market,
      isPinned: row.isPinned,
      sortOrder: row.sortOrder,
      alertEnabled: row.alertEnabled,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
