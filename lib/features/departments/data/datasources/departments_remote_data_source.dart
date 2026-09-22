import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_processor.dart';
import '../../../seat_profile/data/models/department_model.dart';
import '../../../seat_profile/domain/entities/department.dart';

class DepartmentsRemoteDataSource {
  DepartmentsRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<List<DepartmentModel>> getDepartments() {
    return _apiCallExecutor.processApi<List<DepartmentModel>>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.departments(),
      decoder: _decodeDepartments,
    );
  }

  Future<void> updateDepartment({
    required Department department,
    required String name,
    required String colorHex,
  }) {
    return _apiCallExecutor.processApi<void>(
      apiCallType: ApiCallType.put,
      endpoint: ApiEndPoints.departmentDetail(department.id),
      parameters: <String, dynamic>{
        'name': name,
        'color_hex': colorHex,
        if (department.fromSandbox != null)
          'from_sandbox': department.fromSandbox,
        if ((department.driveId ?? '').trim().isNotEmpty)
          'drive_id': department.driveId!.trim(),
      },
      decoder: (_) {},
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

  final items = json['all'] ?? json['results'] ?? json['departments'];
  if (items is! List) {
    throw const ApiError.invalidResponse();
  }

  return items
      .whereType<Map<String, dynamic>>()
      .map(DepartmentModel.fromApiJson)
      .toList(growable: false);
}

DepartmentsRemoteDataSource createDepartmentsRemoteDataSource() {
  return DepartmentsRemoteDataSource();
}
