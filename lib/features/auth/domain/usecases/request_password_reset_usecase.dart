import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_error.dart';
import '../repositories/password_reset_repository.dart';

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase(this._repository);

  final PasswordResetRepository _repository;

  Future<void> call({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw const PasswordResetException(AppStrings.loginEnterEmail);
    }

    if (!normalizedEmail.contains('@')) {
      throw const PasswordResetException(AppStrings.loginEnterValidEmail);
    }

    try {
      await _repository.requestPasswordReset(email: normalizedEmail);
    } on ApiError catch (error) {
      if (error.message == AppStrings.apiInvalidResponse) {
        throw const PasswordResetException(
          AppStrings.authResetLinkUnableToSend,
        );
      }

      if (error.message == AppStrings.apiInvalidUrl) {
        throw const PasswordResetException(
          AppStrings.authResetLinkServiceUnavailable,
        );
      }

      if (error.statusCode == 0) {
        throw PasswordResetException(error.message);
      }

      if (!error.message.startsWith(AppStrings.apiRequestFailedPrefix)) {
        throw PasswordResetException(error.message);
      }

      throw const PasswordResetException(AppStrings.authResetLinkUnableToSend);
    }
  }
}

class PasswordResetException implements Exception {
  const PasswordResetException(this.message);

  final String message;

  @override
  String toString() => message;
}
