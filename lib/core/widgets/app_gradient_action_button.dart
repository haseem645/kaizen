import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_text_view.dart';

class AppGradientActionButton extends StatelessWidget {
  const AppGradientActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconSize = 18,
    this.textSize = 15,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    this.borderRadius = 14,
    this.minHeight = 48,
    this.iconSpacing = 10,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;
  final double textSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double minHeight;
  final double iconSpacing;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final resolvedBorderRadius = BorderRadius.circular(borderRadius);

    return Opacity(
      opacity: isEnabled ? 1 : 0.58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: resolvedBorderRadius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Ink(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: resolvedBorderRadius,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[AppColors.purple1, AppColors.secondaryColor],
                ),
                border: Border.all(
                  color: AppColors.lightPurple1.withValues(alpha: 0.35),
                ),
                boxShadow: isEnabled
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.purple1.withValues(alpha: 0.36),
                          blurRadius: 10,
                          offset: const Offset(-6, 0),
                          spreadRadius: -1,
                        ),
                        BoxShadow(
                          color: AppColors.secondaryColor.withValues(
                            alpha: 0.42,
                          ),
                          blurRadius: 16,
                          offset: const Offset(12, 0),
                          spreadRadius: -2,
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: AppColors.textPrimary, size: iconSize),
                  SizedBox(width: iconSpacing),
                  AppTextView.body(
                    label,
                    color: AppColors.textPrimary,
                    fontWeight: fontWeight,
                    fontSize: textSize,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
