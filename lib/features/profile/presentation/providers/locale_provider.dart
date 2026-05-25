import 'package:flutter_riverpod/legacy.dart';
import 'package:ilearnit/features/profile/presentation/providers/locale_notifier.dart';
import 'package:ilearnit/features/profile/presentation/providers/locale_state.dart';
import 'package:ilearnit/shared/providers/storage_providers.dart';

/// State notifier provider for the app locale.
final localeStateNotifierProvider =
    StateNotifierProvider<LocaleNotifier, LocaleState>(
  (ref) => LocaleNotifier(ref.watch(prefsProvider)),
);
