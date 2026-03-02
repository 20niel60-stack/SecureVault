class Validators {
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

  // Min 8 chars, 1 uppercase, 1 special char
  static final RegExp _strongPassRegex =
      RegExp(r'^(?=.*[A-Z])(?=.*[\W_]).{8,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Invalid email format';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (!_strongPassRegex.hasMatch(v)) {
      return 'Min 8 chars, 1 uppercase, 1 special char';
    }
    return null;
  }

  static String? confirmPassword(String? pass, String? confirm) {
    if ((confirm ?? '').isEmpty) return 'Confirm password is required';
    if (pass != confirm) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 2) return 'Name too short';
    return null;
  }
}