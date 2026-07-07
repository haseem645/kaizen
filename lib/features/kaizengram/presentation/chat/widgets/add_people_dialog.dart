import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../chat_strings.dart';
import '../providers/kaizengram_chat_controller.dart';

class AddPeopleDialog extends StatefulWidget {
  const AddPeopleDialog({super.key, required this.controller});

  final KaizengramChatController controller;

  @override
  State<AddPeopleDialog> createState() => _AddPeopleDialogState();
}

class _AddPeopleDialogState extends State<AddPeopleDialog> {
  late final TextEditingController _emailController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.sizeOf(context).width * 0.96;

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: AppTextView.body1(
        KaizengramChatStrings.addPersonTitle(
          widget.controller.activeChannelName ?? '',
        ),
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      content: SizedBox(
        width: dialogWidth,
        child: TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: KaizengramChatStrings.addPeopleEmailLabel,
            hintText: KaizengramChatStrings.addPeopleEmailHint,
            errorText: _errorText,
            filled: true,
            fillColor: const Color(0xFF24283D),
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red1),
            ),
          ),
          onChanged: (_) {
            if (_errorText == null) {
              return;
            }
            setState(() => _errorText = null);
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AppTextView.body2(
            KaizengramChatStrings.actionCancel,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(
          width: 88,
          child: AppButton(
            text: KaizengramChatStrings.addPeopleConfirm,
            onPressed: _handleAdd,
            minimumHeight: 42,
            borderRadius: 12,
            textSize: 14,
          ),
        ),
      ],
    );
  }

  void _handleAdd() {
    final validation = widget.controller.validateUserEmailForCurrentChannel(
      _emailController.text,
    );
    if (validation != null) {
      setState(() => _errorText = validation);
      return;
    }

    Navigator.of(context).pop(_emailController.text.trim().toLowerCase());
  }
}
