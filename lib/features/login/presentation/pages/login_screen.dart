import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/utils/custom_functions.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/splash_background_effects.dart';
import '../../../../routes/app_router.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/login_usecase.dart';
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
          AppRouter.kaizengram,
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

  String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) {
      return AppStrings.loginEnterEmail;
    }
    if (!email.contains('@')) {
      return AppStrings.loginEnterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String value) {
    final password = value.trim();
    if (password.isEmpty) {
      return AppStrings.loginEnterPassword;
    }
    if (password.length < 6) {
      return AppStrings.loginPasswordLength;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    return Scaffold(
      backgroundColor: const Color(0xFF292C3C),
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF33364B), Color(0xFF2E3144), Color(0xFF292C3C)],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: SplashBackgroundEffects()),
            _buildBody(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LoginController controller) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(30, 80, 30, bottomInset + 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildTitle(context),
                      const SizedBox(height: 90),
                      Form(
                        key: controller.formKey,
                        child: Column(
                          children: [
                            _buildSignInTitle(context),
                            const SizedBox(height: 10),
                            _buildSubtitle(context),
                            const SizedBox(height: 60),
                            _buildEmailField(),
                            const SizedBox(height: 2),
                            _buildPasswordField(),
                            const SizedBox(height: 12),
                            _buildLoginButton(context, controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppTextView.body1(
          AppStrings.kaizen,
          color: AppColors.secondaryColor,
          fontSize: 25,
          fontWeight: FontWeight.w400,
        ),
        Container(
          width: 1,
          height: 18,
          margin: const EdgeInsets.only(left: 7, top: 4, right: 7),
          color: AppColors.textPrimary,
        ),
        AppTextView.body1(
          AppStrings.teams,
          color: AppColors.textPrimary,
          fontSize: 25,
          fontWeight: FontWeight.w400,
        ),
      ],
    );
  }

  Widget _buildSignInTitle(BuildContext context) {
    return AppTextView.title(
      AppStrings.loginToYourAccount,
      textAlign: TextAlign.center,
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return AppTextView.body3(
      AppStrings.enterProvidedCredentialsToContinue,
      textAlign: TextAlign.center,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w500,
      fontSize: 16,
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: _controller.emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.textPrimary,
            cursorHeight: 18,
            onChanged: (value) {
              setState(() {
                _hasInteractedWithEmail = true;
                _emailError = _validateEmail(value);
              });
            },
            decoration: _buildInputDecoration(
              labelText: AppStrings.loginEmailLabel,
              hasError: _hasInteractedWithEmail && _emailError != null,
            ),
          ),
        ),
        SizedBox(
          height: 18,
          child: _buildFieldError(_hasInteractedWithEmail ? _emailError : null),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: TextFormField(
            controller: _controller.passwordController,
            obscureText: _isPasswordHidden,
            style: const TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.textPrimary,
            cursorHeight: 18,
            onChanged: (value) {
              setState(() {
                _hasInteractedWithPassword = true;
                _passwordError = _validatePassword(value);
              });
            },
            decoration: _buildInputDecoration(
              labelText: AppStrings.loginPasswordLabel,
              hasError: _hasInteractedWithPassword && _passwordError != null,
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
            ),
          ),
        ),
        SizedBox(
          height: 18,
          child: _buildFieldError(
            _hasInteractedWithPassword ? _passwordError : null,
          ),
        ),
      ],
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
          _emailError = _validateEmail(controller.emailController.text);
          _passwordError = _validatePassword(
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

  Widget _buildFieldError(String? errorText) {
    if (errorText == null || errorText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: AppTextView.body4(errorText, color: AppColors.red1, fontSize: 10),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required bool hasError,
    Widget? suffixIcon,
  }) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: AppColors.fieldBorder),
      filled: true,
      fillColor: Colors.transparent,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.textPrimary, width: 1),
      ),
      border: hasError
          ? inputBorder.copyWith(
              borderSide: const BorderSide(color: AppColors.red),
            )
          : inputBorder,
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: AppColors.red),
      ),
      suffixIcon: suffixIcon,
    );
  }
}
