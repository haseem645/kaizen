import 'organization_hierarchy_job.dart';
import 'organization_hierarchy_profile.dart';
import 'user_role_utils.dart';

class UserHierarchyMembership {
  const UserHierarchyMembership({
    required this.nodeUuid,
    required this.role,
    this.title,
    this.profile,
    this.job,
    this.colorHex,
    this.isPrimary = false,
    this.isEmployed = false,
    this.parentUuid,
    this.departmentUuid,
    this.isPaygradePending = false,
    this.paygradeAssignmentExists = false,
    this.manageableSeatProfileIds = const <String>[],
  });

  static const Set<String> _trainingManagerRoles = <String>{
    'owner',
    'csuite',
    'dept_lead',
    'team_lead',
  };
  static const Set<String> _departmentManagerRoles = <String>{
    'owner',
    'csuite',
    'dept_lead',
    'team_lead',
  };
  static const Set<String> _organizationWideTrainingManagerRoles = <String>{
    'owner',
    'csuite',
  };

  final String nodeUuid;
  final String role;
  final String? title;
  final OrganizationHierarchyProfile? profile;
  final OrganizationHierarchyJob? job;
  final String? colorHex;
  final bool isPrimary;
  final bool isEmployed;
  final String? parentUuid;
  final String? departmentUuid;
  final bool isPaygradePending;
  final bool paygradeAssignmentExists;
  final List<String> manageableSeatProfileIds;

  String get normalizedRole => normalizeUserRole(role);
  bool get canManageTrainingModules =>
      _trainingManagerRoles.contains(normalizedRole);
  bool get canManageSeatProfileDepartments =>
      _departmentManagerRoles.contains(normalizedRole);
  bool get hasOrganizationWideTrainingManagement =>
      _organizationWideTrainingManagerRoles.contains(normalizedRole);
  bool get hasManagedSeatProfiles => manageableSeatProfileIds.isNotEmpty;
  bool get hasDepartmentScope =>
      _normalizeIdentifier(departmentUuid).isNotEmpty;

  bool managesDepartment(String departmentId) {
    final normalizedDepartmentId = _normalizeIdentifier(departmentId);
    if (normalizedDepartmentId.isEmpty) {
      return false;
    }

    return _normalizeIdentifier(departmentUuid) == normalizedDepartmentId;
  }

  bool managesSeatProfile(String seatProfileId) {
    final normalizedSeatProfileId = _normalizeIdentifier(seatProfileId);
    if (normalizedSeatProfileId.isEmpty) {
      return false;
    }

    for (final manageableSeatProfileId in manageableSeatProfileIds) {
      if (_normalizeIdentifier(manageableSeatProfileId) ==
          normalizedSeatProfileId) {
        return true;
      }
    }

    return false;
  }

  factory UserHierarchyMembership.fromJson(Map<String, dynamic> json) {
    final profileJson = _readMap(json['profile']);
    final jobJson = _readMap(json['job']);

    return UserHierarchyMembership(
      nodeUuid: json['node_uuid']?.toString().trim() ?? '',
      role: json['role']?.toString().trim() ?? '',
      title: _readNullableString(json['title']),
      profile: profileJson == null
          ? null
          : OrganizationHierarchyProfile.fromJson(profileJson),
      job: jobJson == null ? null : OrganizationHierarchyJob.fromJson(jobJson),
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
      manageableSeatProfileIds: _parseStringList(
        json['manageable_seat_profile_ids'] ?? json['manageableSeatProfileIds'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'node_uuid': nodeUuid,
      'role': role,
      'title': title,
      'profile': profile?.toJson(),
      'job': job?.toJson(),
      'color_hex': colorHex,
      'is_primary': isPrimary,
      'is_employed': isEmployed,
      'parent_uuid': parentUuid,
      'department_uuid': departmentUuid,
      'is_paygrade_pending': isPaygradePending,
      'paygrade_assignment_exists': paygradeAssignmentExists,
      'manageable_seat_profile_ids': manageableSeatProfileIds,
    };
  }
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  return null;
}

String? _readNullableString(dynamic value) {
  final resolvedValue = value?.toString().trim();
  if (resolvedValue == null || resolvedValue.isEmpty) {
    return null;
  }

  return resolvedValue;
}

List<String> _parseStringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _normalizeIdentifier(String? value) {
  return value?.trim().toLowerCase() ?? '';
}
