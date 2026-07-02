import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class SplashBackgroundEffects extends StatelessWidget {
  const SplashBackgroundEffects({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white24, Colors.transparent, Colors.black12],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -280,
          left: -280,
          child: _GlowOrb(
            size: 520,
            color: AppColors.purple1,
            blur: 170,
            opacity: 0.96,
          ),
        ),
        Positioned(
          right: -360,
          bottom: -355,
          child: _GlowOrb(
            size: 620,
            color: AppColors.purple1,
            blur: 190,
            opacity: 0.92,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
    required this.blur,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
