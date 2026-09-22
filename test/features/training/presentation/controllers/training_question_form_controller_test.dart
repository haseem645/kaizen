import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_question_form_controller.dart';

void main() {
  late TrainingQuestionFormController form;

  setUp(() {
    form = TrainingQuestionFormController(minOptionCount: 2, maxOptionCount: 4);
  });
  tearDown(() => form.dispose());

  test('starts empty and requires a question and two filled options', () {
    expect(form.optionControllers, isEmpty);
    expect(form.selectedCorrectOptionIndex, -1);
    expect(form.validate(), AppStrings.trainingQuestionRequired);

    form.questionController.text = 'How should the tool be used?';
    form.addOptionField();
    form.optionControllers.first.text = 'Light pressure';
    expect(form.validate(), AppStrings.trainingQuestionMinOptionsRequired);
    form.addOptionField();
    expect(form.validate(), AppStrings.trainingQuestionOptionsRequired);
    form.optionControllers.last.text = 'Heavy pressure';
    expect(form.validate(), isNull);
    expect(form.correctAnswerLabel, 'A');
  });

  test('correct answer cycles safely and follows the option when earlier rows are deleted', () {
    form.previousCorrectAnswer();
    form.nextCorrectAnswer();
    expect(form.selectedCorrectOptionIndex, -1);
    for (final text in ['First', 'Second', 'Third']) {
      form.addOptionField();
      form.optionControllers.last.text = text;
    }
    form.previousCorrectAnswer();
    expect(form.correctAnswerLabel, 'C');
    form.nextCorrectAnswer();
    expect(form.correctAnswerLabel, 'A');
    form.nextCorrectAnswer();
    final correctOption = form.optionControllers[1];

    form.removeOptionField(0);

    expect(form.optionControllers[form.selectedCorrectOptionIndex], same(correctOption));
    expect(form.correctAnswerLabel, 'A');
    form.removeOptionField(0);
    expect(form.correctAnswerLabel, 'A');
    form.removeOptionField(0);
    expect(form.selectedCorrectOptionIndex, -1);
    expect(form.canChangeCorrectAnswer, isFalse);
    form.addOptionField();
    expect(form.correctAnswerLabel, 'A');
  });

  test('option limit and invalid removals preserve the draft', () {
    for (var index = 0; index < 6; index++) {
      form.addOptionField();
    }
    expect(form.optionControllers, hasLength(4));
    expect(form.canAddOption, isFalse);
    form.removeOptionField(-1);
    form.removeOptionField(4);
    expect(form.optionControllers, hasLength(4));
    form.removeOptionField(3);
    expect(form.canAddOption, isTrue);
  });

  test('a PNG can be selected, kept after cancel, and removed', () async {
    final directory = await Directory.systemTemp.createTemp('question-image-');
    addTearDown(() => directory.delete(recursive: true));
    final image = await File('${directory.path}/picture.png').writeAsBytes([137, 80, 78, 71]);

    await form.pickQuestionImage(() async => image);
    expect(form.questionImage?.path, image.path);
    await form.pickQuestionImage(() async => null);
    expect(form.questionImage?.path, image.path);
    form.removeQuestionImage();
    expect(form.questionImage, isNull);
  });

  test('unsupported or oversized images do not replace a valid selection', () async {
    final directory = await Directory.systemTemp.createTemp('question-image-');
    addTearDown(() => directory.delete(recursive: true));
    final image = await File('${directory.path}/picture.JPG').writeAsBytes([255, 216, 255]);
    await form.pickQuestionImage(() async => image);

    await form.pickQuestionImage(() async => File('${directory.path}/picture.gif'));
    expect(form.validationMessage, AppStrings.trainingQuestionImageFormatError);
    expect(form.questionImage?.path, image.path);

    final oversized = File('${directory.path}/large.jpg');
    final handle = await oversized.open(mode: FileMode.write);
    await handle.truncate(TrainingQuestionFormController.maxImageBytes + 1);
    await handle.close();
    await form.pickQuestionImage(() async => oversized);
    expect(form.validationMessage, AppStrings.trainingQuestionImageSizeError);
    expect(form.questionImage?.path, image.path);
    expect(form.isPickingImage, isFalse);
  });

  test('duplicate picks are ignored and picker errors become a retryable error', () async {
    final result = Completer<File?>();
    final firstPick = form.pickQuestionImage(() => result.future);
    expect(form.isPickingImage, isTrue);
    await form.pickQuestionImage(() => throw StateError('Must not open twice'));
    result.completeError(StateError('Picker failed'));
    await firstPick;
    expect(form.validationMessage, AppStrings.pickImageError);
    expect(form.isPickingImage, isFalse);
    await form.pickQuestionImage(() async => null);
    expect(form.validationMessage, isNull);
  });

  test('closing the form while the picker is open does not notify after disposal', () async {
    final closingForm = TrainingQuestionFormController(minOptionCount: 2, maxOptionCount: 4);
    final result = Completer<File?>();
    final pick = closingForm.pickQuestionImage(() => result.future);
    closingForm.dispose();
    result.complete(File('picture.png'));
    await expectLater(pick, completes);
  });
}
