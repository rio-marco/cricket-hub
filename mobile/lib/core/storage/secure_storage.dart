import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Service for persisting sensitive credentials and user state securely on device.
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage(this._storage);

  static const AndroidOptions defaultAndroidOptions = AndroidOptions();

  static const IOSOptions defaultIosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  /// Saves the primary JWT access token.
  Future<void> saveToken(String token) async {
    await _storage.write(
      key: AppConstants.tokenKey,
      value: token,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Retrieves the JWT access token.
  Future<String?> getToken() async {
    return await _storage.read(
      key: AppConstants.tokenKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Deletes the stored access token.
  Future<void> deleteToken() async {
    await _storage.delete(
      key: AppConstants.tokenKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Checks if a valid token exists.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Saves the refresh token.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: AppConstants.refreshTokenKey,
      value: token,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Retrieves the stored refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: AppConstants.refreshTokenKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Deletes the stored refresh token.
  Future<void> deleteRefreshToken() async {
    await _storage.delete(
      key: AppConstants.refreshTokenKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Saves serialized user JSON payload.
  Future<void> saveUser(String userJson) async {
    await _storage.write(
      key: AppConstants.userDataKey,
      value: userJson,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Retrieves serialized user JSON payload.
  Future<String?> getUser() async {
    return await _storage.read(
      key: AppConstants.userDataKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Deletes stored user payload.
  Future<void> deleteUser() async {
    await _storage.delete(
      key: AppConstants.userDataKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  Future<String?> getPushToken() async {
    return await _storage.read(
      key: AppConstants.pushTokenKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  Future<void> savePushToken(String token) async {
    await _storage.write(
      key: AppConstants.pushTokenKey,
      value: token,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  Future<void> deletePushToken() async {
    await _storage.delete(
      key: AppConstants.pushTokenKey,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  Future<String?> getString(String key) async {
    return await _storage.read(
      key: key,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  Future<void> saveString(String key, String value) async {
    await _storage.write(
      key: key,
      value: value,
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }

  /// Clears all keys in secure storage (logout / session cleanup).
  Future<void> clearAll() async {
    await _storage.deleteAll(
      aOptions: defaultAndroidOptions,
      iOptions: defaultIosOptions,
    );
  }
}

/// Base FlutterSecureStorage instance provider.
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: SecureStorage.defaultAndroidOptions,
    iOptions: SecureStorage.defaultIosOptions,
  );
});

/// Riverpod provider for SecureStorage wrapper service.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  final rawStorage = ref.watch(flutterSecureStorageProvider);
  return SecureStorage(rawStorage);
});
