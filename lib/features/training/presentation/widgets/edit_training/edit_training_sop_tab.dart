part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

//////
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
    required this.onDoneTap,
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
  final VoidCallback onDoneTap;
  final VoidCallback? onBoldTap;
  final VoidCallback? onItalicTap;
  final VoidCallback? onUnderlineTap;
  final VoidCallback? onBulletListTap;
  final VoidCallback? onNumberedListTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onHeadingTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = _buildContent();
        if (constraints.hasBoundedHeight) {
          return content;
        }

        // Embedded sections and incoming swipe previews have no height constraint.
        return SizedBox(height: MediaQuery.sizeOf(context).height * 0.65, child: content);
      },
    );
  }

  Widget _buildContent() {
    final hasEditorContent = documentController.text.trim().isNotEmpty;
    final showProgress = isSavingDocument || isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: AppTextView.body1(
                AppStrings.trainingCreateSop,
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isSavingDocument || (isLoading && hasEditorContent))
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: FastCircularProgressIndicator(width: 16, height: 16),
              ),
            if (canManageGeneration)
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _TrainingCreateWithAiButton(
                    isEnabled: canGenerate,
                    isLoading: isGeneratingSop,
                    onTap: onGenerateSopTap,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                Expanded(
                  child: isLoading && !hasEditorContent
                      ? const Center(
                          child: FastCircularProgressIndicator(color: AppColors.secondaryColor),
                        )
                      : _TrainingEditableTextCard(
                          controller: documentController,
                          hintText: AppStrings.trainingSopHint,
                          minLines: 10,
                          maxLines: 18,
                          expands: true,
                          readOnly: !canEditDocument,
                          wrapWithCard: false,
                          textColor: AppColors.mainBg,
                          hintColor: AppColors.trainingUploadMuted,
                          padding: const EdgeInsets.all(16),
                        ),
                ),
                if (canEditDocument)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    child: TextFieldTapRegion(
                      child: _TrainingFormattingToolbar(
                        controller: documentController,
                        isSaving: showProgress,
                        onDoneTap: onDoneTap,
                        onBoldTap: onBoldTap,
                        onItalicTap: onItalicTap,
                        onUnderlineTap: onUnderlineTap,
                        onBulletListTap: onBulletListTap,
                        onNumberedListTap: onNumberedListTap,
                        onQuoteTap: onQuoteTap,
                        onHeadingTap: onHeadingTap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
