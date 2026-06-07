import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../features/auth/data/models/user_model.dart'
    show TimestampConverter;
import '../../domain/notification_item.dart';
import '../../domain/notification_payload.dart';

part 'notification_item_model.freezed.dart';
part 'notification_item_model.g.dart';

/// Firestore DTO for `users/{uid}/notifications/{id}`.
///
/// `type` is stored as the [NotificationType.id] string so docs are
/// stable across enum reorderings. Cloud Functions write the same
/// schema — see `functions/src/index.ts`.
@freezed
abstract class NotificationItemModel with _$NotificationItemModel {
  const NotificationItemModel._();

  const factory NotificationItemModel({
    required String id,
    @Default('unknown') String type,
    @Default('') String title,
    @Default('') String body,
    @Default(<String, String>{}) Map<String, String> payload,
    @TimestampConverter() DateTime? readAt,
    @TimestampConverter() DateTime? createdAt,
  }) = _NotificationItemModel;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationItemModelFromJson(json);

  factory NotificationItemModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    // Firestore returns nested maps as Map<String, dynamic>; cast the
    // payload entry to Map<String, String> defensively.
    final raw = data['payload'];
    final stringPayload = <String, String>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final v = entry.value;
        if (v == null) continue;
        stringPayload[entry.key.toString()] = v.toString();
      }
    }
    final merged = <String, dynamic>{
      ...data,
      'id': doc.id,
      'payload': stringPayload,
    };
    return NotificationItemModel.fromJson(merged);
  }

  NotificationItem toEntity() => NotificationItem(
        id: id,
        type: NotificationType.fromId(type),
        title: title,
        body: body,
        payload: payload,
        readAt: readAt,
        createdAt: createdAt,
      );
}
