import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_processor.dart';
import '../models/department_model.dart';
import '../models/seat_profile_detail_model.dart';
import '../models/seat_profile_page_model.dart';

class SeatProfileRemoteDataSource {
  SeatProfileRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<SeatProfilePageModel> getSeatProfiles({
    required int page,
    int pageSize = 10,
    String? departmentId,
  }) {
    return _apiCallExecutor.processApi<SeatProfilePageModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.jobs,
      parameters: {
        'page': page,
        'page_size': pageSize,
        if (departmentId != null && departmentId.trim().isNotEmpty)
          'department': departmentId,
      },
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        return SeatProfilePageModel.fromApiJson(json, pageSize: pageSize);
      },
    );
  }

  Future<List<DepartmentModel>> getDepartments() {
    return _apiCallExecutor.processApi<List<DepartmentModel>>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.departments(),
      decoder: _decodeDepartments,
    );
  }

  Future<SeatProfileDetailModel> getSeatProfileDetail(String seatId) {
    return _apiCallExecutor.processApi<SeatProfileDetailModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.seatProfileDetail(seatId),
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        return SeatProfileDetailModel.fromApiJson(json);
      },
    );
  }
}

List<DepartmentModel> _decodeDepartments(dynamic json) {
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(DepartmentModel.fromApiJson)
        .toList(growable: false);
  }

  if (json is! Map<String, dynamic>) {
    throw const ApiError.invalidResponse();
  }

  final items = json['all'];
  if (items is! List) {
    throw const ApiError.invalidResponse();
  }

  return items
      .whereType<Map<String, dynamic>>()
      .map(DepartmentModel.fromApiJson)
      .toList(growable: false);
}

SeatProfileRemoteDataSource createSeatProfileRemoteDataSource() {
  return SeatProfileRemoteDataSource();
}
