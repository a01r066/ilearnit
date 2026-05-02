import 'package:flutter_riverpod/legacy.dart';
import 'package:ilearnit/core/storage/prefs_service.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_state.dart';

class ThemeNotifier extends StateNotifier<ThemeState>{
  ThemeNotifier(this.prefsService,): super(ThemeState.initial()){
    _loadSavedTheme();
  }

  final PrefsService prefsService;

  // Load saved theme when initializing
  Future<void> _loadSavedTheme() async {
    final savedThemeTypeString = prefsService.themeMode;

    ThemeType themeType = ThemeType.light;
    if (savedThemeTypeString != null) {
      themeType = ThemeType.values.firstWhere(
            (type) => type.name == savedThemeTypeString,
        orElse: () => ThemeType.light,
      );
    }

    // log('themeType: ${themeType.name}');
    state = state.copyWith(
      themeType: themeType);
  }

  // Set theme type and save to shared preferences
  Future<void> setThemeMode(ThemeType themeType) async {
    await prefsService.setThemeMode(themeType.name);
    state = state.copyWith(themeType: themeType);
  }
}