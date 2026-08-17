class OrganizationHierarchyJob {
  const OrganizationHierarchyJob({
    required this.uuid,
    required this.title,
    this.paygradeUnit,
  });

  final String uuid;
  final String title;
  final String? paygradeUnit;

  factory OrganizationHierarchyJob.fromJson(Map<String, dynamic> json) {
    return OrganizationHierarchyJob(
      uuid: json['uuid']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      paygradeUnit: _readNullableString(
        json['paygrade_unit'] ?? json['paygradeUnit'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'uuid': uuid, 'title': title, 'paygrade_unit': paygradeUnit};
  }
}

String? _readNullableString(dynamic value) {
  final resolvedValue = value?.toString().trim();
  if (resolvedValue == null || resolvedValue.isEmpty) {
    return null;
  }

  return resolvedValue;
}
