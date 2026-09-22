import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../domain/entities/training_library_module.dart';
import '../controllers/training_library_detail_controller.dart';

Future<bool?> showTrainingLibraryLessonDeleteDialog(
  BuildContext context, {
  required TrainingLibraryLesson lesson,
  required TrainingLibraryDetailController controller,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ListenableBuilder(
      listenable: controller,
      builder: (context, _) => PopScope(
        canPop: !controller.isDeletingLesson,
        child: AppConfirmationDialog(
          title: AppStrings.trainingLibraryDeleteLessonTitle,
          description: AppStrings.trainingDeleteModuleDescription(
            TrainingLibraryDetailController.displayLessonSelectionTitle(lesson),
          ),
          confirmText: AppStrings.trainingDeleteModuleAction,
          cancelText: AppStrings.trainingCancel,
          isConfirmLoading: controller.isDeletingLesson,
          onCancelCallback: () async => Navigator.of(context).pop(),
          onConfirmCallback: () async {
            final didDelete = await controller.deleteLesson(lesson.id);
            if (context.mounted) {
              Navigator.of(context).pop(didDelete);
            }
          },
        ),
      ),
    ),
  );
}
