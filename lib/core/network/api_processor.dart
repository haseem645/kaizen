import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/network/api_endpoints.dart';
import 'package:sparrowkaizen/core/network/api_error.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/core/utils/auth_controller.dart';

class ApiCallExecutor {
  const ApiCallExecutor();

  static const Duration _getCacheTtl = Duration(seconds: 30);
  static final Map<String, _CachedHttpResponse> _getCache =
      <String, _CachedHttpResponse>{};

  Future<Response> processApi<Response>({
    required ApiCallType apiCallType,
    required String endpoint,
    required Response Function(dynamic json) decoder,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    String? authToken,
    bool allowAutoRefresh = true,
    bool invalidateCacheBeforeRequest = false,
  }) async {
    final resolvedAuthToken =
        authToken ??
        (endpoint == ApiEndPoints.login ? null : AppPreference.getAuthToken());
    final cacheKey = _buildCacheKey(
      apiCallType: apiCallType,
      endpoint: endpoint,
      parameters: parameters,
      authToken: resolvedAuthToken,
    );

    if (apiCallType == ApiCallType.get &&
        invalidateCacheBeforeRequest &&
        cacheKey != null) {
      _invalidateGetCacheEntry(cacheKey);
    }

    http.Response? response;
    if (apiCallType == ApiCallType.get && cacheKey != null) {
      response = _readCachedGetResponse(cacheKey);
    }

    response ??= await _sendRequest(
      apiCallType: apiCallType,
      endpoint: endpoint,
      parameters: parameters,
      headers: headers,
      authToken: resolvedAuthToken,
    );

    final statusCode = response.statusCode;
    final fullEndpoint =
        '${ApiEndPoints.baseUrl}${ApiEndPoints.version}$endpoint';
    debugPrint('Call $fullEndpoint $statusCode');

    if (statusCode == 401 &&
        allowAutoRefresh &&
        endpoint != ApiEndPoints.refreshToken) {
      final refreshedAccessToken = await AuthController.requestRefreshToken();
      debugPrint('Retrying $fullEndpoint after token refresh');
      return processApi<Response>(
        apiCallType: apiCallType,
        endpoint: endpoint,
        authToken: refreshedAccessToken,
        parameters: parameters,
        headers: headers,
        allowAutoRefresh: false,
        invalidateCacheBeforeRequest: invalidateCacheBeforeRequest,
        decoder: decoder,
      );
    }

    final retriedStatusCode = response.statusCode;

    if (retriedStatusCode == 409) {
      AppManager.instance.handleConflict409();
    }

    if (retriedStatusCode < 200 || retriedStatusCode > 299) {
      throw ApiError.requestFailed(
        retriedStatusCode,
        message:
            _extractErrorMessage(response.body) ??
            AppStrings.apiRequestFailed(retriedStatusCode),
      );
    }

    if (apiCallType == ApiCallType.get && cacheKey != null) {
      _storeCachedGetResponse(cacheKey, response);
    } else if (apiCallType != ApiCallType.get) {
      _invalidateGetCache();
    }

    final dynamic decodedJson = response.body.isEmpty
        ? null
        : jsonDecode(response.body);

    return decoder(decodedJson);
  }

  Future<http.Response> _sendRequest({
    required ApiCallType apiCallType,
    required String endpoint,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    String? authToken,
  }) async {
    final fullEndpoint =
        '${ApiEndPoints.baseUrl}${ApiEndPoints.version}$endpoint';

    Uri uri;
    try {
      uri = Uri.parse(fullEndpoint);
    } catch (_) {
      throw const ApiError.invalidUrl();
    }

    if (apiCallType == ApiCallType.get &&
        parameters != null &&
        parameters.isNotEmpty) {
      uri = buildUriWithQueryParameters(uri: uri, parameters: parameters);
    }

    final resolvedHeaders = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authToken != null && authToken.isNotEmpty) {
      resolvedHeaders['Authorization'] = 'Bearer $authToken';
    }

