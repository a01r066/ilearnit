import 'package:freezed_annotation/freezed_annotation.dart';

part '__entity__.freezed.dart';

/// Pure domain object — no Firestore / JSON types here.
@freezed
abstract class __Entity__ with _$__Entity__ {
  const factory __Entity__({
    required String id,
    required String ownerId,
    required String title,
    required DateTime createdAt,
  }) = ___Entity__;
}
