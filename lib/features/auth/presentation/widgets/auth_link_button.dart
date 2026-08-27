import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_text_view.dart';

class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.label,
    this.onTap,
    this.fontSize = 13,
    this.color = AppColors.secondaryColor,
    this.icon,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final VoidCallback? onTap;
  final double fontSize;
  final Color color;
  final IconData? icon;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
          ],
          AppTextView.body2(
            label,
            color: color,
            fontWeight: fontWeight,
            fontSize: fontSize,
          ),
        ],
      ),
    );
  }
}
