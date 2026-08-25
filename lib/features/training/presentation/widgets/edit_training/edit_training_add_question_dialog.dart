part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _AddQuestionDialog extends StatefulWidget {
  const _AddQuestionDialog();

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogFormController extends ChangeNotifier {
  _AddQuestionDialogFormController({required int initialOptionCount}) {
    for (var index = 0; index < initialOptionCount; index++) {
      optionControllers.add(_buildOptionController());
    }
  }

  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      <TextEditingController>[];
  int selectedCorrectOptionIndex = 0;
  String? validationMessage;

  TextEditingController _buildOptionController() {
    return TextEditingController()..addListener(clearValidationMessage);
  }

  void addOptionField() {
    if (optionControllers.length >=
        TrainingModuleController.maxQuizOptionsPerQuestion) {
      return;
    }

    optionControllers.add(_buildOptionController());
    validationMessage = null;
    notifyListeners();
  }

  void removeOptionField(int index, {required int minOptionCount}) {
    if (optionControllers.length <= minOptionCount) {
      return;
    }

    final controller = optionControllers.removeAt(index);
    controller
      ..removeListener(clearValidationMessage)
      ..dispose();

    if (selectedCorrectOptionIndex >= optionControllers.length) {
      selectedCorrectOptionIndex = optionControllers.length - 1;
    } else if (index < selectedCorrectOptionIndex) {
      selectedCorrectOptionIndex -= 1;
    }

    validationMessage = null;
    notifyListeners();
  }

  void selectCorrectOption(int index) {
    if (selectedCorrectOptionIndex == index && validationMessage == null) {
      return;
    }

    selectedCorrectOptionIndex = index;
    validationMessage = null;
    notifyListeners();
  }

  void setValidationMessage(String message) {
    validationMessage = message;
    notifyListeners();
  }

  void clearValidationMessage() {
    if (validationMessage == null) {
      return;
    }

    validationMessage = null;
    notifyListeners();
  }

  String? validate({required int minOptionCount}) {
    if (questionController.text.trim().isEmpty) {
      return AppStrings.trainingQuestionRequired;
    }

    if (optionControllers.length < minOptionCount) {
      return AppStrings.trainingQuestionMinOptionsRequired;
    }

    final hasEmptyOption = optionControllers.any(
      (controller) => controller.text.trim().isEmpty,
    );
    if (hasEmptyOption) {
      return AppStrings.trainingQuestionOptionsRequired;
    }

    if (selectedCorrectOptionIndex < 0 ||
        selectedCorrectOptionIndex >= optionControllers.length) {
      return AppStrings.trainingQuestionCorrectOptionRequired;
    }

    return null;
  }

  @override
  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller
        ..removeListener(clearValidationMessage)
        ..dispose();
    }
    super.dispose();
  }
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  static const int _minOptionCount = 2;
  static const int _initialOptionCount = 2;
  late final _AddQuestionDialogFormController _formController;

  @override
  void initState() {
    super.initState();
    _formController = _AddQuestionDialogFormController(
      initialOptionCount: _initialOptionCount,
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validationMessage = _formController.validate(
      minOptionCount: _minOptionCount,
    );
    if (validationMessage != null) {
      _formController.setValidationMessage(validationMessage);
      return;
    }

    final trainingController = context.read<TrainingModuleController>();
    final didAdd = await trainingController.addQuestionToSelectedModule(
      questionText: _formController.questionController.text.trim(),
      optionTexts: _formController.optionControllers
          .map((controller) => controller.text.trim())
          .toList(growable: false),
      correctOptionIndex: _formController.selectedCorrectOptionIndex,
    );
    if (!mounted || !didAdd) {
      final errorMessage = trainingController.questionsErrorMessage?.trim();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        _formController.setValidationMessage(errorMessage);
      }
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return AnimatedBuilder(
      animation: _formController,
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            decoration: const BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
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
                      const Expanded(
                        child: AppTextView.body1(
                          AppStrings.trainingAddQuestionDialogTitle,
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
                  const AppTextView.body2(
                    AppStrings.trainingAddQuestionDialogDescription,
                    color: AppColors.lightPurple1,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  const SizedBox(height: 20),
                  _QuizDialogField(
                    label: AppStrings.trainingQuestionLabel,
                    hintText: AppStrings.trainingQuestionHint,
                    controller: _formController.questionController,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _formController.clearValidationMessage,
                  ),
                  const SizedBox(height: 18),
                  const AppTextView.body3(
                    AppStrings.trainingQuestionOptionsLabel,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 6),
                  const AppTextView.body4(
                    AppStrings.trainingQuestionSelectCorrectAnswerHint,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  const SizedBox(height: 14),
                  for (
                    var index = 0;
                    index < _formController.optionControllers.length;
                    index++
                  ) ...[
                    _QuizOptionEditorCard(
                      label: AppStrings.trainingQuestionOptionLabel(index + 1),
                      hintText: AppStrings.trainingQuestionOptionHint(
                        index + 1,
                      ),
                      controller: _formController.optionControllers[index],
                      isSelected:
                          _formController.selectedCorrectOptionIndex == index,
                      onSelect: () =>
                          _formController.selectCorrectOption(index),
                      onChanged: _formController.clearValidationMessage,
                      onRemove:
                          _formController.optionControllers.length >
                              _minOptionCount
                          ? () => _formController.removeOptionField(
                              index,
                              minOptionCount: _minOptionCount,
                            )
                          : null,
                    ),
                    if (index != _formController.optionControllers.length - 1)
                      const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 14),
                  if (_formController.optionControllers.length <
                      TrainingModuleController.maxQuizOptionsPerQuestion)
                    _InlineTextAction(
                      label: AppStrings.trainingQuestionAddOption,
                      icon: Icons.add_circle_outline_rounded,
                      onTap: _formController.addOptionField,
                    ),
                  if (_formController.validationMessage != null) ...[
                    const SizedBox(height: 14),
                    _DialogErrorMessageCard(
                      message: _formController.validationMessage!,
                    ),
                  ],
                  const SizedBox(height: 22),
                  Center(
                    child: SizedBox(
                      width: 210,
                      child: TextButton.icon(
                        onPressed: controller.isAddingQuestion ? null : _submit,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          disabledForegroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
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
                        icon: controller.isAddingQuestion
                            ? FastCircularProgressIndicator(
                                width: 16,
                                height: 16,
                              )
                            : const Icon(
                                Icons.playlist_add_rounded,
                                size: 17,
                                color: AppColors.textPrimary,
                              ),
                        label: const AppTextView.body(
                          AppStrings.trainingQuestionSaveAction,
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
      ),
    );
  }
}
