import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/providers.dart';
import 'alert_scheduler.dart';
import 'review_scheduler.dart';
import 'notification_service.dart';

/// workmanager task name registered for periodic background alert scans.
const String kAlertScanTaskName = 'stockpilot-alert-scan';

/// workmanager task name registered for periodic background daily reviews.
const String kDailyReviewTaskName = 'stockpilot-daily-review';

/// Top-level callback dispatcher invoked by workmanager from a background
/// isolate. Because this runs outside the main Riverpod scope, it builds its
/// own short-lived [ProviderContainer] and constructs an [AlertScheduler]
/// directly from the singleton services — mirroring the provider wiring but
/// without depending on the widget tree.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      switch (taskName) {
        case kAlertScanTaskName:
          await _runBackgroundScan();
          break;
        case kDailyReviewTaskName:
          await _runBackgroundReview();
          break;
        default:
          debugPrint('[Workmanager] unknown task: $taskName');
      }
    } catch (e, st) {
      debugPrint('[Workmanager] task $taskName failed: $e\n$st');
      // Returning false lets workmanager retry with backoff. We only retry on
      // unexpected failures; normal "no alert" runs return true below.
      return false;
    }
    return true;
  });
}

Future<void> _runBackgroundScan() async {
  // Initialize notifications first so any triggered alert can actually fire.
  await NotificationService.instance.init();

  final container = ProviderContainer();
  try {
    final scheduler = AlertScheduler(
      watchlistService: container.read(watchlistServiceProvider),
      apiService: container.read(stockApiServiceProvider),
      analysisEngine: container.read(analysisEngineProvider),
      notificationService: NotificationService.instance,
    );
    await scheduler.runScan();
  } finally {
    container.dispose();
  }
}

Future<void> _runBackgroundReview() async {
  // Initialize notifications so the "reviews ready" summary can fire.
  await NotificationService.instance.init();

  final container = ProviderContainer();
  try {
    final scheduler = ReviewScheduler(
      strategyService: container.read(strategyServiceProvider),
      notificationService: NotificationService.instance,
    );
    await scheduler.runDailyReview();
  } finally {
    container.dispose();
  }
}

/// Initialize workmanager and register the periodic background tasks
/// (alert scan + daily review).
///
/// Idempotent: safe to call on every app start; workmanager deduplicates the
/// registered tasks by name. iOS background execution is best-effort (the OS
/// decides when to wake the app), so the foreground timer in app.dart remains
/// the reliable path on iOS.
Future<void> initBackgroundAlerts() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    kAlertScanTaskName,
    kAlertScanTaskName,
    frequency: Duration(
      minutes: AppConstants.backgroundTaskIntervalMinutes,
    ),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    backoffPolicy: BackoffPolicy.exponential,
  );
  // Daily review: runs at the OS-discretion interval; ReviewScheduler itself
  // de-duplicates by calendar day so even frequent wakeups only review once.
  await Workmanager().registerPeriodicTask(
    kDailyReviewTaskName,
    kDailyReviewTaskName,
    frequency: const Duration(hours: 6),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
