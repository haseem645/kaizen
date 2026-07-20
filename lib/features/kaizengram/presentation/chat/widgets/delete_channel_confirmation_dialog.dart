import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_confirmation_dialog.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';

class DeleteChannelConfirmationDialog extends StatelessWidget {
  const DeleteChannelConfirmationDialog({super.key, required this.channelName});

  final String channelName;

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      title: AppStrings.deleteChannelTitle,
      description: AppStrings.deleteChannelDescription(channelName),
      confirmText: AppStrings.actionDelete,
      cancelText: AppStrings.actionCancel,
      onConfirmCallback: () async {
        Navigator.of(context).pop(true);
      },
      onCancelCallback: () async {
        Navigator.of(context).pop(false);
      },
    );
  }
}
