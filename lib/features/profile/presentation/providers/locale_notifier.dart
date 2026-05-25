import 'package:flutter_riverpod/legacy.dart';
import 'package:ilearnit/core/storage/prefs_service.dart';
import 'package:ilearnit/features/profile/presentation/providers/locale_state.dart';

class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier(this.prefsService) : super(LocaleState.initial()) {
    _loadSavedLocale();
  }

  final PrefsService prefsService;

  Future<void> _loadSavedLocale() async {
    final saved = prefsService.locale;
    final language = AppLanguage.fromCode(saved);
    state = state.copyWith(language: language);
  }

  /// Switch to [language] and persist the choice.
  Future<void> setLanguage(AppLanguage language) async {
    if (state.language == language) return;
    await prefsService.setLocale(language.locale.languageCode);
    state = state.copyWith(language: language);
  }
}
