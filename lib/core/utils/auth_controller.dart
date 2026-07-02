import '../network/api_endpoints.dart';
import '../network/api_error.dart';
import '../network/api_processor.dart';
import '../managers/app_manager.dart';
import '../preference/app_preference.dart';
import '../../routes/app_router.dart';

class AuthController {
  AuthController._();

  static final ApiCallExecutor _apiCallExecutor = const ApiCallExecutor();

  static Future<void> logout() async {
    await AppPreference.clearUserSession();
    AppManager.instance.resetSessionState();
    await AppRouter.resetToLogin();
  }

  static Future<String> requestRefreshToken() async {
    final refreshToken = AppPreference.getRefreshToken().trim();
    if (refreshToken.isEmpty) {
      await logout();
      throw const ApiError.invalidResponse();
    }

    try {
      final response = await _apiCallExecutor.processApi<Map<String, String>>(
        apiCallType: ApiCallType.post,
        endpoint: ApiEndPoints.refreshToken,
        parameters: {'refresh': refreshToken},
        allowAutoRefresh: false,
        decoder: (json) {
          if (json is! Map<String, dynamic>) {
            throw const ApiError.invalidResponse();
          }

          final access = json['access']?.toString().trim();
          final refresh = json['refresh']?.toString().trim();

          if (access == null ||
              access.isEmpty ||
              refresh == null ||
              refresh.isEmpty) {
            throw const ApiError.invalidResponse();
          }

          return <String, String>{'access': access, 'refresh': refresh};
        },
      );

      await AppPreference.clearTokens();
      await AppPreference.setAuthToken(response['access']!);
      await AppPreference.setRefreshToken(response['refresh']!);

      return response['access']!;
    } on ApiError catch (error) {
      if (error.statusCode == 400 || error.statusCode == 401) {
        await logout();
      }

      rethrow;
    }
  }
}
