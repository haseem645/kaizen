import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_view.dart';

class ComplianceEmptyState extends StatelessWidget {
  const ComplianceEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AppTextView.body(
        message,
        textAlign: TextAlign.center,
        color: AppColors.textSecondary,
      ),
    );
  }
}
