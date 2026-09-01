import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

import 'splash_background_effects.dart';

class SplashGradientBackground extends StatelessWidget {
  const SplashGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.hex33364b,
            AppColors.hex2e3144,
            AppColors.hex292c3c,
          ],
          stops: [0.0, 0.42, 1.0],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: SplashBackgroundEffects()),
          child,
        ],
      ),
    );
  }
}
