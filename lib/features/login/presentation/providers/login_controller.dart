import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/auth_validators.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../google_sign_in_diagnostics.dart';

typedef GoogleLoginAction = Future<AppUser?> Function({void Function()? onAuthorizationComplete});

class LoginController extends ChangeNotifier {
  LoginController(
    this._loginUseCase, {
    GoogleLoginAction? googleLogin,
    VoidCallback? cancelGoogleLogin,
  }) : _googleLogin = googleLogin,
       _cancelGoogleLogin = cancelGoogleLogin;

  final LoginUseCase _loginUseCase;
  final GoogleLoginAction? _googleLogin;
  final VoidCallback? _cancelGoogleLogin;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAwaitingGoogleAuthorization = false;
  bool _isDisposed = false;
  bool _isPasswordHidden = true;
  bool _hasInteractedWithEmail = false;
  bool _hasInteractedWithPassword = false;
  bool _hasShownError = false;
  String? _emailError;
  String? _passwordError;
  AppUser? _user;
  String? _errorMessage;
  AppUser? _lastUser;
  String _lastAttemptedEmail = '';
  String _lastAttemptedPassword = '';

  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get canCancelGoogleLogin => _isAwaitingGoogleAuthorization && _cancelGoogleLogin != null;
  bool get isPasswordLoading => _isLoading && !_isGoogleLoading;
  bool get isPasswordHidden => _isPasswordHidden;
  String? get emailError => _hasInteractedWithEmail ? _emailError : null;
  String? get passwordError => _hasInteractedWithPassword ? _passwordError : null;
  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;

  bool shouldShowErrorMessage() {
    if (_errorMessage == null || _hasShownError) {
      return false;
    }

    _hasShownError = true;
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
    if (_isLoading || _isDisposed) return;
    _lastAttemptedEmail = email;
    _lastAttemptedPassword = password;
    _isLoading = true;
    _user = null;
    _errorMessage = null;
    _hasShownError = false;
    notifyListeners();

    try {
      _user = await _loginUseCase.call(email: email, password: password);
    } on LoginException catch (error) {
      _user = null;
      _errorMessage = error.message;
      if (!_isDisposed) _restoreLastAttemptedCredentials();
    } catch (_) {
      _user = null;
      _errorMessage = AppStrings.loginSomethingWentWrong;
      if (!_isDisposed) _restoreLastAttemptedCredentials();
    }

    _isLoading = false;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> loginWithGoogle() async {
    GoogleSignInDiagnostics.log(
      'button.pressed',
      data: {'is_loading': _isLoading, 'is_disposed': _isDisposed},
    );
    if (_isLoading || _isDisposed) {
      GoogleSignInDiagnostics.log('button.ignored');
      return;
    }
    _isLoading = true;
    _isGoogleLoading = true;
    _isAwaitingGoogleAuthorization = true;
    _user = null;
    _errorMessage = null;
    _hasShownError = false;
    notifyListeners();

    try {
      final googleLogin = _googleLogin;
      if (googleLogin == null) {
        throw const LoginException(AppStrings.loginGoogleUnavailable);
      }
      // Cancellation returns null; only an app-authenticated user can navigate.
      _user = await googleLogin(
        onAuthorizationComplete: () {
          GoogleSignInDiagnostics.log('button.authorization_finished');
          _isAwaitingGoogleAuthorization = false;
          if (!_isDisposed) notifyListeners();
        },
      );
      GoogleSignInDiagnostics.log('login.result', data: {'authenticated': _user != null});
    } on LoginException catch (error, stackTrace) {
      GoogleSignInDiagnostics.log('login.error', error: error, stackTrace: stackTrace);
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      GoogleSignInDiagnostics.log('login.unexpected_error', error: error, stackTrace: stackTrace);
      _errorMessage = AppStrings.loginGoogleFailed;
    } finally {
      _isLoading = false;
      _isGoogleLoading = false;
      _isAwaitingGoogleAuthorization = false;
      GoogleSignInDiagnostics.log('button.loading_cleared', data: {'is_disposed': _isDisposed});
      if (!_isDisposed) notifyListeners();
    }
  }

  void cancelGoogleLogin() {
    GoogleSignInDiagnostics.log('button.cancel', data: {'can_cancel': canCancelGoogleLogin});
    if (canCancelGoogleLogin) _cancelGoogleLogin?.call();
  }

  void updateEmail(String value) {
    _hasInteractedWithEmail = true;
    _emailError = AuthValidators.validateEmail(value);
    notifyListeners();
  }

  void updatePassword(String value) {
    _hasInteractedWithPassword = true;
    _passwordError = AuthValidators.validateLoginPassword(value);
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _isPasswordHidden = !_isPasswordHidden;
    notifyListeners();
  }

  bool validateLoginFields() {
    _hasInteractedWithEmail = true;
    _hasInteractedWithPassword = true;
    _emailError = AuthValidators.validateEmail(emailController.text);
    _passwordError = AuthValidators.validateLoginPassword(passwordController.text);
    notifyListeners();
    return _emailError == null && _passwordError == null;
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
        selection: TextSelection.collapsed(offset: _lastAttemptedPassword.length),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    cancelGoogleLogin();
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
