import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/seat_description_training_route.dart';
import '../../domain/entities/training_library_module.dart';
import 'edit_training_screen.dart';
import 'view_training_screen.dart';

class TrainingLibraryDetailScreen extends StatefulWidget {
  const TrainingLibraryDetailScreen({super.key, required this.module});

  final TrainingLibraryModule module;

  @override
  State<TrainingLibraryDetailScreen> createState() =>
      _TrainingLibraryDetailScreenState();
}

class _TrainingLibraryDetailScreenState
    extends State<TrainingLibraryDetailScreen> {
  var _shouldRefreshOnExit = false;

  @override
  Widget build(BuildContext context) {
    final canEditModules =
        AppManager.instance.canCurrentUserManageTrainingForSeatProfile(
          seatProfileId: widget.module.seat.id,
        ) &&
        widget.module.id.trim().isNotEmpty &&
        widget.module.seat.id.trim().isNotEmpty;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBg,
        appBar: AppBar(
          backgroundColor: AppColors.mainBg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const AppTextView.title1(
            AppStrings.trainingLibraryTitle,
            color: AppColors.secondaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _TrainingLibraryHero(module: widget.module),
              const SizedBox(height: 18),
              _LibrarySummaryCard(module: widget.module),
              const SizedBox(height: 20),
              AppTextView.body1(
                AppStrings.trainingLibraryLessonsSection,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
              const SizedBox(height: 12),
              if (widget.module.lessons.isEmpty)
                const _MessageCard(
                  message: AppStrings.trainingLibraryNoLessonsFound,
                )
              else
                for (
                  var index = 0;
                  index < widget.module.lessons.length;
                  index++
                ) ...[
                  _TrainingLessonCard(
                    lesson: widget.module.lessons[index],
                    onTap: () => _openLessonViewer(
                      context,
                      widget.module.lessons[index],
                    ),
                    canEdit: canEditModules,
                    onEditTap: canEditModules
                        ? () => _openLessonEditor(
                            context,
                            widget.module.lessons[index],
                          )
                        : null,
                  ),
                  if (index != widget.module.lessons.length - 1)
                    const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    Navigator.of(context).pop(_shouldRefreshOnExit ? true : null);
  }

  Future<void> _openLessonViewer(
    BuildContext context,
    TrainingLibraryLesson lesson,
  ) async {
    final lessonId = lesson.id.trim();
    if (lessonId.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ViewTrainingScreen(
          trainingRoute: SeatDescriptionTrainingRoute(
            job: widget.module.seat.id,
            category: widget.module.category.id,
            description: widget.module.id,
            initialModuleId: lessonId,
          ),
        ),
      ),
    );
  }

  Future<void> _openLessonEditor(
    BuildContext context,
    TrainingLibraryLesson lesson,
  ) async {
    final lessonId = lesson.id.trim();
    if (lessonId.isEmpty) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EditTrainingScreen(
          trainingRoute: SeatDescriptionTrainingRoute(
            job: widget.module.seat.id,
            category: widget.module.category.id,
            description: widget.module.id,
          ),
          initialModuleId: lessonId,
          canManageTraining: AppManager.instance
              .canCurrentUserManageTrainingForSeatProfile(
                seatProfileId: widget.module.seat.id,
              ),
          useNonBlockingVideoUpload: true,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _shouldRefreshOnExit = true;
    });
  }
}

class _TrainingLibraryHero extends StatelessWidget {
  const _TrainingLibraryHero({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = CustomFunctions.resolveImageUrl(module.thumbnailLink);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: thumbnailUrl == null
            ? const _LibraryPlaceholder(icon: Icons.video_library_rounded)
            : CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _LibraryPlaceholder(
                  icon: Icons.video_library_rounded,
                ),
                errorWidget: (_, __, ___) => const _LibraryPlaceholder(
                  icon: Icons.video_library_rounded,
                ),
              ),
      ),
    );
  }
}

class _LibrarySummaryCard extends StatelessWidget {
  const _LibrarySummaryCard({required this.module});

  final TrainingLibraryModule module;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.body1(
            _displayValue(
              module.title,
              fallback: AppStrings.trainingLibraryUntitledModule,
            ),
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 10),
          _LibraryMetaRow(
            lessonsCount: module.lessonsCount,
            totalDuration: module.totalDuration,
          ),
          const SizedBox(height: 14),
          _SummaryValueRow(
            label: AppStrings.trainingLibraryDepartment,
            value: _displayValue(
              module.department.name,
              fallback: AppStrings.trainingLibraryNotAvailable,
            ),
          ),
          const SizedBox(height: 10),
          _SummaryValueRow(
            label: AppStrings.trainingLibrarySeat,
            value: _displayValue(
              module.seat.title,
              fallback: AppStrings.trainingLibraryNotAvailable,
            ),
          ),
          const SizedBox(height: 10),
          _SummaryValueRow(
            label: AppStrings.trainingLibraryCategory,
            value: _displayValue(
              module.category.title,
              fallback: AppStrings.trainingLibraryNotAvailable,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryValueRow extends StatelessWidget {
  const _SummaryValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: AppTextView.body3(
            label,
            color: AppColors.purple1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppTextView.body2(
            value,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrainingLessonCard extends StatelessWidget {
  const _TrainingLessonCard({
    required this.lesson,
    required this.onTap,
    required this.canEdit,
    this.onEditTap,
  });

  final TrainingLibraryLesson lesson;
  final VoidCallback onTap;
  final bool canEdit;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LessonThumbnail(thumbnailLink: lesson.thumbnailLink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AppTextView.body(
                                _displayValue(
                                  lesson.title,
                                  fallback:
                                      AppStrings.trainingLibraryUntitledModule,
                                ),
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (canEdit && onEditTap != null) ...[
                              const SizedBox(width: 10),
                              _LessonEditButton(onTap: onEditTap!),
                            ],
                          ],
                        ),
                        if (lesson.hasDescription) ...[
                          const SizedBox(height: 6),
                          AppTextView.body3(
                            lesson.description,
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonEditButton extends StatelessWidget {
  const _LessonEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.secondaryColor.withValues(alpha: 0.34),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppColors.secondaryColor,
              ),
              const SizedBox(width: 4),
              AppTextView.body3(
                AppStrings.trainingEditAction,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonThumbnail extends StatelessWidget {
  const _LessonThumbnail({required this.thumbnailLink});

  final String? thumbnailLink;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CustomFunctions.resolveImageUrl(thumbnailLink);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl == null
            ? const _LibraryPlaceholder(icon: Icons.play_circle_outline_rounded)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const _LibraryPlaceholder(
                  icon: Icons.play_circle_outline_rounded,
                ),
                errorWidget: (_, __, ___) => const _LibraryPlaceholder(
                  icon: Icons.play_circle_outline_rounded,
                ),
              ),
      ),
    );
  }
}

class _LibraryPlaceholder extends StatelessWidget {
  const _LibraryPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '${AppStrings.imagePath}fallback_image.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Center(
          child: Icon(icon, color: AppColors.textSecondary, size: 28),
        );
      },
    );
  }
}

class _LibraryMetaRow extends StatelessWidget {
  const _LibraryMetaRow({
    required this.lessonsCount,
    required this.totalDuration,
  });

  final int lessonsCount;
  final int totalDuration;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        AppTextView.body3(
          AppStrings.trainingLibraryLessonsCount(lessonsCount),
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        const _MetaDot(),
        AppTextView.body3(
          CustomFunctions.formatDuration(totalDuration),
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AppTextView.body(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

String _displayValue(String value, {required String fallback}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return fallback;
  }

  return trimmed;
}
