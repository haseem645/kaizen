import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/learning_module_detail_track.dart';

class TracksBreakpointCard extends StatelessWidget {
  const TracksBreakpointCard({super.key, required this.track});

  final LearningTrackModuleDetail track;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.body(
            track.displayBreakPointTitle,
            color: AppColors.secondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          AppTextView.body(
            track.displayBreakPointSubtitle,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}
