import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/network/api_processor.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/core/widgets/app_overlay_close_button.dart';
import 'package:sparrowkaizen/features/login/domain/entities/user.dart';
import 'package:sparrowkaizen/features/paygrades/data/datasources/paygrade_remote_data_source.dart';
import 'package:sparrowkaizen/features/paygrades/data/repositories/paygrade_repository_impl.dart';
import 'package:sparrowkaizen/features/paygrades/domain/usecases/get_paygrades_usecase.dart';
import 'package:sparrowkaizen/features/paygrades/presentation/pages/paygrade_detail_screen.dart';
import 'package:sparrowkaizen/features/paygrades/presentation/providers/paygrade_detail_controller.dart';

void main() {
  late _Executor executor;
  late GetPaygradesUseCase useCase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreference.init();
    AppManager.instance.resetSessionState();
    AppManager.instance.updateCurrentUser(
      User(uuid: 'owner', isOwner: true, organizationUuid: 'org'),
    );
    executor = _Executor();
    useCase = GetPaygradesUseCase(
      PaygradeRepositoryImpl(
        PaygradeRemoteDataSource(apiCallExecutor: executor),
      ),
    );
  });
  tearDown(AppManager.instance.resetSessionState);

  Future<void> openScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaygradeDetailScreen(
          paygradeId: 'job-id',
          getPaygradesUseCase: useCase,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('row opens a prefilled dialog and PATCH updates only that rate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    executor.pendingSave = Completer<void>();
    await openScreen(tester);
    expect(find.text('10.00/hr'), findsOneWidget);
    await tester.tap(find.text(AppStrings.paygradesRate).first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('ID1: Instructional Designer'),
      ),
      findsOneWidget,
    );
    expect(find.text(AppStrings.paygradesPayRateInputLabel), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '10.00',
    );
    final save = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(TextButton),
    );
    final size = tester.getSize(save);
    await tester.enterText(find.byType(TextField), '12.50');
    await tester.tap(save);
    await tester.pump();
    expect(tester.getSize(save), size);
    expect(tester.widget<TextButton>(save).onPressed, isNull);
    expect(find.text('10.00/hr'), findsOneWidget);
    expect(executor.patches, hasLength(1));
    expect(executor.patches.single.endpoint, 'pay_grade/$_entryId/');
    expect(executor.patches.single.payload, {
      'uuid': _entryId,
      'pay_rate': '12.50',
    });
    executor.pendingSave!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('12.50/hr'), findsOneWidget);
    expect(find.text('20.00/hr'), findsOneWidget);
    expect(find.text('ID1: Instructional Designer'), findsOneWidget);
    expect(find.text('Primary responsibilities'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid values and cancelling do not write', (tester) async {
    await openScreen(tester);
    await tester.tap(find.text('10.00/hr'));
    await tester.pumpAndSettle();
    for (final value in ['', '-10', 'abc', 'NaN', 'Infinity', '1e3']) {
      await tester.enterText(find.byType(TextField), value);
      await tester.tap(find.text(AppStrings.seatProfileSaveAction));
      await tester.pump();
      expect(find.text(AppStrings.paygradesPayRateInvalid), findsOneWidget);
      expect(executor.patches, isEmpty);
    }
    await tester.enterText(find.byType(TextField), '99');
    await tester.tap(find.byType(AppOverlayCloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('10.00/hr'), findsOneWidget);
    expect(executor.patches, isEmpty);
  });

  testWidgets('failed saves retain the draft and can retry', (tester) async {
    executor.failNextSave = true;
    await openScreen(tester);
    await tester.tap(find.text('10.00/hr'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text(AppStrings.seatProfileSaveAction));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.paygradesPayRateSaveFailed), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '0',
    );
    expect(find.text('10.00/hr'), findsOneWidget);
    await tester.tap(find.text(AppStrings.seatProfileSaveAction));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('0/hr'), findsOneWidget);
    expect(executor.patches, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ancillary rates save to the ancillary entry', (tester) async {
    await openScreen(tester);
    await tester.tap(find.text(AppStrings.paygradesAncillaryTab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30.00/hr'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.text('LD1: Lead Designer'),
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '35');
    await tester.tap(find.text(AppStrings.seatProfileSaveAction));
    await tester.pumpAndSettle();
    expect(executor.patches.single.endpoint, 'pay_grade/ancillary-entry/');
    expect(executor.patches.single.payload, {
      'uuid': 'ancillary-entry',
      'pay_rate': '35',
    });
    expect(find.text('35/hr'), findsOneWidget);
    await tester.tap(find.text(AppStrings.paygradesPrimaryTab));
    await tester.pumpAndSettle();
    expect(find.text('10.00/hr'), findsOneWidget);
  });

  test(
    'a pending save targets its original tab and blocks duplicate writes',
    () async {
      final controller = PaygradeDetailController(useCase);
      addTearDown(controller.dispose);
      await controller.initialize('job-id');
      final entry = controller.detail!.payGrades.first;
      executor.pendingSave = Completer<void>();
      final save = controller.updatePayRate(entry: entry, payRate: '42');
      await expectLater(
        controller.updatePayRate(entry: entry, payRate: '43'),
        throwsStateError,
      );
      await controller.selectTab(PaygradeDetailTab.ancillary);
      executor.pendingSave!.complete();
      await save;
      expect(controller.detail!.payGrades.single.payRate, '30.00');
      await controller.selectTab(PaygradeDetailTab.primary);
      expect(controller.detail!.payGrades.first.payRate, '42');
      expect(executor.patches, hasLength(1));
      expect(controller.isUpdatingPaygrade, isFalse);
    },
  );

  test(
    'permission loss and child organisations block writes in the controller',
    () async {
      final controller = PaygradeDetailController(useCase);
      addTearDown(controller.dispose);
      await controller.initialize('job-id');
      final entry = controller.detail!.payGrades.first;
      AppManager.instance.updateCurrentUser(
        User(uuid: 'member', organizationUuid: 'org', roles: ['team_member']),
      );
      expect(controller.canEditPayRate(entry), isFalse);
      await expectLater(
        controller.updatePayRate(entry: entry, payRate: '42'),
        throwsStateError,
      );
      AppManager.instance.updateCurrentUser(
        User(uuid: 'owner', isOwner: true, organizationUuid: 'org'),
      );
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode([
            {'uuid': 'org', 'name': 'Child', 'type': 'child'},
          ]),
          200,
        ),
      );
      addTearDown(client.close);
      await http.runWithClient(
        () => AppManager.instance.fetchOrganizations(
          forceRefresh: true,
          requireSuccess: true,
        ),
        () => client,
      );
      expect(AppManager.instance.currentOrganization?.type, 'child');
      expect(controller.canEditPayRate(entry), isFalse);
      await expectLater(
        controller.updatePayRate(entry: entry, payRate: '42'),
        throwsStateError,
      );
      expect(executor.patches, isEmpty);
    },
  );

  test(
    'invalid direct saves are rejected and disposal ignores a pending result',
    () async {
      final controller = PaygradeDetailController(useCase);
      await controller.initialize('job-id');
      final entry = controller.detail!.payGrades.first;
      await expectLater(
        controller.updatePayRate(entry: entry, payRate: '-5'),
        throwsArgumentError,
      );
      expect(executor.patches, isEmpty);
      executor.pendingSave = Completer<void>();
      final save = controller.updatePayRate(entry: entry, payRate: '15');
      controller.dispose();
      executor.pendingSave!.complete();
      await expectLater(save, completes);
    },
  );
}

