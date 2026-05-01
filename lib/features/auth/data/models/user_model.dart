import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Firestore-backed DTO for the `users` collection.
@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    @Default(false) bool emailVerified,
    String? primaryInstrument,
    @TimestampConverter() DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  factory UserModel.fromFirebase(fb.User user) => UserModel(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        emailVerified: user.emailVerified,
        createdAt: user.metadata.creationTime,
      );

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel.fromJson({...data, 'id': doc.id});
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        emailVerified: emailVerified,
        primaryInstrument: primaryInstrument,
        createdAt: createdAt,
      );
}

/// Firestore Timestamp ↔ DateTime.
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    if (json is String) return DateTime.tryParse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return null;
  }

  @override
  Object? toJson(DateTime? object) =>
      object == null ? null : Timestamp.fromDate(object);
}
