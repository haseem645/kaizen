import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';

class SeatProfileDescriptionDialog extends StatelessWidget {
  const SeatProfileDescriptionDialog({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextView.body1(
              title,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: AppTextView.body(description, color: AppColors.textPrimary, height: 1.45),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(text: AppStrings.done, onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}
