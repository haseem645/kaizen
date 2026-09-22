import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_text_view.dart';
import 'fast_circular_progress.dart';

class AppAiGenerateButton extends StatelessWidget {
  const AppAiGenerateButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.expand = false,
    this.showOutline = false,
    this.minHeight,
    this.textSize,
    this.maxLines = 1,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLoading;
  final bool expand;
  final bool showOutline;
  final double? minHeight;
  final double? textSize;
  final int? maxLines;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final isInteractive = isEnabled && !isLoading && onTap != null;

    return Padding(
      // Keep the glow inside the surrounding scroll view or page clip.
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isInteractive
              ? [
                  BoxShadow(
                    color: AppColors.purple1.withValues(alpha: 0.55),
                    blurRadius: 8,
                    spreadRadius: -1,
                    offset: const Offset(-2, 0),
                  ),
                  BoxShadow(
                    color: AppColors.secondaryColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: -1,
                    offset: const Offset(2, 0),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: SizedBox(
          width: expand ? double.infinity : null,
          child: TextButton.icon(
            onPressed: isInteractive ? onTap : null,
            clipBehavior: Clip.antiAlias,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
              foregroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.secondaryColor.withValues(alpha: 0.5),
              disabledForegroundColor: AppColors.textSecondary,
              minimumSize: Size(0, minHeight ?? 34),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: showOutline && isInteractive
                  ? BorderSide(color: AppColors.lightPurple1.withValues(alpha: 0.7))
                  : BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: isLoading
                ? FastCircularProgressIndicator(width: 16, height: 16)
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: AppTextView.body2(
              label,
              fontSize: textSize ?? 13,
              fontWeight: fontWeight,
              maxLines: maxLines,
              overflow: maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
