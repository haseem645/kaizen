import 'user_hierarchy_membership.dart';

class User {
  final String? uuid;
  final String? status;
  final String? driveId;
  final bool? onboarded;
  final String? organizationUuid;
  final String? name;
  final String? email;
  final String? image;
  final String? gender;
  final Signature? signature;
  final String? userUuid;
  final String? imageUrl;
  final String? lastName;
  final String? firstName;
  final String? contactNo;
  final DateTime? dateJoined;
  final dynamic userProgress;
  final ProfileAddress? profileAddress;
  final bool? isEmailVerified;
  final dynamic envelope;
  final bool? isOwner;
  final DateTime? lastLogin;
  final bool? isIntegrator;
  final bool? isTopOperator;
  final List<String>? roles;
  final bool? isInActiveOrganization;
  final bool? hasSandboxAccess;
  final String? sandboxUuid;
  final String? feVersion;
  final bool? isPasswordReset;
  final String? companyUuid;
  final bool? hasPaymentDetailsProvided;
  final String? personalityType;
  final String? dateOfBirth;
  final List<UserHierarchyMembership>? hierarchyMemberships;

  List<String> get normalizedRoles =>
      _normalizeRoles(roles: roles, hierarchyMemberships: hierarchyMemberships);
  bool get hasOwnerOverrideAccess {
    final availableRoles = normalizedRoles.toSet();
    return isOwner == true || availableRoles.contains('owner');
  }

  bool get canManageAnyTrainingModules {
    if (hasOwnerOverrideAccess) {
      return true;
    }

    for (final membership
        in hierarchyMemberships ?? const <UserHierarchyMembership>[]) {
      if (membership.canManageTrainingModules) {
        return true;
      }
    }

    return false;
  }

  bool get canCreateSeatProfiles {
    final availableRoles = normalizedRoles.toSet();
    return hasOwnerOverrideAccess ||
        availableRoles.contains('csuite') ||
        availableRoles.contains('dept_lead') ||
        availableRoles.contains('team_lead');
  }

  bool get canAccessAuditTeamMembers {
    final availableRoles = normalizedRoles.toSet();
    return hasOwnerOverrideAccess ||
        availableRoles.contains('dept_lead') ||
        availableRoles.contains('supervisor') ||
        availableRoles.contains('team_lead');
  }

  bool get canAccessSandbox {
    return hasOwnerOverrideAccess || hasSandboxAccess == true;
  }

  bool occupiesSeatProfile(String seatProfileId) {
    final normalizedSeatProfileId = seatProfileId.trim();
    if (normalizedSeatProfileId.isEmpty) {
      return false;
    }

    for (final membership
        in hierarchyMemberships ?? const <UserHierarchyMembership>[]) {
      if (membership.job?.uuid.trim() == normalizedSeatProfileId) {
        return true;
      }
    }

    return false;
  }

  bool canManageTrainingForSeatProfile({required String seatProfileId}) {
    final normalizedSeatProfileId = seatProfileId.trim();
    if (normalizedSeatProfileId.isEmpty) {
      return false;
    }

    if (hasOwnerOverrideAccess) {
      return true;
    }

    if (occupiesSeatProfile(normalizedSeatProfileId)) {
      return false;
    }

    for (final membership
        in hierarchyMemberships ?? const <UserHierarchyMembership>[]) {
      if (!membership.canManageTrainingModules) {
        continue;
      }

      if (membership.manageableSeatProfileIds.contains(
        normalizedSeatProfileId,
      )) {
        return true;
      }
    }

    return false;
  }

  User({
    this.uuid,
    this.status,
    this.driveId,
    this.onboarded,
    this.organizationUuid,
    this.name,
    this.email,
    this.image,
    this.gender,
    this.signature,
    this.userUuid,
    this.imageUrl,
    this.lastName,
    this.firstName,
    this.contactNo,
    this.dateJoined,
    this.userProgress,
    this.profileAddress,
    this.isEmailVerified,
    this.envelope,
    this.isOwner,
    this.lastLogin,
    this.isIntegrator,
    this.isTopOperator,
    this.roles,
    this.isInActiveOrganization,
    this.hasSandboxAccess,
    this.sandboxUuid,
    this.feVersion,
    this.isPasswordReset,
    this.companyUuid,
    this.hasPaymentDetailsProvided,
    this.personalityType,
    this.dateOfBirth,
    this.hierarchyMemberships,
  });

