import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_gradient_action_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../providers/questions_feedback_controller.dart';
import '../questions_feedback_overlay_visibility.dart';

class FeedbackPostCreateSheet extends StatelessWidget {
  const FeedbackPostCreateSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final controller = context.read<QuestionsFeedbackController>();
    QuestionsFeedbackOverlayVisibility.setCreateSheetOpen(true);

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            ChangeNotifierProvider<QuestionsFeedbackController>.value(
              value: controller,
              child: const FeedbackPostCreateSheet(),
            ),
      );
    } finally {
      QuestionsFeedbackOverlayVisibility.setCreateSheetOpen(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<QuestionsFeedbackController>();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 1.9,
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const AppTextView.title1(
                AppStrings.questionsFeedbackCreatePostTitle,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
              const SizedBox(height: 18),
              _CreatePostTextField(
                label: AppStrings.questionsFeedbackPostTitleLabel,
                hintText: AppStrings.questionsFeedbackPostTitleHint,
                controller: controller.createTitleController,
                errorText: controller.createTitleError == null
                    ? null
                    : AppStrings.questionsFeedbackTitleRequired,
                enabled: !controller.isCreatingPost,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _CreatePostTextField(
                label: AppStrings.questionsFeedbackDescriptionLabel,
                hintText: AppStrings.questionsFeedbackDescriptionHint,
                controller: controller.createDescriptionController,
                errorText: controller.createDescriptionError == null
                    ? null
                    : AppStrings.questionsFeedbackDescriptionRequired,
                enabled: !controller.isCreatingPost,
                minLines: 4,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                attachmentCount: controller.createAttachments.length,
                attachmentOnTap: controller.canAddImageAttachments
                    ? controller.pickImageAttachments
                    : null,
              ),
              if (controller.createAttachments.isNotEmpty) ...[
                const SizedBox(height: 20),
                _AttachmentPreviewStrip(controller: controller),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: AppGradientActionButton(
                  label: AppStrings.questionsFeedbackCreatePostAction,
                  icon: Icons.send_rounded,
                  iconSize: 18,
                  textSize: 14,
                  minHeight: 44,
                  borderRadius: 10,
                  isLoading: controller.isCreatingPost,
                  onTap: controller.isCreatingPost
                      ? null
                      : () => _submit(context, controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    QuestionsFeedbackController controller,
  ) async {
    final result = await controller.createPost();
    if (!context.mounted) {
      return;
    }

    if (result == FeedbackPostCreateResult.created) {
      Navigator.of(context).pop();
      return;
    }

    if (result == FeedbackPostCreateResult.failed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(AppStrings.questionsFeedbackCreatePostFailed),
          ),
        );
    }
  }
}

class _CreatePostTextField extends StatelessWidget {
  const _CreatePostTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.enabled,
    this.errorText,
    this.textInputAction,
    this.minLines = 1,
    this.maxLines = 1,
    this.attachmentCount,
    this.attachmentOnTap,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final TextInputAction? textInputAction;
  final int minLines;
  final int maxLines;
  final int? attachmentCount;
  final Future<void> Function()? attachmentOnTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextView.body(
          label,
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            TextField(
              controller: controller,
              enabled: enabled,
              minLines: minLines,
              maxLines: maxLines,
              textInputAction: textInputAction,
              cursorColor: AppColors.textPrimary,
              cursorHeight: 16,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                errorText: errorText,
                filled: true,
                fillColor: AppColors.hex252a40,
                isDense: true,
                contentPadding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  attachmentCount == null ? 12 : 82,
                  18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.fieldBorder.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.secondaryColor),
                ),
              ),
            ),
            if (attachmentCount != null)
              Positioned(
                right: 38,
                bottom: errorText == null ? 12 : 36,
                child: AppTextView.body(
                  AppStrings.questionsFeedbackImageAttachmentCount(
                    attachmentCount!,
                    QuestionsFeedbackController.maxImageAttachments,
                  ),
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            if (attachmentCount != null)
              Positioned(
                right: 6,
                bottom: errorText == null ? 6 : 30,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: enabled ? attachmentOnTap : null,
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      color: AppColors.secondaryColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _AttachmentPreviewStrip extends StatelessWidget {
  const _AttachmentPreviewStrip({required this.controller});

  final QuestionsFeedbackController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.createAttachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _AttachmentThumbnail(
          bytes: controller.createAttachments[index].bytes,
          onRemove: controller.isCreatingPost
              ? null
              : () => controller.removeImageAttachment(index),
        ),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({required this.bytes, this.onRemove});

  final Uint8List bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, width: 68, height: 68, fit: BoxFit.cover),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Material(
            color: AppColors.secondaryColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textPrimary,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
