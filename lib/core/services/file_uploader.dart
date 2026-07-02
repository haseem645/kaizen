import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../network/api_endpoints.dart';
import '../network/api_error.dart';
import '../network/api_processor.dart';
import '../preference/app_preference.dart';

class FileUploader {
  const FileUploader({ApiCallExecutor? apiCallExecutor})
    : _apiCallExecutor = apiCallExecutor ?? const ApiCallExecutor();

  final ApiCallExecutor _apiCallExecutor;

  Future<PresignedFileUpload> generatePresignedUpload({
    required String key,
    required String fileName,
    String? authToken,
  }) {
    return _apiCallExecutor.processApi<PresignedFileUpload>(
      apiCallType: ApiCallType.post,
      endpoint: ApiEndPoints.generatePreSignedUrl,
      authToken: _resolveAuthToken(authToken),
      parameters: {'key': key, 'file_name': fileName},
      decoder: (json) {
        final uploadUrl = _readFirstString(json, const ['signedUrl']);
        if (uploadUrl == null || uploadUrl.isEmpty) {
          throw const ApiError.invalidResponse();
        }

        return PresignedFileUpload(
          uploadUrl: uploadUrl,
          fileUrl: _readFirstString(json, const ['fileUrl', 'url']),
        );
      },
    );
  }

  Future<void> uploadBinaryFile({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
    ValueChanged<double>? onProgress,
  }) async {
    final uri = Uri.tryParse(uploadUrl);
    if (uri == null) {
      throw const ApiError.invalidUrl();
    }

    final request = _ProgressByteRequest(
      'PUT',
      uri,
      fileBytes: fileBytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    final client = http.Client();
    late final http.Response response;
    try {
      final streamedResponse = await client.send(request);
      response = await http.Response.fromStream(streamedResponse);
    } finally {
      client.close();
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw ApiError.requestFailed(response.statusCode);
    }
  }

  Future<UploadedImagePayload> uploadImage({
    required String fileName,
    required List<int> fileBytes,
    required String contentType,
    ValueChanged<double>? onProgress,
    String? authToken,
  }) async {
    final presignedUpload = await generatePresignedUpload(
      key: 'image',
      fileName: fileName,
      authToken: authToken,
    );

    await uploadBinaryFile(
      uploadUrl: presignedUpload.uploadUrl,
      fileBytes: fileBytes,
      contentType: contentType,
      onProgress: onProgress,
    );

    final uploadedUrl =
        presignedUpload.fileUrl ??
        publicUrlFromUploadUrl(presignedUpload.uploadUrl);

    return _apiCallExecutor.processApi<UploadedImagePayload>(
      apiCallType: ApiCallType.post,
      endpoint: ApiEndPoints.images,
      authToken: _resolveAuthToken(authToken),
      parameters: {'image': uploadedUrl},
      decoder: (json) {
        if (json is! Map<String, dynamic>) {
          throw const ApiError.invalidResponse();
        }

        final uuid = _readFirstString(json, const ['uuid']);
        final image = _readFirstString(json, const ['image']);
        if (uuid == null || uuid.isEmpty || image == null || image.isEmpty) {
          throw const ApiError.invalidResponse();
        }

        return UploadedImagePayload(uuid: uuid, image: image);
      },
    );
  }

  Future<UploadedImagePayload> uploadOnboardingImage({
    required String fileName,
    required List<int> fileBytes,
    required String contentType,
    ValueChanged<double>? onProgress,
    String? authToken,
  }) async {
    final uri = Uri.parse(
      '${ApiEndPoints.baseUrl}${ApiEndPoints.version}${ApiEndPoints.images}',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${_resolveAuthToken(authToken)}'
      ..files.add(
        http.MultipartFile.fromBytes('image', fileBytes, filename: fileName),
      );

    final client = http.Client();
    late final http.Response response;
    try {
      final streamedResponse = await client.send(request);
      response = await http.Response.fromStream(streamedResponse);
    } finally {
      client.close();
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw ApiError.requestFailed(response.statusCode);
    }

    final decodedBody = jsonDecode(response.body);
    if (decodedBody is! Map<String, dynamic>) {
      throw const ApiError.invalidResponse();
    }

    final uuid = _readFirstString(decodedBody, const ['uuid']);
    final image = _readFirstString(decodedBody, const ['image']);
    if (uuid == null || uuid.isEmpty || image == null || image.isEmpty) {
      throw const ApiError.invalidResponse();
    }

    return UploadedImagePayload(uuid: uuid, image: image);
  }

  String publicUrlFromUploadUrl(String value) {
    final querySeparatorIndex = value.indexOf('?');
    if (querySeparatorIndex == -1) {
      return value;
    }

    return value.substring(0, querySeparatorIndex);
  }

  String _resolveAuthToken(String? authToken) {
    final resolved = authToken?.trim();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }

    return AppPreference.getPreferredApiToken(includeOnboardingToken: true);
  }

  String? _readFirstString(dynamic json, List<String> keys) {
    if (json is! Map) {
      return null;
    }

    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}

class PresignedFileUpload {
  const PresignedFileUpload({required this.uploadUrl, this.fileUrl});

  final String uploadUrl;
  final String? fileUrl;
}

class UploadedImagePayload {
  const UploadedImagePayload({required this.uuid, required this.image});

  final String uuid;
  final String image;
}

class _ProgressByteRequest extends http.BaseRequest {
  _ProgressByteRequest(
    super.method,
    super.url, {
    required List<int> fileBytes,
    required this.contentType,
    this.onProgress,
  }) : _fileBytes = fileBytes;

  final List<int> _fileBytes;
  final String contentType;
  final ValueChanged<double>? onProgress;

  @override
  int get contentLength => _fileBytes.length;

  @override
  http.ByteStream finalize() {
    headers['Content-Type'] = contentType;
    headers['Content-Length'] = contentLength.toString();
    super.finalize();

    final streamController = StreamController<List<int>>(sync: true);
    Future<void>(() async {
      const chunkSize = 64 * 1024;
      var bytesSent = 0;

      try {
        while (bytesSent < _fileBytes.length) {
          final nextBytesSent = (bytesSent + chunkSize).clamp(
            0,
            _fileBytes.length,
          );
          final chunk = _fileBytes.sublist(bytesSent, nextBytesSent);
          streamController.add(chunk);
          bytesSent = nextBytesSent;
          onProgress?.call(
            _fileBytes.isEmpty ? 1 : bytesSent / _fileBytes.length,
          );
          await Future<void>.delayed(Duration.zero);
        }

        await streamController.close();
      } catch (error, stackTrace) {
        streamController.addError(error, stackTrace);
        await streamController.close();
      }
    });

    return http.ByteStream(streamController.stream);
  }
}
