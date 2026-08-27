import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../../../routes/app_router.dart';
import '../../data/datasources/password_confirm_remote_data_source.dart';
import '../../data/repositories/password_confirm_repository_impl.dart';
import '../../domain/usecases/confirm_password_reset_usecase.dart';
import '../auth_validators.dart';
import '../providers/set_password_controller.dart';
import '../widgets/auth_link_button.dart';
import '../widgets/auth_outlined_text_field.dart';
import '../widgets/auth_page_frame.dart';

class SetPasswordScreen extends StatelessWidget {
  const SetPasswordScreen({super.key, this.initialEmail, this.initialToken});

  final String? initialEmail;
  final String? initialToken;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PasswordConfirmRemoteDataSource>(
          create: (_) => createPasswordConfirmRemoteDataSource(),
        ),
        ProxyProvider<PasswordConfirmRemoteDataSource, PasswordConfirmRepositoryImpl>(
          update: (_, remoteDataSource, __) => createPasswordConfirmRepository(remoteDataSource),
        ),
        ProxyProvider<PasswordConfirmRepositoryImpl, ConfirmPasswordResetUseCase>(
          update: (_, repository, __) => createConfirmPasswordResetUseCase(repository),
        ),
        ChangeNotifierProvider<SetPasswordController>(
          create: (context) => SetPasswordController(
            context.read<ConfirmPasswordResetUseCase>(),
            initialEmail: initialEmail,
            initialToken: initialToken,
          ),
        ),
      ],
      child: const _SetPasswordScreenView(),
    );
  }
}

class _SetPasswordScreenView extends StatefulWidget {
  const _SetPasswordScreenView();

  @override
  State<_SetPasswordScreenView> createState() => _SetPasswordScreenViewState();
}

class _SetPasswordScreenViewState extends State<_SetPasswordScreenView> {
  late final SetPasswordController _controller;
  final ValueNotifier<bool> _isPasswordHiddenNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isConfirmPasswordHiddenNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _hasInteractedWithPasswordNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasInteractedWithConfirmPasswordNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> _passwordErrorNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _confirmPasswordErrorNotifier = ValueNotifier<String?>(null);
  bool _isErrorDialogVisible = false;
  String? _lastHandledErrorMessage;

  @override
  void initState() {
    super.initState();
    _controller = context.read<SetPasswordController>();
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _isPasswordHiddenNotifier.dispose();
    _isConfirmPasswordHiddenNotifier.dispose();
    _hasInteractedWithPasswordNotifier.dispose();
    _hasInteractedWithConfirmPasswordNotifier.dispose();
    _passwordErrorNotifier.dispose();
    _confirmPasswordErrorNotifier.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final successMessage = _controller.takeSuccessMessage();
    if (successMessage != null) {
      _showSuccessSnackBarAndGoToLogin(successMessage);
      return;
    }

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
    await CustomFunctions.showCustomAlert(context, AppStrings.authSetPasswordFailedTitle, message);
    _isErrorDialogVisible = false;
  }

