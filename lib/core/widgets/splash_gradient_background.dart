import 'package:flutter/material.dart';

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
          colors: [Color(0xFF33364B), Color(0xFF2E3144), Color(0xFF292C3C)],
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
