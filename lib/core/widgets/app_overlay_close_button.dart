import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppOverlayCloseButton extends StatelessWidget {
  const AppOverlayCloseButton({
    super.key,
    this.onTap,
    this.size = 28,
    this.iconSize = 18,
  });

  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
