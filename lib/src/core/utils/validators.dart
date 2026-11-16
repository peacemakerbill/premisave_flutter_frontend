/// Form validators. Each returns an error message, or null when the value is fine.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    return _email.hasMatch(v.trim()) ? null : 'Enter a valid email address';
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) return 'Enter a valid phone number with country code';
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional, the server generates one
    return RegExp(r'^[a-zA-Z0-9_.-]{3,50}$').hasMatch(v.trim())
        ? null
        : '3 to 50 letters, digits, dots, underscores or hyphens';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? Function(String?) matches(String Function() other, [String message = 'Passwords do not match']) =>
      (v) => (v ?? '') == other() ? null : message;
}

/// 0 (empty) to 4 (strong). Advisory only; the server decides what is acceptable.
int passwordStrength(String v) {
  if (v.isEmpty) return 0;
  var score = 0;
  if (v.length >= 8) score++;
  if (v.length >= 12) score++;
  if (RegExp(r'[a-z]').hasMatch(v) && RegExp(r'[A-Z]').hasMatch(v)) score++;
  if (RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v)) score++;
  return score.clamp(1, 4);
}

String passwordStrengthLabel(int s) {
  switch (s) {
    case 0:
      return '';
    case 1:
      return 'Weak';
    case 2:
      return 'Fair';
    case 3:
      return 'Good';
    default:
      return 'Strong';
  }
}
