import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/core/widgets/app_overlay_close_button.dart';
import 'package:sparrowkaizen/features/login/domain/entities/user.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/entities/department.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/entities/seat_profile_detail.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/usecases/get_seat_profiles_usecase.dart';
import 'package:sparrowkaizen/features/seat_profile/presentation/pages/seat_profile_detail_screen.dart';
import 'package:sparrowkaizen/features/seat_profile/presentation/pages/shared_seat_profile_screen.dart';
import 'package:sparrowkaizen/features/seat_profile/presentation/providers/seat_profile_detail_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreference.init();
    AppManager.instance.resetSessionState();
    AppManager.instance.updateCurrentUser(
      User(uuid: 'owner', isOwner: true, organizationUuid: 'org'),
    );
  });
  tearDown(AppManager.instance.resetSessionState);

  testWidgets('category headers stay fixed while descriptions expand and collapse smoothly', (
    tester,
  ) async {
    await _openScreen(tester);
    final card = _category('finance');
    final title = find.text('Financial Management');
    final weight = find.text('30%');
    final nextTitle = find.text('Service Quality');
    final addAction = _withinCategory('finance', AppStrings.seatProfileAddSeatDescriptionAction);
    final description = find.text('Controls Financial Records');
    final collapsedHeight = tester.getSize(card).height;
    final titleTop = tester.getTopLeft(title).dy;
    final weightTop = tester.getTopLeft(weight).dy;
    final nextTitleTop = tester.getTopLeft(nextTitle).dy;
    expect(description.hitTestable(), findsNothing);
    expect(addAction.hitTestable(), findsNothing);

    await tester.tap(title);
    await tester.pump();
    var previousHeight = collapsedHeight;
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 40));
      final height = tester.getSize(card).height;
      expect(height, greaterThan(previousHeight));
      expect(tester.getTopLeft(title).dy, closeTo(titleTop, 0.01));
      expect(tester.getTopLeft(weight).dy, closeTo(weightTop, 0.01));
      expect(
        tester.getTopLeft(nextTitle).dy,
        closeTo(nextTitleTop + height - collapsedHeight, 0.01),
      );
      if (frame < 7) {
        expect(description.hitTestable(), findsNothing);
        expect(addAction.hitTestable(), findsNothing);
      }
      previousHeight = height;
    }
    await tester.pumpAndSettle();
    expect(description.hitTestable(), findsOneWidget);
    expect(addAction.hitTestable(), findsOneWidget);
    expect(_controller(tester).isCategoryExpanded('finance'), isTrue);
    expect(_controller(tester).isCategoryExpanded('service'), isFalse);

    await tester.tap(title);
    await tester.pump();
    expect(description.hitTestable(), findsNothing);
    expect(addAction.hitTestable(), findsNothing);
    for (var frame = 0; frame < 7; frame++) {
      await tester.pump(const Duration(milliseconds: 40));
      final height = tester.getSize(card).height;
      expect(height, lessThan(previousHeight));
      expect(tester.getTopLeft(title).dy, closeTo(titleTop, 0.01));
      expect(tester.getTopLeft(weight).dy, closeTo(weightTop, 0.01));
      previousHeight = height;
    }
    expect(previousHeight, closeTo(collapsedHeight, 0.01));
    expect(_controller(tester).isCategoryExpanded('finance'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header and chevron taps reverse smoothly through controller rebuilds', (
    tester,
  ) async {
    await _openScreen(tester);
    final controller = _controller(tester);
    final card = _category('finance');
    final title = find.text('Financial Management');
    final chevron = find
        .ancestor(
          of: find.descendant(of: card, matching: find.byType(RotationTransition)),
          matching: find.byType(GestureDetector),
        )
        .first;
    final collapsedHeight = tester.getSize(card).height;

    await tester.tap(chevron);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    final openingHeight = tester.getSize(card).height;
    expect(openingHeight, greaterThan(collapsedHeight));
    controller.selectTone(SeatProfileDetailContentTone.technical);
    await tester.pump();
    expect(tester.getSize(card).height, closeTo(openingHeight, 0.01));

    await tester.tap(title);
    await tester.pump();
    expect(tester.getSize(card).height, closeTo(openingHeight, 0.01));
    await tester.pump(const Duration(milliseconds: 60));
    final closingHeight = tester.getSize(card).height;
    expect(closingHeight, lessThan(openingHeight));
    expect(controller.isCategoryExpanded('finance'), isFalse);

    await tester.tap(chevron);
    await tester.pump();
    expect(tester.getSize(card).height, closeTo(closingHeight, 0.01));
    await tester.pumpAndSettle();
    final expandedHeight = tester.getSize(card).height;
    expect(expandedHeight, greaterThan(openingHeight));
    expect(controller.isCategoryExpanded('finance'), isTrue);
    await controller.refresh();
    await tester.pumpAndSettle();
    expect(tester.getSize(card).height, expandedHeight);
    expect(controller.isCategoryExpanded('finance'), isTrue);

    await tester.tap(find.text('Controls Financial Records'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsWidgets);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'Controls Financial Records',
    );
    final cardTapDraft = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!.text)
        .toList();
    await tester.tap(find.byType(AppOverlayCloseButton));
    await tester.pumpAndSettle();
    final edit = _withinCategory('finance', AppStrings.seatProfileEditAction);
    final trainings = _withinCategory('finance', AppStrings.seatProfileViewTrainings);
    expect(edit.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(edit).dx, lessThan(tester.getTopLeft(trainings).dx));
    expect(tester.getTopLeft(edit).dy, closeTo(tester.getTopLeft(trainings).dy, 0.01));
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(
      tester.widgetList<TextField>(find.byType(TextField)).map((field) => field.controller!.text),
      cardTapDraft,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long category titles expand safely with large text on narrow screens', (
    tester,
  ) async {
    AppManager.instance.updateCurrentUser(User(uuid: 'member', roles: ['team_member']));
    const longTitle = 'Financial Management and Customer Experience Operations';
    await _openScreen(tester, firstTitle: longTitle, width: 320, textScale: 2);
    final title = find.text(longTitle);
    final titleTop = tester.getTopLeft(title).dy;
    await tester.tap(title);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.getTopLeft(title).dy, closeTo(titleTop, 0.01));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    final trainings = _withinCategory('finance', AppStrings.seatProfileViewTrainings);
    await tester.ensureVisible(trainings);
    await tester.pumpAndSettle();
    expect(trainings.hitTestable(), findsOneWidget);
    expect(find.text(AppStrings.seatProfileAddSeatDescriptionAction), findsNothing);
    expect(find.text(AppStrings.seatProfileEditAction), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion opens empty categories immediately', (tester) async {
    await _openScreen(tester, disableAnimations: true);
    final card = _category('service');
    final title = find.text('Service Quality');
    final collapsedHeight = tester.getSize(card).height;
    final titleTop = tester.getTopLeft(title).dy;
    final emptyMessage = _withinCategory('service', AppStrings.seatProfileNoDescriptionsFound);
    expect(emptyMessage.hitTestable(), findsNothing);

    await tester.tap(title);
    await tester.pump();
    final expandedHeight = tester.getSize(card).height;
    expect(expandedHeight, greaterThan(collapsedHeight));
    expect(emptyMessage.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(title).dy, titleTop);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(card).height, expandedHeight);

    await tester.tap(title);
    await tester.pump();
    expect(tester.getSize(card).height, collapsedHeight);
    expect(emptyMessage.hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared details expand smoothly and keep editing actions hidden', (tester) async {
    await _openScreen(tester, shared: true);
    final title = find.text('Financial Management');
    final titleTop = tester.getTopLeft(title).dy;
    await tester.tap(title);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.getTopLeft(title).dy, closeTo(titleTop, 0.01));
    await tester.pumpAndSettle();
    expect(find.text('Controls Financial Records').hitTestable(), findsOneWidget);
    expect(find.text(AppStrings.seatProfileAddSeatDescriptionAction), findsNothing);
    expect(find.text(AppStrings.seatProfileViewTrainings), findsNothing);
    expect(find.text(AppStrings.seatProfileEditAction), findsNothing);
    expect(find.text(AppStrings.seatProfileGenerateAction), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final textScale in [1.0, 2.0]) {
    testWidgets('truncated specifics keep inline See All visible at text scale $textScale', (
      tester,
    ) async {
      final specifics = List.filled(
        12,
        'Verify every invoice and its approval before closing the monthly accounts.',
      ).join(' ');
      await _openScreen(
        tester,
        width: textScale == 1 ? 390 : 320,
        textScale: textScale,
        auditSpecifics: specifics,
      );
      await tester.scrollUntilVisible(find.text('Financial Management'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Financial Management'));
      await tester.pumpAndSettle();
      final seeAll = _withinCategory('finance', AppStrings.seeAllAction);
      expect(seeAll, findsOneWidget);
      await tester.ensureVisible(seeAll);
      await tester.pumpAndSettle();
      expect(seeAll.hitTestable(), findsOneWidget);
      final preview = find.textContaining(
        AppStrings.seatProfileDescriptionEllipsis,
        findRichText: true,
      );
      expect(preview, findsOneWidget);
      expect(tester.getRect(preview).contains(tester.getCenter(seeAll)), isTrue);
      expect(find.text(specifics), findsNothing);
      await tester.tap(seeAll);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text(specifics), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}

Finder _category(String id) => find.byKey(ValueKey(id));

Finder _withinCategory(String id, String label) =>
    find.descendant(of: _category(id), matching: find.text(label));

SeatProfileDetailController _controller(WidgetTester tester) =>
    tester.element(find.byType(SeatProfileDetailView)).read<SeatProfileDetailController>();

Future<void> _openScreen(
  WidgetTester tester, {
  String firstTitle = 'Financial Management',
  double width = 390,
  double textScale = 1,
  bool disableAnimations = false,
  bool shared = false,
  String auditSpecifics = 'Verify all transactions accurately',
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final useCase = _SeatProfileDetailUseCase(firstTitle, auditSpecifics);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: disableAnimations),
        child: child!,
      ),
      home: shared
          ? SharedSeatProfileScreen(publicId: 'public-id', getSeatProfilesUseCase: useCase)
          : SeatProfileDetailScreen(seatId: 'seat-id', getSeatProfilesUseCase: useCase),
    ),
  );
  await tester.pumpAndSettle();
}

class _SeatProfileDetailUseCase extends Fake implements GetSeatProfilesUseCase {
  _SeatProfileDetailUseCase(this.firstTitle, this.auditSpecifics);

  final String firstTitle;
  final String auditSpecifics;

  @override
  Future<String?> getSeatProfilePublicLink(String seatId) async => null;

  @override
  Future<SeatProfileDetail> getSeatProfileDetail(String seatId) async => _detail;

  @override
  Future<SeatProfileDetail> getSharedSeatProfileDetail(String publicId) async => _detail;

  SeatProfileDetail get _detail => SeatProfileDetail(
    id: 'seat-id',
    actualId: 'actual-seat-id',
    title: 'Operations Lead',
    department: const Department(id: 'operations', name: 'Operations'),
    paygradeUnit: 'hr',
    categories: [
      SeatProfileCategory(
        id: 'finance',
        title: firstTitle,
        weightPercent: 30,
        descriptions: [
          SeatProfileDescription(
            id: 'records',
            actualId: 'actual-records',
            name: 'Controls Financial Records',
            auditSpecifics: auditSpecifics,
            auditFactorType: 'observation',
            milestoneDays: '30',
          ),
        ],
      ),
      const SeatProfileCategory(
        id: 'service',
        title: 'Service Quality',
        weightPercent: 70,
        descriptions: [],
      ),
    ],
  );
}
