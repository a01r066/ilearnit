import 'package:flutter_riverpod/legacy.dart';
import 'package:ilearnit/core/storage/prefs_service.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_state.dart';

/// Drives the active [ThemeState] and persists the user's choice in
/// [PrefsService].
///
/// On startup it loads the previously saved value. Legacy values from the
/// earlier `{system, light, dark}` enum are remapped:
///   - `"light"` → [ThemeType.vibrant]   (the new default light look)
///   - `"dark"`  → [ThemeType.system]    (closest match — picks up OS dark)
///   - `"system"` and unknown values  → [ThemeType.system] / vibrant.
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier(this.prefsService) : super(ThemeState.initial()) {
    _loadSavedTheme();
  }

  final PrefsService prefsService;

  Future<void> _loadSavedTheme() async {
    final saved = prefsService.themeMode;
    state = state.copyWith(themeType: _parseThemeType(saved));
  }

  /// Set the active theme and persist it.
  Future<void> setThemeType(ThemeType themeType) async {
    if (state.themeType == themeType) return;
    await prefsService.setThemeMode(themeType.name);
    state = state.copyWith(themeType: themeType);
  }

  /// Backwards-compatible alias for callers still using `setThemeMode`.
  @Deprecated('Use setThemeType instead')
  Future<void> setThemeMode(ThemeType themeType) => setThemeType(themeType);

  // ---------- helpers -----------------------------------------------------

  static ThemeType _parseThemeType(String? raw) {
    if (raw == null || raw.isEmpty) return ThemeType.vibrant;

    // First try a direct name match against the current enum.
    for (final t in ThemeType.values) {
      if (t.name == raw) return t;
    }

    // Then map legacy names from the previous {system, light, dark} enum.
    switch (raw) {
      case 'light':
        return ThemeType.vibrant;
      case 'dark':
        return ThemeType.system;
      default:
        return ThemeType.vibrant;
    }
  }
}
