import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/constants/api_constants.dart';

/// Initializes and wraps flutter_local_notifications.
///
/// The alert scheduling layer (AlertScheduler) talks only to this service, so
/// the rest of the app never imports the notifications plugin directly. This
/// keeps the platform-specific setup (channels, permissions, quiet hours) in a
/// single, testable boundary.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'stockpilot_alerts';
  static const String _channelName = '关注股提醒';
  static const String _channelDesc = '关注股票的下跌预警与价格提醒';

  bool _initialized = false;

  /// Pending tap payload from a notification that launched the app cold.
  /// Populated in [init] from `getNotificationAppLaunchDetails` and consumed
  /// once by [consumeLaunchPayload] after the router is ready.
  String? _launchPayload;
  bool _launchConsumed = false;

  /// Stream of payloads produced when the user taps a notification while the
  /// app is already running (hot tap). The app shell subscribes and routes.
  StreamController<String>? _tapController;
  StreamController<String> get _tap {
    // Lazily (re)created so the stream survives widget rebuilds / hot restart
    // and stays open for the lifetime of the singleton, not any one widget.
    // Closing it in dispose() would break later subscribers because the
    // NotificationService instance persists across widget lifecycles.
    _tapController ??= StreamController<String>.broadcast();
    return _tapController!;
  }

  Stream<String> get onTapPayload => _tap.stream;

  /// Take the cold-start payload once. Returns null if there was none or it
  /// has already been consumed.
  String? consumeLaunchPayload() {
    if (_launchConsumed) return null;
    _launchConsumed = true;
    return _launchPayload;
  }

  /// Android notification channel for downside/price alerts.
  AndroidNotificationChannel get _androidChannel =>
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      );

  /// Initialize the plugin, create the Android channel and request permission.
  /// Safe to call more than once; subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // DarwinInitializationSettings covers both iOS AND macOS (flutter_local_
    // notifications 18.x unified them). Passing the same instance to both
    // iOS and macOS is required — otherwise initialize() throws "macOS
    // settings must be set when targeting macOS platform" on desktop.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    // onDidReceiveNotificationResponse fires when the app is already running
    // (hot tap). The cold-start case is handled via launch details below.
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleTap,
    );

    // Cold start: the user tapped a notification that launched the app.
    // Capture its payload; app.dart consumes it once the router is mounted.
    // Wrapped in a timeout because some platforms' channel implementations
    // never return in test/headless environments, which would otherwise hang
    // initialization forever. 3s is plenty for a real launch.
    try {
      final details = await _plugin
          .getNotificationAppLaunchDetails()
          .timeout(const Duration(seconds: 3));
      if (details != null && details.didNotificationLaunchApp) {
        _launchPayload = details.notificationResponse?.payload;
      }
    } catch (e, st) {
      // Best-effort: some desktop platforms don't implement this. Falling
      // through just means cold-start taps behave like a normal app open.
      debugPrint('[NotificationService] launch details unavailable: $e\n$st');
    }

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }

    _initialized = true;
  }

  void _handleTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      // Guard against the (rare) case of the controller being closed between
      // subscription teardown and a late platform callback.
      final c = _tapController;
      if (c != null && !c.isClosed) {
        c.add(payload);
      }
    }
  }

  /// Request notification authorization. Returns whether it was granted.
  /// On Android < 13 permission is granted at install time so this returns true.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? true;
    }
    return false;
  }

  /// Whether the current wall-clock time falls inside the configured quiet
  /// window (default 22:00-08:00). Uses [AppConstants.alertQuietStartHour] /
  /// [AppConstants.alertQuietEndHour]. Quiet window wraps across midnight when
  /// start > end.
  bool isQuietHour([DateTime? at]) {
    final hour = (at ?? DateTime.now()).hour;
    final start = AppConstants.alertQuietStartHour;
    final end = AppConstants.alertQuietEndHour;
    if (start <= end) {
      return hour >= start && hour < end;
    }
    // Wraps midnight, e.g. 22 -> 8.
    return hour >= start || hour < end;
  }

  /// Show a downside/price alert notification. No-op during quiet hours.
  ///
  /// [id] should be a stable per-stock id so a re-trigger updates rather than
  /// stacks notifications. [payload] is an opaque string delivered back to the
  /// app when the user taps the notification (used for in-app deep-linking).
  /// Returns whether a notification was actually shown.
  Future<bool> showAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    if (isQuietHour()) {
      return false;
    }

    try {
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      return true;
    } catch (e, st) {
      debugPrint('[NotificationService] showAlert failed: $e\n$st');
      return false;
    }
  }
}
