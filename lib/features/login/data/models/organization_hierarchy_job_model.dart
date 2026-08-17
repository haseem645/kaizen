import '../../domain/entities/organization_hierarchy_job.dart';

class OrganizationHierarchyJobModel extends OrganizationHierarchyJob {
  const OrganizationHierarchyJobModel({
    required super.uuid,
    required super.title,
    super.paygradeUnit,
  });

  factory OrganizationHierarchyJobModel.fromApiJson(Map<String, dynamic> json) {
    return OrganizationHierarchyJobModel(
      uuid: json['uuid']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      paygradeUnit: _readNullableString(
        json['paygrade_unit'] ?? json['paygradeUnit'],
      ),
    );
  }
}

String? _readNullableString(dynamic value) {
  final resolvedValue = value?.toString().trim();
  if (resolvedValue == null || resolvedValue.isEmpty) {
    return null;
  }

  return resolvedValue;
}
