import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/presentation/notification_providers.dart';

/// Admin portal: browsers only allow the notification prompt from a user
/// gesture, so instead of prompting at startup we show this banner until
/// the admin decides. Hidden once permission is granted or denied.
class NotificationPermissionBanner extends ConsumerStatefulWidget {
  const NotificationPermissionBanner({super.key});

  @override
  ConsumerState<NotificationPermissionBanner> createState() =>
      _NotificationPermissionBannerState();
}

class _NotificationPermissionBannerState
    extends ConsumerState<NotificationPermissionBanner> {
  bool _dismissed = false;
  bool _busy = false;

  Future<void> _enable() async {
    setState(() => _busy = true);
    final status = await ref
        .read(notificationBootstrapProvider)
        .requestPermissionAndBind();
    if (!mounted) return;
    setState(() => _busy = false);
    if (status == AuthorizationStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications are blocked. Allow them in your browser\'s site settings.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final status = ref.watch(notificationPermissionProvider).value;
    if (status != AuthorizationStatus.notDetermined) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.notifications_active_outlined,
                color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Turn on notifications to get alerts for new instructor '
                'applications, course submissions and content reports.',
                style: TextStyle(color: scheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => setState(() => _dismissed = true),
              child: const Text('Not now'),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: _busy ? null : _enable,
              child: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }
}
