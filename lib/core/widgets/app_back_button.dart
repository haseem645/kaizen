import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  static const double iconSize = 24;
  static const String assetPath = '${AppStrings.imagePath}back.svg';

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: iconSize,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: SvgPicture.asset(assetPath, width: iconSize, height: iconSize),
    );
  }
}
