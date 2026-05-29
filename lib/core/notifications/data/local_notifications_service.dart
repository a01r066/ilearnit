import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/notification_payload.dart';

/// Thin wrapper around `flutter_local_notifications` used for two things:
///   1. Displaying an FCM message when the app is in the **foreground**
///      (FCM doesn't auto-display in that state on Android).
///   2. Emitting [taps] when a notification is tapped.
///
/// Background-state notifications (app suspended) are surfaced by the OS
/// itself from the FCM payload — we don't go through this service for those.
class LocalNotificationsService {
  LocalNotificationsService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<NotificationPayload> _taps =
      StreamController<NotificationPayload>.broadcast();

  /// Stream of payloads parsed from notification taps. The FcmService /
  /// notifier subscribes and forwards into go_router.
  Stream<NotificationPayload> get taps => _taps.stream;

  static const _androidChannelId = 'ilearnit_default';
  static const _androidChannelName = 'iLearnIt notifications';
  static const _androidChannelDesc =
      'Course updates, application status, and announcements.';

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      // We ask FCM for permission later, so don't double-prompt here.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Create the default Android channel up front so the first notification
    // doesn't get filed under "Misc".
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _androidChannelId,
            _androidChannelName,
            description: _androidChannelDesc,
            importance: Importance.high,
          ),
        );
  }

  /// Display a notification immediately. Use this from the FCM
  /// `onMessage` foreground handler.
  Future<void> show({
    required String title,
    required String body,
    required NotificationPayload payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(payload.toJson()),
    );
  }

  void _onTap(NotificationResponse resp) {
    final raw = resp.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _taps.add(NotificationPayload.fromData(map));
    } catch (_) {
      // Malformed payload — silently drop.
    }
  }

  Future<void> dispose() => _taps.close();
}
