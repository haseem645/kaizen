part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _TrainingTabs extends StatelessWidget {
  const _TrainingTabs({required this.tabController, required this.areExtraTabsEnabled});

  final TabController tabController;
  final bool areExtraTabsEnabled;

  @override
  Widget build(BuildContext context) {
    const labels = <String>[
      AppStrings.trainingVideoTab,
      AppStrings.trainingSopTab,
      AppStrings.trainingQuizTab,
      AppStrings.trainingAssignmentTab,
    ];

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              _TrainingTabChip(
                label: labels[index],
                isSelected: tabController.index == index,
                isEnabled: index == 0 || areExtraTabsEnabled,
                onTap: () {
                  if (index != 0 && !areExtraTabsEnabled) {
                    tabController.animateTo(0);
                    return;
                  }

                  if (tabController.index != index) {
                    tabController.animateTo(index);
                  }
                },
              ),
              if (index != labels.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainingTabChip extends StatelessWidget {
  const _TrainingTabChip({
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected
        ? AppColors.secondaryColor
        : isEnabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 98),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryColor.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondaryColor
                  : Colors.white.withValues(alpha: isEnabled ? 0.4 : 0.16),
            ),
          ),
          child: Center(
            child: AppTextView.body2(label, color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

const double _trainingModuleThumbnailHeight = 180;
const double _trainingModulePagerHeight = 245;
