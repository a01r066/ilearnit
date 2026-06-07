import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../data/datasources/notification_preferences_datasource.dart';
import '../data/datasources/notifications_inbox_datasource.dart';
import '../data/models/notification_item_model.dart';
import 'notification_providers.dart';

// ---------- Datasources ---------------------------------------------------

final notificationsInboxDataSourceProvider =
    Provider<NotificationsInboxDataSource>(
  (ref) => NotificationsInboxDataSource(ref.watch(firestoreProvider)),
);

final notificationPreferencesDataSourceProvider =
    Provider<NotificationPreferencesDataSource>(
  (ref) => NotificationPreferencesDataSource(
    firestore: ref.watch(firestoreProvider),
    fcm: ref.watch(fcmServiceProvider),
  ),
);

// ---------- Inbox ---------------------------------------------------------

/// Live list of inbox items for the current user. Empty when signed out.
final notificationsInboxProvider =
    StreamProvider.autoDispose<List<NotificationItemModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref
      .watch(notificationsInboxDataSourceProvider)
      .watchInbox(userId: user.id);
});

/// Live unread count for the bell badge.
///
/// NOT autoDispose — the bell renders on Home + Songbooks and we don't
/// want the stream torn down on every tab switch.
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(0);
  return ref
      .watch(notificationsInboxDataSourceProvider)
      .watchUnreadCount(userId: user.id);
});

// ---------- Preferences ---------------------------------------------------

/// Live stream of the user's subscribed FCM topics.
final subscribedTopicsProvider =
    StreamProvider.autoDispose<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <String>{});
  return ref
      .watch(notificationPreferencesDataSourceProvider)
      .watchSubscribedTopics(userId: user.id);
});

/// Drives the SwitchListTiles on the preferences page. Owns the
/// busy/error state per-topic so a slow FCM round-trip can show a
/// loading state without blocking the entire screen.
class TopicTogglesState {
  const TopicTogglesState({
    this.busyTopics = const <String>{},
    this.lastErrorTopic,
  });

  final Set<String> busyTopics;
  final String? lastErrorTopic;

  TopicTogglesState copyWith({
    Set<String>? busyTopics,
    Object? lastErrorTopic = _unset,
  }) =>
      TopicTogglesState(
        busyTopics: busyTopics ?? this.busyTopics,
        lastErrorTopic: identical(lastErrorTopic, _unset)
            ? this.lastErrorTopic
            : lastErrorTopic as String?,
      );

  static const Object _unset = Object();
}

class TopicTogglesNotifier extends StateNotifier<TopicTogglesState> {
  TopicTogglesNotifier({
    required this.userId,
    required NotificationPreferencesDataSource datasource,
  })  : _datasource = datasource,
        super(const TopicTogglesState());

  final String userId;
  final NotificationPreferencesDataSource _datasource;

  Future<void> setSubscribed(String topic, bool subscribed) async {
    state = state.copyWith(
      busyTopics: {...state.busyTopics, topic},
      lastErrorTopic: null,
    );
    try {
      if (subscribed) {
        await _datasource.subscribe(userId: userId, topic: topic);
      } else {
        await _datasource.unsubscribe(userId: userId, topic: topic);
      }
      final next = {...state.busyTopics}..remove(topic);
      state = state.copyWith(busyTopics: next);
    } catch (_) {
      final next = {...state.busyTopics}..remove(topic);
      state = state.copyWith(
        busyTopics: next,
        lastErrorTopic: topic,
      );
    }
  }
}

final topicTogglesNotifierProvider = StateNotifierProvider.autoDispose<
    TopicTogglesNotifier, TopicTogglesState>(
  (ref) {
    final user = ref.watch(currentUserProvider);
    return TopicTogglesNotifier(
      userId: user?.id ?? '',
      datasource: ref.watch(notificationPreferencesDataSourceProvider),
    );
  },
);
