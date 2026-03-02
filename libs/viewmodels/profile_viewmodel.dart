import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/storage_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;
  final BiometricService _biometricService;

  ProfileViewModel({
    required AuthService authService,
    required StorageService storageService,
    required BiometricService biometricService,
  })  : _authService = authService,
        _storageService = storageService,
        _biometricService = biometricService;

  UserModel? user;
  bool biometricEnabled = false;
  bool biometricSupported = false;

  bool isLoading = false;
  String? errorMessage;

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    errorMessage = msg;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _setError(null);
    _setLoading(true);
    try {
      final u = _authService.currentUser;
      if (u != null) {
        user = UserModel(uid: u.uid, displayName: u.displayName, email: u.email);
      }
      biometricEnabled = await _storageService.isBiometricEnabled();
      biometricSupported = await _biometricService.isSupported();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDisplayName(String newName) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authService.updateDisplayName(newName);

      // Refresh local model immediately (IMPORTANT: notifyListeners)
      final u = _authService.currentUser;
      if (u != null) {
        user = user?.copyWith(displayName: u.displayName) ??
            UserModel(uid: u.uid, displayName: u.displayName, email: u.email);
      }
      notifyListeners(); // constraint requirement
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle fingerprint login:
  /// Constraint: should only be allowed if user logged in with password at least once.
  Future<bool> setBiometricEnabled(bool enabled) async {
    _setError(null);

    final hasPassLogin = await _storageService.hasPasswordLogin();
    if (enabled && !hasPassLogin) {
      _setError('Biometric requires at least one password login first.');
      return false;
    }

    final supported = await _biometricService.isSupported();
    if (enabled && !supported) {
      _setError('Biometrics not supported on this device.');
      return false;
    }

    await _storageService.setBiometricEnabled(enabled);
    biometricEnabled = enabled;
    biometricSupported = supported;
    notifyListeners();
    return true;
  }

Future<bool> biometricUnlock() async {
  _setError(null);

  // Must be logged in already (session exists)
  final u = _authService.currentUser;
  if (u == null) {
    _setError('No user session. Please login with email/password first.');
    return false;
  }

  if (!biometricEnabled) return false;

  final ok = await _biometricService.authenticate();
  if (!ok) {
    _setError('Biometric authentication failed.');
    return false;
  }

  // After successful biometric auth, reload profile data
  await loadProfile();
  return true;
}
}