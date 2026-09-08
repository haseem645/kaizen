import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../domain/entities/training_library_module.dart';
import '../controllers/training_library_lesson_visibility_controller.dart';
import 'training_library_selection_sheet.dart';

Future<void> showTrainingLibraryLessonVisibilitySheet(
  BuildContext context, {
  required TrainingLibraryLesson lesson,
  required TrainingLibraryLessonVisibilityController controller,
  required Future<bool> Function(bool value) onApply,
}) async {
  controller.clearError(lesson.id);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isUpdating = controller.isUpdatingLesson(lesson.id);
        final selectedValue = controller.isLessonPubliclyAvailable(lesson);
        final pendingValue = controller.pendingVisibilityForLesson(lesson.id);
        return TrainingLibrarySelectionSheet(
          isBusy: isUpdating,
          heightFactor: 0.5,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            children: [
              TrainingLibrarySelectionHeading(
                title: AppStrings.trainingEditFieldTitle(AppStrings.trainingVisibilityLabel),
                centerTitle: true,
                onClose: isUpdating ? null : () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              const AppTextView.body3(
                AppStrings.trainingLibraryVisibilitySheetDescription,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              const SizedBox(height: 12),
              TrainingLibrarySelectionError(message: controller.errorForLesson(lesson.id)),
              for (final value in [true, false])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: ListTile(
                    selected: value == selectedValue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: value == (pendingValue ?? selectedValue)
                            ? AppColors.secondaryColor
                            : Colors.transparent,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    minVerticalPadding: 10,
                    leading: Icon(
                      value ? Icons.public_rounded : Icons.lock_outline_rounded,
                      color: AppColors.secondaryColor,
                    ),
                    title: AppTextView.body2(
                      value
                          ? AppStrings.trainingLibraryAllVisibility
                          : AppStrings.trainingLibraryRestrictedVisibility,
                      color: AppColors.textPrimary,
                    ),
                    subtitle: AppTextView.body3(
                      value
                          ? AppStrings.trainingVisibilityAllDescription
                          : AppStrings.trainingVisibilityUplineDescription,
                      color: AppColors.textSecondary,
                    ),
                    trailing: SizedBox(
                      width: 24,
                      height: 24,
                      child: isUpdating && pendingValue == value
                          ? FastCircularProgressIndicator(width: 18, height: 18)
                          : Icon(
                              value == selectedValue
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: value == selectedValue
                                  ? AppColors.secondaryColor
                                  : AppColors.textSecondary,
                            ),
                    ),
                    onTap: isUpdating
                        ? null
                        : () async {
                            final succeeded = await onApply(value);
                            if (succeeded && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
