import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/storage_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/services/app_rating_service.dart';
import 'app_rating_notifier.dart';

/// Singleton wrapper around the `in_app_review` plugin.
final appRatingServiceProvider = Provider<AppRatingService>(
  (_) => AppRatingService(),
);

/// Long-lived notifier. Read once from the lecture progress notifier
/// (and any other "natural moment" trigger). The notifier holds no
/// reactive state — it just orchestrates gating + the plugin call.
final appRatingNotifierProvider = Provider<AppRatingNotifier>(
  (ref) => AppRatingNotifier(
    prefs: ref.watch(prefsProvider),
    service: ref.watch(appRatingServiceProvider),
    authRepo: ref.watch(authRepositoryProvider),
  ),
);
