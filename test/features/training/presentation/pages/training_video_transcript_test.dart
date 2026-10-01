import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sparrowkaizen/core/constants/app_colors.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/managers/app_manager.dart';
import 'package:sparrowkaizen/core/network/api_endpoints.dart';
import 'package:sparrowkaizen/core/preference/app_preference.dart';
import 'package:sparrowkaizen/features/compliance/presentation/providers/compliance_video_controller.dart';
import 'package:sparrowkaizen/features/compliance/presentation/widgets/compliance_video_player.dart';
import 'package:sparrowkaizen/features/login/domain/entities/user.dart';
import 'package:sparrowkaizen/features/training/domain/entities/seat_description_training_route.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_module_controller.dart';
import 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

void main() {
  testWidgets('Edit Training uses nested video transcripts and resets captions on lesson change', (
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

    final client = MockClient((request) async {
      expect(request.method, 'GET');
      final endpoint = request.url.path.replaceFirst(ApiEndPoints.version, '');
      final Object response;
      if (endpoint == ApiEndPoints.seatDescriptionTrainingModules('description')) {
        response = [
          {'uuid': 'lesson', 'title': 'Lesson'},
          {'uuid': 'next-lesson', 'title': 'Next lesson'},
        ];
      } else if (endpoint == ApiEndPoints.trainingModuleDetail('lesson') ||
          endpoint == ApiEndPoints.trainingModuleDetail('next-lesson')) {
        final isNext = endpoint == ApiEndPoints.trainingModuleDetail('next-lesson');
        response = {
          'uuid': isNext ? 'next-lesson' : 'lesson',
          'title': isNext ? 'Next lesson' : 'Lesson',
          'description': 'The summary stays available',
          'training_video': {
            'uuid': isNext ? 'next-video' : 'video',
            'title': 'Video',
            // Keep initialization deterministic; native seeking is tested separately.
            'url': 'http://[',
            'duration': 60,
            'transcript': isNext
                ? '[00:00] Next caption'
                : '[00:00] Introduction\n[00:05] Main point',
          },
        };
      } else if (endpoint == ApiEndPoints.lmsPublicLink('description')) {
        response = {'active': false};
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
            home: EditTrainingScreen(
              trainingRoute: SeatDescriptionTrainingRoute(
                job: 'seat',
                category: 'category',
                description: 'description',
              ),
              canManageTraining: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.text(AppStrings.trainingViewTranscript);
      final controller = tester.element(action).read<ComplianceVideoController>();
      final moduleController = tester.element(action).read<TrainingModuleController>();
      final player = find.byType(ComplianceVideoPlayer);
      final bounds = tester.getRect(player);
      expect(bounds.height, 362);
      expect(tester.widget<ComplianceVideoPlayer>(player).height, 362);
      expect(tester.widget<ComplianceVideoPlayer>(player).fillBounds, isTrue);
      expect(controller.transcriptLines.map((line) => line.text), ['Introduction', 'Main point']);
      expect(controller.isCcEnabled, isFalse);
      expect(find.byTooltip(AppStrings.trainingThumbnailAction), findsOneWidget);
      expect(find.byTooltip(AppStrings.trainingReUploadVideoAction), findsOneWidget);
      expect(find.text(AppStrings.trainingSummaryLabel), findsOneWidget);

      controller.updatePlaybackPosition(Duration.zero);
      await tester.pump();
      expect(find.text('Introduction'), findsOneWidget);
      await tester.tap(find.text(AppStrings.trainingCc));
      await tester.pump();
      expect(find.text('Introduction'), findsNothing);
      expect(tester.getRect(player), bounds);
      final positions = <Duration>[];
      controller.setSeekHandler((position) async {
        positions.add(position);
        controller.updatePlaybackPosition(position);
        return true;
      });
      await tester.tap(action);
      await tester.pumpAndSettle();
      final introduction = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Introduction'),
      );
      expect(tester.widget<Text>(introduction).style?.color, AppColors.secondaryColor);
      await tester.tap(find.text('Main point'));
      await tester.pumpAndSettle();
      expect(positions, [const Duration(seconds: 5)]);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Main point'), findsNothing);
      await tester.tap(find.text(AppStrings.trainingCc));
      await tester.pump();
      expect(find.text('Main point'), findsOneWidget);
      expect(tester.getRect(player), bounds);

      await tester.tap(find.text(AppStrings.trainingCc));
      await tester.pump();
      await moduleController.selectModule('next-lesson');
      await tester.pumpAndSettle();
      final nextController = tester.element(action).read<ComplianceVideoController>();
      expect(identical(nextController, controller), isFalse);
      expect(nextController.isCcEnabled, isFalse);
      expect(nextController.activeTranscriptIndex, isNull);
      expect(nextController.transcriptLines.single.text, 'Next caption');
      expect(find.text('Main point'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => client);
  });
}
