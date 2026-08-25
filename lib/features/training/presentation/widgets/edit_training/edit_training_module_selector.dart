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
  final Future<void> Function(SeatDescriptionTrainingModule module)
  onDeleteModuleTap;

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

  @override
  Widget build(BuildContext context) {
    final selectedIndex = controller.selectedModuleIndex;
    final selectedModule = controller.selectedModule;
    final showPager =
        controller.isCreatingNewLessonDraft || selectedModule != null;
    final canSwipeModules = controller.canSwipeBetweenModules;

    Future<void> goToPreviousModule() async {
      if (!controller.canSelectPreviousModule || selectedIndex <= 0) {
        return;
      }

      await onModuleSelected(controller.modules[selectedIndex - 1].uuid);
    }

    Future<void> goToNextModule() async {
      if (!controller.canSelectNextModule &&
          !controller.canSelectFirstModuleFromDraft) {
        return;
      }

      await onModuleSelected(
        controller.canSelectNextModule
            ? controller.modules[selectedIndex + 1].uuid
            : controller.modules.first.uuid,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.canManageTraining) ...[
          _AddNewLessonButton(
            isSelected: controller.isCreatingNewLessonDraft,
            onTap: onAddNewLessonTap,
          ),
          if (showPager) const SizedBox(height: 10),
        ],
        if (showPager) ...[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: canSwipeModules
                ? (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity <= -220) {
                      unawaited(goToNextModule());
                      return;
                    }

                    if (velocity >= 220) {
                      unawaited(goToPreviousModule());
                    }
                  }
                : null,
            child: controller.isCreatingNewLessonDraft
                ? const _DraftModulePagerCard()
                : _SelectedModulePagerCard(
                    module: selectedModule!,
                    currentLessonNumber: controller.selectedModuleNumber,
                    totalLessons: controller.totalModules,
                    onTap: () => unawaited(_showModuleSheet(context)),
                  ),
          ),
        ] else if (controller.canManageTraining) ...[
          const SizedBox(height: 2),
          AppTextView.body3(
            AppStrings.trainingAddLessonPrompt,
            color: AppColors.textSecondary,
          ),
        ],
      ],
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
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.secondaryColor,
                    size: 18,
                  ),
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

class _SelectedModulePagerCard extends StatelessWidget {
  const _SelectedModulePagerCard({
    required this.module,
    required this.currentLessonNumber,
    required this.totalLessons,
    required this.onTap,
  });

  final SeatDescriptionTrainingModule module;
  final int currentLessonNumber;
  final int totalLessons;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedThumbnail = CustomFunctions.resolveImageUrl(
      module.thumbnailLink,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: _trainingModulePagerHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark3,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.secondaryColor, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: -12,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: _trainingModuleThumbnailHeight,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            color: AppColors.mainBg,
                          ),
                          child: resolvedThumbnail == null
                              ? const _ModuleThumbnailPlaceholder()
                              : CachedNetworkImage(
                                  imageUrl: resolvedThumbnail,
                                  fit: BoxFit.contain,
                                  placeholder: (_, _) =>
                                      const _ModuleThumbnailPlaceholder(),
                                  errorWidget: (_, _, _) =>
                                      const _ModuleThumbnailPlaceholder(),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: 40,
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceDark1,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextView.body3(
                              AppStrings.trainingLessonCounter(
                                currentLessonNumber,
                                totalLessons,
                              ),
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.view_list_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
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

class _DraftModulePagerCard extends StatelessWidget {
  const _DraftModulePagerCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedRoundedBorderPainter(
        color: AppColors.secondaryColor.withValues(alpha: 0.62),
        radius: 20,
      ),
      child: SizedBox(
        height: _trainingModulePagerHeight,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.secondaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: AppTextView.body1(
                        AppStrings.trainingNewLesson,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextView.body3(
                  AppStrings.trainingAddLessonPrompt,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ],
            ),
          ),
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
  final Future<void> Function(SeatDescriptionTrainingModule module)
  onDeleteModuleTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
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
                      _DialogCloseButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
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
                    for (
                      var index = 0;
                      index < controller.modules.length;
                      index++
                    ) ...[
                      _ModuleSheetTile(
                        module: controller.modules[index],
                        isSelected:
                            !controller.isCreatingNewLessonDraft &&
                            controller.modules[index].uuid ==
                                controller.selectedModuleId,
                        isDeleting:
                            controller.deletingModuleId ==
                            controller.modules[index].uuid,
                        showDeleteAction: controller.canManageTraining,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(
                            onModuleSelected(controller.modules[index].uuid),
                          );
                        },
                        onDeleteTap: () {
                          Navigator.of(context).pop();
                          unawaited(
                            onDeleteModuleTap(controller.modules[index]),
                          );
                        },
                      ),
                      if (index != controller.modules.length - 1)
                        const SizedBox(height: 12),
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
    final resolvedThumbnail = CustomFunctions.resolveImageUrl(
      module.thumbnailLink,
    );

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
                            placeholder: (_, _) =>
                                const _ModuleThumbnailPlaceholder(),
                            errorWidget: (_, _, _) =>
                                const _ModuleThumbnailPlaceholder(),
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
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.secondaryColor,
                    size: 20,
                  ),
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
                        border: Border.all(
                          color: AppColors.red.withValues(alpha: 0.34),
                        ),
                      ),
                      child: Center(
                        child: isDeleting
                            ? FastCircularProgressIndicator(
                                width: 12,
                                height: 12,
                              )
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
