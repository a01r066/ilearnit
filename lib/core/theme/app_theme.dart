import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'theme_palette.dart';

/// Builds the [ThemeData] variants the app ships:
/// `vibrant`, `professional`, `systemLight`, `systemDark`.
///
/// Each public method is a thin wrapper around [_build] that injects a
/// different [ThemePalette]. All four themes share the same widget-level
/// styling (AppBar, Card, Inputs, Buttons, NavigationBar) so the only
/// difference between them is the color tokens.
class AppTheme {
  const AppTheme._();

  // ---------- Public theme factories ---------------------------------------

  /// Bold, music-forward look: violet primary + gold accent.
  static ThemeData vibrant() => _build(ThemePalette.vibrant);

  /// Quiet, editorial look: slate primary + sky accent.
  static ThemeData professional() => _build(ThemePalette.professional);

  /// Light theme used when the user picks "System" and the OS is in light mode.
  static ThemeData systemLight() => _build(ThemePalette.systemLight);

  /// Dark theme used when the user picks "System" and the OS is in dark mode.
  static ThemeData systemDark() => _build(ThemePalette.systemDark);

  // ---------- Builder -------------------------------------------------------

  static ThemeData _build(ThemePalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: p.brightness,
      primary: p.primary,
      secondary: p.secondary,
      surface: p.surface,
      error: p.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: _textTheme(p.textPrimary),
      appBarTheme: _appBarTheme(p),
      cardTheme: _cardTheme(p),
      inputDecorationTheme: _inputDecorationTheme(p),
      filledButtonTheme: _filledButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      navigationBarTheme: _navigationBarTheme(p),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ---------- Sub-theme builders -------------------------------------------

  static TextTheme _textTheme(Color bodyColor) => TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineLarge: AppTextStyles.headlineLarge,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.labelLarge,
        bodySmall: AppTextStyles.caption,
      ).apply(
        bodyColor: bodyColor,
        displayColor: bodyColor,
      );

  static AppBarTheme _appBarTheme(ThemePalette p) => AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
      );

  static CardThemeData _cardTheme(ThemePalette p) => CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme(ThemePalette p) =>
      InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(p.border),
        enabledBorder: _inputBorder(p.border),
        focusedBorder: _inputBorder(p.primary, width: 1.5),
        errorBorder: _inputBorder(p.error),
        focusedErrorBorder: _inputBorder(p.error, width: 1.5),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      );

  static NavigationBarThemeData _navigationBarTheme(ThemePalette p) =>
      NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll(AppTextStyles.caption),
        height: 64,
      );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
}
