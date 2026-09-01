import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/app_strings.dart';
import '../preference/app_preference.dart';
import '../utils/auth_controller.dart';
import 'api_endpoints.dart';
import 'api_error.dart';
import 'api_processor.dart';

class MultipartApiFile {
  const MultipartApiFile({
    required this.fieldName,
    required this.fileName,
    required this.bytes,
    required this.contentType,
  });

  final String fieldName;
  final String fileName;
  final Uint8List bytes;
  final String contentType;
}

class MultipartApiExecutor {
  const MultipartApiExecutor();

  static const Duration _requestTimeout = Duration(seconds: 30);

  Future<Response> process<Response>({
    required String endpoint,
    required Map<String, String> fields,
    required List<MultipartApiFile> files,
    required Response Function(dynamic json) decoder,
  }) async {
    final response = await _send(
      endpoint: endpoint,
      fields: fields,
      files: files,
    );
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw ApiError.requestFailed(response.statusCode);
    }

    // Multipart mutations bypass ApiCallExecutor, so invalidate its GET cache.
    ApiCallExecutor.clearGetCache();

    dynamic json;
    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(response.body);
      } on FormatException {
        throw const ApiError.invalidResponse();
      }
    }

    return decoder(json);
  }

  Future<http.Response> _send({
    required String endpoint,
    required Map<String, String> fields,
    required List<MultipartApiFile> files,
  }) async {
    final resolvedEndpoint = ApiEndPoints.resolveEndpoint(endpoint);
    final uri = Uri.parse(
      '${ApiEndPoints.baseUrl}${ApiEndPoints.version}$resolvedEndpoint',
    );

    Future<http.Response> sendWithToken(String token) async {
      final request = http.MultipartRequest('POST', uri)..fields.addAll(fields);
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      for (final file in files) {
        request.files.add(
          http.MultipartFile.fromBytes(
            file.fieldName,
            file.bytes,
            filename: file.fileName,
            contentType: MediaType.parse(file.contentType),
          ),
        );
      }

      try {
        final response = await request.send().timeout(_requestTimeout);
        return http.Response.fromStream(response).timeout(_requestTimeout);
      } on SocketException {
        throw ApiError.requestFailed(
          0,
          message: AppStrings.apiUnableToConnectServer,
        );
      } on HttpException {
        throw ApiError.requestFailed(
          0,
          message: AppStrings.apiUnableToConnectServer,
        );
      } on TimeoutException {
        throw ApiError.requestFailed(0, message: AppStrings.apiRequestTimedOut);
      }
    }

    final initialToken = AppPreference.getAuthToken();
    var response = await sendWithToken(initialToken);
    if (response.statusCode == 401) {
      final refreshedToken = await AuthController.requestRefreshToken();
      response = await sendWithToken(refreshedToken);
    }

    debugPrint('Multipart call ${uri.toString()} ${response.statusCode}');
    return response;
  }
}
