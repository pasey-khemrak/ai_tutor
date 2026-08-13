class AuthValidators {
  const AuthValidators._();

  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your full name.';
    }
    if (trimmed.length < 2) {
      return 'Name is too short.';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Enter your email address.';
    }
    final hasValidShape = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(trimmed);
    if (!hasValidShape) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return 'Enter your password.';
    }
    if (raw.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }
}
