import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_option_delete_dialog.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_swipe_delete_action.dart';

void main() {
  Future<void> mountRow(WidgetTester tester, {required VoidCallback? onDelete}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: TrainingSwipeDeleteAction(
                onDelete: onDelete,
                child: const SizedBox(height: 60, child: Center(child: Text('Answer option'))),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Finder deleteAction() => find.text(AppStrings.trainingDeleteQuestionAction).hitTestable();

  testWidgets('a left swipe reveals Delete and waits for a tap', (tester) async {
    var requests = 0;
    await mountRow(tester, onDelete: () => requests++);
    expect(deleteAction(), findsNothing);

    await tester.drag(find.byType(TrainingSwipeDeleteAction), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(deleteAction(), findsOneWidget);
    expect(requests, 0);
    expect(find.text('Answer option'), findsOneWidget);

    await tester.tap(deleteAction());
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(deleteAction(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a right swipe closes the action without requesting deletion', (tester) async {
    var requests = 0;
    await mountRow(tester, onDelete: () => requests++);
    await tester.drag(find.byType(TrainingSwipeDeleteAction), const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(TrainingSwipeDeleteAction), const Offset(140, 0));
    await tester.pumpAndSettle();

    expect(deleteAction(), findsNothing);
    expect(requests, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled rows do not reveal Delete', (tester) async {
    await mountRow(tester, onDelete: null);
    await tester.drag(find.byType(TrainingSwipeDeleteAction), const Offset(-180, 0));
    await tester.pumpAndSettle();

    expect(deleteAction(), findsNothing);
    expect(find.text('Answer option'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping a tappable lesson reveals Delete without selecting the lesson', (
    tester,
  ) async {
    var selections = 0;
    var deleteRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: TrainingSwipeDeleteAction(
                deleteSemanticLabel: AppStrings.trainingLibraryDeleteLessonTitle,
                borderRadius: 18,
                onDelete: () => deleteRequests++,
                child: Material(
                  child: InkWell(
                    onTap: () => selections++,
                    child: const SizedBox(height: 84, child: Center(child: Text('Lesson title'))),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lesson title'));
    await tester.pumpAndSettle();
    expect(selections, 1);

    await tester.drag(find.byType(TrainingSwipeDeleteAction), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(deleteAction(), findsOneWidget);
    expect(selections, 1);
    expect(deleteRequests, 0);

    await tester.tap(deleteAction());
    await tester.pumpAndSettle();
    expect(deleteRequests, 1);
    expect(selections, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping an editable option asks for confirmation and Cancel keeps the text', (
    tester,
  ) async {
    final input = TextEditingController(text: 'Keep this option');
    addTearDown(input.dispose);
    var removals = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: SizedBox(
                width: 320,
                child: TrainingSwipeDeleteAction(
                  onDelete: () async {
                    if (await showTrainingOptionDeleteDialog(context)) removals++;
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(controller: input),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(TrainingSwipeDeleteAction), const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.tap(deleteAction());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.trainingDeleteOptionDescription), findsOneWidget);
    expect(removals, 0);

    await tester.tap(find.text(AppStrings.trainingCancel));
    await tester.pumpAndSettle();
    expect(input.text, 'Keep this option');
    expect(removals, 0);

    await tester.drag(find.byType(TrainingSwipeDeleteAction), const Offset(-180, 0));
    await tester.pumpAndSettle();
    await tester.tap(deleteAction());
    await tester.pumpAndSettle();
    await tester.tap(deleteAction());
    await tester.pumpAndSettle();
    expect(removals, 1);
    expect(tester.takeException(), isNull);
  });
}
