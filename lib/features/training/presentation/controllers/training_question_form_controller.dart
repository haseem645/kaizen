import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';

class TrainingQuestionFormController extends ChangeNotifier {
  TrainingQuestionFormController({required this.minOptionCount, required this.maxOptionCount}) {
    questionController.addListener(clearValidationMessage);
  }

  static const int maxImageBytes = 10 * 1024 * 1024;

  final int minOptionCount;
  final int maxOptionCount;
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int _selectedCorrectOptionIndex = -1;
  File? _questionImage;
  String? _validationMessage;
  bool _isPickingImage = false;
  bool _isDisposed = false;

  List<TextEditingController> get optionControllers => List.unmodifiable(_optionControllers);
  int get selectedCorrectOptionIndex => _selectedCorrectOptionIndex;
  File? get questionImage => _questionImage;
  String? get validationMessage => _validationMessage;
  bool get isPickingImage => _isPickingImage;
  bool get canAddOption => _optionControllers.length < maxOptionCount;
  bool get canChangeCorrectAnswer => _optionControllers.length > 1;
  String get correctAnswerLabel => _selectedCorrectOptionIndex < 0
      ? AppStrings.trainingQuestionNoCorrectAnswer
      : AppStrings.trainingQuestionOptionLetter(_selectedCorrectOptionIndex);

  void addOptionField() {
    if (!canAddOption) return;

    _optionControllers.add(TextEditingController()..addListener(clearValidationMessage));
    if (_selectedCorrectOptionIndex < 0) _selectedCorrectOptionIndex = 0;
    _validationMessage = null;
    notifyListeners();
  }

  void removeOptionField(int index) {
    if (index < 0 || index >= _optionControllers.length) return;

    final controller = _optionControllers.removeAt(index);
    controller
      ..removeListener(clearValidationMessage)
      ..dispose();
    if (_optionControllers.isEmpty) {
      _selectedCorrectOptionIndex = -1;
    } else if (index < _selectedCorrectOptionIndex) {
      _selectedCorrectOptionIndex -= 1;
    } else if (_selectedCorrectOptionIndex >= _optionControllers.length) {
      _selectedCorrectOptionIndex = _optionControllers.length - 1;
    }
    _validationMessage = null;
    notifyListeners();
  }

  void previousCorrectAnswer() => _moveCorrectAnswer(-1);
  void nextCorrectAnswer() => _moveCorrectAnswer(1);

  void _moveCorrectAnswer(int direction) {
    if (!canChangeCorrectAnswer) return;

    _selectedCorrectOptionIndex =
        (_selectedCorrectOptionIndex + direction) % _optionControllers.length;
    _validationMessage = null;
    notifyListeners();
  }

  Future<void> pickQuestionImage(Future<File?> Function() pickImage) async {
    if (_isPickingImage || _isDisposed) return;

    _isPickingImage = true;
    _validationMessage = null;
    notifyListeners();
    try {
      final image = await pickImage();
      if (_isDisposed || image == null) return;

      final extension = image.path.split('.').last.toLowerCase();
      if (!const ['png', 'jpg', 'jpeg'].contains(extension)) {
        _validationMessage = AppStrings.trainingQuestionImageFormatError;
        return;
      }
      final length = await image.length();
      if (_isDisposed) return;
      if (length > maxImageBytes) {
        _validationMessage = AppStrings.trainingQuestionImageSizeError;
        return;
      }
      if (length == 0) {
        _validationMessage = AppStrings.pickImageError;
        return;
      }
      _questionImage = image;
    } catch (_) {
      if (!_isDisposed) _validationMessage = AppStrings.pickImageError;
    } finally {
      if (!_isDisposed) {
        _isPickingImage = false;
        notifyListeners();
      }
    }
  }

  void removeQuestionImage() {
    if (_isPickingImage) return;
    _questionImage = null;
    _validationMessage = null;
    notifyListeners();
  }

  void setValidationMessage(String message) {
    _validationMessage = message;
    notifyListeners();
  }

  void clearValidationMessage() {
    if (_validationMessage == null) return;
    _validationMessage = null;
    notifyListeners();
  }

  String? validate() {
    if (questionController.text.trim().isEmpty) {
      return AppStrings.trainingQuestionRequired;
    }
    if (_optionControllers.length < minOptionCount) {
      return AppStrings.trainingQuestionMinOptionsRequired;
    }
    if (_optionControllers.any((controller) => controller.text.trim().isEmpty)) {
      return AppStrings.trainingQuestionOptionsRequired;
    }
    if (_selectedCorrectOptionIndex < 0 ||
        _selectedCorrectOptionIndex >= _optionControllers.length) {
      return AppStrings.trainingQuestionCorrectOptionRequired;
    }
    return null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    questionController
      ..removeListener(clearValidationMessage)
      ..dispose();
    for (final controller in _optionControllers) {
      controller
        ..removeListener(clearValidationMessage)
        ..dispose();
    }
    super.dispose();
  }
}
