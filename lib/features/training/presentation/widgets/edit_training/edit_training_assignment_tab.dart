part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _AssignmentTabContent extends StatelessWidget {
  const _AssignmentTabContent({
    required this.isLoading,
    required this.hasResolvedAssignment,
    required this.canEditAssignment,
    required this.canSaveAssignment,
    required this.isSavingAssignment,
    required this.hasSavedAssignment,
    required this.titleController,
    required this.descriptionController,
    required this.onSaveTap,
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
  final bool hasResolvedAssignment;
  final bool canEditAssignment;
  final bool canSaveAssignment;
  final bool isSavingAssignment;
  final bool hasSavedAssignment;
  final TextEditingController titleController;
  final TrainingRichTextEditingController descriptionController;
  final Future<bool> Function() onSaveTap;
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
    final hasVisibleContent =
        titleController.text.trim().isNotEmpty || descriptionController.text.trim().isNotEmpty;
    if (!canEditAssignment && !hasVisibleContent) {
      return _AssignmentPlaceholder(isLoading: isLoading);
    }

    return _buildContent();
  }

  Widget _buildContent() {
    final isResolvingAssignmentState = canEditAssignment && !hasResolvedAssignment;
    final hasDescriptionContent = descriptionController.text.trim().isNotEmpty;
    final isBusy = isLoading || isSavingAssignment || isResolvingAssignmentState;

    return TrainingAssignmentLayout(
      header: _buildTitleSection(isResolvingAssignmentState),
      body: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Expanded(
              child: isResolvingAssignmentState || (isLoading && !hasDescriptionContent)
                  ? const Center(
                      child: FastCircularProgressIndicator(color: AppColors.secondaryColor),
                    )
                  : _TrainingEditableTextCard(
                      controller: descriptionController,
                      scrollPhysics: const AlwaysScrollableScrollPhysics(),
                      hintText: AppStrings.trainingAssignmentDescriptionHint,
                      minLines: 10,
                      maxLines: 18,
                      expands: true,
                      readOnly: !canEditAssignment || isBusy,
                      wrapWithCard: false,
                      textColor: AppColors.mainBg,
                      hintColor: AppColors.trainingUploadMuted,
                      padding: const EdgeInsets.all(16),
                    ),
            ),
            if (canEditAssignment && !isResolvingAssignmentState)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: TextFieldTapRegion(
                  child: _TrainingFormattingToolbar(
                    controller: descriptionController,
                    isSaving: isBusy,
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
    );
  }

  Widget _buildTitleSection(bool isResolvingAssignmentState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canEditAssignment) ...[
          Row(
            children: [
              Expanded(
                child: AppTextView.body1(
                  hasSavedAssignment
                      ? AppStrings.trainingEditAction
                      : AppStrings.trainingLibraryCreate,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _GradientTrainingActionButton(
                      label: hasSavedAssignment
                          ? AppStrings.trainingSaveAction
                          : AppStrings.trainingCreateAssignment,
                      icon: hasSavedAssignment ? null : Icons.assignment_rounded,
                      isEnabled: canSaveAssignment,
                      isLoading: isSavingAssignment || isResolvingAssignmentState,
                      showLoaderInIconSlot: true,
                      verticalPadding: 8,
                      onTap: canSaveAssignment ? () => unawaited(onSaveTap()) : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const _TrainingSectionHeader(title: AppStrings.trainingLessonTitle),
        const SizedBox(height: 8),
        _TrainingSingleLineInputCard(
          controller: titleController,
          hintText: AppStrings.trainingAssignmentTitleHint,
          readOnly: !canEditAssignment || isSavingAssignment || isResolvingAssignmentState,
        ),
        const SizedBox(height: 18),
        const _TrainingSectionHeader(title: AppStrings.trainingAssignmentDescriptionLabel),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AssignmentPlaceholder extends StatelessWidget {
  const _AssignmentPlaceholder({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const FastCircularProgressIndicator(color: AppColors.secondaryColor)
              : const AppTextView.body3(
                  AppStrings.trainingNoAssignmentAvailable,
                  color: AppColors.mainBg,
                  textAlign: TextAlign.center,
                  height: 1.55,
                ),
        ),
      ),
    );
  }
}
