import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_full_screen.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../../core/widgets/splash_gradient_background.dart';
import '../../../../routes/app_router.dart';
import '../providers/onboarding_controller.dart';

class SetProfileImageScreen extends StatelessWidget {
  const SetProfileImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingController>(
      create: (_) => OnboardingController(),
      child: const _SetProfileImageScreenView(),
    );
  }
}

class _SetProfileImageScreenView extends StatefulWidget {
  const _SetProfileImageScreenView();

  @override
  State<_SetProfileImageScreenView> createState() =>
      _SetProfileImageScreenViewState();
}

class _SetProfileImageScreenViewState
    extends State<_SetProfileImageScreenView> {
  late final OnboardingController _controller;
  bool _hasShownExpiredLinkDialog = false;

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
    if (!_controller.isDeepLinkExpired) {
      _hasShownExpiredLinkDialog = false;
      return;
    }

    if (_controller.isInitializingUser ||
        _hasShownExpiredLinkDialog ||
        !mounted) {
      return;
    }

    _hasShownExpiredLinkDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      CustomFunctions.showCustomAlert(
        context,
        'Link Expired',
        OnboardingController.expiredLinkMessage,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();

    return AppFullScreen(
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      resizeToAvoidBottomInset: false,
      child: SplashGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Stack(
                  children: [
                    IgnorePointer(
                      ignoring: controller.isInitializingUser,
                      child: SizedBox.expand(
                        child: Column(
                          children: [
                            const SizedBox(height: 28),
                            const AppTextView.title(
                              'Upload Profile Picture',
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            const AppTextView.body(
                              'Please upload profile picture to continue',
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 64),
                            _ProfileImagePicker(
                              imagePath: controller.profileImagePath,
                              isLoading: controller.isPickingImage,
                              onTap: () async {
                                await controller.pickProfileImage();
                              },
                            ),
                            const SizedBox(height: 16),
                            const AppTextView.body(
                              '(optional)',
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            const AppTextView.body(
                              'Allowed Formats *.jpeg, *.jpg, *.png, *.heic, *.heif',
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const AppTextView.body(
                              'Max Size: 3.0 MB 256px x 256px',
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                            AppButton(
                              text: 'Next',
                              onPressed: () async {
                                if (controller.isDeepLinkExpired) {
                                  CustomFunctions.showCustomAlert(
                                    context,
                                    'Link Expired',
                                    OnboardingController.expiredLinkMessage,
                                  );
                                  return;
                                }

                                if (!controller.hasLocalProfileImageToUpload) {
                                  AppRouter.pushNamed<void>(
                                    context,
                                    AppRouter.onboardingPassword,
                                    arguments: OnboardingPasswordRouteArgs(
                                      profileImagePath:
                                          controller.profileImagePath,
                                      email: controller.email,
                                    ),
                                  );
                                  return;
                                }

                                final success = await controller
                                    .submitProfileImage();
                                if (!context.mounted) {
                                  return;
                                }

                                if (!success) {
                                  if (controller.isSubmitting) {
                                    return;
                                  }

                                  CustomFunctions.showCustomAlert(
                                    context,
                                    'Unable to Continue',
                                    controller.errorMessage ??
                                        'Unable to upload profile image right now.',
                                  );
                                  return;
                                }

                                AppRouter.pushNamed<void>(
                                  context,
                                  AppRouter.onboardingPassword,
                                  arguments: OnboardingPasswordRouteArgs(
                                    profileImagePath:
                                        controller.profileImagePath,
                                    email: controller.email,
                                  ),
                                );
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
                    if (controller.isInitializingUser)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: false,
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.25),
                            child: Center(
                              child: FastCircularProgressIndicator(
                                width: 42,
                                height: 42,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileImagePicker extends StatelessWidget {
  const _ProfileImagePicker({
    required this.imagePath,
    required this.isLoading,
    required this.onTap,
  });

  final String? imagePath;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedImagePath = imagePath?.trim();
    final imageProvider = resolvedImagePath == null || resolvedImagePath.isEmpty
        ? null
        : resolvedImagePath.startsWith('http')
        ? NetworkImage(resolvedImagePath) as ImageProvider<Object>
        : FileImage(File(resolvedImagePath)) as ImageProvider<Object>;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 184,
        height: 184,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.85),
            width: 1.2,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            image: imageProvider == null
                ? null
                : DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
          child: imageProvider == null
              ? Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.textPrimary,
                        size: 108,
                      ),
                    ),
                    Positioned(
                      top: 22,
                      left: 22,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                    if (isLoading)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 1.4,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isLoading)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
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

class OnboardingPoweredByFooter extends StatelessWidget {
  const OnboardingPoweredByFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTextView.body(
          'Powered By',
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: AppTextView.body(
                'Kaizen',
                color: AppColors.purple1,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: AppTextView.body(
                '|',
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 5),
              child: AppTextView.body(
                'Teams',
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
