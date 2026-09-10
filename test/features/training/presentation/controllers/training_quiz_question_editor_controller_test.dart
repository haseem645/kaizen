import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/training/domain/entities/seat_description_training.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_quiz_question_editor_controller.dart';

void main() {
  const question = SeatDescriptionTrainingQuestion(
    uuid: 'question-1',
    question: 'Which option is correct?',
    options: [
      SeatDescriptionTrainingQuestionOption(uuid: 'option-a', text: 'First'),
      SeatDescriptionTrainingQuestionOption(uuid: 'option-b', text: 'Second'),
    ],
    selectedOptionUuid: 'option-a',
    imageUrl: null,
  );
  late TrainingQuizQuestionEditorController editor;

  setUp(() {
    editor = TrainingQuizQuestionEditorController(question: question)..startEditing();
  });
  tearDown(() => editor.dispose());

  test('correct-answer arrows wrap through the existing options', () {
    expect(editor.correctAnswerLabel, 'A');
    expect(editor.canChangeCorrectAnswer, isTrue);

    editor.previousCorrectAnswer();
    expect(editor.correctAnswerLabel, 'B');
    expect(editor.selectedCorrectOptionUuid, 'option-b');

    editor.nextCorrectAnswer();
    expect(editor.correctAnswerLabel, 'A');
    expect(editor.selectedCorrectOptionUuid, 'option-a');
  });

  test('answer letters include new options and follow UUIDs when earlier options are removed', () {
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Third';
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Fourth';
    final fourthUuid = editor.draftOptionUuid;

    editor.previousCorrectAnswer();
    expect(editor.correctAnswerLabel, 'D');
    expect(editor.selectedCorrectOptionUuid, fourthUuid);
    editor.nextCorrectAnswer();
    expect(editor.correctAnswerLabel, 'A');
    editor.previousCorrectAnswer();
    editor.removeExistingOption('option-a');

    expect(editor.correctAnswerLabel, 'C');
    expect(editor.selectedCorrectOptionUuid, fourthUuid);
    expect(editor.validate(question), isNull);
  });

  test('empty and single-option states keep arrow selection safe', () {
    editor.removeExistingOption('option-a');
    editor.removeExistingOption('option-b');
    editor.previousCorrectAnswer();
    editor.nextCorrectAnswer();
    expect(editor.correctAnswerLabel, AppStrings.trainingQuestionNoCorrectAnswer);
    expect(editor.canChangeCorrectAnswer, isFalse);

    editor.showDraftOption(question);
    expect(editor.correctAnswerLabel, 'A');
    expect(editor.canChangeCorrectAnswer, isFalse);
    editor.previousCorrectAnswer();
    editor.nextCorrectAnswer();
    expect(editor.selectedCorrectOptionUuid, editor.draftOptionUuid);
  });

  test('adds multiple options before saving and preserves their UUIDs and correct answer', () {
    editor.showDraftOption(question);
    final thirdUuid = editor.draftOptionUuid;
    editor.draftOptionController.text = ' Third ';
    editor.selectCorrectOption(thirdUuid);

    editor.showDraftOption(question);
    final fourthUuid = editor.draftOptionUuid;
    editor.draftOptionController.text = 'Fourth';

    final options = editor.buildOptions(question);
    expect(options.map((option) => option.text), ['First', 'Second', 'Third', 'Fourth']);
    expect(options.map((option) => option.uuid), ['option-a', 'option-b', thirdUuid, fourthUuid]);
    expect(thirdUuid, isNot(fourthUuid));
    expect(editor.selectedCorrectOptionUuid, thirdUuid);
    expect(editor.validate(question), isNull);
    expect(editor.canSave(question: question), isTrue);

    final promotedOption = editor.visibleExistingOptions(question).last;
    editor.optionControllerFor(promotedOption).text = 'Updated third';
    expect(editor.buildOptions(question)[2].text, 'Updated third');
  });

  test('adding another row keeps blank options and requires them to be filled or removed', () {
    editor.showDraftOption(question);
    final blankUuid = editor.draftOptionUuid;
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Fourth';

    expect(editor.visibleExistingOptions(question).last.uuid, blankUuid);
    expect(editor.validate(question), AppStrings.trainingQuestionOptionsRequired);
    expect(editor.canSave(question: question), isFalse);

    editor.removeExistingOption(blankUuid);
    expect(editor.validate(question), isNull);
    expect(editor.buildOptions(question).map((option) => option.text), [
      'First',
      'Second',
      'Fourth',
    ]);
  });

  test('removing the last draft keeps the chosen existing answer and other additions', () {
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Third';
    editor.showDraftOption(question);
    editor.selectCorrectOption('option-b');
    editor.removeDraftOption(question);

    expect(editor.showsDraftOption, isFalse);
    expect(editor.selectedCorrectOptionUuid, 'option-b');
    expect(editor.isOptionSelected('option-b'), isTrue);
    expect(editor.buildOptions(question), hasLength(3));
    expect(editor.canSave(question: question), isTrue);
  });

  test('removing an added correct option falls back to an existing option', () {
    editor.showDraftOption(question);
    final thirdUuid = editor.draftOptionUuid;
    editor.draftOptionController.text = 'Third';
    editor.selectCorrectOption(thirdUuid);
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Fourth';
    editor.removeExistingOption(thirdUuid);

    expect(editor.selectedCorrectOptionUuid, 'option-a');
    expect(editor.buildOptions(question).any((option) => option.uuid == thirdUuid), isFalse);
    expect(editor.validate(question), isNull);
  });

  test('cancel restores original options and discards all local additions', () {
    editor.optionControllerFor(question.options.first).text = 'Changed';
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Third';
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Fourth';
    editor.selectCorrectOption(editor.draftOptionUuid);
    editor.finishEditing(question);

    expect(editor.isEditing, isFalse);
    expect(editor.showsDraftOption, isFalse);
    expect(editor.buildOptions(question).map((option) => option.text), ['First', 'Second']);
    expect(editor.selectedCorrectOptionUuid, 'option-a');
    expect(editor.canSave(question: question), isFalse);
  });

  test('a refreshed saved question retains added options without duplicates', () {
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Third';
    editor.showDraftOption(question);
    editor.draftOptionController.text = 'Fourth';
    editor.selectCorrectOption(editor.draftOptionUuid);
    final savedQuestion = SeatDescriptionTrainingQuestion(
      uuid: question.uuid,
      question: question.question,
      options: editor.buildOptions(question),
      selectedOptionUuid: editor.selectedCorrectOptionUuid,
      imageUrl: null,
    );

    editor.syncWithQuestion(savedQuestion);

    expect(editor.isEditing, isFalse);
    expect(editor.showsDraftOption, isFalse);
    expect(editor.buildOptions(savedQuestion), hasLength(4));
    expect(editor.selectedCorrectOptionUuid, savedQuestion.selectedOptionUuid);
    expect(editor.canSave(question: savedQuestion), isFalse);
  });
}
