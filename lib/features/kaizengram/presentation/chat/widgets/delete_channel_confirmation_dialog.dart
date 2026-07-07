import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_confirmation_dialog.dart';
import '../chat_strings.dart';

class DeleteChannelConfirmationDialog extends StatelessWidget {
  const DeleteChannelConfirmationDialog({super.key, required this.channelName});

  final String channelName;

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      title: KaizengramChatStrings.deleteChannelTitle,
      description: KaizengramChatStrings.deleteChannelDescription(channelName),
      confirmText: KaizengramChatStrings.actionDelete,
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
