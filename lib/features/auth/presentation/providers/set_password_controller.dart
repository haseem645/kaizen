import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/datasources/password_confirm_remote_data_source.dart';
import '../../data/repositories/password_confirm_repository_impl.dart';
import '../../domain/usecases/confirm_password_reset_usecase.dart';

class SetPasswordController extends ChangeNotifier {
  SetPasswordController(
    this._confirmPasswordResetUseCase, {
    String? initialEmail,
    String? initialToken,
  }) : emailController = TextEditingController(text: initialEmail ?? ''),
       passwordController = TextEditingController(),
       confirmPasswordController = TextEditingController(),
       _token = initialToken?.trim() ?? '';

  final ConfirmPasswordResetUseCase _confirmPasswordResetUseCase;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String _token;

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get token => _token;
  String? takeSuccessMessage() {
    final successMessage = _successMessage;
    _successMessage = null;
    return successMessage;
  }

  Future<bool> submit() async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _confirmPasswordResetUseCase.call(
        token: _token,
        email: emailController.text,
        password: passwordController.text,
      );
      _successMessage = AppStrings.authPasswordUpdatedDescription;
      return true;
    } on SetPasswordException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = AppStrings.loginSomethingWentWrong;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }

    return false;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}

PasswordConfirmRemoteDataSource createPasswordConfirmRemoteDataSource() {
  return PasswordConfirmRemoteDataSource();
}

PasswordConfirmRepositoryImpl createPasswordConfirmRepository(
  PasswordConfirmRemoteDataSource remoteDataSource,
) {
  return PasswordConfirmRepositoryImpl(remoteDataSource);
}

ConfirmPasswordResetUseCase createConfirmPasswordResetUseCase(
  PasswordConfirmRepositoryImpl repository,
) {
  return ConfirmPasswordResetUseCase(repository);
}