    if (headers != null && headers.isNotEmpty) {
      resolvedHeaders.addAll(headers);
    }

    final request = http.Request(apiCallType.value, uri);
    request.headers.addAll(resolvedHeaders);

    if (apiCallType != ApiCallType.get && parameters != null) {
      request.body = jsonEncode(parameters);
    }

    try {
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } on SocketException {
      throw ApiError.requestFailed(0, message: 'Unable to connect to server.');
    } on HttpException {
      throw ApiError.requestFailed(0, message: 'Unable to connect to server.');
    }
  }

  Uri buildUriWithQueryParameters({
    required Uri uri,
    required Map<String, dynamic> parameters,
  }) {
    final queryParameters = parameters.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return uri.replace(
      queryParameters: {...uri.queryParameters, ...queryParameters},
    );
  }

  String? _buildCacheKey({
    required ApiCallType apiCallType,
    required String endpoint,
    Map<String, dynamic>? parameters,
    String? authToken,
  }) {
    if (apiCallType != ApiCallType.get) {
      return null;
    }

    final baseUri = Uri.parse(
      '${ApiEndPoints.baseUrl}${ApiEndPoints.version}$endpoint',
    );
    final resolvedUri = parameters == null || parameters.isEmpty
        ? baseUri
        : buildUriWithQueryParameters(uri: baseUri, parameters: parameters);

    return ' ::${resolvedUri.toString()}';
  }

  http.Response? _readCachedGetResponse(String cacheKey) {
    final cachedResponse = _getCache[cacheKey];
    if (cachedResponse == null) {
      debugPrint('GET cache MISS $cacheKey');
      return null;
    }

    if (DateTime.now().difference(cachedResponse.createdAt) > _getCacheTtl) {
      _getCache.remove(cacheKey);
      debugPrint('GET cache EXPIRED $cacheKey');
      return null;
    }

    debugPrint('GET cache HIT $cacheKey');
    return cachedResponse.toHttpResponse();
  }

  void _storeCachedGetResponse(String cacheKey, http.Response response) {
    _getCache[cacheKey] = _CachedHttpResponse(
      body: response.body,
      statusCode: response.statusCode,
      headers: response.headers,
      createdAt: DateTime.now(),
    );
    debugPrint('GET cache STORE $cacheKey');
  }

  void _invalidateGetCache() {
    if (_getCache.isEmpty) {
      return;
    }

    _getCache.clear();
    debugPrint('GET cache INVALIDATED');
  }

  void _invalidateGetCacheEntry(String cacheKey) {
    final removed = _getCache.remove(cacheKey);
    if (removed != null) {
      debugPrint('GET cache INVALIDATED $cacheKey');
    }
  }

  String? _extractErrorMessage(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      return _readErrorMessage(decoded);
    } catch (_) {
      return body.trim();
    }
  }

  String? _readErrorMessage(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is String) {
      final value = data.trim();
      return value.isEmpty ? null : value;
    }

    if (data is List) {
      for (final item in data) {
        final message = _readErrorMessage(item);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      return null;
    }

    if (data is Map<String, dynamic>) {
      final directKeys = [
        'message',
        'detail',
        'error',
        'non_field_errors',
        'email',
        'password',
      ];

      for (final key in directKeys) {
        final message = _readErrorMessage(data[key]);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }

      for (final value in data.values) {
        final message = _readErrorMessage(value);
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }

    return null;
  }
}

enum ApiCallType {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const ApiCallType(this.value);

  final String value;
}

class _CachedHttpResponse {
  const _CachedHttpResponse({
    required this.body,
    required this.statusCode,
    required this.headers,
    required this.createdAt,
  });

  final String body;
  final int statusCode;
  final Map<String, String> headers;
  final DateTime createdAt;

  http.Response toHttpResponse() {
    return http.Response(body, statusCode, headers: headers);
  }
}
