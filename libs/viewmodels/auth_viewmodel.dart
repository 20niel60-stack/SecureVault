import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  AuthViewModel({
    required AuthService authService,
    required StorageService storageService,
  })  : _authService = authService,
        _storageService = storageService;

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

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authService.registerWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      );

      final token = await _authService.getIdToken();
      if (token != null) {
        await _storageService.saveToken(token);
      }

      // Mark that password login exists (needed for biometrics constraint)
      await _storageService.setHasPasswordLogin(true);

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setError(null);
    _setLoading(true);
    try {
      await _authService.loginWithEmail(email: email, password: password);

      final token = await _authService.getIdToken();
      if (token != null) {
        await _storageService.saveToken(token);
      }

      await _storageService.setHasPasswordLogin(true);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setError(null);
    _setLoading(true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (cred == null) {
        _setError('Google sign-in cancelled.');
        return false;
      }

      final token = await _authService.getIdToken();
      if (token != null) {
        await _storageService.saveToken(token);
      }

      // Google sign-in is not "password login", but user is authenticated
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setError(null);
    _setLoading(true);
    try {
      await _authService.signOut();

      // clear session ONLY (token etc.)
      await _storageService.clearSession();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
}
}