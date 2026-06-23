import 'package:flutter/foundation.dart';
import '../../strategy/data/strategy_service.dart';
import '../../strategy/domain/strategy_models.dart';
import 'notification_service.dart';

/// Runs automatic daily strategy reviews.
///
/// Mirrors the AlertScheduler pattern: a plain Dart class that walks enabled
/// strategies, generates a checklist for any that haven't been reviewed today,
/// persists the review, and (optionally) notifies the user. Both the foreground
/// timer (app.dart) and the background workmanager task call [runDailyReview],
/// so this class must not depend on Riverpod / BuildContext.
class ReviewScheduler {
  ReviewScheduler({
    required StrategyService strategyService,
    required NotificationService notificationService,
  })  : _strategyService = strategyService,
        _notificationService = notificationService;

  final StrategyService _strategyService;
  final NotificationService _notificationService;

  bool _running = false;

  /// Run a daily review pass across all enabled strategies.
  ///
  /// Each strategy is reviewed at most once per calendar day (de-duplicated by
  /// comparing [Strategy.lastReviewAt] to today's date). Re-entrant calls are
  /// coalesced. A single strategy failing never aborts the batch.
  Future<void> runDailyReview() async {
    if (_running) return;
    _running = true;
    try {
      await _strategyService.init();
      final today = DateTime.now();
      final todayDate = _dateOnly(today);
      final strategies = _strategyService.getStrategies();
      final candidates =
          strategies.where((s) => s.isEnabled && _needsReviewToday(s, todayDate));

      var reviewed = 0;
      for (final strategy in candidates) {
        final ok = await _reviewOne(strategy);
        if (ok) reviewed++;
      }

      if (reviewed > 0) {
        // Notify the user that new reviews are available. Suppressed during
        // quiet hours (same window as alerts) to avoid late-night pings.
        await _notificationService.showAlert(
          id: _reviewNotificationId,
          title: '每日复盘已完成',
          body: '$reviewed 个策略已生成今日复盘，点击查看',
        );
      }
    } catch (e, st) {
      debugPrint('[ReviewScheduler] runDailyReview failed: $e\n$st');
    } finally {
      _running = false;
    }
  }

  Future<bool> _reviewOne(Strategy strategy) async {
    try {
      final result = await _strategyService.generateChecklistResult(strategy.id);
      await _strategyService.createReview(
        strategy.id,
        result.items,
        note: '系统每日自动复盘',
      );
      return true;
    } catch (e, st) {
      debugPrint(
        '[ReviewScheduler] review failed for strategy ${strategy.id}: $e\n$st',
      );
      return false;
    }
  }

  /// A strategy needs a review today if it has never been reviewed, or its
  /// last review was on a previous calendar day. Uses [lastReviewAt] (which
  /// createReview updates), falling back to createdAt for never-reviewed.
  bool _needsReviewToday(Strategy strategy, DateTime today) {
    final last = strategy.lastReviewAt ?? strategy.createdAt;
    return _dateOnly(last).isBefore(today);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Stable notification id for the daily-review summary.
  static const int _reviewNotificationId = 900001;
}
