import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_error.dart';
import '../repositories/password_confirm_repository.dart';

class ConfirmPasswordResetUseCase {
  const ConfirmPasswordResetUseCase(this._repository);

  final PasswordConfirmRepository _repository;

  Future<void> call({
    required String token,
    required String password,
    String? email,
  }) async {
    final normalizedToken = token.trim();
    final normalizedPassword = password.trim();
    final normalizedEmail = email?.trim().toLowerCase();

    if (normalizedToken.isEmpty) {
      throw const SetPasswordException(AppStrings.authSetPasswordMissingToken);
    }

    if (normalizedEmail != null &&
        normalizedEmail.isNotEmpty &&
        !normalizedEmail.contains('@')) {
      throw const SetPasswordException(AppStrings.loginEnterValidEmail);
    }

    if (normalizedPassword.isEmpty) {
      throw const SetPasswordException(AppStrings.loginEnterPassword);
    }

    if (normalizedPassword.length < 8) {
      throw const SetPasswordException(AppStrings.authPasswordMinLength);
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(normalizedPassword)) {
      throw const SetPasswordException(AppStrings.authPasswordLetterRequired);
    }

    if (!RegExp(r'\d').hasMatch(normalizedPassword)) {
      throw const SetPasswordException(AppStrings.authPasswordNumberRequired);
    }

    try {
      await _repository.confirmPassword(
        token: normalizedToken,
        email: normalizedEmail == null || normalizedEmail.isEmpty
            ? null
            : normalizedEmail,
        password: normalizedPassword,
      );
    } on ApiError catch (error) {
      if (error.message == AppStrings.apiInvalidResponse) {
        throw const SetPasswordException(
          AppStrings.authSetPasswordUnableToUpdate,
        );
      }

      if (error.message == AppStrings.apiInvalidUrl) {
        throw const SetPasswordException(
          AppStrings.authSetPasswordServiceUnavailable,
        );
      }

      if (error.statusCode == 0) {
        throw SetPasswordException(error.message);
      }

      if (!error.message.startsWith(AppStrings.apiRequestFailedPrefix)) {
        throw SetPasswordException(error.message);
      }

      throw const SetPasswordException(
        AppStrings.authSetPasswordUnableToUpdate,
      );
    }
  }
}

class SetPasswordException implements Exception {
  const SetPasswordException(this.message);

  final String message;

  @override
  String toString() => message;
}
