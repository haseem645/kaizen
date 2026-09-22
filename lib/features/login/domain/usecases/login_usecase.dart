import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_error.dart';
import '../entities/app_user.dart';
import '../entities/login_exception.dart';
import '../repositories/auth_repository.dart';
import 'login_session_usecase.dart';

export '../entities/login_exception.dart';

class LoginUseCase {
  const LoginUseCase(this._authRepository, {LoginSessionUseCase? session}) : _session = session;

  final AuthRepository _authRepository;
  final LoginSessionUseCase? _session;

  Future<AppUser> call({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty) {
      throw const LoginException(AppStrings.loginEnterEmail);
    }

    if (!normalizedEmail.contains('@')) {
      throw const LoginException(AppStrings.loginEnterValidEmail);
    }

    if (normalizedPassword.isEmpty) {
      throw const LoginException(AppStrings.loginEnterPassword);
    }

    if (normalizedPassword.length < 8) {
      throw const LoginException(AppStrings.authPasswordMinLength);
    }

    try {
      final loginResponse = await _authRepository.login(
        email: normalizedEmail,
        password: normalizedPassword,
      );

      return await (_session ?? LoginSessionUseCase(_authRepository))(
        loginResponse,
        fallbackEmail: normalizedEmail,
      );
    } on ApiError catch (error) {
      if (error.message == AppStrings.apiInvalidResponse) {
        throw const LoginException(AppStrings.loginInvalidUserData);
      }
      if (error.message == AppStrings.apiInvalidUrl) {
        throw const LoginException(AppStrings.loginServiceUnavailable);
      }

      final statusCode = error.statusCode;
      if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
        if (!error.message.startsWith(AppStrings.apiRequestFailedPrefix)) {
          throw LoginException(error.message);
        }

        throw const LoginException(AppStrings.loginIncorrectPassword);
      }

      if (statusCode == 404) {
        throw LoginException(
          error.message.startsWith(AppStrings.apiRequestFailedPrefix)
              ? AppStrings.loginNoAccount
              : error.message,
        );
      }

      if (statusCode == 0) {
        throw LoginException(error.message);
      }

      if (error.message.startsWith(AppStrings.apiRequestFailedPrefix)) {
        throw const LoginException(AppStrings.loginUnableToConnect);
      }

      throw LoginException(error.message);
    }
  }
}
