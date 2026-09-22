import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/managers/app_manager_remote_data_source.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';

import '../../../../core/constants/app_strings.dart';
import '../entities/app_user.dart';
import '../entities/login_exception.dart';
import '../entities/login_response.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Initializes the same app session for password and Google authentication.
class LoginSessionUseCase {
  const LoginSessionUseCase(
    this._authRepository, {
    Future<void> Function(String)? initializeWorkspace,
  }) : _initializeWorkspace = initializeWorkspace;

  final AuthRepository _authRepository;
  final Future<void> Function(String)? _initializeWorkspace;

  Future<AppUser> call(LoginResponse response, {String fallbackEmail = ''}) async {
    if (response.access.trim().isEmpty || response.refresh.trim().isEmpty) {
      throw const LoginException(AppStrings.loginInvalidUserData);
    }
    try {
      await AppPreference.clearUserSession();
      AppManager.instance.resetSessionState();
      await AppPreference.setAuthToken(response.access);
      await AppPreference.setRefreshToken(response.refresh);
      final profile = await _authRepository.fetchUserDetail(accessToken: response.access);
      final email = (profile.email ?? response.email ?? fallbackEmail).trim();
      final id = (profile.uuid ?? profile.userUuid ?? response.userId ?? email).trim();
      if (email.isEmpty || id.isEmpty) {
        throw const LoginException(AppStrings.loginInvalidUserData);
      }
      await _authRepository.saveUserProfile(profile);
      AppManager.instance.updateCurrentUser(profile);
      if (_initializeWorkspace != null) {
        await _initializeWorkspace(response.access);
      } else {
        await _fetchCompanyDetailsAfterUserDetails(response.access);
        await _fetchOrganizationsAfterLogin();
      }
      return AppUser(
        id: id,
        email: email,
        displayName: _resolveDisplayName(email: email, profile: profile),
      );
    } catch (_) {
      // Never leave a partial session behind if loading or persisting the profile fails.
      await AppPreference.clearUserSession();
      AppManager.instance.resetSessionState();
      rethrow;
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
