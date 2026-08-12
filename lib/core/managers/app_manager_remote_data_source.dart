import '../network/api_endpoints.dart';
import '../network/api_error.dart';
import '../network/api_processor.dart';
import '../../features/login/data/datasources/auth_remote_data_source.dart';
import '../../features/login/domain/entities/user.dart';
import 'models/company_details.dart';

class AppManagerRemoteDataSource {
  AppManagerRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<User> fetchUserDetail({String? accessToken}) {
    return AuthRemoteDataSource(
      apiCallExecutor: _apiCallExecutor,
    ).fetchUserDetail(accessToken: accessToken?.trim() ?? '');
  }

  Future<CompanyDetails> fetchCompanyDetails({String? accessToken}) {
    return _apiCallExecutor.processApi<CompanyDetails>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.companyDetail,
      authToken: accessToken,
      invalidateCacheBeforeRequest: true,
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        return CompanyDetails.fromApiJson(json);
      },
    );
  }
}

AppManagerRemoteDataSource createAppManagerRemoteDataSource() {
  return AppManagerRemoteDataSource();
}
