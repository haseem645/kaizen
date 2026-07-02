import 'package:flutter/material.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../constants/app_colors.dart';
import 'app_text_view.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.borderRadius = 4,
    this.minimumHeight = 40,
    this.textSize = 16,
  });

  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final double borderRadius;
  final double minimumHeight;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    final resolvedTextColor = textColor ?? AppColors.textPrimary;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.secondaryColor,
        foregroundColor: resolvedTextColor,
        disabledBackgroundColor: backgroundColor ?? AppColors.grey1,
        disabledForegroundColor: resolvedTextColor,
        minimumSize: Size.fromHeight(minimumHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: SizedBox(
        height: minimumHeight,
        child: Center(
          child: isLoading
              ? FastCircularProgressIndicator(width: 18, height: 18)
              : AppTextView.body(
                  text,
                  color: resolvedTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: textSize,
                ),
        ),
      ),
    );
  }
}
