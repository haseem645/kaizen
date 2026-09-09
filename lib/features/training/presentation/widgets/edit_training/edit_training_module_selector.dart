part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _EditModuleSelector extends StatelessWidget {
  const _EditModuleSelector({
    required this.controller,
    required this.onAddNewLessonTap,
    required this.onModuleSelected,
    required this.onDeleteModuleTap,
  });

  final TrainingModuleController controller;
  final VoidCallback onAddNewLessonTap;
  final Future<void> Function(String moduleId) onModuleSelected;
  final Future<void> Function(SeatDescriptionTrainingModule module) onDeleteModuleTap;

  Future<void> _showModuleSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _ModuleSelectionSheet(
        controller: controller,
        onAddNewLessonTap: onAddNewLessonTap,
        onModuleSelected: onModuleSelected,
        onDeleteModuleTap: onDeleteModuleTap,
      ),
    );
  }

  void _handleModuleSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final selectedIndex = controller.selectedModuleIndex;
    if (velocity >= 220 && controller.canSelectPreviousModule) {
      unawaited(onModuleSelected(controller.modules[selectedIndex - 1].uuid));
    } else if (velocity <= -220) {
      if (controller.canSelectNextModule) {
        unawaited(onModuleSelected(controller.modules[selectedIndex + 1].uuid));
      } else if (controller.canSelectFirstModuleFromDraft) {
        unawaited(onModuleSelected(controller.modules.first.uuid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: controller.canSwipeBetweenModules ? _handleModuleSwipe : null,
          child: _LessonOverviewRow(
            selectedModule: controller.selectedModule,
            selectedTitle: controller.selectedModuleTitle,
            canAddLesson: controller.canManageTraining,
            isCreatingNewLesson: controller.isCreatingNewLessonDraft,
            onAddLesson: onAddNewLessonTap,
            onShowAllLessons: () => unawaited(_showModuleSheet(context)),
          ),
        ),
        const SizedBox(height: 22),
        const AppDotDivider(),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _LessonOverviewRow extends StatelessWidget {
  const _LessonOverviewRow({
    required this.selectedModule,
    required this.selectedTitle,
    required this.canAddLesson,
    required this.isCreatingNewLesson,
    required this.onAddLesson,
    required this.onShowAllLessons,
  });

  final SeatDescriptionTrainingModule? selectedModule;
  final String selectedTitle;
  final bool canAddLesson;
  final bool isCreatingNewLesson;
  final VoidCallback onAddLesson;
  final VoidCallback onShowAllLessons;

  @override
  Widget build(BuildContext context) {
    final module = selectedModule;

    return SizedBox(
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (module != null) ...[
            Expanded(
              flex: 4,
              child: _OpenedLessonCard(
                module: module,
                title: selectedTitle,
                onTap: onShowAllLessons,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (canAddLesson) ...[
            Expanded(
              flex: 4,
              child: _NewLessonCard(isSelected: isCreatingNewLesson, onTap: onAddLesson),
            ),
            const SizedBox(width: 12),
          ],
          _SeeAllLessonsButton(onTap: onShowAllLessons),
        ],
      ),
    );
  }
}

class _AddNewLessonButton extends StatelessWidget {
  const _AddNewLessonButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _DottedRoundedBorderPainter(
            color: isSelected
                ? AppColors.secondaryColor
                : AppColors.secondaryColor.withValues(alpha: 0.58),
            radius: 18,
          ),
          child: Ink(
            height: 45,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondaryColor.withValues(alpha: 0.08)
                  : AppColors.surfaceDark3.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.secondaryColor, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: AppTextView.body2(
                      AppStrings.trainingAddNewLesson,
                      maxLines: 1,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenedLessonCard extends StatelessWidget {
  const _OpenedLessonCard({required this.module, required this.title, required this.onTap});

  final SeatDescriptionTrainingModule module;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: true,
      label: title,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: AppColors.surfaceDark3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _OpenedLessonThumbnail(thumbnailLink: module.thumbnailLink),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: AppTextView.body2(
                title,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenedLessonThumbnail extends StatelessWidget {
  const _OpenedLessonThumbnail({required this.thumbnailLink});

  final String? thumbnailLink;

  @override
  Widget build(BuildContext context) {
    final imageUrl = CustomFunctions.resolveImageUrl(thumbnailLink);
    if (imageUrl == null) {
      return const _ModuleThumbnailPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, _) => const _ModuleThumbnailPlaceholder(),
      errorWidget: (_, _, _) => const _ModuleThumbnailPlaceholder(),
    );
  }
}

class _NewLessonCard extends StatelessWidget {
  const _NewLessonCard({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.secondaryColor.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          foregroundPainter: const _DottedRoundedBorderPainter(
            color: AppColors.secondaryColor,
            radius: 10,
            strokeWidth: 0.6,
            dashLength: 1.5,
            gapLength: 1,
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, color: AppColors.lightPurple1, size: 18),
                    SizedBox(width: 6),
                    AppTextView.body2(
                      AppStrings.trainingNewLesson,
                      color: AppColors.lightPurple1,
                      fontWeight: FontWeight.w500,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeeAllLessonsButton extends StatelessWidget {
  const _SeeAllLessonsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      child: Material(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onTap,
          tooltip: AppStrings.trainingAllLessons,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.north_east, color: AppColors.textPrimary, size: 24),
        ),
      ),
    );
  }
}

class _ModuleSelectionSheet extends StatelessWidget {
  const _ModuleSelectionSheet({
    required this.controller,
    required this.onAddNewLessonTap,
    required this.onModuleSelected,
    required this.onDeleteModuleTap,
  });

  final TrainingModuleController controller;
  final VoidCallback onAddNewLessonTap;
  final Future<void> Function(String moduleId) onModuleSelected;
  final Future<void> Function(SeatDescriptionTrainingModule module) onDeleteModuleTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: const BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextView.body1(
                          AppStrings.trainingChooseLesson,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                  if (controller.canManageTraining) ...[
                    const SizedBox(height: 18),
                    _AddNewLessonButton(
                      isSelected: controller.isCreatingNewLessonDraft,
                      onTap: () {
                        Navigator.of(context).pop();
                        onAddNewLessonTap();
                      },
                    ),
                  ],
                  if (controller.modules.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    for (var index = 0; index < controller.modules.length; index++) ...[
                      _ModuleSheetTile(
                        module: controller.modules[index],
                        isSelected:
                            !controller.isCreatingNewLessonDraft &&
                            controller.modules[index].uuid == controller.selectedModuleId,
                        isDeleting: controller.deletingModuleId == controller.modules[index].uuid,
                        showDeleteAction: controller.canManageTraining,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(onModuleSelected(controller.modules[index].uuid));
                        },
                        onDeleteTap: () {
                          Navigator.of(context).pop();
                          unawaited(onDeleteModuleTap(controller.modules[index]));
                        },
                      ),
                      if (index != controller.modules.length - 1) const SizedBox(height: 12),
                    ],
                  ] else if (!controller.canManageTraining) ...[
                    const SizedBox(height: 18),
                    AppTextView.body3(
                      AppStrings.trainingNoModulesAvailable,
                      color: AppColors.textSecondary,
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

class _ModuleSheetTile extends StatelessWidget {
  const _ModuleSheetTile({
    required this.module,
    required this.isSelected,
    required this.isDeleting,
    required this.showDeleteAction,
    required this.onTap,
    required this.onDeleteTap,
  });

  final SeatDescriptionTrainingModule module;
  final bool isSelected;
  final bool isDeleting;
  final bool showDeleteAction;
  final VoidCallback onTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final resolvedThumbnail = CustomFunctions.resolveImageUrl(module.thumbnailLink);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryColor.withValues(alpha: 0.1)
                : AppColors.surfaceDark3,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondaryColor.withValues(alpha: 0.42)
                  : AppColors.fieldBorder.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 82,
                    height: 60,
                    child: resolvedThumbnail == null
                        ? const _ModuleThumbnailPlaceholder()
                        : CachedNetworkImage(
                            imageUrl: resolvedThumbnail,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const _ModuleThumbnailPlaceholder(),
                            errorWidget: (_, _, _) => const _ModuleThumbnailPlaceholder(),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextView.body2(
                    module.title,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                if (isSelected) ...[
                  const Icon(Icons.check_circle_rounded, color: AppColors.secondaryColor, size: 20),
                  if (showDeleteAction) const SizedBox(width: 10),
                ],
                if (showDeleteAction)
                  InkWell(
                    onTap: isDeleting ? null : onDeleteTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.34)),
                      ),
                      child: Center(
                        child: isDeleting
                            ? FastCircularProgressIndicator(width: 12, height: 12)
                            : const Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: AppColors.red,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
