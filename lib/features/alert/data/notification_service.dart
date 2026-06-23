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
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }

    _initialized = true;
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
  /// stacks notifications. Returns whether a notification was actually shown.
  Future<bool> showAlert({
    required int id,
    required String title,
    required String body,
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
      );
      return true;
    } catch (e, st) {
      debugPrint('[NotificationService] showAlert failed: $e\n$st');
      return false;
    }
  }
}