  User copyWith({
    String? uuid,
    String? status,
    String? driveId,
    bool? onboarded,
    String? organizationUuid,
    String? name,
    String? email,
    String? image,
    String? gender,
    Signature? signature,
    String? userUuid,
    String? imageUrl,
    String? lastName,
    String? firstName,
    String? contactNo,
    DateTime? dateJoined,
    dynamic userProgress,
    ProfileAddress? profileAddress,
    bool? isEmailVerified,
    dynamic envelope,
    bool? isOwner,
    DateTime? lastLogin,
    bool? isIntegrator,
    bool? isTopOperator,
    List<String>? roles,
    bool? isInActiveOrganization,
    bool? hasSandboxAccess,
    String? sandboxUuid,
    String? feVersion,
    bool? isPasswordReset,
    String? companyUuid,
    bool? hasPaymentDetailsProvided,
    String? personalityType,
    String? dateOfBirth,
    List<UserHierarchyMembership>? hierarchyMemberships,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      status: status ?? this.status,
      driveId: driveId ?? this.driveId,
      onboarded: onboarded ?? this.onboarded,
      organizationUuid: organizationUuid ?? this.organizationUuid,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      gender: gender ?? this.gender,
      signature: signature ?? this.signature,
      userUuid: userUuid ?? this.userUuid,
      imageUrl: imageUrl ?? this.imageUrl,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      contactNo: contactNo ?? this.contactNo,
      dateJoined: dateJoined ?? this.dateJoined,
      userProgress: userProgress ?? this.userProgress,
      profileAddress: profileAddress ?? this.profileAddress,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      envelope: envelope ?? this.envelope,
      isOwner: isOwner ?? this.isOwner,
      lastLogin: lastLogin ?? this.lastLogin,
      isIntegrator: isIntegrator ?? this.isIntegrator,
      isTopOperator: isTopOperator ?? this.isTopOperator,
      roles: roles ?? this.roles,
      isInActiveOrganization:
          isInActiveOrganization ?? this.isInActiveOrganization,
      hasSandboxAccess: hasSandboxAccess ?? this.hasSandboxAccess,
      sandboxUuid: sandboxUuid ?? this.sandboxUuid,
      feVersion: feVersion ?? this.feVersion,
      isPasswordReset: isPasswordReset ?? this.isPasswordReset,
      companyUuid: companyUuid ?? this.companyUuid,
      hasPaymentDetailsProvided:
          hasPaymentDetailsProvided ?? this.hasPaymentDetailsProvided,
      personalityType: personalityType ?? this.personalityType,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      hierarchyMemberships: hierarchyMemberships ?? this.hierarchyMemberships,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'],
      status: json['status'],
      driveId: json['drive_id'],
      onboarded: json['onboarded'],
      organizationUuid: json['organization_uuid'],
      name: json['name'],
      email: json['email'],
      image: json['image'],
      gender: json['gender'],
      signature: json['signature'] != null
          ? Signature.fromJson(json['signature'])
          : null,
      userUuid: json['user_uuid'],
      imageUrl: json['image_url'],
      lastName: json['last_name'],
      firstName: json['first_name'],
      contactNo: json['contact_no'],
      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'])
          : null,
      userProgress: json['user_progress'],
      profileAddress: json['profile_address'] != null
          ? ProfileAddress.fromJson(json['profile_address'])
          : null,
      isEmailVerified: json['is_email_verified'],
      envelope: json['envelope'],
      isOwner: json['is_owner'],
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'])
          : null,
      isIntegrator: json['is_integrator'],
      isTopOperator: json['is_top_operator'],
      roles: _parseRoles(json['roles']),
      isInActiveOrganization: json['is_in_active_organization'],
      hasSandboxAccess: json['has_sandbox_access'] ?? json['hasSandboxAccess'],
      sandboxUuid: json['sandbox_uuid'],
      feVersion: json['fe_version'],
      isPasswordReset: json['is_password_reset'],
      companyUuid: json['company_uuid'],
      hasPaymentDetailsProvided: json['has_payment_details_provided'],
      personalityType: _readPersonalityType(json),
      dateOfBirth: _readDateOfBirth(json),
      hierarchyMemberships: _parseHierarchyMemberships(
        json['hierarchy_memberships'] ?? json['hierarchyMemberships'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'status': status,
      'drive_id': driveId,
      'onboarded': onboarded,
      'organization_uuid': organizationUuid,
      'name': name,
      'email': email,
      'image': image,
      'gender': gender,
      'signature': signature?.toJson(),
      'user_uuid': userUuid,
      'image_url': imageUrl,
      'last_name': lastName,
      'first_name': firstName,
      'contact_no': contactNo,
      'date_joined': dateJoined?.toIso8601String(),
      'user_progress': userProgress,
      'profile_address': profileAddress?.toJson(),
      'is_email_verified': isEmailVerified,
      'envelope': envelope,
      'is_owner': isOwner,
      'last_login': lastLogin?.toIso8601String(),
      'is_integrator': isIntegrator,
      'is_top_operator': isTopOperator,
      'roles': roles,
      'is_in_active_organization': isInActiveOrganization,
      'has_sandbox_access': hasSandboxAccess,
      'sandbox_uuid': sandboxUuid,
      'fe_version': feVersion,
      'is_password_reset': isPasswordReset,
      'company_uuid': companyUuid,
      'has_payment_details_provided': hasPaymentDetailsProvided,
      'personality_type': personalityType,
      'date_of_birth': dateOfBirth,
      'hierarchy_memberships': hierarchyMemberships
          ?.map((membership) => membership.toJson())
          .toList(growable: false),
    };
  }

  static String? _readPersonalityType(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['personalityType'],
      json['personality_type'],
      _readMap(json['personality'])?['personalityType'],
      _readMap(json['personality'])?['personality_type'],
      _readMap(json['envelope'])?['personalityType'],
      _readMap(json['envelope'])?['personality_type'],
      _readMap(json['user_progress'])?['personalityType'],
      _readMap(json['user_progress'])?['personality_type'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static String? _readDateOfBirth(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['dateOfBirth'],
      json['date_of_birth'],
      _readMap(json['envelope'])?['dateOfBirth'],
      _readMap(json['envelope'])?['date_of_birth'],
      _readMap(json['user_progress'])?['dateOfBirth'],
      _readMap(json['user_progress'])?['date_of_birth'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  static List<String>? _parseRoles(dynamic rawRoles) {
    if (rawRoles == null) {
      return null;
    }

    if (rawRoles is List) {
      final roles = rawRoles
          .map((role) => role?.toString().trim() ?? '')
          .where((role) => role.isNotEmpty)
          .toList(growable: false);
      return roles;
    }

    if (rawRoles is Map) {
      final roles = <String>[];

      rawRoles.forEach((key, value) {
        final normalizedKey = key.toString().trim();
        if (normalizedKey.isEmpty) {
          return;
        }

        if (value == null || value == false) {
          return;
        }

        roles.add(normalizedKey);
      });

      return roles;
    }

    return null;
  }

  static List<UserHierarchyMembership>? _parseHierarchyMemberships(
    dynamic rawMemberships,
  ) {
    if (rawMemberships is! List) {
      return null;
    }

    return rawMemberships
        .whereType<Map<String, dynamic>>()
        .map(UserHierarchyMembership.fromJson)
        .toList(growable: false);
  }

  static List<String> _normalizeRoles({
    List<String>? roles,
    List<UserHierarchyMembership>? hierarchyMemberships,
  }) {
    final normalizedRoles = <String>[];
    final seenRoles = <String>{};

    void addRole(String? rawRole) {
      final normalizedRole = rawRole?.trim().toLowerCase() ?? '';
      if (normalizedRole.isEmpty || !seenRoles.add(normalizedRole)) {
        return;
      }

      normalizedRoles.add(normalizedRole);
    }

    for (final role in roles ?? const <String>[]) {
      addRole(role);
    }

    for (final membership
        in hierarchyMemberships ?? const <UserHierarchyMembership>[]) {
      addRole(membership.role);
    }

    return List<String>.unmodifiable(normalizedRoles);
  }
}

class Signature {
  final String? uuid;
  final String? image;

  Signature({this.uuid, this.image});

  factory Signature.fromJson(Map<String, dynamic> json) {
    return Signature(uuid: json['uuid'], image: json['image']);
  }

  Map<String, dynamic> toJson() => {'uuid': uuid, 'image': image};
}

class ProfileAddress {
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;

  ProfileAddress({
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
  });

  factory ProfileAddress.fromJson(Map<String, dynamic> json) {
    return ProfileAddress(
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      zipCode: json['zip_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
    };
  }
}
