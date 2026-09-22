import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_full_screen.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/splash_gradient_background.dart';
import '../providers/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SplashController>(
      create: (_) => SplashController(),
      child: const _SplashScreenView(),
    );
  }
}

class _SplashScreenView extends StatefulWidget {
  const _SplashScreenView();

  @override
  State<_SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<_SplashScreenView> {
  bool _hasInitialized = false;
  late SplashController _controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) {
      return;
    }

    _hasInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller = context.read<SplashController>();
      _controller.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SplashController>();

    return AppFullScreen(
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      child: _buildBackground(context, controller),
    );
  }

  Widget _buildBackground(BuildContext context, SplashController controller) {
    return SplashGradientBackground(child: _buildContent(context, controller));
  }

  Widget _buildContent(BuildContext context, SplashController controller) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(flex: 3),
                _buildTitle(context),
                const Spacer(flex: 3),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(children: [_buildStatus(context, controller)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final titleFontSize = Theme.of(context).textTheme.displaySmall?.fontSize;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppTextView.body1(
          AppStrings.kaizen,
          color: AppColors.secondaryColor,
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
        ),
        Container(
          width: 2,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          color: AppColors.textPrimary,
        ),
        AppTextView.body1(
          AppStrings.teams,
          color: AppColors.textPrimary,
          fontSize: titleFontSize,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }

  Widget _buildStatus(BuildContext context, SplashController controller) {
    if (controller.isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: FastCircularProgressIndicator(),
      );
    }

    final errorMessage = controller.errorMessage?.trim();
    if (errorMessage == null || errorMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextView.body3(
            errorMessage,
            color: AppColors.textPrimary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => controller.retry(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondaryColor,
              side: const BorderSide(color: AppColors.secondaryColor),
            ),
            child: const Text(AppStrings.actionRetry),
          ),
        ],
      ),
    );
  }
}
