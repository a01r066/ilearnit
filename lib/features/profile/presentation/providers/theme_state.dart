import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_state.freezed.dart';

enum ThemeType { system, light, dark }

@freezed
abstract class ThemeState with _$ThemeState {
  const factory ThemeState({
    required ThemeType themeType,
    required bool isDark,
  }) = _ThemeState;

  factory ThemeState.initial() => ThemeState(themeType: ThemeType.light, isDark: false);
}