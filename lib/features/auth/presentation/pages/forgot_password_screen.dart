import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../../../routes/app_router.dart';
import '../../data/datasources/password_reset_remote_data_source.dart';
import '../../data/repositories/password_reset_repository_impl.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../auth_validators.dart';
import '../providers/forgot_password_controller.dart';
import '../widgets/auth_link_button.dart';
import '../widgets/auth_outlined_text_field.dart';
import '../widgets/auth_page_frame.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PasswordResetRemoteDataSource>(
          create: (_) => createPasswordResetRemoteDataSource(),
        ),
        ProxyProvider<PasswordResetRemoteDataSource, PasswordResetRepositoryImpl>(
          update: (_, remoteDataSource, __) => createPasswordResetRepository(remoteDataSource),
        ),
        ProxyProvider<PasswordResetRepositoryImpl, RequestPasswordResetUseCase>(
          update: (_, repository, __) => createRequestPasswordResetUseCase(repository),
        ),
        ChangeNotifierProvider<ForgotPasswordController>(
          create: (context) => ForgotPasswordController(
            context.read<RequestPasswordResetUseCase>(),
            initialEmail: initialEmail,
          ),
        ),
      ],
      child: const _ForgotPasswordScreenView(),
    );
  }
}

class _ForgotPasswordScreenView extends StatefulWidget {
  const _ForgotPasswordScreenView();

  @override
  State<_ForgotPasswordScreenView> createState() => _ForgotPasswordScreenViewState();
}

class _ForgotPasswordScreenViewState extends State<_ForgotPasswordScreenView> {
  late final ForgotPasswordController _controller;
  final ValueNotifier<String?> _emailErrorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<bool> _hasInteractedNotifier = ValueNotifier<bool>(false);
  bool _isErrorDialogVisible = false;
  String? _lastHandledErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = context.read<ForgotPasswordController>();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _emailErrorNotifier.dispose();
    _hasInteractedNotifier.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final errorMessage = _controller.errorMessage;
    if (errorMessage == null) {
      _lastHandledErrorMessage = null;
      return;
    }

    if (errorMessage == _lastHandledErrorMessage) {
      return;
    }

    _lastHandledErrorMessage = errorMessage;
    _showErrorDialog(errorMessage);
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted || _isErrorDialogVisible) {
      return;
    }

    _isErrorDialogVisible = true;
    await CustomFunctions.showCustomAlert(context, AppStrings.authResetLinkFailedTitle, message);
    _isErrorDialogVisible = false;
  }

  Future<void> _showSuccessDialog() async {
    if (!mounted || _isErrorDialogVisible) {
      return;
    }

    _isErrorDialogVisible = true;
    await CustomFunctions.showCustomAlert(
      context,
      AppStrings.authResetLinkSentTitle,
      AppStrings.authResetLinkSentDescription(
        _controller.lastSentEmail.isEmpty ? AppStrings.authEmailLabel : _controller.lastSentEmail,
      ),
    );
    _isErrorDialogVisible = false;
  }

  void _handleEmailChanged(String value) {
    if (!_hasInteractedNotifier.value) {
      return;
    }

    _emailErrorNotifier.value = AuthValidators.validateEmail(value);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _hasInteractedNotifier.value = true;

    final error = AuthValidators.validateEmail(_controller.emailController.text);
    _emailErrorNotifier.value = error;
    if (error != null) {
      return;
    }

    final didSubmit = await _controller.submit();
    if (!didSubmit) {
      return;
    }

    await _showSuccessDialog();
  }

  void _goBackToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    AppRouter.pushReplacementNamed<void, void>(context, AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageFrame(
      alignTop: true,
      showBrandHeader: false,
      title: AppStrings.authForgotPasswordTitle,
      subtitle: AppStrings.authForgotPasswordSubtitle,
      body: ListenableBuilder(
        listenable: Listenable.merge([_controller, _emailErrorNotifier, _hasInteractedNotifier]),
        builder: (context, _) {
          final emailError = _hasInteractedNotifier.value ? _emailErrorNotifier.value : null;
          final hasSent = _controller.hasSent;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthOutlinedTextField(
                controller: _controller.emailController,
                labelText: AppStrings.authEmailLabel,
                errorText: emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.email],
                onChanged: _handleEmailChanged,
              ),
              const SizedBox(height: 6),
              AppTextView.body3(
                AppStrings.authForgotPasswordHelper,
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
              const SizedBox(height: 80),
              AppButton(
                text: hasSent ? AppStrings.authResendResetLink : AppStrings.authSendResetLink,
                isLoading: _controller.isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              Center(
                child: AuthLinkButton(label: AppStrings.authBackToLogin, onTap: _goBackToLogin),
              ),
            ],
          );
        },
      ),
    );
  }
}
