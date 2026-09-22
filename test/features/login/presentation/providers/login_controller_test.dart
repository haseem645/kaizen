import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/login/domain/entities/app_user.dart';
import 'package:sparrowkaizen/features/login/domain/repositories/auth_repository.dart';
import 'package:sparrowkaizen/features/login/domain/usecases/login_usecase.dart';
import 'package:sparrowkaizen/features/login/presentation/providers/login_controller.dart';

const _user = AppUser(id: 'user', email: 'member@example.com', displayName: 'Member');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Google login bypasses password fields and navigates once after completion', () async {
    final pending = Completer<AppUser?>();
    final controller = LoginController(
      _PasswordLoginUseCase(),
      googleLogin: ({onAuthorizationComplete}) => pending.future,
    );
    addTearDown(controller.dispose);

    final login = controller.loginWithGoogle();
    expect(controller.isGoogleLoading, isTrue);
    expect(controller.isPasswordLoading, isFalse);
    expect(controller.shouldHandleUserNavigation(), isFalse);
    expect(controller.emailError, isNull);
    expect(controller.passwordError, isNull);

    pending.complete(_user);
    await login;
    expect(controller.isLoading, isFalse);
    expect(controller.user, same(_user));
    expect(controller.shouldHandleUserNavigation(), isTrue);
    expect(controller.shouldHandleUserNavigation(), isFalse);
  });

  test('Google cancellation preserves credentials without errors or navigation', () async {
    final controller = LoginController(
      _PasswordLoginUseCase(),
      googleLogin: ({onAuthorizationComplete}) async => null,
    );
    addTearDown(controller.dispose);
    controller.emailController.text = 'saved@example.com';
    controller.passwordController.text = 'saved-password';

    await controller.loginWithGoogle();

    expect(controller.isLoading, isFalse);
    expect(controller.user, isNull);
    expect(controller.errorMessage, isNull);
    expect(controller.shouldHandleUserNavigation(), isFalse);
    expect(controller.emailController.text, 'saved@example.com');
    expect(controller.passwordController.text, 'saved-password');
  });

  test('concurrent Google and password attempts are ignored until Google completes', () async {
    final pending = Completer<AppUser?>();
    final passwordLogin = _PasswordLoginUseCase();
    var googleCalls = 0;
    final controller = LoginController(
      passwordLogin,
      googleLogin: ({onAuthorizationComplete}) {
        googleCalls++;
        return pending.future;
      },
    );
    addTearDown(controller.dispose);

    final login = controller.loginWithGoogle();
    await controller.loginWithGoogle();
    await controller.login(email: 'member@example.com', password: 'password');
    expect(googleCalls, 1);
    expect(passwordLogin.calls, 0);
    pending.complete(null);
    await login;
    await controller.login(email: 'member@example.com', password: 'password');
    expect(passwordLogin.calls, 1);
  });

  test('Google cannot start during password login', () async {
    final pending = Completer<AppUser>();
    var googleCalls = 0;
    final controller = LoginController(
      _PasswordLoginUseCase(signIn: () => pending.future),
      googleLogin: ({onAuthorizationComplete}) async {
        googleCalls++;
        return _user;
      },
    );
    addTearDown(controller.dispose);

    final login = controller.login(email: 'member@example.com', password: 'password');
    expect(controller.isPasswordLoading, isTrue);
    await controller.loginWithGoogle();
    expect(googleCalls, 0);
    pending.complete(_user);
    await login;
  });

  test('backend failure is shown once and allows retry', () async {
    var fail = true;
    final controller = LoginController(
      _PasswordLoginUseCase(),
      googleLogin: ({onAuthorizationComplete}) async {
        if (fail) throw const LoginException(AppStrings.loginNoAccount);
        return _user;
      },
    );
    addTearDown(controller.dispose);

    await controller.loginWithGoogle();
    expect(controller.errorMessage, AppStrings.loginNoAccount);
    expect(controller.shouldShowErrorMessage(), isTrue);
    controller.updateEmail('member@example.com');
    expect(controller.shouldShowErrorMessage(), isFalse);
    expect(controller.isLoading, isFalse);
    fail = false;
    await controller.loginWithGoogle();
    expect(controller.errorMessage, isNull);
    expect(controller.user, same(_user));
  });

  test('unconfigured Google login fails closed without authenticating', () async {
    final controller = LoginController(_PasswordLoginUseCase());
    addTearDown(controller.dispose);
    await controller.loginWithGoogle();
    expect(controller.user, isNull);
    expect(controller.errorMessage, AppStrings.loginGoogleUnavailable);
    expect(controller.isLoading, isFalse);
  });

  test('unexpected Google failure does not display SDK internals', () async {
    final controller = LoginController(
      _PasswordLoginUseCase(),
      googleLogin: ({onAuthorizationComplete}) async {
        throw StateError('internal SDK details');
      },
    );
    addTearDown(controller.dispose);
    await controller.loginWithGoogle();
    expect(controller.errorMessage, AppStrings.loginGoogleFailed);
  });

  test('a Google completion after disposal does not notify listeners', () async {
    final pending = Completer<AppUser?>();
    final controller = LoginController(
      _PasswordLoginUseCase(),
      googleLogin: ({onAuthorizationComplete}) => pending.future,
    );
    var notifications = 0;
    controller.addListener(() => notifications++);
    final login = controller.loginWithGoogle();
    controller.dispose();
    pending.complete(_user);
    await login;
    expect(notifications, 1);
  });

  test('controller owns field validation and password visibility', () {
    final controller = LoginController(_PasswordLoginUseCase());
    addTearDown(controller.dispose);
    expect(controller.emailError, isNull);
    expect(controller.validateLoginFields(), isFalse);
    expect(controller.emailError, isNotNull);
    expect(controller.passwordError, isNotNull);
    controller.emailController.text = 'member@example.com';
    controller.passwordController.text = 'password';
    expect(controller.validateLoginFields(), isTrue);
    controller.togglePasswordVisibility();
    expect(controller.isPasswordHidden, isFalse);
  });

  test('cancel is available in the browser and ends when token exchange starts', () async {
    final pending = Completer<AppUser?>();
    void Function()? authorized;
    var cancellations = 0;
    final controller = LoginController(
      _PasswordLoginUseCase(),
      googleLogin: ({onAuthorizationComplete}) {
        authorized = onAuthorizationComplete;
        return pending.future;
      },
      cancelGoogleLogin: () => cancellations++,
    );
    addTearDown(controller.dispose);
    final login = controller.loginWithGoogle();
    expect(controller.canCancelGoogleLogin, isTrue);
    controller.cancelGoogleLogin();
    expect(cancellations, 1);
    authorized!();
    expect(controller.canCancelGoogleLogin, isFalse);
    controller.cancelGoogleLogin();
    expect(cancellations, 1);
    pending.complete(_user);
    await login;
    expect(controller.user, same(_user));
  });
}

class _PasswordLoginUseCase extends LoginUseCase {
  _PasswordLoginUseCase({this.signIn}) : super(_UnusedAuthRepository());

  final Future<AppUser> Function()? signIn;
  int calls = 0;

  @override
  Future<AppUser> call({required String email, required String password}) async {
    calls++;
    return signIn == null ? _user : await signIn!();
  }
}

class _UnusedAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
