import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_view.dart';

class TrainingLibraryStatusState extends StatelessWidget {
  const TrainingLibraryStatusState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onActionTap,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            AppTextView.body(message, color: AppColors.textSecondary, textAlign: TextAlign.center),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onActionTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryColor,
                  side: const BorderSide(color: AppColors.secondaryColor),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
