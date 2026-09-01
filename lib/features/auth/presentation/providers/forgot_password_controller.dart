import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/datasources/password_reset_remote_data_source.dart';
import '../../data/repositories/password_reset_repository_impl.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';

class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController(
    this._requestPasswordResetUseCase, {
    String? initialEmail,
  }) : emailController = TextEditingController(text: initialEmail ?? '');

  final RequestPasswordResetUseCase _requestPasswordResetUseCase;
  final TextEditingController emailController;

  bool _isLoading = false;
  bool _hasSent = false;
  String? _errorMessage;
  String? _lastSentEmail;

  bool get isLoading => _isLoading;
  bool get hasSent => _hasSent;
  String? get errorMessage => _errorMessage;
  String get lastSentEmail => _lastSentEmail ?? emailController.text.trim();

  Future<bool> submit() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _requestPasswordResetUseCase.call(email: emailController.text);
      _hasSent = true;
      _lastSentEmail = emailController.text.trim();
      _isLoading = false;
      notifyListeners();
      return true;
    } on PasswordResetException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = AppStrings.loginSomethingWentWrong;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}

PasswordResetRemoteDataSource createPasswordResetRemoteDataSource() {
  return PasswordResetRemoteDataSource();
}

PasswordResetRepositoryImpl createPasswordResetRepository(
  PasswordResetRemoteDataSource remoteDataSource,
) {
  return PasswordResetRepositoryImpl(remoteDataSource);
}

RequestPasswordResetUseCase createRequestPasswordResetUseCase(
  PasswordResetRepositoryImpl repository,
) {
  return RequestPasswordResetUseCase(repository);
}
