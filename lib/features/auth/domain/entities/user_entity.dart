import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_role.dart';

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
    String? skillLevel, // 'beginner' | 'intermediate' | 'advanced'
    @Default(UserRole.student) UserRole role,
    @Default(false) bool isSuspended,
    /// Latest accepted EULA version. 0 = legacy / unaccepted →
    /// re-prompt before any UGC-creating action.
    @Default(0) int eulaAcceptedVersion,
    DateTime? createdAt,
  }) = _UserEntity;
}
