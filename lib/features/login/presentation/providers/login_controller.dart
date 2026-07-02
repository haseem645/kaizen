import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._loginUseCase);

  final LoginUseCase _loginUseCase;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  AppUser? _user;
  String? _errorMessage;
  AppUser? _lastUser;
  String _lastAttemptedEmail = '';
  String _lastAttemptedPassword = '';

  bool get isLoading => _isLoading;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;

  bool shouldShowErrorMessage() {
    if (_errorMessage == null) {
      return false;
    }

    return true;
  }

  bool shouldHandleUserNavigation() {
    if (_user == null || _user == _lastUser) {
      return false;
    }

    _lastUser = _user;
    return true;
  }

  Future<void> login({required String email, required String password}) async {
    _lastAttemptedEmail = email;
    _lastAttemptedPassword = password;
    _isLoading = true;
    _user = null;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _loginUseCase.call(email: email, password: password);
    } on LoginException catch (error) {
      _user = null;
      _errorMessage = error.message;
      _restoreLastAttemptedCredentials();
    } catch (_) {
      _user = null;
      _errorMessage = AppStrings.loginSomethingWentWrong;
      _restoreLastAttemptedCredentials();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _restoreLastAttemptedCredentials() {
    if (emailController.text != _lastAttemptedEmail) {
      emailController.value = TextEditingValue(
        text: _lastAttemptedEmail,
        selection: TextSelection.collapsed(offset: _lastAttemptedEmail.length),
      );
    }

    if (passwordController.text != _lastAttemptedPassword) {
      passwordController.value = TextEditingValue(
        text: _lastAttemptedPassword,
        selection: TextSelection.collapsed(
          offset: _lastAttemptedPassword.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

AuthRemoteDataSource createAuthRemoteDataSource() => AuthRemoteDataSource();

AuthRepositoryImpl createAuthRepository(AuthRemoteDataSource remoteDataSource) {
  return AuthRepositoryImpl(remoteDataSource);
}

LoginUseCase createLoginUseCase(AuthRepositoryImpl repository) {
  return LoginUseCase(repository);
}