const _entryId = '09d256d0-1ef4-47f5-b973-c2d824009bcc';

class _Executor extends ApiCallExecutor {
  final patches = <({String endpoint, Map<String, dynamic> payload})>[];
  Completer<void>? pendingSave;
  bool failNextSave = false;

  @override
  Future<Response> processApi<Response>({
    required ApiCallType apiCallType,
    required String endpoint,
    required Response Function(dynamic json) decoder,
    Map<String, dynamic>? parameters,
    Map<String, String>? headers,
    String? authToken,
    bool allowAutoRefresh = true,
    bool allowConflictRetry = true,
    bool invalidateCacheBeforeRequest = false,
  }) async {
    if (apiCallType == ApiCallType.patch) {
      patches.add((endpoint: endpoint, payload: parameters!));
      if (failNextSave) {
        failNextSave = false;
        throw StateError('offline');
      }
      await pendingSave?.future;
      return decoder(null);
    }
    if (endpoint.endsWith('/public-links/paygrades/')) {
      return decoder({'active': false});
    }
    if (endpoint == 'job/job-id/pay_grades/') {
      final ancillary = parameters!['type'] == 'ancillary';
      return decoder({
        'uuid': 'job-id',
        'title': 'Designer',
        'department': 'Operations',
        'paygrade_unit': 'hr',
        'pay_grades': [
          {
            'uuid': ancillary ? 'ancillary-entry' : _entryId,
            'title': ancillary
                ? 'Lead Designer'
                : 'Paygrade: Instructional Designer',
            'type': ancillary ? 'ancillary' : 'primary',
            'pay_rate': ancillary ? '30.00' : '10.00',
            'level': 1,
            'description': 'Primary responsibilities',
            'promotion_requirement': 'Complete training',
          },
          if (!ancillary)
            {
              'uuid': 'second-entry',
              'title': 'Senior Designer',
              'pay_rate': '20.00',
              'level': 2,
            },
        ],
      });
    }
    throw StateError('Unexpected request: $apiCallType $endpoint');
  }
}
