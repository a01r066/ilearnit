import 'package:freezed_annotation/freezed_annotation.dart';

import 'notification_payload.dart';

part 'notification_item.freezed.dart';

/// A single notification rendered in the in-app inbox.
///
/// Persisted at `users/{uid}/notifications/{id}` by Cloud Functions in
/// parallel to the FCM send, so users who disable OS notifications still
/// see their account-related events when they open the app.
@freezed
abstract class NotificationItem with _$NotificationItem {
  const NotificationItem._();

  const factory NotificationItem({
    required String id,
    required NotificationType type,
    required String title,
    required String body,

    /// The same `data` payload that's attached to the FCM push, copied
    /// here so the in-app tap handler can deep-link to the same route.
    @Default(<String, String>{}) Map<String, String> payload,

    /// Null while unread; set to the server timestamp on read.
    DateTime? readAt,

    /// Server-side creation time. Drives the inbox sort.
    DateTime? createdAt,
  }) = _NotificationItem;

  bool get isUnread => readAt == null;

  /// Where tapping should route the user. Falls back to '/' so the UI can
  /// always pop the inbox cleanly.
  String get route => payload['route'] ?? '/';
}
