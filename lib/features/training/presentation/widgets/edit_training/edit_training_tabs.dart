part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class TrainingTabs extends StatelessWidget {
  const TrainingTabs({super.key, required this.navigation, required this.maxTabIndex});

  final TrainingTabNavigationController navigation;
  final int maxTabIndex;

  List<Widget> get _tabs => [
    _TrainingTab(
      index: 0,
      label: AppStrings.trainingVideoTab,
      icon: AppAssets.video,
      selectedIcon: AppAssets.videoEnabled,
      maxTabIndex: maxTabIndex,
    ),
    _TrainingTab(
      index: 1,
      label: AppStrings.trainingSopTab,
      icon: AppAssets.sop,
      selectedIcon: AppAssets.sopEnabled,
      maxTabIndex: maxTabIndex,
    ),
    _TrainingTab(
      index: 2,
      label: AppStrings.trainingQuizTab,
      icon: AppAssets.quizTab,
      selectedIcon: AppAssets.quizTabEnabled,
      maxTabIndex: maxTabIndex,
    ),
    _TrainingTab(
      index: 3,
      label: AppStrings.trainingAssignmentTab,
      icon: AppAssets.assignment,
      selectedIcon: AppAssets.assignmentEnabled,
      maxTabIndex: maxTabIndex,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableProvider<TrainingTabNavigationController>.value(
      value: navigation,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.trainingLessonActionSurface,
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    required this.maxTabIndex,
  });

  final int index;
  final String label;
  final String icon;
  final String selectedIcon;
  final int maxTabIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Selector<TrainingTabNavigationController, bool>(
          selector: (_, tabs) => tabs.selectedIndex == index,
          builder: (context, isSelected, _) => _TrainingTabItem(
            label: label,
            iconAsset: isSelected ? selectedIcon : icon,
            isSelected: isSelected,
            isEnabled: index <= maxTabIndex,
            onTap: () {
              context.read<TrainingTabNavigationController>().selectTab(index);
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
              padding: EdgeInsets.symmetric(
                horizontal: label == AppStrings.trainingAssignmentTab ? 4 : 0,
                vertical: 7,
              ),
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
