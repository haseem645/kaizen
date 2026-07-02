import '../constants/app_strings.dart';

class ApiError implements Exception {
  const ApiError._(this.message, {this.statusCode});

  const ApiError.invalidUrl() : this._(AppStrings.apiInvalidUrl);
  const ApiError.invalidResponse() : this._(AppStrings.apiInvalidResponse);
  ApiError.requestFailed(int statusCode, {String? message})
    : this._(message ?? AppStrings.apiRequestFailed(statusCode), statusCode: statusCode);

  final String message;
  final int? statusCode;

  @override
  String toString() => '${AppStrings.apiErrorPrefix} $message';
}
