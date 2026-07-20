import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_confirmation_dialog.dart';
import '../providers/kaizengram_chat_controller.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';

class RemoveUserConfirmationDialog extends StatelessWidget {
  const RemoveUserConfirmationDialog({super.key, required this.user});

  final KaizengramChatUser user;

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      title: AppStrings.removeUserTitle(user.name),
      description: AppStrings.removeUserDescription(user.email),
      confirmText: AppStrings.actionRemove,
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
