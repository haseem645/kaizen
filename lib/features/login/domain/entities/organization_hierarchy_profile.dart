class OrganizationHierarchyProfile {
  const OrganizationHierarchyProfile({
    required this.name,
    required this.uuid,
    this.email,
    this.image,
    this.onboarded,
    this.userUuid,
  });

  final String name;
  final String uuid;
  final String? email;
  final String? image;
  final bool? onboarded;
  final String? userUuid;

  factory OrganizationHierarchyProfile.fromJson(Map<String, dynamic> json) {
    return OrganizationHierarchyProfile(
      name: json['name']?.toString().trim() ?? '',
      uuid: json['uuid']?.toString().trim() ?? '',
      email: _readNullableString(json['email']),
      image: _readNullableString(json['image']),
      onboarded: json['onboarded'] as bool?,
      userUuid: _readNullableString(json['user_uuid'] ?? json['userUuid']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uuid': uuid,
      'email': email,
      'image': image,
      'onboarded': onboarded,
      'user_uuid': userUuid,
    };
  }
}

String? _readNullableString(dynamic value) {
  final resolvedValue = value?.toString().trim();
  if (resolvedValue == null || resolvedValue.isEmpty) {
    return null;
  }

  return resolvedValue;
}
