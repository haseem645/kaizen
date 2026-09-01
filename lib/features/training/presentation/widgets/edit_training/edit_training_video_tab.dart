part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _VideoTabContent extends StatelessWidget {
  const _VideoTabContent({
    required this.detail,
    required this.localVideoPath,
    required this.isReadOnly,
    required this.isUploadEnabled,
    required this.isPickingVideo,
    required this.isFinalizingVideoSetup,
    required this.isUploadingVideo,
    required this.isDeletingVideo,
    required this.isUploadingThumbnail,
    required this.canEditSummary,
    required this.isEditingSummary,
    required this.isSavingSummary,
    required this.summaryController,
    this.onUploadVideoTap,
    this.onDeleteVideoTap,
    this.onUpdateThumbnailTap,
    this.onEditSummaryTap,
    this.onCancelSummaryTap,
    this.onSaveSummaryTap,
  });

  final SeatDescriptionTrainingModuleDetail? detail;
  final String? localVideoPath;
  final bool isReadOnly;
  final bool isUploadEnabled;
  final bool isPickingVideo;
  final bool isFinalizingVideoSetup;
  final bool isUploadingVideo;
  final bool isDeletingVideo;
  final bool isUploadingThumbnail;
  final bool canEditSummary;
  final bool isEditingSummary;
  final bool isSavingSummary;
  final TextEditingController summaryController;
  final VoidCallback? onUploadVideoTap;
  final VoidCallback? onDeleteVideoTap;
  final VoidCallback? onUpdateThumbnailTap;
  final VoidCallback? onEditSummaryTap;
  final VoidCallback? onCancelSummaryTap;
  final Future<bool> Function()? onSaveSummaryTap;

  @override
  Widget build(BuildContext context) {
    final video = detail?.trainingVideo;
    final videoUrl = video?.url?.trim();
    final summary = detail?.description?.trim();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final canRevealVideo = hasVideo && !isFinalizingVideoSetup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canRevealVideo)
          ComplianceVideoPlayer(
            key: ValueKey<String>(videoUrl),
            videoUrl: videoUrl,
            localVideoPath: localVideoPath,
            title: detail?.title ?? '',
            thumbnailLink: detail?.previewThumbnailLink,
            fillBounds: true,
            topRightActions: !isReadOnly
                ? [
                    _TrainingVideoActionMenu(
                      isLoading: isDeletingVideo || isUploadingThumbnail,
                      onSelected: (action) {
                        if (action == _TrainingVideoMenuAction.delete) {
                          onDeleteVideoTap?.call();
                          return;
                        }

                        onUpdateThumbnailTap?.call();
                      },
                    ),
                  ]
                : const <Widget>[],
          )
        else if (isReadOnly)
          const _ContentMessage(message: AppStrings.trainingNoVideoAvailable)
        else
          _TrainingVideoEmptyState(
            isEnabled: isUploadEnabled && !isFinalizingVideoSetup,
            isPickingVideo: isPickingVideo || isFinalizingVideoSetup,
            isUploading: isUploadingVideo,
            isFinalizingSetup: isFinalizingVideoSetup,
            isLoading:
                isUploadingVideo ||
                isDeletingVideo ||
                isPickingVideo ||
                isFinalizingVideoSetup,
            onTap: onUploadVideoTap,
          ),
        if (canRevealVideo) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: _TrainingSectionHeader(
                  title: AppStrings.trainingSummaryLabel,
                ),
              ),
              if (canEditSummary && isSavingSummary)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: FastCircularProgressIndicator(width: 12, height: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),
          canEditSummary
              ? _TrainingOutlinedTextField(
                  controller: summaryController,
                  hintText: AppStrings.trainingSummaryHint,
                  minLines: 4,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  textHeight: 1.65,
                  hintFontWeight: FontWeight.w400,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                )
              : _TrainingDisplayCard(
                  child: AppTextView.body3(
                    summary != null && summary.isNotEmpty
                        ? CustomFunctions.stripHtmlTags(summary)
                        : AppStrings.trainingNoSummaryAvailable,
                    color: AppColors.textPrimary,
                    height: 1.65,
                  ),
                ),
        ],
      ],
    );
  }
}

