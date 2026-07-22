import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_processor.dart';
import '../../../seat_profile/data/models/department_model.dart';
import '../models/paygrade_detail_model.dart';
import '../models/paygrade_page_model.dart';

class PaygradeRemoteDataSource {
  PaygradeRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<PaygradePageModel> getPaygrades({
    required int page,
    int pageSize = 10,
    String? departmentId,
    String title = '',
  }) {
    return _apiCallExecutor.processApi<PaygradePageModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.payGrade,
      parameters: {
        'department': departmentId ?? '',
        'title': title,
        'page': page,
        'page_size': pageSize,
      },
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        return PaygradePageModel.fromApiJson(json, pageSize: pageSize);
      },
    );
  }

  Future<List<DepartmentModel>> getDepartments() {
    return getDepartmentsByAccess(isOwner: true);
  }

  Future<List<DepartmentModel>> getDepartmentsByAccess({
    required bool isOwner,
  }) {
    return _apiCallExecutor.processApi<List<DepartmentModel>>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.departments(),
      decoder: (json) => _decodeDepartments(json, isOwner: isOwner),
    );
  }

  Future<PaygradeDetailModel> getPaygradeDetail({
    required String paygradeId,
    required String type,
  }) {
    return _apiCallExecutor.processApi<PaygradeDetailModel>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.payGradeDetail(paygradeId),
      parameters: {'type': type},
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        return PaygradeDetailModel.fromApiJson(json);
      },
    );
  }
}

List<DepartmentModel> _decodeDepartments(
  dynamic json, {
  required bool isOwner,
}) {
  if (json is List) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(DepartmentModel.fromApiJson)
        .toList(growable: false);
  }

  if (json is! Map<String, dynamic>) {
    throw const ApiError.invalidResponse();
  }

  final items = isOwner ? json['all'] : json['subordinate_departments'];
  if (items is! List) {
    throw const ApiError.invalidResponse();
  }

  return items
      .whereType<Map<String, dynamic>>()
      .map(DepartmentModel.fromApiJson)
      .toList(growable: false);
}

PaygradeRemoteDataSource createPaygradeRemoteDataSource() {
  return PaygradeRemoteDataSource();
}
