part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _QuizQuestionEditorController extends ChangeNotifier {
  _QuizQuestionEditorController({
    required SeatDescriptionTrainingQuestion question,
  }) : draftOptionController = TextEditingController() {
    draftOptionController.addListener(_handleDraftOptionChanged);
    syncWithQuestion(question, force: true);
  }

  final TextEditingController draftOptionController;
  final Map<String, TextEditingController> _optionControllers =
      <String, TextEditingController>{};
  final List<String> _activeOptionUuids = <String>[];

  String _questionSignature = '';
  String _selectedOptionUuid = '';
  String _initialSelectedOptionUuid = '';
  String _draftOptionUuid = '';
  String _draftCorrectOptionUuid = '';
  bool _showsDraftOption = false;
  String? _validationMessage;
  bool _isSyncingDraftText = false;

  String get selectedOptionUuid => _selectedOptionUuid;
  String get selectedCorrectOptionUuid =>
      _showsDraftOption ? _draftCorrectOptionUuid : _selectedOptionUuid;
  String get draftOptionUuid => _draftOptionUuid;
  bool get showsDraftOption => _showsDraftOption;
  String? get validationMessage => _validationMessage;

  bool isOptionSelected(String optionUuid) => _selectedOptionUuid == optionUuid;

  TextEditingController optionControllerFor(
    SeatDescriptionTrainingQuestionOption option,
  ) {
    return _optionControllers.putIfAbsent(
      option.uuid,
      () =>
          TextEditingController(text: option.text)
            ..addListener(_handleExistingOptionChanged),
    );
  }

  bool canAddOption() => !_showsDraftOption;

  List<SeatDescriptionTrainingQuestionOption> visibleExistingOptions(
    SeatDescriptionTrainingQuestion question,
  ) {
    final originalOptionsByUuid =
        <String, SeatDescriptionTrainingQuestionOption>{
          for (final option in question.options) option.uuid: option,
        };

    return _activeOptionUuids
        .map((uuid) => originalOptionsByUuid[uuid])
        .whereType<SeatDescriptionTrainingQuestionOption>()
        .toList(growable: false);
  }

  bool canSave({required SeatDescriptionTrainingQuestion question}) {
    final hasCorrectSelectionChange =
        selectedCorrectOptionUuid != _initialSelectedOptionUuid;
    final hasDraftChange =
        _showsDraftOption && draftOptionController.text.trim().isNotEmpty;
    final hasExistingOptionStructureChanges =
        _hasExistingOptionStructureChanges(question);
    final hasExistingOptionChanges = _hasExistingOptionTextChanges(question);
    if (!hasCorrectSelectionChange &&
        !hasDraftChange &&
        !hasExistingOptionStructureChanges &&
        !hasExistingOptionChanges) {
      return false;
    }

    if (_hasEmptyExistingOptionText(question) ||
        (_showsDraftOption && draftOptionController.text.trim().isEmpty)) {
      return false;
    }

    final options = buildOptions(question);
    if (options.length < TrainingModuleController.minQuizOptionsPerQuestion) {
      return false;
    }

    return options.any((option) => option.uuid == selectedCorrectOptionUuid);
  }

  void syncWithQuestion(
    SeatDescriptionTrainingQuestion question, {
    bool force = false,
  }) {
    final nextSignature = _buildQuestionSignature(question);
    if (!force && nextSignature == _questionSignature) {
      return;
    }

    _questionSignature = nextSignature;
    _initialSelectedOptionUuid = _resolveSelectedOptionUuid(question);
    _selectedOptionUuid = _initialSelectedOptionUuid;
    _showsDraftOption = false;
    _draftOptionUuid = '';
    _draftCorrectOptionUuid = '';
    _validationMessage = null;
    _syncOptionControllers(question);
    _activeOptionUuids
      ..clear()
      ..addAll(question.options.map((option) => option.uuid));
    _setDraftText('');
    notifyListeners();
  }

  void showDraftOption(SeatDescriptionTrainingQuestion question) {
    if (!canAddOption()) {
      return;
    }

    _showsDraftOption = true;
    _draftOptionUuid = TrainingModuleController.generateClientUuid();
    _draftCorrectOptionUuid = _selectedOptionUuid;
    _validationMessage = null;
    notifyListeners();
  }

  void removeDraftOption(SeatDescriptionTrainingQuestion question) {
    if (!_showsDraftOption) {
      return;
    }

    _showsDraftOption = false;
    _draftOptionUuid = '';
    _draftCorrectOptionUuid = '';
    _validationMessage = null;
    _setDraftText('');
    if (_selectedOptionUuid.isEmpty) {
      _selectedOptionUuid = _firstActiveOptionUuid();
    }
    notifyListeners();
  }

  void selectOption(String optionUuid) {
    if (_showsDraftOption) {
      return;
    }

    final resolvedOptionUuid = optionUuid.trim();
    if (resolvedOptionUuid.isEmpty) {
      return;
    }

    if (_selectedOptionUuid == resolvedOptionUuid &&
        _validationMessage == null) {
      return;
    }

    _selectedOptionUuid = resolvedOptionUuid;
    _validationMessage = null;
    notifyListeners();
  }

  void selectCorrectOption(String? optionUuid) {
    final resolvedOptionUuid = optionUuid?.trim() ?? '';
    if (resolvedOptionUuid.isEmpty) {
      return;
    }

    if (_showsDraftOption) {
      if (_draftCorrectOptionUuid == resolvedOptionUuid &&
          _validationMessage == null) {
        return;
      }

      _draftCorrectOptionUuid = resolvedOptionUuid;
    } else {
      if (_selectedOptionUuid == resolvedOptionUuid &&
          _validationMessage == null) {
        return;
      }

      _selectedOptionUuid = resolvedOptionUuid;
    }

    _validationMessage = null;
    notifyListeners();
  }

  void removeExistingOption(String optionUuid) {
    final resolvedOptionUuid = optionUuid.trim();
    if (resolvedOptionUuid.isEmpty ||
        !_activeOptionUuids.remove(resolvedOptionUuid)) {
      return;
    }

    final removedController = _optionControllers.remove(resolvedOptionUuid);
    removedController
      ?..removeListener(_handleExistingOptionChanged)
      ..dispose();

    if (_selectedOptionUuid == resolvedOptionUuid) {
      _selectedOptionUuid = _firstActiveOptionUuid();
    }

    if (_draftCorrectOptionUuid == resolvedOptionUuid) {
      _draftCorrectOptionUuid = _resolveDraftCorrectOptionUuid();
    }

    _validationMessage = null;
    notifyListeners();
  }

  void setValidationMessage(String message) {
    _validationMessage = message;
    notifyListeners();
  }

  String? validate(SeatDescriptionTrainingQuestion question) {
    if (_hasEmptyExistingOptionText(question) ||
        (_showsDraftOption && draftOptionController.text.trim().isEmpty)) {
      return AppStrings.trainingQuestionOptionsRequired;
    }

    final options = buildOptions(question);
    if (options.length < TrainingModuleController.minQuizOptionsPerQuestion) {
      return AppStrings.trainingQuestionMinOptionsRequired;
    }

    final resolvedCorrectOptionUuid = selectedCorrectOptionUuid.trim();
    if (resolvedCorrectOptionUuid.isEmpty ||
        !options.any((option) => option.uuid == resolvedCorrectOptionUuid)) {
      return AppStrings.trainingQuestionCorrectOptionRequired;
    }

    return null;
  }

  List<SeatDescriptionTrainingQuestionOption> buildOptions(
    SeatDescriptionTrainingQuestion question,
  ) {
    final originalOptionsByUuid =
        <String, SeatDescriptionTrainingQuestionOption>{
          for (final option in question.options) option.uuid: option,
        };
    final options = _activeOptionUuids
        .map((uuid) => originalOptionsByUuid[uuid])
        .whereType<SeatDescriptionTrainingQuestionOption>()
        .map(
          (option) => SeatDescriptionTrainingQuestionOption(
            uuid: option.uuid,
            text: optionControllerFor(option).text.trim(),
          ),
        )
        .toList(growable: true);
    final draftText = draftOptionController.text.trim();
    if (_showsDraftOption &&
        draftText.isNotEmpty &&
        _draftOptionUuid.isNotEmpty) {
      options.add(
        SeatDescriptionTrainingQuestionOption(
          uuid: _draftOptionUuid,
          text: draftText,
        ),
      );
    }
    return options;
  }

  void _handleExistingOptionChanged() {
    _validationMessage = null;
    notifyListeners();
  }

  void _handleDraftOptionChanged() {
    if (_isSyncingDraftText) {
      return;
    }

    _validationMessage = null;
    notifyListeners();
  }

  void _syncOptionControllers(SeatDescriptionTrainingQuestion question) {
    final retainedControllers = <String, TextEditingController>{};

    for (final option in question.options) {
      final controller =
          _optionControllers.remove(option.uuid) ??
          (TextEditingController(text: option.text)
            ..addListener(_handleExistingOptionChanged));
      if (controller.text != option.text) {
        controller.value = controller.value.copyWith(
          text: option.text,
          selection: TextSelection.collapsed(offset: option.text.length),
          composing: TextRange.empty,
        );
      }
      retainedControllers[option.uuid] = controller;
    }

    for (final controller in _optionControllers.values) {
      controller
        ..removeListener(_handleExistingOptionChanged)
        ..dispose();
    }

    _optionControllers
      ..clear()
      ..addAll(retainedControllers);
  }

  bool _hasEmptyExistingOptionText(SeatDescriptionTrainingQuestion question) {
    return visibleExistingOptions(
      question,
    ).any((option) => optionControllerFor(option).text.trim().isEmpty);
  }

  bool _hasExistingOptionTextChanges(SeatDescriptionTrainingQuestion question) {
    return visibleExistingOptions(question).any(
      (option) => optionControllerFor(option).text.trim() != option.text.trim(),
    );
  }

  bool _hasExistingOptionStructureChanges(
    SeatDescriptionTrainingQuestion question,
  ) {
    if (question.options.length != _activeOptionUuids.length) {
      return true;
    }

    for (var index = 0; index < question.options.length; index++) {
      if (question.options[index].uuid != _activeOptionUuids[index]) {
        return true;
      }
    }

    return false;
  }

  void _setDraftText(String value) {
    _isSyncingDraftText = true;
    draftOptionController.value = draftOptionController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
    _isSyncingDraftText = false;
  }

  String _resolveSelectedOptionUuid(SeatDescriptionTrainingQuestion question) {
    final currentSelectedOptionUuid = question.selectedOptionUuid?.trim() ?? '';
    final hasCurrentSelection = question.options.any(
      (option) => option.uuid == currentSelectedOptionUuid,
    );
    if (hasCurrentSelection) {
      return currentSelectedOptionUuid;
    }

    return question.options.isNotEmpty ? question.options.first.uuid : '';
  }

  String _firstActiveOptionUuid() {
    if (_activeOptionUuids.isNotEmpty) {
      return _activeOptionUuids.first;
    }

    return '';
  }

  String _resolveDraftCorrectOptionUuid() {
    final selectedOptionUuid = _selectedOptionUuid.trim();
    if (selectedOptionUuid.isNotEmpty &&
        _activeOptionUuids.contains(selectedOptionUuid)) {
      return selectedOptionUuid;
    }

    return _firstActiveOptionUuid();
  }

  String _buildQuestionSignature(SeatDescriptionTrainingQuestion question) {
    final optionsSignature = question.options
        .map((option) => '${option.uuid}:${option.text}')
        .join('|');
    return [
      question.uuid,
      question.question,
      question.selectedOptionUuid ?? '',
      question.imageUrl ?? '',
      optionsSignature,
    ].join('::');
  }

  @override
  void dispose() {
    for (final controller in _optionControllers.values) {
      controller
        ..removeListener(_handleExistingOptionChanged)
        ..dispose();
    }
    draftOptionController.removeListener(_handleDraftOptionChanged);
    draftOptionController.dispose();
    super.dispose();
  }
}
