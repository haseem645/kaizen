import '../../domain/entities/organization_hierarchy_profile.dart';

class OrganizationHierarchyProfileModel extends OrganizationHierarchyProfile {
  const OrganizationHierarchyProfileModel({
    required super.name,
    required super.uuid,
    super.email,
    super.image,
    super.onboarded,
    super.userUuid,
  });

  factory OrganizationHierarchyProfileModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return OrganizationHierarchyProfileModel(
      name: json['name']?.toString().trim() ?? '',
      uuid: json['uuid']?.toString().trim() ?? '',
      email: _readNullableString(json['email']),
      image: _readNullableString(json['image']),
      onboarded: json['onboarded'] as bool?,
      userUuid: _readNullableString(json['user_uuid'] ?? json['userUuid']),
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
