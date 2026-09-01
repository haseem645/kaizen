part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _QuizTabContent extends StatelessWidget {
  const _QuizTabContent({
    required this.isLoading,
    required this.questions,
    required this.canManageQuestions,
    required this.canAddQuestion,
    required this.canGenerateQuiz,
    required this.isGeneratingQuiz,
    required this.isAddingQuestion,
    required this.savingQuestionId,
    required this.deletingQuestionId,
    required this.onAddQuestionTap,
    required this.onGenerateQuizTap,
    required this.onDeleteQuestionTap,
    required this.onSaveQuestionTap,
  });

  final bool isLoading;
  final List<SeatDescriptionTrainingQuestion> questions;
  final bool canManageQuestions;
  final bool canAddQuestion;
  final bool canGenerateQuiz;
  final bool isGeneratingQuiz;
  final bool isAddingQuestion;
  final String? savingQuestionId;
  final String? deletingQuestionId;
  final VoidCallback onAddQuestionTap;
  final VoidCallback onGenerateQuizTap;
  final Future<void> Function(SeatDescriptionTrainingQuestion question) onDeleteQuestionTap;
  final Future<bool> Function(
    String questionId,
    List<SeatDescriptionTrainingQuestionOption> options,
    String? correctOptionUuid,
  )
  onSaveQuestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canManageQuestions) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 5,
              runSpacing: 5,
              children: [
                SizedBox(width: 5),
                _SecondaryTrainingActionButton(
                  label: AppStrings.trainingAddQuestion,
                  icon: Icons.add_rounded,
                  isEnabled: canAddQuestion,
                  isLoading: isAddingQuestion,
                  isDottedBorder: true,
                  horizontalPadding: 16,
                  verticalPadding: 12,
                  borderRadius: 14,
                  backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.04),
                  activeBorderColor: AppColors.secondaryColor.withValues(alpha: 0.42),
                  activeTextColor: AppColors.secondaryColor,
                  activeIconColor: AppColors.secondaryColor,
                  onTap: canAddQuestion ? onAddQuestionTap : null,
                ),
                SizedBox(width: 10),
                _AiGenerateButton(
                  label: AppStrings.trainingGenerateQuiz,
                  isEnabled: canGenerateQuiz,
                  isLoading: isGeneratingQuiz,
                  onTap: canGenerateQuiz ? onGenerateQuizTap : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(child: FastCircularProgressIndicator()),
          )
        else if (questions.isEmpty)
          const _QuizEmptyStateCard()
        else
          for (var index = 0; index < questions.length; index++) ...[
            _QuizQuestionCard(
              number: index + 1,
              question: questions[index],
              canManageQuestions: canManageQuestions,
              isSaving: savingQuestionId == questions[index].uuid,
              isDeleting: deletingQuestionId == questions[index].uuid,
              onDeleteQuestionTap: onDeleteQuestionTap,
              onSaveQuestionTap: onSaveQuestionTap,
            ),
            if (index != questions.length - 1) const SizedBox(height: 14),
          ],
      ],
    );
  }
}
