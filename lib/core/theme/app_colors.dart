import 'package:flutter/material.dart';

/// Brand-level color tokens used directly by widgets across the app.
///
/// These are *constants*, intentionally not driven by the active theme. They
/// represent the iLearnIt brand (violet primary, gold accent), the instrument
/// category accents (guitar / piano / violin), and a fixed status palette
/// (success / warning / error / info).
///
/// Widgets that want to react to the active theme (Vibrant / Professional /
/// System light/dark) should pull colors from `Theme.of(context).colorScheme`
/// instead — those are sourced from [ThemePalette] in `theme_palette.dart`.
class AppColors {
  const AppColors._();

  // --- Brand ----------------------------------------------------------------
  static const Color primary = Color(0xFF6C5CE7); // deep violet
  static const Color primaryDark = Color(0xFF4C3FBA);
  static const Color accent = Color(0xFFE8B931); // warm gold

  // --- Instrument category accents -----------------------------------------
  static const Color guitar = Color(0xFFD2691E);
  static const Color piano = Color(0xFF1F2937);
  static const Color violin = Color(0xFFB22222);

  // --- Status ---------------------------------------------------------------
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // --- Neutrals (light) -----------------------------------------------------
  static const Color background = Color(0xFFF7F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // --- Neutrals (dark) ------------------------------------------------------
  static const Color darkBackground = Color(0xFF0E0F1A);
  static const Color darkSurface = Color(0xFF181A2C);
  static const Color darkBorder = Color(0xFF2A2D44);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA0A3B8);

  // --- Professional palette (used by [AppTheme.professional]) --------------
  static const Color professionalPrimary = Color(0xFF1E293B); // slate-800
  static const Color professionalAccent = Color(0xFF0EA5E9); // sky-500
  static const Color professionalBackground = Color(0xFFFAFAF9);
  static const Color professionalSurface = Color(0xFFFFFFFF);
  static const Color professionalBorder = Color(0xFFE2E8F0);
  static const Color professionalTextPrimary = Color(0xFF0F172A);
  static const Color professionalTextSecondary = Color(0xFF64748B);
}
