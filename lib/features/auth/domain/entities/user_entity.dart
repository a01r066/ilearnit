import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

/// Pure domain user — no JSON, no Firebase types. UI binds to this.
@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    @Default(false) bool emailVerified,
    String? primaryInstrument, // e.g. 'guitar' | 'piano' | 'violin'
    DateTime? createdAt,
  }) = _UserEntity;
}
