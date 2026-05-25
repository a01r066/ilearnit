import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'locale_state.freezed.dart';

/// Supported app languages. The order here is the order they'll appear in
/// the language picker UI.
enum AppLanguage {
  en(Locale('en')),
  vi(Locale('vi'));

  const AppLanguage(this.locale);

  final Locale locale;

  /// Map a stored language code (or any Locale) back to an [AppLanguage].
  /// Falls back to [AppLanguage.en] when unknown.
  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.en;
    return AppLanguage.values.firstWhere(
      (l) => l.locale.languageCode == code,
      orElse: () => AppLanguage.en,
    );
  }
}

@freezed
abstract class LocaleState with _$LocaleState {
  const factory LocaleState({
    required AppLanguage language,
  }) = _LocaleState;

  factory LocaleState.initial() =>
      const LocaleState(language: AppLanguage.en);
}
