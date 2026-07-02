import 'dart:convert';

class AuthUtils {
  const AuthUtils._();

  static String userIdFromEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized
        .replaceAll('@', '_at_')
        .replaceAll('.', '_dot_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
  }

  static String hashPassword(String password) {
    return base64Encode(utf8.encode(password.trim()));
  }
}
