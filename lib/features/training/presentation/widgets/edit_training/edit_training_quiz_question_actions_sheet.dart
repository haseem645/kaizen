part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _QuizQuestionActionsSheet extends StatelessWidget {
  const _QuizQuestionActionsSheet({
    required this.onSelected,
    required this.onClose,
  });

  final ValueChanged<_QuizQuestionAction> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: AppColors.mainBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const SizedBox(width: 28),
                    const Expanded(
                      child: AppTextView.body1(
                        AppStrings.trainingLibraryLessonActions,
                        color: AppColors.secondaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    AppOverlayCloseButton(onTap: onClose),
                  ],
                ),
                const SizedBox(height: 18),
                const AppDotDivider(),
                const SizedBox(height: 18),
                _QuizQuestionActionTile(
                  title: AppStrings.trainingQuestionEditAction,
                  description: AppStrings.trainingQuestionEditDescription,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  iconBackground: AppColors.lightGreen1,
                  onTap: () => onSelected(_QuizQuestionAction.edit),
                ),
                const SizedBox(height: 10),
                _QuizQuestionActionTile(
                  title: AppStrings.trainingDeleteQuestionAction,
                  description: AppStrings.trainingQuestionDeleteDescription,
                  icon: SvgPicture.asset(
                    '${AppStrings.imagePath}delete.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      AppColors.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  iconBackground: AppColors.red1,
                  onTap: () => onSelected(_QuizQuestionAction.delete),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizQuestionActionTile extends StatelessWidget {
  const _QuizQuestionActionTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBackground,
    required this.onTap,
  });

  final String title;
  final String description;
  final Widget icon;
  final Color iconBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.trainingLessonActionSurface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: icon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextView.body2(
                      title,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 4),
                    AppTextView.body3(
                      description,
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
