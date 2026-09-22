import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/training_library_module.dart';
import '../controllers/training_library_detail_controller.dart';
import 'training_library_selection_sheet.dart';

Future<TrainingLibraryLesson?> showTrainingLibraryLessonSelectionSheet(
  BuildContext context, {
  required List<TrainingLibraryLesson> lessons,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<TrainingLibraryLesson>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TrainingLibrarySelectionSheet(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TrainingLibrarySelectionHeading(
              title: AppStrings.trainingLibrarySelectLesson,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: lessons.isEmpty
                ? const Center(
                    child: AppTextView.body2(
                      AppStrings.trainingLibraryNoMatchingLessons,
                      color: AppColors.textSecondary,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      return ListTile(
                        minTileHeight: 44,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: AppTextView.body2(
                          TrainingLibraryDetailController.displayLessonSelectionTitle(lesson),
                          color: AppColors.textPrimary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.grey1),
                        onTap: () => Navigator.of(context).pop(lesson),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
