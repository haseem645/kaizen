import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/background_media_upload_controller.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../routes/app_router.dart';

class TrainingVideoUploadBanner extends StatefulWidget {
  const TrainingVideoUploadBanner({super.key});

  @override
  State<TrainingVideoUploadBanner> createState() =>
      _TrainingVideoUploadBannerState();
}

class _TrainingVideoUploadBannerState extends State<TrainingVideoUploadBanner> {
  static const double _circleSize = 82;
  static const double _circleMargin = 16;

  final ValueNotifier<bool> _isBottomSheetOpenNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<Offset?> _circleOffsetNotifier = ValueNotifier<Offset?>(
    null,
  );

  @override
  void dispose() {
    _isBottomSheetOpenNotifier.dispose();
    _circleOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        BackgroundMediaUploadController.instance,
        _isBottomSheetOpenNotifier,
        _circleOffsetNotifier,
      ]),
      builder: (context, _) {
        final tasks = BackgroundMediaUploadController.instance.visibleTasks;
        if (tasks.isEmpty || _isBottomSheetOpenNotifier.value) {
          return const SizedBox.shrink();
        }

        final mediaSize = MediaQuery.sizeOf(context);
        final mediaPadding = MediaQuery.paddingOf(context);
        final defaultOffset = Offset(
          mediaSize.width - _circleSize - _circleMargin,
          mediaSize.height - mediaPadding.bottom - _circleSize - _circleMargin,
        );
        final effectiveOffset = _clampCircleOffset(
          _circleOffsetNotifier.value ?? defaultOffset,
          mediaSize: mediaSize,
          mediaPadding: mediaPadding,
        );

        return Positioned(
          left: effectiveOffset.dx,
          top: effectiveOffset.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              final nextOffset = _clampCircleOffset(
                effectiveOffset + details.delta,
                mediaSize: mediaSize,
                mediaPadding: mediaPadding,
              );
              if (_circleOffsetNotifier.value != nextOffset) {
                _circleOffsetNotifier.value = nextOffset;
              }
            },
            child: _TrainingVideoUploadProgressCircle(
              tasks: tasks,
              onTap: _showUploadsSheet,
              onDismissCompleted: _dismissCompletedTasks,
            ),
          ),
        );
      },
    );
  }

  Offset _clampCircleOffset(
    Offset offset, {
    required Size mediaSize,
    required EdgeInsets mediaPadding,
  }) {
    final minX = _circleMargin;
    final maxX = mediaSize.width - _circleSize - _circleMargin;
    final minY = mediaPadding.top + _circleMargin;
    final maxY =
        mediaSize.height - mediaPadding.bottom - _circleSize - _circleMargin;
    return Offset(
      offset.dx.clamp(minX, maxX).toDouble(),
      offset.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Future<void> _showUploadsSheet() async {
    if (_isBottomSheetOpenNotifier.value) {
      return;
    }

    final navigatorContext = AppRouter.navigatorKey.currentContext;
    if (navigatorContext == null) {
      return;
    }

    _isBottomSheetOpenNotifier.value = true;
    try {
      await showModalBottomSheet<void>(
        context: navigatorContext,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _TrainingVideoUploadBottomSheet(),
      );
    } finally {
      _isBottomSheetOpenNotifier.value = false;
    }
  }

  void _dismissCompletedTasks() {
    final dismissibleTaskIds = BackgroundMediaUploadController
        .instance
        .visibleTasks
        .where((task) => task.canDismiss)
        .map((task) => task.taskId)
        .toList(growable: false);
    for (final taskId in dismissibleTaskIds) {
      BackgroundMediaUploadController.instance.dismissTask(taskId);
    }
  }
}

class _TrainingVideoUploadBottomSheet extends StatefulWidget {
  const _TrainingVideoUploadBottomSheet();

  @override
  State<_TrainingVideoUploadBottomSheet> createState() =>
      _TrainingVideoUploadBottomSheetState();
}

class _TrainingVideoUploadBottomSheetState
    extends State<_TrainingVideoUploadBottomSheet> {
  @override
  void initState() {
    super.initState();
    BackgroundMediaUploadController.instance.addListener(_handleTasksChanged);
  }

  @override
  void dispose() {
    BackgroundMediaUploadController.instance.removeListener(
      _handleTasksChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: BackgroundMediaUploadController.instance,
      builder: (context, _) {
        final tasks = BackgroundMediaUploadController.instance.visibleTasks;
        if (tasks.isEmpty) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          bottom: false,
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark3,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBorder.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextView.body1(
                          _buildTitle(tasks),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) =>
                          _TrainingVideoUploadBannerCard(task: tasks[index]),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTasksChanged() {
    if (!mounted ||
        BackgroundMediaUploadController.instance.visibleTasks.isNotEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  String _buildTitle(List<BackgroundMediaUploadTask> tasks) {
    final hasOnlyActiveTasks = tasks.every((task) => task.isActive);
    if (hasOnlyActiveTasks) {
      return AppStrings.backgroundUploadsUploadingCount(tasks.length);
    }

    return AppStrings.backgroundUploadsCount(tasks.length);
  }
}

class _TrainingVideoUploadProgressCircle extends StatelessWidget {
  const _TrainingVideoUploadProgressCircle({
    required this.tasks,
    required this.onTap,
    required this.onDismissCompleted,
  });

  final List<BackgroundMediaUploadTask> tasks;
  final VoidCallback onTap;
  final VoidCallback onDismissCompleted;

  @override
  Widget build(BuildContext context) {
    final failedCount = tasks.where((task) => task.isFailed).length;
    final effectiveTotalCount = _resolveEffectiveTotalCount();
    final uploadedCount = tasks.where((task) => task.isCompleted).length;
    final overallProgress = _resolveOverallProgress();
    final progressPercent = (overallProgress * 100).round();
    final showDismissAction =
        progressPercent >= 100 && tasks.every((task) => task.canDismiss);

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.textPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: overallProgress),
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: AppColors.fieldBorder.withValues(
                              alpha: 0.18,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.secondaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTextView.body2(
                          '$uploadedCount/$effectiveTotalCount',
                          color: AppColors.mainBg,
                          fontSize: effectiveTotalCount >= 10 ? 12 : 15,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 2),
                        AppTextView.body4(
                          '$progressPercent%',
                          color: AppColors.secondaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                        if (failedCount > 0) ...[
                          const SizedBox(height: 1),
                          AppTextView.body4(
                            AppStrings.backgroundUploadsFailedCount(
                              failedCount,
                            ),
                            color: AppColors.red1,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showDismissAction)
            Positioned(
              top: -4,
              right: -4,
              child: Material(
                color: AppColors.red1,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onDismissCompleted,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _resolveOverallProgress() {
    if (tasks.isEmpty) {
      return 0;
    }

    final effectiveTotalCount = _resolveEffectiveTotalCount();
    if (effectiveTotalCount <= 0) {
      return 0;
    }

    final completedCount = tasks.where((task) => task.isCompleted).length;
    final activeProgressTotal = tasks
        .where((task) => task.isActive)
        .fold<double>(0, (sum, task) => sum + _resolveTaskProgress(task));
    return ((completedCount + activeProgressTotal) / effectiveTotalCount)
        .clamp(0, 1)
        .toDouble();
  }

  int _resolveEffectiveTotalCount() {
    return tasks.where((task) => !task.isFailed).length;
  }

  double _resolveTaskProgress(BackgroundMediaUploadTask task) {
    switch (task.status) {
      case BackgroundMediaUploadStatus.finalizing:
        return 1;
      case BackgroundMediaUploadStatus.uploading:
      case BackgroundMediaUploadStatus.failed:
        return task.uploadProgress.clamp(0, 1).toDouble();
      case BackgroundMediaUploadStatus.completed:
      case BackgroundMediaUploadStatus.idle:
      case BackgroundMediaUploadStatus.preparing:
        return 0;
    }
  }
}

class _TrainingVideoUploadBannerCard extends StatelessWidget {
  const _TrainingVideoUploadBannerCard({required this.task});

  final BackgroundMediaUploadTask task;

  @override
  Widget build(BuildContext context) {
    final accentColor = _resolveAccentColor(task.status);
    final actionIcon = task.canCancel || task.canDismiss
        ? Icons.close_rounded
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark3,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _resolveIcon(task.status),
                  color: accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextView.body3(
                      task.bannerTitle,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.bannerMessage.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      AppTextView.body4(
                        task.bannerMessage,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (task.bannerDetail != null) ...[
                      const SizedBox(height: 3),
                      AppTextView.body4(
                        task.bannerDetail!,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (actionIcon != null)
                InkWell(
                  onTap: task.canCancel
                      ? () {
                          BackgroundMediaUploadController.instance.cancelUpload(
                            task.taskId,
                          );
                        }
                      : task.canDismiss
                      ? () {
                          BackgroundMediaUploadController.instance.dismissTask(
                            task.taskId,
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(actionIcon, size: 18, color: accentColor),
                  ),
                ),
            ],
          ),
          if (task.isActive || task.isCompleted) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: task.progressValue,
                backgroundColor: accentColor.withValues(alpha: 0.16),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _resolveIcon(BackgroundMediaUploadStatus status) {
    switch (status) {
      case BackgroundMediaUploadStatus.completed:
        return Icons.check_circle_rounded;
      case BackgroundMediaUploadStatus.failed:
        return Icons.error_outline_rounded;
      case BackgroundMediaUploadStatus.idle:
      case BackgroundMediaUploadStatus.preparing:
      case BackgroundMediaUploadStatus.uploading:
      case BackgroundMediaUploadStatus.finalizing:
        return Icons.upload_rounded;
    }
  }

  Color _resolveAccentColor(BackgroundMediaUploadStatus status) {
    switch (status) {
      case BackgroundMediaUploadStatus.completed:
        return AppColors.green1;
      case BackgroundMediaUploadStatus.failed:
        return AppColors.red1;
      case BackgroundMediaUploadStatus.idle:
      case BackgroundMediaUploadStatus.preparing:
      case BackgroundMediaUploadStatus.uploading:
      case BackgroundMediaUploadStatus.finalizing:
        return AppColors.secondaryColor;
    }
  }
}
