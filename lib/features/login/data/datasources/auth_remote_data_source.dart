import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_processor.dart';
import '../../../../core/preference/app_preference.dart';
import '../models/organization_hierarchy_node_model.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_hierarchy_membership.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) {
    return _apiCallExecutor.processApi<LoginResponse>(
      apiCallType: ApiCallType.post,
      endpoint: ApiEndPoints.login,
      parameters: {'email': email, 'password': password},
      allowAutoRefresh: false,
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        try {
          final access = (json['access'] as String?)?.trim();
          final refresh = (json['refresh'] as String?)?.trim();

          if (access == null ||
              access.isEmpty ||
              refresh == null ||
              refresh.isEmpty) {
            throw const ApiError.invalidResponse();
          }

          final userJson =
              _readMap(json['user']) ?? _readMap(json['data']) ?? json;

          return LoginResponse(
            refresh: refresh,
            access: access,
            userId: _readUserId(userJson),
            email:
                (userJson['email'] as String?)?.trim() ??
                (json['email'] as String?)?.trim(),
            displayName: _readDisplayName(userJson),
          );
        } on FormatException {
          throw const ApiError.invalidResponse();
        }
      },
    );
  }

  Future<User> fetchUserDetail({required String accessToken}) async {
    final user = await _apiCallExecutor.processApi<User>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.userDetail,
      authToken: accessToken,
      invalidateCacheBeforeRequest: true,
      decoder: (json) {
        return _decodeUserProfile(json);
      },
    );

    return _enrichUserWithHierarchy(accessToken: accessToken, user: user);
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  static String? _readUserId(Map<String, dynamic> json) {
    final dynamic id = json['id'] ?? json['user_id'] ?? json['uuid'];
    if (id == null) {
      return null;
    }

    final value = id.toString().trim();
    return value.isEmpty ? null : value;
  }

  static String? _readDisplayName(Map<String, dynamic> json) {
    final candidates = [
      json['display_name'],
      json['displayName'],
      json['full_name'],
      json['fullName'],
      json['name'],
      json['username'],
      [
        (json['first_name'] as String?)?.trim(),
        (json['last_name'] as String?)?.trim(),
      ].whereType<String>().where((value) => value.isNotEmpty).join(' '),
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Future<User> _enrichUserWithHierarchy({
    required String accessToken,
    required User user,
  }) async {
    final normalizedAccessToken = accessToken.trim();
    if (normalizedAccessToken.isEmpty) {
      return user;
    }

    try {
      final hierarchyMemberships = await _apiCallExecutor
          .processApi<List<UserHierarchyMembership>>(
            apiCallType: ApiCallType.get,
            endpoint: ApiEndPoints.organizationHierarchy,
            authToken: normalizedAccessToken,
            invalidateCacheBeforeRequest: true,
            parameters: const <String, dynamic>{'all_employees': 'True'},
            decoder: (json) =>
                _decodeHierarchyMemberships(json: json, user: user),
          );

      return user.copyWith(hierarchyMemberships: hierarchyMemberships);
    } catch (_) {
      final cachedUser = await AppPreference.getUser();
      if (!_representsSameUser(user, cachedUser)) {
        return user;
      }

      return user.copyWith(
        hierarchyMemberships:
            cachedUser?.hierarchyMemberships ??
            const <UserHierarchyMembership>[],
      );
    }
  }

  List<UserHierarchyMembership> _decodeHierarchyMemberships({
    required dynamic json,
    required User user,
  }) {
    final userIdentifiers = _resolveUserIdentifiers(user);
    if (userIdentifiers.isEmpty) {
      return const <UserHierarchyMembership>[];
    }

    final rootNodes = OrganizationHierarchyNodeModel.listFromApiJson(json);
    final memberships = <UserHierarchyMembership>[];
    final seenMembershipKeys = <String>{};

    for (final rootNode in rootNodes) {
      for (final membership in rootNode.collectMembershipsForUser(
        userIdentifiers,
      )) {
        final membershipKey = _membershipKey(membership);
        if (seenMembershipKeys.add(membershipKey)) {
          memberships.add(membership);
        }
      }
    }

    return List<UserHierarchyMembership>.unmodifiable(memberships);
  }

  Set<String> _resolveUserIdentifiers(User user) {
    return <String>{
      _normalizeIdentifier(user.userUuid),
      _normalizeIdentifier(user.uuid),
      _normalizeIdentifier(user.email),
    }..removeWhere((identifier) => identifier.isEmpty);
  }

  bool _representsSameUser(User user, User? cachedUser) {
    if (cachedUser == null) {
      return false;
    }

    final userIdentifiers = _resolveUserIdentifiers(user);
    if (userIdentifiers.isEmpty) {
      return false;
    }

    final cachedIdentifiers = _resolveUserIdentifiers(cachedUser);
    if (cachedIdentifiers.isEmpty) {
      return false;
    }

    return userIdentifiers.any(cachedIdentifiers.contains);
  }

  String _membershipKey(UserHierarchyMembership membership) {
    final nodeUuid = membership.nodeUuid.trim();
    if (nodeUuid.isNotEmpty) {
      return nodeUuid;
    }

    return [
      membership.departmentUuid?.trim() ?? '',
      membership.parentUuid?.trim() ?? '',
      membership.normalizedRole,
      membership.profile?.userUuid?.trim() ?? '',
      membership.profile?.uuid.trim() ?? '',
      membership.profile?.email?.trim().toLowerCase() ?? '',
    ].join('|');
  }

  static User _decodeUserProfile(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw const ApiError.invalidResponse();
    }

    final profile = json['profile'];
    if (profile is! Map<String, dynamic>) {
      throw const ApiError.invalidResponse();
    }

    try {
      return User.fromJson(profile);
    } on FormatException {
      throw const ApiError.invalidResponse();
    }
  }

  static String _normalizeIdentifier(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }
}
