import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/landing_content.dart';

/// Editor state for the landing-page CMS form.
///
/// `original` is the last-saved snapshot; `draft` is what the form
/// currently shows. `isDirty` returns true when the two diverge so
/// the Save button can light up.
@immutable
class SiteContentFormState {
  const SiteContentFormState({
    required this.draft,
    required this.original,
    this.isSubmitting = false,
    this.justSaved = false,
    this.lastFailure,
  });

  factory SiteContentFormState.initial() {
    final fresh = LandingContent.initial();
    return SiteContentFormState(draft: fresh, original: fresh);
  }

  final LandingContent draft;
  final LandingContent original;
  final bool isSubmitting;
  final bool justSaved;
  final Failure? lastFailure;

  /// We compare by hash here — Freezed entities are deeply equal so
  /// any nested edit flips `isDirty`. Save is a no-op when not dirty.
  bool get isDirty => draft != original;

  bool get canSubmit => isDirty && !isSubmitting;

  SiteContentFormState copyWith({
    LandingContent? draft,
    LandingContent? original,
    bool? isSubmitting,
    bool? justSaved,
    Object? lastFailure = _unset,
  }) =>
      SiteContentFormState(
        draft: draft ?? this.draft,
        original: original ?? this.original,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        justSaved: justSaved ?? this.justSaved,
        lastFailure: identical(lastFailure, _unset)
            ? this.lastFailure
            : lastFailure as Failure?,
      );

  static const Object _unset = Object();
}
