part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _AssignmentTabContent extends StatelessWidget {
  const _AssignmentTabContent({
    required this.isLoading,
    required this.hasResolvedAssignment,
    required this.canEditAssignment,
    required this.isSavingAssignment,
    required this.hasSavedAssignment,
    required this.titleController,
    required this.descriptionController,
    required this.onSaveTap,
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
  final bool isSavingAssignment;
  final bool hasSavedAssignment;
  final TextEditingController titleController;
  final TrainingRichTextEditingController descriptionController;
  final Future<bool> Function() onSaveTap;
  final VoidCallback? onBoldTap;
  final VoidCallback? onItalicTap;
  final VoidCallback? onUnderlineTap;
  final VoidCallback? onBulletListTap;
  final VoidCallback? onNumberedListTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onHeadingTap;

  @override
  Widget build(BuildContext context) {
    final hasTitleContent = titleController.text.trim().isNotEmpty;
    final hasDescriptionContent = descriptionController.text.trim().isNotEmpty;
    final hasVisibleContent = hasTitleContent || hasDescriptionContent;
    final isResolvingAssignmentState =
        canEditAssignment && !hasResolvedAssignment;
    final actionHeader = hasSavedAssignment
        ? AppStrings.trainingEditAction
        : AppStrings.trainingLibraryCreate;
    final actionLabel = hasSavedAssignment
        ? AppStrings.trainingSaveAction
        : AppStrings.trainingCreateAssignment;
    final actionIcon = hasSavedAssignment
        ? Icons.save_rounded
        : Icons.assignment_rounded;
    final descriptionContent = isLoading && !hasDescriptionContent
        ? SizedBox(
            height: 180,
            child: Center(child: FastCircularProgressIndicator()),
          )
        : _TrainingEditableTextCard(
            controller: descriptionController,
            hintText: AppStrings.trainingAssignmentDescriptionHint,
            minLines: 10,
            maxLines: 18,
            readOnly: !canEditAssignment || isSavingAssignment,
            wrapWithCard: !canEditAssignment,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          );

    if (!canEditAssignment && !hasVisibleContent) {
      if (isLoading) {
        return SizedBox(
          height: 180,
          child: Center(child: FastCircularProgressIndicator()),
        );
      }

      return const _ContentMessage(
        message: AppStrings.trainingNoAssignmentAvailable,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canEditAssignment) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppTextView.body3(
                  actionHeader,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isResolvingAssignmentState)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: FastCircularProgressIndicator(width: 14, height: 14),
                )
              else
                _GradientTrainingActionButton(
                  label: actionLabel,
                  icon: actionIcon,
                  isEnabled: !isLoading,
                  isLoading: isSavingAssignment,
                  showLoaderInIconSlot: true,
                  verticalPadding: 8,
                  onTap: !isLoading
                      ? () {
                          unawaited(onSaveTap());
                        }
                      : null,
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
          readOnly:
              !canEditAssignment ||
              isSavingAssignment ||
              isResolvingAssignmentState,
        ),
        const SizedBox(height: 18),
        const _TrainingSectionHeader(
          title: AppStrings.trainingAssignmentDescriptionLabel,
        ),
        const SizedBox(height: 8),
        if (canEditAssignment && !isResolvingAssignmentState)
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
                  controller: descriptionController,
                  isSaving: isSavingAssignment,
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
                  child: descriptionContent,
                ),
              ],
            ),
          )
        else if (isResolvingAssignmentState)
          SizedBox(
            height: 180,
            child: Center(child: FastCircularProgressIndicator()),
          )
        else
          descriptionContent,
      ],
    );
  }
}
