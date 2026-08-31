import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_processor.dart';
import '../models/training_library_page_model.dart';

class TrainingLibraryRemoteDataSource {
  TrainingLibraryRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<TrainingLibraryPageModel> getTrainingLibraryModules({
    required String view,
    required int page,
    int pageSize = 10,
    String searchType = 'category',
    String searchText = '',
    String? departmentId,
  }) {
    return _apiCallExecutor.processApi<TrainingLibraryPageModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.trainingModulesAll,
      parameters: <String, dynamic>{
        'view': view,
        'searchType': searchType,
        if (searchText.trim().isNotEmpty) 'searchText': searchText.trim(),
        if (departmentId?.trim().isNotEmpty ?? false)
          'department': departmentId!.trim(),
      },
      decoder: (json) {
        if (json is Map<String, dynamic>) {
          return TrainingLibraryPageModel.fromApiJson(json, pageSize: pageSize);
        }

        if (json is List) {
          return TrainingLibraryPageModel.fromLegacyList(
            json.whereType<Map<String, dynamic>>().toList(growable: false),
            pageSize: pageSize,
          );
        }

        if (json == null) {
          throw const ApiError.invalidResponse();
        }
        throw const ApiError.invalidResponse();
      },
    );
  }
}

TrainingLibraryRemoteDataSource createTrainingLibraryRemoteDataSource() {
  return TrainingLibraryRemoteDataSource();
}
