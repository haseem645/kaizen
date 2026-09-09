part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _TrainingTabs extends StatelessWidget {
  const _TrainingTabs({required this.tabController});

  final TabController tabController;

  static const _tabs = <Widget>[
    _TrainingTab(
      index: 0,
      label: AppStrings.trainingVideoTab,
      icon: AppAssets.video,
      selectedIcon: AppAssets.videoEnabled,
    ),
    _TrainingTab(
      index: 1,
      label: AppStrings.trainingSopTab,
      icon: AppAssets.sop,
      selectedIcon: AppAssets.sopEnabled,
    ),
    _TrainingTab(
      index: 2,
      label: AppStrings.trainingQuizTab,
      icon: AppAssets.quizTab,
      selectedIcon: AppAssets.quizTabEnabled,
    ),
    _TrainingTab(
      index: 3,
      label: AppStrings.trainingAssignmentTab,
      icon: AppAssets.assignment,
      selectedIcon: AppAssets.assignmentEnabled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableProvider<TabController>.value(
      value: tabController,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.trainingLessonActionSurface,
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: _tabs),
        ),
      ),
    );
  }
}

class _TrainingTab extends StatelessWidget {
  const _TrainingTab({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final int index;
  final String label;
  final String icon;
  final String selectedIcon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child:
            Selector2<TabController, TrainingModuleController, ({bool isSelected, bool isEnabled})>(
              selector: (_, tabs, training) => (
                isSelected: tabs.index == index,
                isEnabled: index == 0 || training.canAccessSelectedModuleExtras,
              ),
              builder: (context, state, _) => _TrainingTabItem(
                label: label,
                iconAsset: state.isSelected ? selectedIcon : icon,
                isSelected: state.isSelected,
                isEnabled: state.isEnabled,
                onTap: () {
                  final tabs = context.read<TabController>();
                  if (tabs.index != index) {
                    tabs.animateTo(index);
                  }
                },
              ),
            ),
      ),
    );
  }
}

class _TrainingTabItem extends StatelessWidget {
  const _TrainingTabItem({
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? AppColors.textPrimary : AppColors.trainingNavigationInactive;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      label: label,
      onTap: isEnabled ? onTap : null,
      excludeSemantics: true,
      child: Material(
        color: isSelected ? AppColors.secondaryColor : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isSelected ? AppColors.lightPurple1 : Colors.transparent),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 28),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == "Assignment" ? 4 : 0, vertical: 7),
              child: Opacity(
                opacity: isEnabled ? 1 : 0.55,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(iconAsset, width: 15, height: 15, excludeFromSemantics: true),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AppTextView.body3(
                        label,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                        maxLines: 1,
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
