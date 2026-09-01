import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/utils/custom_functions.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../routes/app_router.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../auth/presentation/auth_validators.dart';
import '../../../auth/presentation/widgets/auth_link_button.dart';
import '../../../auth/presentation/widgets/auth_outlined_text_field.dart';
import '../../../auth/presentation/widgets/auth_page_frame.dart';
import '../providers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRemoteDataSource>(
          create: (_) => createAuthRemoteDataSource(),
        ),
        ProxyProvider<AuthRemoteDataSource, AuthRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createAuthRepository(remoteDataSource),
        ),
        ProxyProvider<AuthRepositoryImpl, LoginUseCase>(
          update: (_, repository, __) => createLoginUseCase(repository),
        ),
        ChangeNotifierProvider<LoginController>(
          create: (context) => LoginController(context.read<LoginUseCase>()),
        ),
      ],
      child: const _LoginScreenView(),
    );
  }
}

class _LoginScreenView extends StatefulWidget {
  const _LoginScreenView();

  @override
  State<_LoginScreenView> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends State<_LoginScreenView> {
  late final LoginController _controller;
  bool _isErrorDialogVisible = false;
  bool _isPasswordHidden = true;
  String? _emailError;
  String? _passwordError;
  bool _hasInteractedWithEmail = false;
  bool _hasInteractedWithPassword = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<LoginController>();
    _controller.addListener(_handleControllerStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerStateChanged);
    super.dispose();
  }

  void _handleControllerStateChanged() {
    final errorMessage = _controller.errorMessage;
    final user = _controller.user;

    if (_controller.shouldShowErrorMessage() && errorMessage != null) {
      _showLoginErrorDialog(errorMessage);
    }

    if (_controller.shouldHandleUserNavigation() && user != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: AppTextView.body2(
              AppStrings.welcomeBackUser(user.displayName),
            ),
          ),
        );
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) {
          return;
        }

        if (!mounted) {
          return;
        }
        if (DeepLinkService.instance.hasPendingAuthenticatedTarget) {
          await DeepLinkService.instance
              .openPendingAuthenticatedTargetAfterLogin();
          return;
        }

        AppRouter.pushReplacementNamed<void, void>(
          context,
          AppRouter.defaultAuthenticatedRouteName,
        );
      });
    }
  }

  Future<void> _showLoginErrorDialog(String message) async {
    if (!mounted || _isErrorDialogVisible) {
      return;
    }
    _isErrorDialogVisible = true;
    CustomFunctions.showCustomAlert(context, "Login Failed", message);
    _isErrorDialogVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    return AuthPageFrame(
      title: AppStrings.loginToYourAccount,
      subtitle: AppStrings.enterProvidedCredentialsToContinue,
      body: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailField(),
            _buildPasswordField(),
            Align(
              alignment: Alignment.centerRight,
              child: AuthLinkButton(
                label: AppStrings.loginForgotPassword,
                color: AppColors.textSecondary,
                icon: Icons.lock_outline_rounded,
                fontWeight: FontWeight.w500,
                onTap: () {
                  AppRouter.pushNamed<void>(context, AppRouter.forgotPassword);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildLoginButton(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return AuthOutlinedTextField(
      controller: _controller.emailController,
      labelText: AppStrings.loginEmailLabel,
      errorText: _hasInteractedWithEmail ? _emailError : null,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const <String>[AutofillHints.email],
      onChanged: (value) {
        setState(() {
          _hasInteractedWithEmail = true;
          _emailError = AuthValidators.validateEmail(value);
        });
      },
    );
  }

  Widget _buildPasswordField() {
    return AuthOutlinedTextField(
      controller: _controller.passwordController,
      labelText: AppStrings.loginPasswordLabel,
      errorText: _hasInteractedWithPassword ? _passwordError : null,
      obscureText: _isPasswordHidden,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.password],
      onChanged: (value) {
        setState(() {
          _hasInteractedWithPassword = true;
          _passwordError = AuthValidators.validateLoginPassword(value);
        });
      },
      suffixIcon: IconButton(
        onPressed: () {
          setState(() {
            _isPasswordHidden = !_isPasswordHidden;
          });
        },
        icon: Icon(
          _isPasswordHidden
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.secondaryColor,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginController controller) {
    return AppButton(
      text: AppStrings.loginButton,
      isLoading: controller.isLoading,
      onPressed: () async {
        setState(() {
          _hasInteractedWithEmail = true;
          _hasInteractedWithPassword = true;
          _emailError = AuthValidators.validateEmail(
            controller.emailController.text,
          );
          _passwordError = AuthValidators.validateLoginPassword(
            controller.passwordController.text,
          );
        });

        if (_emailError != null || _passwordError != null) {
          return;
        }

        await context.read<LoginController>().login(
          email: controller.emailController.text,
          password: controller.passwordController.text,
        );
      },
    );
  }
}
