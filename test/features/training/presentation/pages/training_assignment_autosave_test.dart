import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/network/api_endpoints.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/features/login/domain/entities/user.dart';
import 'package:sparrowkaizen/features/training/domain/entities/seat_description_training_route.dart';
import 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

void main() {
  testWidgets(
    'editing one letter in the Assignment tab PATCHes instructions without a title',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await AppPreference.init();
      AppManager.instance.resetSessionState();
      AppManager.instance.updateCurrentUser(
        User(uuid: 'owner', isOwner: true, organizationUuid: 'org-id'),
      );
      addTearDown(AppManager.instance.resetSessionState);

      final writes = <http.Request>[];
      final client = MockClient((request) async {
        final endpoint = request.url.path.replaceFirst(
          ApiEndPoints.version,
          '',
        );
        if (request.method != 'GET') {
          writes.add(request);
          return http.Response('', 204);
        }
        final Object response;
        if (endpoint ==
            ApiEndPoints.seatDescriptionTrainingModules('description')) {
          response = [
            {'uuid': 'lesson', 'title': 'Lesson'},
          ];
        } else if (endpoint == ApiEndPoints.trainingModuleDetail('lesson')) {
          response = {'uuid': 'lesson', 'title': 'Lesson'};
        } else if (endpoint ==
            ApiEndPoints.trainingModuleAssignment('lesson')) {
          response = {'id': 42, 'instructions': '<p>Complete the task</p>'};
        } else if (endpoint == ApiEndPoints.trainingModuleDocument('lesson')) {
          response = {'uuid': 'document', 'text': '<p>Procedure</p>'};
        } else if (endpoint == ApiEndPoints.trainingModuleQuestions('lesson')) {
          response = [];
        } else {
          throw StateError('Unexpected API request: $endpoint');
        }
        return http.Response(
          jsonEncode(response),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);

      await http.runWithClient(() async {
        await tester.pumpWidget(
          ChangeNotifierProvider<AppManager>.value(
            value: AppManager.instance,
            child: const MaterialApp(
              home: Scaffold(
                body: EditTrainingSection(
                  trainingRoute: SeatDescriptionTrainingRoute(
                    job: 'seat',
                    category: 'category',
                    description: 'description',
                  ),
                  canManageTraining: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(TrainingTabs),
            matching: find.text(AppStrings.trainingAssignmentTab),
          ),
        );
        await tester.pumpAndSettle();
        final editor = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText ==
                  AppStrings.trainingAssignmentDescriptionHint,
        );
        expect(editor, findsOneWidget);
        expect(writes, isEmpty);

        await tester.enterText(editor, 'Complete the tasks');
        await tester.pump(const Duration(milliseconds: 399));
        expect(writes, isEmpty);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();

        expect(writes, hasLength(1));
        expect(writes.single.method, 'PATCH');
        expect(
          writes.single.url.path,
          '${ApiEndPoints.version}training_assignment/42/',
        );
        expect(jsonDecode(writes.single.body), {
          'instructions': 'Complete the tasks',
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => client);
    },
  );
}
