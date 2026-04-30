import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/prefs_service.dart';
import '../../core/storage/secure_storage_service.dart';

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => SecureStorageService.defaults(),
);

/// Override in `main_*.dart` after `PrefsService.create()` resolves.
final prefsProvider = Provider<PrefsService>(
  (_) => throw UnimplementedError(
    'prefsProvider was not initialized. '
    'Override it in ProviderScope.overrides during bootstrap.',
  ),
);
