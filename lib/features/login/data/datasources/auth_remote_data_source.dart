import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_processor.dart';
import '../../domain/entities/login_response.dart';
import '../../domain/entities/user.dart';

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

  Future<User> fetchUserDetail({required String accessToken}) {
    return _apiCallExecutor.processApi<User>(
      apiCallType: ApiCallType.get,
      endpoint: ApiEndPoints.userDetail,
      authToken: accessToken,
      decoder: (json) {
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
      },
    );
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
}
