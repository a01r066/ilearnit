import 'package:in_app_review/in_app_review.dart';

/// Thin wrapper around `in_app_review` so the rest of the codebase
/// doesn't depend on the plugin directly. Makes the notifier testable
/// with a fake — see `test/features/app_rating/`.
class AppRatingService {
  AppRatingService([InAppReview? client])
      : _client = client ?? InAppReview.instance;

  final InAppReview _client;

  /// Returns false on platforms that don't have a native rating sheet
  /// (web, desktop, older iOS). The notifier short-circuits in that
  /// case so we never appear to "prompt" without anything happening.
  Future<bool> isAvailable() => _client.isAvailable();

  /// Fire the native sheet. We get no callback — Apple and Google both
  /// hide the user's verdict by design. Treat success as "we asked".
  Future<void> requestReview() => _client.requestReview();
}
