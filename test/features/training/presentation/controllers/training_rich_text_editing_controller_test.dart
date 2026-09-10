import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_module_controller.dart';

void main() {
  const firstParagraph = 'Standard Operating Procedure';
  const remainingContent = '\n\nPurpose\nFollow the procedure.';
  const document = '$firstParagraph$remainingContent';

  late TrainingRichTextEditingController controller;

  setUp(() {
    controller = TrainingRichTextEditingController(text: document);
  });

  tearDown(() => controller.dispose());

  test(
    'preserves repeated HTML line breaks instead of collapsing blank lines',
    () {
      controller.loadFromHtml(
        'Purpose<br><br>Scope<br/><br /><BR class="gap">Procedure',
      );

      expect(controller.text, 'Purpose\n\nScope\n\n\nProcedure');
      expect(controller.toHtml(), 'Purpose<br><br>Scope<br><br><br>Procedure');
    },
  );

  test('paragraph and heading spacing survives saving and reopening', () {
    controller.loadFromHtml(
      '<h2 class="title">SOP</h2>\n'
      '<p class="purpose">Purpose</p>\n'
      '<p><strong>Follow the procedure.</strong></p>',
    );
    const expected = 'SOP\n\nPurpose\n\nFollow the procedure.';
    expect(controller.text, expected);

    for (var reload = 0; reload < 3; reload++) {
      controller.loadFromHtml(controller.toHtml());
      expect(controller.text, expected);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 3,
      );
      expect(
        controller.isFormatActive(TrainingDocumentFormatKind.heading),
        isTrue,
      );
      controller.selection = TextSelection(
        baseOffset: expected.indexOf('Follow'),
        extentOffset: expected.length,
      );
      expect(
        controller.isFormatActive(TrainingDocumentFormatKind.bold),
        isTrue,
      );
    }
  });

  test('formatting after large gaps keeps its correct text offsets', () {
    controller.loadFromHtml(
      'First<br><br><br><br><strong class="text">Last</strong>',
    );
    const expected = 'First\n\n\n\nLast';
    expect(controller.text, expected);
    controller.selection = TextSelection(
      baseOffset: expected.indexOf('Last'),
      extentOffset: expected.length,
    );
    expect(controller.isFormatActive(TrainingDocumentFormatKind.bold), isTrue);

    final saved = controller.toHtml();
    expect(saved, 'First<br><br><br><br><strong>Last</strong>');
    controller.loadFromHtml(saved);
    expect(controller.text, expected);
  });

  test('empty paragraphs retain their additional blank line', () {
    controller.loadFromHtml('<p>First</p><p><br></p><p>Last</p>');
    expect(controller.text, 'First\n\n\nLast');
    controller.loadFromHtml(controller.toHtml());
    expect(controller.text, 'First\n\n\nLast');
  });

  test('list items and following paragraphs keep separate lines', () {
    controller.loadFromHtml(
      '<p>Steps</p><ol class="steps"><li>First<br><br>Details</li><li>Second</li></ol>'
      '<p>Finish</p>',
    );
    expect(controller.text, 'Steps\n\n1. First\n\nDetails\n2. Second\nFinish');
    controller.loadFromHtml(controller.toHtml());
    expect(controller.text, 'Steps\n\n1. First\n\nDetails\n2. Second\nFinish');
  });

  for (final selection in <String, TextSelection>{
    'first paragraph': const TextSelection(
      baseOffset: 0,
      extentOffset: firstParagraph.length,
    ),
    'reversed first paragraph': const TextSelection(
      baseOffset: firstParagraph.length,
      extentOffset: 0,
    ),
    'whole document': const TextSelection(
      baseOffset: 0,
      extentOffset: document.length,
    ),
  }.entries) {
    test('toolbar reads formatting for the ${selection.key}', () {
      controller.selection = selection.value;

      expect(controller.isBulletListActive, isFalse);
      expect(controller.isNumberedListActive, isFalse);
      for (final format in TrainingDocumentFormatKind.values) {
        expect(controller.isFormatActive(format), isFalse);
      }
      expect(controller.text, document);
      expect(controller.selection, selection.value);
    });
  }

  test('bullet formatting toggles the first paragraph only', () {
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: firstParagraph.length,
    );

    controller.applyBulletList();

    expect(controller.text, '• $firstParagraph$remainingContent');
    expect(controller.isBulletListActive, isTrue);
    expect(controller.isNumberedListActive, isFalse);
    expect(
      controller.selection.textInside(controller.text),
      '• $firstParagraph',
    );

    controller.applyBulletList();

    expect(controller.text, document);
    expect(controller.isBulletListActive, isFalse);
  });

  test('numbered formatting handles a reversed first-paragraph selection', () {
    controller.selection = const TextSelection(
      baseOffset: firstParagraph.length,
      extentOffset: 0,
    );

    controller.applyNumberedList();

    expect(controller.text, '1. $firstParagraph$remainingContent');
    expect(controller.isNumberedListActive, isTrue);
    expect(controller.isBulletListActive, isFalse);

    controller.applyNumberedList();

    expect(controller.text, document);
    expect(controller.isNumberedListActive, isFalse);
  });

  test('select-all list formatting preserves blank paragraphs', () {
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: document.length,
    );

    controller.applyNumberedList();

    expect(
      controller.text,
      '1. $firstParagraph\n\n2. Purpose\n3. Follow the procedure.',
    );
    expect(controller.isNumberedListActive, isTrue);

    controller.applyNumberedList();

    expect(controller.text, document);
  });

  test('inline formatting at the start keeps list controls readable', () {
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: firstParagraph.length,
    );
    final originalHtml = controller.toHtml();
    final actions = <TrainingDocumentFormatKind, VoidCallback>{
      TrainingDocumentFormatKind.bold: controller.applyBold,
      TrainingDocumentFormatKind.italic: controller.applyItalic,
      TrainingDocumentFormatKind.underline: controller.applyUnderline,
      TrainingDocumentFormatKind.heading: controller.applyHeading,
      TrainingDocumentFormatKind.quote: controller.applyQuote,
    };

    for (final action in actions.entries) {
      action.value();

      expect(controller.isFormatActive(action.key), isTrue);
      expect(controller.isBulletListActive, isFalse);
      expect(controller.isNumberedListActive, isFalse);
      expect(controller.toHtml(), isNot(originalHtml));
      expect(controller.text, document);

      action.value();

      expect(controller.isFormatActive(action.key), isFalse);
      expect(controller.toHtml(), originalHtml);
    }
  });

  test('a caret at the start and an empty document leave lists inactive', () {
    controller.selection = const TextSelection.collapsed(offset: 0);

    expect(controller.isBulletListActive, isFalse);
    expect(controller.isNumberedListActive, isFalse);
    controller.applyBulletList();
    expect(controller.text, document);

    controller.clear();
    controller.applyNumberedList();

    expect(controller.isBulletListActive, isFalse);
    expect(controller.isNumberedListActive, isFalse);
    expect(controller.text, isEmpty);
  });
}
