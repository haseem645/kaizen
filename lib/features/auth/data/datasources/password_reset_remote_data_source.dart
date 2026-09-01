import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_processor.dart';

class PasswordResetRemoteDataSource {
  PasswordResetRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<void> requestPasswordReset({required String email}) {
    return _apiCallExecutor.processApi<void>(
      apiCallType: ApiCallType.post,
      endpoint: ApiEndPoints.passwordReset,
      parameters: {'email': email},
      authToken: '',
      allowAutoRefresh: false,
      decoder: (_) {},
    );
  }
}
