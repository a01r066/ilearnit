import 'package:flutter/material.dart';

import 'app_colors.dart';

/// A bundle of colors that fully describes a ThemeData variant.
///
/// One [ThemePalette] is consumed by [AppTheme] to produce a [ThemeData].
/// Add a new palette and a new factory in [AppTheme] to ship a new theme —
/// nothing else in the theme layer needs to change.
@immutable
class ThemePalette {
  const ThemePalette({
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
  });

  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color error;

  /// Vibrant — bold violet + warm gold. The default flagship look.
  static const ThemePalette vibrant = ThemePalette(
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.background,
    surface: AppColors.surface,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    error: AppColors.error,
  );

  /// Professional — muted slate + sky accent. Quiet, editorial.
  static const ThemePalette professional = ThemePalette(
    brightness: Brightness.light,
    primary: AppColors.professionalPrimary,
    secondary: AppColors.professionalAccent,
    background: AppColors.professionalBackground,
    surface: AppColors.professionalSurface,
    border: AppColors.professionalBorder,
    textPrimary: AppColors.professionalTextPrimary,
    textSecondary: AppColors.professionalTextSecondary,
    error: AppColors.error,
  );

  /// System light — same brand colors as Vibrant, used when the OS reports
  /// light mode.
  static const ThemePalette systemLight = vibrant;

  /// System dark — brand violet on dark neutrals, used when the OS reports
  /// dark mode.
  static const ThemePalette systemDark = ThemePalette(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    error: AppColors.error,
  );
}
