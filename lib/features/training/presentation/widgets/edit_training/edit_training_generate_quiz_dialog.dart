part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _GenerateQuizDialog extends StatelessWidget {
  const _GenerateQuizDialog();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();
    final errorMessage = controller.questionsErrorMessage?.trim();
    final hasErrorMessage = errorMessage != null && errorMessage.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 620),
          decoration: const BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
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
                    const Expanded(
                      child: AppTextView.body1(
                        AppStrings.trainingGenerateQuizDialogTitle,
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _DialogCloseButton(
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _DividerDot(),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.fieldBorder.withValues(alpha: 0.34),
                      ),
                    ),
                    _DividerDot(),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(
                  child: AppTextView.body(
                    AppStrings.trainingGenerateQuizDialogTitle,
                    color: AppColors.hexd9deff,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: AppTextView.body2(
                    AppStrings.trainingGenerateQuizDialogDescription,
                    color: AppColors.lightPurple1,
                    fontSize: 12,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                _QuizSettingsCard(controller: controller),
                if (hasErrorMessage) ...[
                  const SizedBox(height: 16),
                  _DialogErrorMessageCard(message: errorMessage),
                ],
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: 196,
                    child: TextButton.icon(
                      onPressed: controller.isGeneratingQuiz
                          ? null
                          : () async {
                              final didGenerate = await context
                                  .read<TrainingModuleController>()
                                  .generateQuizForSelectedModule();
                              if (!context.mounted || !didGenerate) {
                                return;
                              }

                              Navigator.of(context).pop(true);
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        disabledForegroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.secondaryColor,
                        disabledBackgroundColor: AppColors.secondaryColor
                            .withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: const BorderSide(
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ),
                      icon: controller.isGeneratingQuiz
                          ? FastCircularProgressIndicator(width: 16, height: 16)
                          : const Icon(
                              Icons.auto_awesome_rounded,
                              size: 15,
                              color: AppColors.textPrimary,
                            ),
                      label: AppTextView.body(
                        AppStrings.trainingGenerateQuiz,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
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
