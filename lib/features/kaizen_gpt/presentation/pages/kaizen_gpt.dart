import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/preference/app_preference.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../features/login/domain/entities/user.dart';

class KaizenGptScreen extends StatefulWidget {
  const KaizenGptScreen({super.key});

  @override
  State<KaizenGptScreen> createState() => _KaizenGptScreenState();
}

class _KaizenGptScreenState extends State<KaizenGptScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbAnimationController;
  late final Animation<double> _orbScaleAnimation;
  late final Future<User?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = AppPreference.getUser();
    _orbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _orbScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.06,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.06,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50,
      ),
    ]).animate(_orbAnimationController);
  }

  @override
  void dispose() {
    _orbAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawerMainScreen(
      title: '',
      selectedMenu: AppMenuType.kaizenGpt,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FutureBuilder<User?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        AppTextView.title1(
                          CustomFunctions.buildGreeting(user),
                          color: AppColors.textPrimary.withValues(alpha: 0.72),
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        AppTextView.body1(
                          AppStrings.kaizenGptGreeting,
                          color: AppColors.textPrimary.withValues(alpha: 0.74),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        _buildAiOrb(),
                        const SizedBox(height: 16),
                        AppTextView.body1(
                          AppStrings.kaizenGptReady,
                          color: AppColors.textPrimary.withValues(alpha: 0.8),
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        _buildAvailabilityCard(),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAiOrb() {
    const outerBorderColor = Color(0xFF7756DA);
    final outerShadowColor = AppColors.purple2.withValues(alpha: 0.10);
    final coreGlowColor = AppColors.secondaryColor.withValues(alpha: 0.22);

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.10),
                width: 1.1,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _orbScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _orbScaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: outerBorderColor.withValues(alpha: 0.82),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: outerShadowColor,
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                ],
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.84,
                  colors: <Color>[
                    const Color(0xFF7756DA).withValues(alpha: 0.10),
                    const Color(0xFF5F3CB8).withValues(alpha: 0.16),
                    const Color(0xFF251A45).withValues(alpha: 0.56),
                    const Color(0xFF09080F),
                  ],
                  stops: const <double>[0.0, 0.30, 0.64, 1.0],
                ),
              ),
            ),
          ),
          Container(
            width: 184,
            height: 184,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                width: 1,
              ),
              gradient: RadialGradient(
                center: const Alignment(-0.05, -0.08),
                radius: 0.80,
                colors: <Color>[
                  const Color(0xFF9C78FF).withValues(alpha: 0.94),
                  const Color(0xFF6546CC).withValues(alpha: 0.64),
                  const Color(0xFF2C1F52).withValues(alpha: 0.52),
                  const Color(0xFF0E0C17),
                ],
                stops: const <double>[0.0, 0.24, 0.54, 1.0],
              ),
            ),
          ),
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple2.withValues(alpha: 0.14),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
              gradient: RadialGradient(
                colors: <Color>[coreGlowColor, Colors.transparent],
                stops: const <double>[0.0, 1.0],
              ),
            ),
          ),
          Image.asset(
            '${AppStrings.imagePath}ai.png',
            width: 95,
            height: 95,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.26),
        ),
      ),
      child: AppTextView.body2(
        AppStrings.kaizenGptUnavailableMessage,
        color: AppColors.textPrimary.withValues(alpha: 0.78),
        height: 1.45,
        textAlign: TextAlign.center,
      ),
    );
  }
}
