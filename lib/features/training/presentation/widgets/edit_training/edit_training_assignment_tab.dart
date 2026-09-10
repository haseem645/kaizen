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
      return isLoading
          ? Center(child: FastCircularProgressIndicator())
          : const _ContentMessage(message: AppStrings.trainingNoAssignmentAvailable);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.75;
        return SizedBox(height: height, child: _buildContent(height));
      },
    );
  }

  Widget _buildContent(double availableHeight) {
    final isResolvingAssignmentState = canEditAssignment && !hasResolvedAssignment;
    final hasDescriptionContent = descriptionController.text.trim().isNotEmpty;
    final isBusy = isLoading || isSavingAssignment || isResolvingAssignmentState;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (availableHeight - 220).clamp(0.0, availableHeight).toDouble(),
            ),
            child: SingleChildScrollView(
              primary: false,
              child: _buildTitleSection(isResolvingAssignmentState),
            ),
          ),
        ),
      ],
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
                  : Builder(
                      builder: (context) => _TrainingEditableTextCard(
                        controller: descriptionController,
                        // Link text scrolling to the header so dragging reveals more editor space.
                        scrollController: PrimaryScrollController.of(context),
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
              if (isResolvingAssignmentState)
                SizedBox.square(
                  dimension: 20,
                  child: FastCircularProgressIndicator(width: 14, height: 14),
                )
              else
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _GradientTrainingActionButton(
                        label: hasSavedAssignment
                            ? AppStrings.trainingSaveAction
                            : AppStrings.trainingCreateAssignment,
                        icon: hasSavedAssignment ? Icons.save_rounded : Icons.assignment_rounded,
                        isEnabled: canSaveAssignment,
                        isLoading: isSavingAssignment,
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
