import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/splash_background_effects.dart';

class AuthBackgroundScaffold extends StatelessWidget {
  const AuthBackgroundScaffold({
    super.key,
    required this.child,
    this.maxWidth = 400,
    this.alignTop = false,
  });

  final Widget child;
  final double maxWidth;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hex292c3c,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
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
            _AuthBackgroundContent(
              maxWidth: maxWidth,
              alignTop: alignTop,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthBackgroundContent extends StatelessWidget {
  const _AuthBackgroundContent({
    required this.maxWidth,
    required this.child,
    required this.alignTop,
  });

  final double maxWidth;
  final Widget child;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTabletLayout = mediaQuery.size.shortestSide >= 600;
          final contentPadding = EdgeInsets.fromLTRB(
            isTabletLayout ? 40 : 30,
            isTabletLayout ? 40 : 80,
            isTabletLayout ? 40 : 30,
            bottomInset + 24,
          );
          final minHeight = (constraints.maxHeight - contentPadding.vertical)
              .clamp(0.0, double.infinity)
              .toDouble();

          return SingleChildScrollView(
            padding: contentPadding,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Align(
                alignment: alignTop
                    ? Alignment.topCenter
                    : isTabletLayout
                    ? Alignment.center
                    : Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
