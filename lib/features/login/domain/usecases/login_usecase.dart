import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/managers/app_manager_remote_data_source.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_error.dart';
import '../entities/app_user.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

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

      if (loginResponse.access.isEmpty) {
        throw const LoginException(AppStrings.loginInvalidUserData);
      }

      AppManager.instance.resetBillingBannerDismissal();
      await AppPreference.setAuthToken(loginResponse.access);
      await AppPreference.setRefreshToken(loginResponse.refresh);
      await AppPreference.clearOnboardingSession();
      await AppPreference.clearUser();
      await AppPreference.clearSelectedOrganizationId();
      AppManager.instance.updateCurrentUser(null);

      final userProfile = await _authRepository.fetchUserDetail(accessToken: loginResponse.access);

      await _authRepository.saveUserProfile(userProfile);
      AppManager.instance.updateCurrentUser(userProfile);
      await _fetchCompanyDetailsAfterUserDetails(loginResponse.access);
      await _fetchOrganizationsAfterLogin();

      final displayName = _resolveDisplayName(email: normalizedEmail, profile: userProfile);

      return AppUser(
        id: userProfile.uuid ?? userProfile.userUuid ?? normalizedEmail,
        email: userProfile.email ?? normalizedEmail,
        displayName: displayName,
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

  String _resolveDisplayName({required String email, required User profile}) {
    final candidates = [
      profile.name,
      [
        profile.firstName?.trim(),
        profile.lastName?.trim(),
      ].whereType<String>().where((value) => value.isNotEmpty).join(' '),
    ];

    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'User';
    }

    return localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Future<void> _fetchOrganizationsAfterLogin() async {
    try {
      await AppManager.instance.fetchOrganizations(forceRefresh: true);
    } catch (_) {
      // Keep login resilient if organizations cannot be fetched right now.
    }
  }

  Future<void> _fetchCompanyDetailsAfterUserDetails(String accessToken) async {
    try {
      final companyDetails = await AppManagerRemoteDataSource().fetchCompanyDetails(
        accessToken: accessToken,
      );
      await AppPreference.saveActiveCompany(companyDetails);
      AppManager.instance.saveActiveCompany(companyDetails);
    } catch (_) {
      // Keep login resilient if company details cannot be fetched right now.
    }
  }
}

class LoginException implements Exception {
  const LoginException(this.message);

  final String message;

  @override
  String toString() => message;
}
