import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Every repository error is one of these. UI shows [displayMessage],
/// which is already localized by failure_mapper.dart.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  const factory Failure.network({@Default('No internet connection.') String message}) =
      NetworkFailure;
  const factory Failure.server({required String message, int? statusCode}) = ServerFailure;
  const factory Failure.auth({required String message, String? code}) = AuthFailure;
  const factory Failure.permission({required String message}) = PermissionFailure;
  const factory Failure.cache({@Default('Local storage error.') String message}) = CacheFailure;
  const factory Failure.validation({required String message, Map<String, String>? fieldErrors}) =
      ValidationFailure;
  const factory Failure.unexpected({
    @Default('Something went wrong.') String message,
    Object? error,
    StackTrace? stackTrace,
  }) = UnexpectedFailure;

  String get displayMessage => switch (this) {
        NetworkFailure(:final message) => message,
        ServerFailure(:final message) => message,
        AuthFailure(:final message) => message,
        PermissionFailure(:final message) => message,
        CacheFailure(:final message) => message,
        ValidationFailure(:final message) => message,
        UnexpectedFailure(:final message) => message,
      };
}
