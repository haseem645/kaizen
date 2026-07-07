import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_confirmation_dialog.dart';
import '../chat_strings.dart';
import '../providers/kaizengram_chat_controller.dart';

class RemoveUserConfirmationDialog extends StatelessWidget {
  const RemoveUserConfirmationDialog({super.key, required this.user});

  final KaizengramChatUser user;

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      title: KaizengramChatStrings.removeUserTitle(user.name),
      description: KaizengramChatStrings.removeUserDescription(user.email),
      confirmText: KaizengramChatStrings.actionRemove,
      cancelText: KaizengramChatStrings.actionCancel,
      onConfirmCallback: () async {
        Navigator.of(context).pop(true);
      },
      onCancelCallback: () async {
        Navigator.of(context).pop(false);
      },
    );
  }
}
