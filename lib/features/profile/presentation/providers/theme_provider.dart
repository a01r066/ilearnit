import 'package:flutter_riverpod/legacy.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_notifier.dart';
import 'package:ilearnit/features/profile/presentation/providers/theme_state.dart';
import 'package:ilearnit/shared/providers/storage_providers.dart';

// Create a state notifier provider for theme state
final themeStateNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) => ThemeNotifier(ref.watch(prefsProvider)));