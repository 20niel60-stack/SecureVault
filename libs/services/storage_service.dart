import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.authToken, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: StorageKeys.authToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.authToken);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: StorageKeys.biometricEnabled,
      value: enabled ? '1' : '0',
    );
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: StorageKeys.biometricEnabled);
    return v == '1';
  }

  Future<void> setHasPasswordLogin(bool value) async {
    await _storage.write(
      key: StorageKeys.hasPasswordLogin,
      value: value ? '1' : '0',
    );
  }

  Future<bool> hasPasswordLogin() async {
    final v = await _storage.read(key: StorageKeys.hasPasswordLogin);
    return v == '1';
  }

  // ✅ LOGOUT should clear SESSION only (token)
  Future<void> clearSession() async {
    await deleteToken();
    // NOTE: DO NOT reset biometricEnabled / hasPasswordLogin here
  }

  // ✅ OPTIONAL (if you want full reset button somewhere)
  Future<void> clearAll() async {
    await deleteToken();
    await setBiometricEnabled(false);
    await setHasPasswordLogin(false);
  }
}