  Future<void> _showSuccessSnackBarAndGoToLogin(String message) async {
    await AppRouter.resetToLogin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigatorContext = AppRouter.navigatorKey.currentContext;
      if (navigatorContext == null) {
        return;
      }

      ScaffoldMessenger.of(navigatorContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: AppTextView.body2(message)));
    });
  }

  void _handlePasswordChanged(String value) {
    if (_hasInteractedWithPasswordNotifier.value) {
      _passwordErrorNotifier.value = AuthValidators.validateNewPassword(value);
    }
    if (_hasInteractedWithConfirmPasswordNotifier.value) {
      _confirmPasswordErrorNotifier.value = AuthValidators.validatePasswordConfirmation(
        password: value,
        confirmation: _controller.confirmPasswordController.text,
      );
    }
  }

  void _handleConfirmPasswordChanged(String value) {
    if (!_hasInteractedWithConfirmPasswordNotifier.value) {
      return;
    }

    _confirmPasswordErrorNotifier.value = AuthValidators.validatePasswordConfirmation(
      password: _controller.passwordController.text,
      confirmation: value,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _hasInteractedWithPasswordNotifier.value = true;
    _hasInteractedWithConfirmPasswordNotifier.value = true;

    final passwordError = AuthValidators.validateNewPassword(_controller.passwordController.text);
    final confirmPasswordError = AuthValidators.validatePasswordConfirmation(
      password: _controller.passwordController.text,
      confirmation: _controller.confirmPasswordController.text,
    );

    _passwordErrorNotifier.value = passwordError;
    _confirmPasswordErrorNotifier.value = confirmPasswordError;

    if (passwordError != null || confirmPasswordError != null) {
      return;
    }

    await _controller.submit();
  }

  void _goBackToLogin() {
    AppRouter.resetToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        _isPasswordHiddenNotifier,
        _isConfirmPasswordHiddenNotifier,
        _hasInteractedWithPasswordNotifier,
        _hasInteractedWithConfirmPasswordNotifier,
        _passwordErrorNotifier,
        _confirmPasswordErrorNotifier,
      ]),
      builder: (context, _) {
        final showEmailField = _controller.emailController.text.trim().isNotEmpty;

        return AuthPageFrame(
          // leading: AppBackButton(
          //   onPressed: hasUpdatedPassword ? _goBackToLogin : null,
          // ),
          title: AppStrings.authSetPasswordTitle,
          subtitle: AppStrings.authSetPasswordSubtitle,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showEmailField) ...[
                AuthOutlinedTextField(
                  controller: _controller.emailController,
                  labelText: AppStrings.authEmailLabel,
                  enabled: false,
                  readOnly: true,
                  suffixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: AppColors.secondaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              AuthOutlinedTextField(
                controller: _controller.passwordController,
                labelText: AppStrings.authNewPasswordLabel,
                errorText: _hasInteractedWithPasswordNotifier.value
                    ? _passwordErrorNotifier.value
                    : null,
                obscureText: _isPasswordHiddenNotifier.value,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newPassword],
                onChanged: _handlePasswordChanged,
                suffixIcon: IconButton(
                  onPressed: () {
                    _isPasswordHiddenNotifier.value = !_isPasswordHiddenNotifier.value;
                  },
                  icon: Icon(
                    _isPasswordHiddenNotifier.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.secondaryColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AuthOutlinedTextField(
                controller: _controller.confirmPasswordController,
                labelText: AppStrings.authConfirmPasswordLabel,
                errorText: _hasInteractedWithConfirmPasswordNotifier.value
                    ? _confirmPasswordErrorNotifier.value
                    : null,
                obscureText: _isConfirmPasswordHiddenNotifier.value,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.newPassword],
                onChanged: _handleConfirmPasswordChanged,
                suffixIcon: IconButton(
                  onPressed: () {
                    _isConfirmPasswordHiddenNotifier.value =
                        !_isConfirmPasswordHiddenNotifier.value;
                  },
                  icon: Icon(
                    _isConfirmPasswordHiddenNotifier.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.secondaryColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const _PasswordRequirementsList(),
              const SizedBox(height: 24),
              AppButton(
                text: AppStrings.authUpdatePassword,
                isLoading: _controller.isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  AppTextView.body2(
                    AppStrings.authRememberedPassword,
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  AuthLinkButton(label: AppStrings.authBackToLogin, onTap: _goBackToLogin),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PasswordRequirementsList extends StatelessWidget {
  const _PasswordRequirementsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _PasswordRequirementText(AppStrings.authPasswordRequirementMinLength),
        SizedBox(height: 2),
        _PasswordRequirementText(AppStrings.authPasswordRequirementLetter),
        SizedBox(height: 2),
        _PasswordRequirementText(AppStrings.authPasswordRequirementNumber),
      ],
    );
  }
}

class _PasswordRequirementText extends StatelessWidget {
  const _PasswordRequirementText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return AppTextView.body3(text, color: AppColors.textSecondary, fontSize: 12, height: 1.4);
  }
}
