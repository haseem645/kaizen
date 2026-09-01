import '../../../../core/network/api_error.dart';
import '../../domain/entities/organization_hierarchy_node.dart';
import '../models/organization_hierarchy_job_model.dart';
import '../models/organization_hierarchy_profile_model.dart';

class OrganizationHierarchyNodeModel extends OrganizationHierarchyNode {
  const OrganizationHierarchyNodeModel({
    required super.uuid,
    required super.role,
    super.title,
    super.profile,
    super.job,
    super.children,
    super.colorHex,
    super.isPrimary,
    super.isEmployed,
    super.parentUuid,
    super.departmentUuid,
    super.isPaygradePending,
    super.paygradeAssignmentExists,
  });

  factory OrganizationHierarchyNodeModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    final jobJson = json['job'];
    final profileJson = json['profile'];
    final rawChildren = json['children'];

    return OrganizationHierarchyNodeModel(
      uuid: json['uuid']?.toString().trim() ?? '',
      role: json['role']?.toString().trim() ?? '',
      title: _readNullableString(json['title']),
      profile: profileJson is Map<String, dynamic>
          ? OrganizationHierarchyProfileModel.fromApiJson(profileJson)
          : null,
      job: jobJson is Map<String, dynamic>
          ? OrganizationHierarchyJobModel.fromApiJson(jobJson)
          : null,
      children: rawChildren is List
          ? rawChildren
                .whereType<Map<String, dynamic>>()
                .map(OrganizationHierarchyNodeModel.fromApiJson)
                .toList(growable: false)
          : const <OrganizationHierarchyNode>[],
      colorHex: _readNullableString(json['color_hex'] ?? json['colorHex']),
      isPrimary: json['is_primary'] == true || json['isPrimary'] == true,
      isEmployed: json['is_employed'] == true || json['isEmployed'] == true,
      parentUuid: _readNullableString(
        json['parent_uuid'] ?? json['parentUuid'],
      ),
      departmentUuid: _readNullableString(
        json['department_uuid'] ?? json['departmentUuid'],
      ),
      isPaygradePending:
          json['is_paygrade_pending'] == true ||
          json['isPaygradePending'] == true,
      paygradeAssignmentExists:
          json['paygrade_assignment_exists'] == true ||
          json['paygradeAssignmentExists'] == true,
    );
  }

  static List<OrganizationHierarchyNodeModel> listFromApiJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(OrganizationHierarchyNodeModel.fromApiJson)
          .toList(growable: false);
    }

    if (json is! Map<String, dynamic>) {
      throw const ApiError.invalidResponse();
    }

    final items =
        json['results'] ?? json['all'] ?? json['hierarchy'] ?? json['data'];
    if (items is! List) {
      throw const ApiError.invalidResponse();
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(OrganizationHierarchyNodeModel.fromApiJson)
        .toList(growable: false);
  }
}

String? _readNullableString(dynamic value) {
  final resolvedValue = value?.toString().trim();
  if (resolvedValue == null || resolvedValue.isEmpty) {
    return null;
  }

  return resolvedValue;
}
