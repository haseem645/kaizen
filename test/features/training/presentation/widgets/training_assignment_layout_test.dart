import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_assignment_layout.dart';

void main() {
  testWidgets('scrolling the description keeps assignment details in place', (tester) async {
    final descriptionScroll = ScrollController();
    addTearDown(descriptionScroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 480,
            child: TrainingAssignmentLayout(
              header: const SizedBox(height: 140, child: Text('Assignment details')),
              body: SingleChildScrollView(
                key: const ValueKey('description'),
                controller: descriptionScroll,
                primary: false,
                child: const SizedBox(height: 1200, child: Text('Long assignment instructions')),
              ),
            ),
          ),
        ),
      ),
    );
    final headerBounds = tester.getRect(find.text('Assignment details'));
    final descriptionBounds = tester.getRect(find.byKey(const ValueKey('description')));

    await tester.drag(find.byKey(const ValueKey('description')), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(descriptionScroll.offset, greaterThan(0));
    expect(tester.getRect(find.text('Assignment details')), headerBounds);
    expect(tester.getRect(find.byKey(const ValueKey('description'))), descriptionBounds);
    expect(tester.takeException(), isNull);
  });

  testWidgets('focusing and scrolling the editor keeps upper content visible with the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final text = TextEditingController(text: List.filled(60, 'Assignment instructions').join('\n'));
    final descriptionScroll = ScrollController();
    addTearDown(text.dispose);
    addTearDown(descriptionScroll.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 72, child: Text('Lesson selector')),
              Expanded(
                child: TrainingAssignmentLayout(
                  header: const SizedBox(height: 140, child: Text('Assignment details')),
                  body: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: text,
                          scrollController: descriptionScroll,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(height: 56, child: Text('Formatting actions')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final selectorBounds = tester.getRect(find.text('Lesson selector'));
    final headerBounds = tester.getRect(find.text('Assignment details'));

    await tester.showKeyboard(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(TextField), const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(descriptionScroll.offset, greaterThan(0));
    expect(tester.getRect(find.text('Lesson selector')), selectorBounds);
    expect(tester.getRect(find.text('Assignment details')), headerBounds);
    expect(tester.getSize(find.byType(TextField)).height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a compact viewport lets long details scroll without moving the description', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 180,
            child: TrainingAssignmentLayout(
              header: const SizedBox(height: 600, child: Text('Long assignment details')),
              body: const ColoredBox(
                key: ValueKey('description'),
                color: Colors.white,
                child: Center(child: Text('Assignment instructions')),
              ),
            ),
          ),
        ),
      ),
    );
    final descriptionBounds = tester.getRect(find.byKey(const ValueKey('description')));
    expect(tester.getSize(find.byType(SingleChildScrollView)).height, greaterThan(0));
    expect(descriptionBounds.height, greaterThan(0));

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(const ValueKey('description'))), descriptionBounds);
    expect(tester.takeException(), isNull);
  });
}