class _NewLessonTitleField extends StatelessWidget {
  const _NewLessonTitleField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppTextView.body3(
          AppStrings.trainingLessonTitle,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (canSubmit) {
                      onSubmit();
                    }
                  },
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: AppStrings.trainingLessonTitleHint,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: canSubmit ? onSubmit : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: canSubmit
                        ? AppColors.secondaryColor
                        : AppColors.fieldBorder.withValues(alpha: 0.24),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isSubmitting
                        ? FastCircularProgressIndicator(width: 14, height: 14)
                        : Icon(
                            Icons.check_rounded,
                            color: canSubmit
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TrainingVideoMenuAction { delete, thumbnail }

class _TrainingVideoActionMenu extends StatelessWidget {
  const _TrainingVideoActionMenu({
    required this.isLoading,
    required this.onSelected,
  });

  final bool isLoading;
  final ValueChanged<_TrainingVideoMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: FastCircularProgressIndicator(width: 14, height: 14),
        ),
      );
    }

    return PopupMenuButton<_TrainingVideoMenuAction>(
      tooltip: AppStrings.trainingVideoMoreActions,
      color: AppColors.surfaceDark3,
      surfaceTintColor: AppColors.surfaceDark3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem<_TrainingVideoMenuAction>(
          value: _TrainingVideoMenuAction.delete,
          child: _TrainingVideoMenuItemContent(
            icon: Icons.delete_outline_rounded,
            label: AppStrings.trainingDeleteVideoAction,
            color: AppColors.red,
          ),
        ),
        PopupMenuItem<_TrainingVideoMenuAction>(
          value: _TrainingVideoMenuAction.thumbnail,
          child: _TrainingVideoMenuItemContent(
            icon: Icons.image_outlined,
            label: AppStrings.trainingThumbnailAction,
            color: AppColors.secondaryColor,
          ),
        ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.mainBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.fieldBorder.withValues(alpha: 0.25),
          ),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}

class _TrainingVideoMenuItemContent extends StatelessWidget {
  const _TrainingVideoMenuItemContent({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        AppTextView.body3(label, color: color, fontWeight: FontWeight.w700),
      ],
    );
  }
}

class _TrainingVideoEmptyState extends StatelessWidget {
  const _TrainingVideoEmptyState({
    required this.isEnabled,
    required this.isPickingVideo,
    required this.isUploading,
    required this.isFinalizingSetup,
    required this.isLoading,
    this.onTap,
  });

  final bool isEnabled;
  final bool isPickingVideo;
  final bool isUploading;
  final bool isFinalizingSetup;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled && !isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DottedRoundedBorderPainter(
            color: isEnabled
                ? AppColors.secondaryColor.withValues(alpha: 0.75)
                : AppColors.fieldBorder.withValues(alpha: 0.38),
            radius: 14,
          ),
          child: Ink(
            width: double.infinity,
            height: 440,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isPickingVideo
                          ? FastCircularProgressIndicator(width: 20, height: 20)
                          : const Icon(
                              Icons.video_library_outlined,
                              color: AppColors.textPrimary,
                              size: 30,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextView.body(
                    isFinalizingSetup
                        ? AppStrings.trainingFinishingVideoSetup
                        : isUploading
                        ? AppStrings.trainingUploadingVideo
                        : AppStrings.trainingUploadVideo,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                  if (!isUploading && !isFinalizingSetup) ...<Widget>[
                    const SizedBox(height: 8),
                    const AppTextView.body3(
                      AppStrings.trainingUploadVideoHint,
                      color: AppColors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (isUploading || isFinalizingSetup) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: AppColors.secondaryColor.withValues(
                          alpha: 0.18,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
