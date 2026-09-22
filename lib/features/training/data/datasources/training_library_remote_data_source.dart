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
    String? jobId,
    String? jobCategoryId,
    String? jobCategoryDescriptionId,
  }) {
    return _apiCallExecutor.processApi<TrainingLibraryPageModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.trainingModulesAll,
      parameters: <String, dynamic>{
        if (jobId?.trim().isNotEmpty ?? false) 'job': jobId!.trim(),
        if (jobCategoryId?.trim().isNotEmpty ?? false)
          'job_category': jobCategoryId!.trim(),
        if (jobCategoryDescriptionId?.trim().isNotEmpty ?? false)
          'job_category_description': jobCategoryDescriptionId!.trim(),
        'page': page,
        'page_size': pageSize,
        'view': view,
        'searchType': searchType,
        if (departmentId?.trim().isNotEmpty ?? false)
          'department': departmentId!.trim(),
        if (searchText.trim().isNotEmpty) 'search': searchText.trim(),
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
