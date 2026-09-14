import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_library_lesson_actions_sheet.dart';

void main() {
  testWidgets('actions appear in design order and return the selected action', (
    tester,
  ) async {
    TrainingLibraryLessonAction? selected;
    await tester.pumpWidget(
      _host(canEdit: true, onSelected: (action) => selected = action),
    );

    final visibility = find.text(AppStrings.visibilityLabel);
    final edit = find.text(AppStrings.trainingEditAssignment);
    final delete = find.text(AppStrings.trainingDeleteModuleAction);
    expect(
      tester.getTopLeft(visibility).dy,
      lessThan(tester.getTopLeft(edit).dy),
    );
    expect(tester.getTopLeft(edit).dy, lessThan(tester.getTopLeft(delete).dy));
    expect(find.text(AppStrings.trainingLibraryLessonActions), findsOneWidget);
    expect(find.byIcon(Icons.north_east), findsOneWidget);

    await tester.tap(visibility);
    expect(selected, TrainingLibraryLessonAction.visibility);
    await tester.tap(edit);
    expect(selected, TrainingLibraryLessonAction.edit);
    await tester.tap(delete);
    expect(selected, TrainingLibraryLessonAction.delete);
  });

  testWidgets('read-only accounts see no lesson actions or visibility', (
    tester,
  ) async {
    var selected = false;
    await tester.pumpWidget(
      _host(canEdit: false, onSelected: (_) => selected = true),
    );

    expect(find.text(AppStrings.trainingLibraryLessonActions), findsNothing);
    expect(find.text(AppStrings.visibilityLabel), findsNothing);
    expect(find.text(AppStrings.trainingEditAssignment), findsNothing);
    expect(find.text(AppStrings.trainingDeleteModuleAction), findsNothing);
    expect(find.byIcon(Icons.north_east), findsNothing);
    expect(selected, isFalse);
  });

  for (final isPubliclyAvailable in [false, true]) {
    testWidgets(
      'no actions bottom sheet opens without edit permission (public: $isPubliclyAvailable)',
      (tester) async {
        var returned = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    final action = await showTrainingLibraryLessonActionsSheet(
                      context,
                      canEdit: false,
                      isPubliclyAvailable: isPubliclyAvailable,
                    );
                    expect(action, isNull);
                    returned = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(returned, isTrue);
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.byType(TrainingLibraryLessonActionsSheet), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('actions wrap on a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _host(
        canEdit: true,
        onSelected: (_) {},
        textScaler: const TextScaler.linear(2),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.text(AppStrings.trainingDeleteModuleAction),
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _host({
  required bool canEdit,
  required ValueChanged<TrainingLibraryLessonAction> onSelected,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: TrainingLibraryLessonActionsSheet(
            canEdit: canEdit,
            isPubliclyAvailable: true,
            onSelected: onSelected,
            onClose: () {},
          ),
        ),
      ),
    ),
  ),
);
