import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Thin wrapper over `flutter_secure_storage` for tokens & sensitive data.
class SecureStorageService {
  SecureStorageService(this._storage);

  factory SecureStorageService.defaults() => SecureStorageService(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        ),
      );

  final FlutterSecureStorage _storage;

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: AppConstants.kAccessToken, value: token);

  Future<String?> readAccessToken() =>
      _storage.read(key: AppConstants.kAccessToken);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: AppConstants.kRefreshToken, value: token);

  Future<String?> readRefreshToken() =>
      _storage.read(key: AppConstants.kRefreshToken);

  Future<void> clearTokens() async {
    await _storage.delete(key: AppConstants.kAccessToken);
    await _storage.delete(key: AppConstants.kRefreshToken);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
