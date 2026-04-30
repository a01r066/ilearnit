import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// All domain-layer failures funneled through `Either<Failure, T>`.
///
/// Add new variants as new error categories appear; UI maps them via `.when`.
@freezed
sealed class Failure with _$Failure {
  const Failure._();

  /// Network unreachable / timeout / DNS / TLS.
  const factory Failure.network({
    @Default('No internet connection.') String message,
  }) = NetworkFailure;

  /// Server returned non-2xx (status code preserved for callers).
  const factory Failure.server({
    required String message,
    int? statusCode,
  }) = ServerFailure;

  /// Auth-specific (invalid credentials, expired session, etc).
  const factory Failure.auth({
    required String message,
    String? code,
  }) = AuthFailure;

  /// Local cache / secure storage / shared_preferences read-write errors.
  const factory Failure.cache({
    @Default('Local storage error.') String message,
  }) = CacheFailure;

  /// Validation errors raised before hitting the network.
  const factory Failure.validation({
    required String message,
    Map<String, String>? fieldErrors,
  }) = ValidationFailure;

  /// Last-resort bucket. Prefer specific failures.
  const factory Failure.unexpected({
    @Default('Something went wrong.') String message,
    Object? error,
    StackTrace? stackTrace,
  }) = UnexpectedFailure;

  /// User-facing message — safe to surface in UI as-is.
  String get displayMessage => when(
        network: (m) => m,
        server: (m, _) => m,
        auth: (m, _) => m,
        cache: (m) => m,
        validation: (m, _) => m,
        unexpected: (m, _, __) => m,
      );
}
