import 'package:freezed_annotation/freezed_annotation.dart';

part '__feature___state.freezed.dart';

/// Mutation state only — the list itself comes from a StreamProvider.
@freezed
abstract class __Feature__State with _$__Feature__State {
  const factory __Feature__State({
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = ___Feature__State;
}
