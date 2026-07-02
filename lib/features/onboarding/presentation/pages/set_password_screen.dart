import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_full_screen.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/splash_gradient_background.dart';
import '../../../../routes/app_router.dart';
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

class _SetPasswordScreenView extends StatefulWidget {
  const _SetPasswordScreenView();

  @override
  State<_SetPasswordScreenView> createState() => _SetPasswordScreenViewState();
}

class _SetPasswordScreenViewState extends State<_SetPasswordScreenView> {
  late final OnboardingController _controller;
  bool _hasHandledCompletion = false;

  @override
  void initState() {
    super.initState();
    _controller = context.read<OnboardingController>();
    _controller.addListener(_handleStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (!_controller.isCompleted || _hasHandledCompletion || !mounted) {
      return;
    }

    _hasHandledCompletion = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      AppRouter.pushReplacementNamed<void, void>(context, AppRouter.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();

    return AppFullScreen(
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      child: SplashGradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: controller.passwordFormKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          const AppTextView.title(
                            'Set Password',
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 5),
                          const AppTextView.body(
                            'Please create a secure password to continue',
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 120),
                          _ReadOnlyField(
                            value: controller.email.isEmpty
                                ? 'Not available'
                                : controller.email,
                            hint: 'Email',
                          ),
                          const SizedBox(height: 14),
                          _PasswordField(
                            controller: controller.passwordController,
                            hint: 'Enter password',
                            obscureText: controller.isPasswordHidden,
                            onToggle: controller.togglePasswordVisibility,
                            validator: controller.validatePassword,
                          ),
                          const SizedBox(height: 14),
                          _PasswordField(
                            controller: controller.confirmPasswordController,
                            hint: 'Confirm password',
                            obscureText: controller.isConfirmPasswordHidden,
                            onToggle:
                                controller.toggleConfirmPasswordVisibility,
                            validator: controller.validateConfirmPassword,
                          ),
                          const SizedBox(height: 16),
                          const AppTextView.body(
                            'Use at least 8 characters.',
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 60),
                          AppButton(
                            text: 'Next',
                            onPressed: () async {
                              await controller.completeOnboarding();
                            },
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
              Positioned(
                top: 0,
                left: 0,
                child: AppBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
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
          errorStyle: const TextStyle(color: Color(0xFFFFB3B3)),
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
