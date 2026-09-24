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
import 'package:sparrowkaizen/core/widgets/app_overlay_close_button.dart';
import 'package:sparrowkaizen/features/login/domain/entities/user.dart';
import 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';
import 'package:sparrowkaizen/features/training/presentation/pages/training_library_screen.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_library_module_card.dart';

import '../../fixtures/training_library_fixtures.dart';

void main() {
  testWidgets('LMS listing opens a lesson with a working top-bar Share action', (
    tester,
  ) async {
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
    final requests = <http.Request>[];
    Map<String, dynamic>? existingLink;
    final client = MockClient((request) async {
      requests.add(request);
      final endpoint = request.url.path.replaceFirst(ApiEndPoints.version, '');
      final Object response;
      if (endpoint == ApiEndPoints.trainingModulesAll) {
        response = {
          'results': [
            {
              ...lessonListingJson(
                id: 'lesson-1',
                descriptionId: 'description-id',
              ),
              'title': 'Listing lesson',
              'thumbnail_link': null,
            },
          ],
        };
      } else if (endpoint ==
          ApiEndPoints.seatDescriptionTrainingModules('description-id')) {
        response = List.generate(
          3,
          (index) => {
            'uuid': 'lesson-$index',
            'title': 'Lesson $index',
            'actual_id': 'parent-$index',
            'is_publicly_available': false,
          },
        );
      } else if (endpoint == ApiEndPoints.trainingModuleDetail('lesson-1')) {
        response = {'uuid': 'lesson-1', 'title': 'Opened lesson'};
      } else if (endpoint == ApiEndPoints.lmsPublicLink('description-id')) {
        if (request.method == 'GET') {
          response = existingLink ?? {'active': false};
        } else if (request.method == 'DELETE') {
          existingLink = null;
          return http.Response('', 204);
        } else {
          existingLink = {
            'active': true,
            'view_type': 'lms',
            'public_path': '/shared/lms/generated-id',
            'training_module_uuids':
                (jsonDecode(request.body) as Map)['training_module_uuids'],
          };
          response = existingLink!;
        }
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
          child: const MaterialApp(home: TrainingLibraryScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Listing lesson'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(TrainingLibraryModuleCard),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EditTrainingScreen), findsOneWidget);
      expect(find.text('Opened lesson'), findsWidgets);
      expect(
        requests.where(
          (request) =>
              request.method == 'GET' &&
              request.url.path.endsWith('/public-links/lms/'),
        ),
        hasLength(1),
      );
      expect(find.byTooltip(AppStrings.shareAction), findsOneWidget);
      expect(
        tester.getTopLeft(find.byIcon(Icons.share_outlined)).dx,
        greaterThan(
          tester.getTopRight(find.text(AppStrings.training).first).dx,
        ),
      );
      await tester.tap(find.byTooltip(AppStrings.shareAction));
      await tester.pumpAndSettle();
      expect(find.text('3 of 3 selected'), findsOneWidget);
      await tester.tap(find.text('Lesson 0'));
      await tester.pump();
      await tester.tap(find.text(AppStrings.shareCreateLinkAction));
      await tester.pumpAndSettle();
      final creation = requests.singleWhere(
        (request) => request.method == 'POST',
      );
      expect(
        creation.url.path,
        '${ApiEndPoints.version}job_category_description/description-id/public-links/lms/',
      );
      expect(jsonDecode(creation.body), {
        'view_type': 'lms',
        'public_path': '',
        'training_module_uuids': ['lesson-1', 'lesson-2'],
      });
      expect(
        find.text('${ApiEndPoints.publicWebBaseUrl}/shared/lms/generated-id'),
        findsOneWidget,
      );
      expect(find.text(AppStrings.sharePublicLinkTitle), findsOneWidget);
      await tester.tap(find.byType(AppOverlayCloseButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.shareAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.sharePublicLinkTitle), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(
        requests.where(
          (request) => request.url.path.endsWith(
            ApiEndPoints.seatDescriptionTrainingModules('description-id'),
          ),
        ),
        hasLength(1),
      );
      await tester.tap(find.byType(AppOverlayCloseButton));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(EditTrainingScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(TrainingLibraryModuleCard),
          matching: find.byType(InkWell),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        requests.where(
          (request) =>
              request.method == 'GET' &&
              request.url.path.endsWith('/public-links/lms/'),
        ),
        hasLength(2),
      );
      await tester.tap(find.byTooltip(AppStrings.shareAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.sharePublicLinkTitle), findsOneWidget);
      expect(
        find.text('${ApiEndPoints.publicWebBaseUrl}/shared/lms/generated-id'),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text(AppStrings.shareCreateLinkAction), findsNothing);
      expect(
        requests.where((request) => request.method == 'POST'),
        hasLength(1),
      );
      await tester.tap(find.text(AppStrings.shareRevokeLinkAction));
      await tester.pumpAndSettle();
      final deletion = requests.singleWhere(
        (request) => request.method == 'DELETE',
      );
      expect(
        deletion.url.path,
        '${ApiEndPoints.version}job_category_description/description-id/public-links/lms/',
      );
      expect(deletion.body, isEmpty);
      expect(find.text(AppStrings.shareCreateLinkAction), findsOneWidget);
      expect(find.text('3 of 3 selected'), findsOneWidget);
      expect(
        find.text('${ApiEndPoints.publicWebBaseUrl}/shared/lms/generated-id'),
        findsNothing,
      );
      await tester.tap(find.text(AppStrings.shareCreateLinkAction));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.shareRevokeLinkAction), findsOneWidget);
      expect(
        requests.where((request) => request.method == 'POST'),
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}
