import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';

Future<bool> showTrainingOptionDeleteDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AppConfirmationDialog(
          title: AppStrings.trainingDeleteOptionTitle,
          description: AppStrings.trainingDeleteOptionDescription,
          confirmText: AppStrings.trainingDeleteQuestionAction,
          cancelText: AppStrings.trainingCancel,
          onConfirmCallback: () async => Navigator.of(dialogContext).pop(true),
          onCancelCallback: () async => Navigator.of(dialogContext).pop(false),
        ),
      ) ??
      false;
}
