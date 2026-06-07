import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../utils/extensions.dart';
import '../../domain/notification_topics.dart';
import '../inbox_providers.dart';

/// Per-topic notification preferences page. Reachable from
/// `Settings → Notifications`.
///
/// We surface a curated subset of [NotificationTopics] — the `admins`
/// topic is server-managed and not user-toggleable.
class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  // Order is presentation-controlled (not enum order) so we can group
  // "All updates" above the instrument-specific toggles.
  static const _topicsByOrder = <String>[
    NotificationTopics.allUsers,
    NotificationTopics.instrumentGuitar,
    NotificationTopics.instrumentPiano,
    NotificationTopics.instrumentViolin,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final asyncSubscribed = ref.watch(subscribedTopicsProvider);
    final toggle = ref.watch(topicTogglesNotifierProvider);
    final notifier = ref.read(topicTogglesNotifierProvider.notifier);

    final subscribed = asyncSubscribed.value ?? const <String>{};

    ref.listen(topicTogglesNotifierProvider, (_, next) {
      if (next.lastErrorTopic != null) {
        context.showSnack(t.notificationsPrefsUpdateFailed);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(t.notificationsPrefsTitle)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              t.notificationsPrefsSubtitle,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          for (final topic in _topicsByOrder)
            SwitchListTile.adaptive(
              title: Text(_labelFor(topic, t)),
              subtitle: Text(_blurbFor(topic, t)),
              value: subscribed.contains(topic),
              onChanged: toggle.busyTopics.contains(topic)
                  ? null
                  : (next) => notifier.setSubscribed(topic, next),
              secondary: toggle.busyTopics.contains(topic)
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_iconFor(topic)),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(String topic) {
    switch (topic) {
      case NotificationTopics.allUsers:
        return Icons.campaign_outlined;
      case NotificationTopics.instrumentGuitar:
        return Icons.music_note_rounded;
      case NotificationTopics.instrumentPiano:
        return Icons.piano_rounded;
      case NotificationTopics.instrumentViolin:
        return Icons.queue_music_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _labelFor(String topic, AppLocalizations t) {
    switch (topic) {
      case NotificationTopics.allUsers:
        return t.notificationsPrefsTopicAll;
      case NotificationTopics.instrumentGuitar:
        return t.instrumentGuitar;
      case NotificationTopics.instrumentPiano:
        return t.instrumentPiano;
      case NotificationTopics.instrumentViolin:
        return t.instrumentViolin;
      default:
        return topic;
    }
  }

  String _blurbFor(String topic, AppLocalizations t) {
    switch (topic) {
      case NotificationTopics.allUsers:
        return t.notificationsPrefsTopicAllBlurb;
      case NotificationTopics.instrumentGuitar:
      case NotificationTopics.instrumentPiano:
      case NotificationTopics.instrumentViolin:
        return t.notificationsPrefsTopicInstrumentBlurb;
      default:
        return '';
    }
  }
}
