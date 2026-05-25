import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_state.freezed.dart';

/// The set of theme variants the user can pick from in Settings.
///
/// - [system] — follows the OS light/dark preference using the default
///   brand palette.
/// - [vibrant] — bold violet + gold brand look (the default).
/// - [professional] — muted slate + sky, quieter editorial look.
enum ThemeType { system, vibrant, professional }

@freezed
abstract class ThemeState with _$ThemeState {
  const factory ThemeState({required ThemeType themeType}) = _ThemeState;

  factory ThemeState.initial() =>
      const ThemeState(themeType: ThemeType.vibrant);
}
