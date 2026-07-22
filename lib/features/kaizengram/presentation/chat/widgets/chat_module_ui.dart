import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_text_view.dart';

const Color kaizengramChatScreenSurfaceColor = Color(0xFF111317);
const Color kaizengramChatCardSurfaceColor = Color(0xFF1B1E27);

class KaizengramChatSheetHandle extends StatelessWidget {
  const KaizengramChatSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class KaizengramChatPrimaryButton extends StatelessWidget {
  const KaizengramChatPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onTap == null,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: AppTextView.body3(
              label,
              color: const Color(0xFF0B1520),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class KaizengramChatSecondaryButton extends StatelessWidget {
  const KaizengramChatSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onTap == null,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.10),
              ),
            ),
            alignment: Alignment.center,
            child: AppTextView.body3(
              label,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class KaizengramChatInputShell extends StatelessWidget {
  const KaizengramChatInputShell({
    super.key,
    required this.child,
    this.borderColor,
  });

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kaizengramChatCardSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: child,
    );
  }
}
