import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/widgets/app_department_filter_strip.dart';
import 'package:sparrowkaizen/core/widgets/app_department_selection_sheet.dart';
import 'package:sparrowkaizen/core/widgets/app_overlay_close_button.dart';
import 'package:sparrowkaizen/core/widgets/app_selection_sheet.dart';

const _departments = <AppDepartmentFilterItem>[
  AppDepartmentFilterItem(id: 'all', name: AppStrings.categoryAll),
  AppDepartmentFilterItem(id: 'engineering', name: 'Engineering'),
  AppDepartmentFilterItem(id: 'people', name: 'People'),
  AppDepartmentFilterItem(id: 'sales', name: 'Sales'),
  AppDepartmentFilterItem(id: 'finance', name: 'Finance Operations'),
];

void main() {
  testWidgets('See All makes departments beyond the preview searchable and selectable', (
    tester,
  ) async {
    String? selectedId;
    await tester.pumpWidget(_host(items: _departments, onSelected: (id) => selectedId = id));

    expect(find.text('Finance Operations'), findsNothing);
    await tester.tap(find.text('Engineering'));
    expect(selectedId, 'engineering');

    await tester.tap(find.text(AppStrings.seeAllAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  FINANCE  ');
    await tester.pumpAndSettle();

    expect(_sheetText('People'), findsNothing);
    expect(_sheetText(AppStrings.categoryAll), findsOneWidget);
    await tester.tap(_sheetText('Finance Operations'));
    await tester.pumpAndSettle();

    expect(selectedId, 'finance');
    expect(find.byType(AppSelectionSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restricted options stay restricted in the row and searchable picker', (
    tester,
  ) async {
    String? selectedId;
    await tester.pumpWidget(
      _host(
        items: _departments.where((item) => item.id == 'sales').toList(),
        onSelected: (id) => selectedId = id,
      ),
    );

    expect(find.text(AppStrings.categoryAll), findsNothing);
    await tester.tap(find.text(AppStrings.seeAllAction));
    await tester.pumpAndSettle();
    expect(_sheetText(AppStrings.categoryAll), findsNothing);
    expect(_sheetText('Engineering'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Finance');
    await tester.pumpAndSettle();
    expect(_sheetText(AppStrings.departmentsNoSearchResults), findsOneWidget);
    expect(_sheetText('Finance Operations'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(_sheetText('Sales'));
    await tester.pumpAndSettle();
    expect(selectedId, 'sales');
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text on a narrow screen keeps See All reachable and cancel clears search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? selectedId;
    await tester.pumpWidget(
      _host(items: _departments, onSelected: (id) => selectedId = id, textScale: 1.5),
    );

    await tester.drag(find.byType(AppDepartmentFilterStrip), const Offset(-700, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.seeAllAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Finance');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppOverlayCloseButton));
    await tester.pumpAndSettle();

    expect(selectedId, isNull);
    await tester.tap(find.text(AppStrings.seeAllAction));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, isEmpty);
    expect(_sheetText('Engineering'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Finder _sheetText(String text) =>
    find.descendant(of: find.byType(AppSelectionSheet), matching: find.text(text));

Widget _host({
  required List<AppDepartmentFilterItem> items,
  required ValueChanged<String> onSelected,
  double textScale = 1,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: AppDepartmentFilterStrip(
            items: items,
            selectedDepartmentId: items.first.id,
            onSelected: onSelected,
            onSeeAll: () async {
              final id = await showAppDepartmentSelectionSheet(
                context,
                items: items,
                selectedDepartmentId: items.first.id,
              );
              if (id != null) onSelected(id);
            },
          ),
        ),
      ),
    ),
  );
}
