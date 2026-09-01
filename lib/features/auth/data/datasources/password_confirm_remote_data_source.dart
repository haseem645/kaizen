import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_processor.dart';

class PasswordConfirmRemoteDataSource {
  PasswordConfirmRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<void> confirmPassword({
    required String token,
    required String password,
    String? email,
  }) {
    return _apiCallExecutor.processApi<void>(
      apiCallType: ApiCallType.post,
      endpoint: ApiEndPoints.passwordConfirm,
      parameters: <String, dynamic>{
        'token': token,
        'email': email,
        'password': password,
      },
      authToken: '',
      allowAutoRefresh: false,
      decoder: (_) {},
    );
  }
}
