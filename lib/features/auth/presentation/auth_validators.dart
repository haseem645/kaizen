import '../../../../core/constants/app_strings.dart';

class AuthValidators {
  const AuthValidators._();

  static String? validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return AppStrings.loginEnterEmail;
    }
    if (!email.contains('@')) {
      return AppStrings.loginEnterValidEmail;
    }
    return null;
  }

  static String? validateLoginPassword(String value) {
    final password = value.trim();
    if (password.isEmpty) {
      return AppStrings.loginEnterPassword;
    }
    if (password.length < 6) {
      return AppStrings.authPasswordMinLength;
    }
    return null;
  }

  static String? validateNewPassword(String value) {
    final password = value.trim();
    if (password.isEmpty) {
      return AppStrings.loginEnterPassword;
    }
    if (password.length < 8) {
      return AppStrings.authPasswordMinLength;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return AppStrings.authPasswordLetterRequired;
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return AppStrings.authPasswordNumberRequired;
    }
    return null;
  }

  static String? validatePasswordConfirmation({
    required String password,
    required String confirmation,
  }) {
    final confirmationRequirementError = validateNewPassword(confirmation);
    if (confirmationRequirementError != null) {
      return confirmationRequirementError;
    }

    final normalizedConfirmation = confirmation.trim();
    if (password.trim() != normalizedConfirmation) {
      return AppStrings.authPasswordsDoNotMatch;
    }
    return null;
  }
}
