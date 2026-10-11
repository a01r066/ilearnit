import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/notification_payload.dart';
import '../../../l10n/l10n.dart';

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
  // Shown in Android's per-app notification settings; refreshed in the
  // current app language every time we post (see [_ensureChannel]).
  static String get _androidChannelName => L10n.current.notifChannelName;
  static String get _androidChannelDesc => L10n.current.notifChannelDesc;

  Future<void> init() async {
    // Monochrome status-bar icon (res/drawable/ic_notification.xml) — the
    // full-colour launcher icon renders as a white square.
    const android = AndroidInitializationSettings('@drawable/ic_notification');
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
    await _ensureChannel();
  }

  /// Creates the channel, or updates its user-visible name/description
  /// to the current app language (Android keeps id + importance).
  Future<void> _ensureChannel() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
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
    await _ensureChannel();
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF1A8C9C), // = @color/notification_color
        ),
        iOS: const DarwinNotificationDetails(
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
