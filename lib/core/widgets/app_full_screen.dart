import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppFullScreen extends StatelessWidget {
  const AppFullScreen({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.useSafeArea = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool useSafeArea;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    Widget content = SizedBox.expand(
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.mainBg,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: content,
    );
  }
}
