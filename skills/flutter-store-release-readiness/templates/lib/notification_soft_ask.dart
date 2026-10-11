import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Ask for notification permission IN CONTEXT, never at launch.
///
/// The OS prompt can be shown once; a cold "Allow notifications?" on first
/// launch is usually denied and App Review flags permission prompts
/// without context. Show this card where the value is obvious (end of
/// onboarding, after the first purchase, when enabling reminders) and only
/// call the OS prompt after the user taps "Turn on".
class NotificationSoftAsk extends StatelessWidget {
  const NotificationSoftAsk({super.key, required this.onDone});
  final VoidCallback onDone;

  static Future<bool> shouldShow() async {
    final s = await FirebaseMessaging.instance.getNotificationSettings();
    return s.authorizationStatus == AuthorizationStatus.notDetermined;
  }

  Future<void> _enable() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    // Register the token after permission (iOS); your FCM service should
    // also listen to onTokenRefresh and save tokens to users/{uid}.
    onDone();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.notifSoftAskTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(t.notifSoftAskBody),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDone, child: Text(t.notNow)),
                const SizedBox(width: 8),
                FilledButton(onPressed: _enable, child: Text(t.turnOn)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
