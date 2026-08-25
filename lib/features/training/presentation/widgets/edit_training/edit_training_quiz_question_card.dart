part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({
    required this.number,
    required this.question,
    required this.canManageQuestions,
    required this.isSaving,
    required this.isDeleting,
    required this.onDeleteQuestionTap,
    required this.onSaveQuestionTap,
  });

  final int number;
  final SeatDescriptionTrainingQuestion question;
  final bool canManageQuestions;
  final bool isSaving;
  final bool isDeleting;
  final Future<void> Function(SeatDescriptionTrainingQuestion question)
  onDeleteQuestionTap;
  final Future<bool> Function(
    String questionId,
    List<SeatDescriptionTrainingQuestionOption> options,
    String? correctOptionUuid,
  )
  onSaveQuestionTap;

  @override
  Widget build(BuildContext context) {
    return _EditableQuizQuestionCard(
      number: number,
      question: question,
      canManageQuestions: canManageQuestions,
      isSaving: isSaving,
      isDeleting: isDeleting,
      onDeleteQuestionTap: onDeleteQuestionTap,
      onSaveQuestionTap: onSaveQuestionTap,
    );
  }
}

class _EditableQuizQuestionCard extends StatefulWidget {
  const _EditableQuizQuestionCard({
    required this.number,
    required this.question,
    required this.canManageQuestions,
    required this.isSaving,
    required this.isDeleting,
    required this.onDeleteQuestionTap,
    required this.onSaveQuestionTap,
  });

  final int number;
  final SeatDescriptionTrainingQuestion question;
  final bool canManageQuestions;
  final bool isSaving;
  final bool isDeleting;
  final Future<void> Function(SeatDescriptionTrainingQuestion question)
  onDeleteQuestionTap;
  final Future<bool> Function(
    String questionId,
    List<SeatDescriptionTrainingQuestionOption> options,
    String? correctOptionUuid,
  )
  onSaveQuestionTap;

  @override
  State<_EditableQuizQuestionCard> createState() =>
      _EditableQuizQuestionCardState();
}

class _EditableQuizQuestionCardState extends State<_EditableQuizQuestionCard> {
  late final _QuizQuestionEditorController _editorController;

  @override
  void initState() {
    super.initState();
    _editorController = _QuizQuestionEditorController(
      question: widget.question,
    );
  }

  @override
  void didUpdateWidget(covariant _EditableQuizQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _editorController.syncWithQuestion(widget.question);
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (widget.isSaving || widget.isDeleting) {
      return;
    }

    final validationMessage = _editorController.validate(widget.question);
    if (validationMessage != null) {
      _editorController.setValidationMessage(validationMessage);
      return;
    }

    await widget.onSaveQuestionTap(
      widget.question.uuid,
      _editorController.buildOptions(widget.question),
      _editorController.selectedCorrectOptionUuid,
    );
  }

  Future<void> _deleteQuestion() async {
    if (widget.isSaving || widget.isDeleting) {
      return;
    }

    await widget.onDeleteQuestionTap(widget.question);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(
      widget.question.imageUrl,
    );

    return AnimatedBuilder(
      animation: _editorController,
      builder: (context, _) {
        final isBusy = widget.isSaving || widget.isDeleting;
        final visibleOptions = _editorController.visibleExistingOptions(
          widget.question,
        );
        final correctOptionChoices = [
          for (var index = 0; index < visibleOptions.length; index++)
            _QuizCorrectOptionChoice(
              uuid: visibleOptions[index].uuid,
              label: AppStrings.trainingQuestionChoiceLabel(index + 1),
            ),
          if (_editorController.showsDraftOption)
            _QuizCorrectOptionChoice(
              uuid: _editorController.draftOptionUuid,
              label: AppStrings.trainingQuestionChoiceLabel(
                visibleOptions.length + 1,
              ),
            ),
        ];
        final canAddOption =
            widget.canManageQuestions &&
            _editorController.canAddOption() &&
            !isBusy;
        final canSaveQuestion =
            widget.canManageQuestions &&
            !isBusy &&
            _editorController.canSave(question: widget.question);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 22,
                offset: const Offset(0, 12),
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppStrings.trainingQuestionLabel.toUpperCase()} '
                          '${widget.number.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppTextView.body1(
                          widget.question.question,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ],
                    ),
                  ),
                  if (widget.canManageQuestions) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: AppStrings.trainingDeleteQuestionAction,
                      child: InkWell(
                        onTap: isBusy ? null : _deleteQuestion,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.fieldBorder.withValues(
                                alpha: 0.18,
                              ),
                            ),
                          ),
                          child: Center(
                            child: widget.isDeleting
                                ? FastCircularProgressIndicator(
                                    width: 14,
                                    height: 14,
                                  )
                                : const Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.textSecondary,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (resolvedImageUrl != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: resolvedImageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (visibleOptions.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (var index = 0; index < visibleOptions.length; index++) ...[
                  _QuizOptionTile(
                    controller: _editorController.optionControllerFor(
                      visibleOptions[index],
                    ),
                    hintText: AppStrings.trainingQuestionOptionHint(index + 1),
                    isSelected: _editorController.isOptionSelected(
                      visibleOptions[index].uuid,
                    ),
                    isEditable: widget.canManageQuestions && !isBusy,
                    canDelete: widget.canManageQuestions,
                    onTap:
                        widget.canManageQuestions &&
                            !isBusy &&
                            !_editorController.showsDraftOption
                        ? () => _editorController.selectOption(
                            visibleOptions[index].uuid,
                          )
                        : null,
                    onDeleteTap: isBusy
                        ? null
                        : () => _editorController.removeExistingOption(
                            visibleOptions[index].uuid,
                          ),
                  ),
                  if (index != visibleOptions.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
              if (_editorController.showsDraftOption) ...[
                const SizedBox(height: 10),
                _DraftQuizOptionTile(
                  controller: _editorController.draftOptionController,
                  hintText: AppStrings.trainingQuestionOptionHint(
                    visibleOptions.length + 1,
                  ),
                  isSelected: false,
                  onSelect: null,
                  onDeleteTap: isBusy
                      ? null
                      : () => _editorController.removeDraftOption(
                          widget.question,
                        ),
                ),
              ],
              if (canAddOption) ...[
                const SizedBox(height: 12),
                _InlineTextAction(
                  label: AppStrings.trainingQuestionAddOption,
                  icon: Icons.add_rounded,
                  onTap: () =>
                      _editorController.showDraftOption(widget.question),
                ),
              ],
              if (_editorController.validationMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.22),
                    ),
                  ),
                  child: AppTextView.body3(
                    _editorController.validationMessage!,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
              if (widget.canManageQuestions) ...[
                const SizedBox(height: 18),
                _QuizCorrectOptionDropdown(
                  value: _editorController.selectedCorrectOptionUuid,
                  options: correctOptionChoices,
                  showLabel: false,
                  onChanged: isBusy
                      ? null
                      : _editorController.selectCorrectOption,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: canSaveQuestion ? _saveQuestion : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      disabledForegroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      backgroundColor: AppColors.secondaryColor,
                      disabledBackgroundColor: AppColors.secondaryColor
                          .withValues(alpha: 0.42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.secondaryColor),
                      ),
                    ),
                    child: widget.isSaving
                        ? FastCircularProgressIndicator(width: 16, height: 16)
                        : const AppTextView.body(
                            AppStrings.trainingQuestionSaveAction,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
