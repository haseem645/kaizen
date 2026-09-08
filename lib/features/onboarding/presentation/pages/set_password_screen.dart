import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_full_screen.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/splash_gradient_background.dart';
import '../providers/onboarding_controller.dart';
import 'set_profile_image_screen.dart';

class SetPasswordScreen extends StatelessWidget {
  const SetPasswordScreen({
    super.key,
    this.initialProfileImagePath,
    this.initialEmail,
  });

  final String? initialProfileImagePath;
  final String? initialEmail;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingController>(
      create: (_) => OnboardingController(
        initialProfileImagePath: initialProfileImagePath,
        initialEmail: initialEmail,
      ),
      child: const _SetPasswordScreenView(),
    );
  }
}

class _SetPasswordScreenView extends StatelessWidget {
  const _SetPasswordScreenView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final contentPadding = controller.resolveSetPasswordContentPadding(
      bottomInset,
    );

    if (controller.shouldNavigateToLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.navigateToLoginAfterCompletion(context);
      });
    }

    return AppFullScreen(
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      child: SplashGradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final minHeight = controller.resolveSetPasswordMinHeight(
                    maxHeight: constraints.maxHeight,
                    contentPadding: contentPadding,
                  );

                  return SingleChildScrollView(
                    padding: contentPadding,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Form(
                            key: controller.passwordFormKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: controller
                                      .resolveSetPasswordHeaderSpacing(
                                        bottomInset,
                                      ),
                                ),
                                const AppTextView.title(
                                  AppStrings.onboardingSetPasswordTitle,
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 5),
                                const AppTextView.body(
                                  AppStrings.onboardingSetPasswordSubtitle,
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(
                                  height: controller
                                      .resolveSetPasswordFormSpacing(
                                        bottomInset,
                                      ),
                                ),
                                _ReadOnlyField(
                                  value: controller.setPasswordDisplayEmail,
                                  hint:
                                      AppStrings.onboardingSetPasswordEmailHint,
                                ),
                                const SizedBox(height: 14),
                                _PasswordField(
                                  controller: controller.passwordController,
                                  hint: AppStrings
                                      .onboardingSetPasswordPasswordHint,
                                  obscureText: controller.isPasswordHidden,
                                  onToggle: controller.togglePasswordVisibility,
                                  validator: controller.validatePassword,
                                ),
                                const SizedBox(height: 14),
                                _PasswordField(
                                  controller:
                                      controller.confirmPasswordController,
                                  hint: AppStrings
                                      .onboardingSetPasswordConfirmPasswordHint,
                                  obscureText:
                                      controller.isConfirmPasswordHidden,
                                  onToggle: controller
                                      .toggleConfirmPasswordVisibility,
                                  validator: controller.validateConfirmPassword,
                                ),
                                const SizedBox(height: 16),
                                const _PasswordRequirementsList(),
                                SizedBox(
                                  height: controller
                                      .resolveSetPasswordActionSpacing(
                                        bottomInset,
                                      ),
                                ),
                                AppButton(
                                  text: AppStrings.next,
                                  onPressed: controller.submitSetPassword,
                                  isLoading: controller.isSubmitting,
                                  backgroundColor: AppColors.secondaryColor,
                                  minimumHeight: 45,
                                  borderRadius: 8,
                                  textSize: 18,
                                ),
                                const SizedBox(height: 32),
                                const OnboardingPoweredByFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (controller.isInitializingUser)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value, required this.hint});

  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        enabled: false,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          border: InputBorder.none,
          disabledBorder: InputBorder.none,
          suffixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        cursorHeight: 17,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        cursorColor: AppColors.textPrimary,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          border: InputBorder.none,
          errorStyle: const TextStyle(color: AppColors.hexffb3b3),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
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
    return AppTextView.body(
      text,
      color: AppColors.textSecondary,
      fontSize: 14,
      textAlign: TextAlign.left,
    );
  }
}
