part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _SopTabContent extends StatelessWidget {
  const _SopTabContent({
    required this.isLoading,
    required this.canManageGeneration,
    required this.canGenerate,
    required this.isGeneratingSop,
    required this.canEditDocument,
    required this.isSavingDocument,
    required this.documentController,
    required this.onGenerateSopTap,
    this.onBoldTap,
    this.onItalicTap,
    this.onUnderlineTap,
    this.onBulletListTap,
    this.onNumberedListTap,
    this.onQuoteTap,
    this.onHeadingTap,
  });

  final bool isLoading;
  final bool canManageGeneration;
  final bool canGenerate;
  final bool isGeneratingSop;
  final bool canEditDocument;
  final bool isSavingDocument;
  final TrainingRichTextEditingController documentController;
  final VoidCallback onGenerateSopTap;
  final VoidCallback? onBoldTap;
  final VoidCallback? onItalicTap;
  final VoidCallback? onUnderlineTap;
  final VoidCallback? onBulletListTap;
  final VoidCallback? onNumberedListTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onHeadingTap;

  @override
  Widget build(BuildContext context) {
    final hasEditorContent = documentController.text.trim().isNotEmpty;
    final showToolbarProgressIndicator =
        isSavingDocument || (isLoading && hasEditorContent && !isGeneratingSop);
    final sopContent = isLoading && !hasEditorContent
        ? SizedBox(
            height: 180,
            child: Center(child: FastCircularProgressIndicator()),
          )
        : _TrainingEditableTextCard(
            controller: documentController,
            hintText: AppStrings.trainingSopHint,
            minLines: 10,
            maxLines: 18,
            readOnly: !canEditDocument || isSavingDocument,
            wrapWithCard: !canEditDocument,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: AppTextView.body3(
                AppStrings.trainingCreateSop,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (canManageGeneration)
              _AiGenerateButton(
                label: AppStrings.trainingGenerateWithAi,
                isEnabled: canGenerate,
                isLoading: isGeneratingSop,
                verticalPadding: 8,
                onTap: canGenerate ? onGenerateSopTap : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (canEditDocument)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.fieldBorder.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrainingFormattingToolbar(
                  controller: documentController,
                  isSaving: isSavingDocument,
                  showTrailingProgressIndicator: showToolbarProgressIndicator,
                  onBoldTap: onBoldTap,
                  onItalicTap: onItalicTap,
                  onUnderlineTap: onUnderlineTap,
                  onBulletListTap: onBulletListTap,
                  onNumberedListTap: onNumberedListTap,
                  onQuoteTap: onQuoteTap,
                  onHeadingTap: onHeadingTap,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: AppColors.mainBg,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                  child: sopContent,
                ),
              ],
            ),
          )
        else
          sopContent,
      ],
    );
  }
}
