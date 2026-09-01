part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _QuizDialogField extends StatelessWidget {
  const _QuizDialogField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextView.body3(
          label,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          minLines: minLines,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          cursorColor: Colors.white,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.mainBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.18),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.18),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizOptionEditorCard extends StatelessWidget {
  const _QuizOptionEditorCard({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.isSelected,
    required this.onSelect,
    required this.onChanged,
    this.onRemove,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppColors.secondaryColor
              : AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.secondaryColor
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    AppTextView.body3(
                      label,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                _InlineTextAction(
                  label: AppStrings.trainingRemoveOption,
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppColors.red,
                  onTap: onRemove!,
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            cursorColor: Colors.white,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppColors.surfaceDark2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.fieldBorder.withValues(alpha: 0.18),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.fieldBorder.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.secondaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineTextAction extends StatelessWidget {
  const _InlineTextAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.secondaryColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            AppTextView.body3(label, color: color, fontWeight: FontWeight.w700),
          ],
        ),
      ),
    );
  }
}

class _QuizSettingsCard extends StatelessWidget {
  const _QuizSettingsCard({required this.controller});

  final TrainingModuleController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.bgGlow.withValues(alpha: 0.95),
                AppColors.surfaceDark.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: AppColors.secondaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AppTextView.body1(
                      AppStrings.trainingGenerateQuiz,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _QuizGenerationStepper(
                label: AppStrings.trainingQuizNumberOfQuestions,
                value: controller.quizGenerationQuestionCount,
                onIncrement: controller.incrementQuizQuestionCount,
                onDecrement: controller.decrementQuizQuestionCount,
                canIncrement:
                    controller.quizGenerationQuestionCount <
                    TrainingModuleController.maxQuizQuestionCount,
                canDecrement:
                    controller.quizGenerationQuestionCount >
                    TrainingModuleController.minQuizQuestionCount,
              ),
              const SizedBox(height: 10),
              _QuizGenerationStepper(
                label: AppStrings.trainingQuizOptionsPerQuestion,
                value: controller.quizGenerationOptionsPerQuestion,
                onIncrement: controller.incrementQuizOptionsPerQuestion,
                onDecrement: controller.decrementQuizOptionsPerQuestion,
                canIncrement:
                    controller.quizGenerationOptionsPerQuestion <
                    TrainingModuleController.maxQuizOptionsPerQuestion,
                canDecrement:
                    controller.quizGenerationOptionsPerQuestion >
                    TrainingModuleController.minQuizOptionsPerQuestion,
              ),
              const SizedBox(height: 10),
              const AppTextView.body3(
                AppStrings.trainingQuizDifficultyLevel,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuizDifficultyChip(
                    label: AppStrings.trainingQuizDifficultyEasy,
                    isSelected:
                        controller.quizGenerationDifficulty ==
                        QuizGenerationDifficulty.easy,
                    onTap: () => controller.setQuizGenerationDifficulty(
                      QuizGenerationDifficulty.easy,
                    ),
                  ),
                  _QuizDifficultyChip(
                    label: AppStrings.trainingQuizDifficultyMedium,
                    isSelected:
                        controller.quizGenerationDifficulty ==
                        QuizGenerationDifficulty.medium,
                    onTap: () => controller.setQuizGenerationDifficulty(
                      QuizGenerationDifficulty.medium,
                    ),
                  ),
                  _QuizDifficultyChip(
                    label: AppStrings.trainingQuizDifficultyHard,
                    isSelected:
                        controller.quizGenerationDifficulty ==
                        QuizGenerationDifficulty.hard,
                    onTap: () => controller.setQuizGenerationDifficulty(
                      QuizGenerationDifficulty.hard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _QuizReplaceToggle(
                value: controller.replaceExistingQuestions,
                onChanged: controller.setReplaceExistingQuestions,
              ),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -2,
          child: IgnorePointer(
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withValues(alpha: 0.26),
                    blurRadius: 70,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
