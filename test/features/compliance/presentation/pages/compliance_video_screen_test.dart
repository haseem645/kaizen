import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/constants/app_colors.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/compliance/domain/entities/compliance_track_item_detail.dart';
import 'package:sparrowkaizen/features/compliance/presentation/pages/training/compliance_video_screen.dart';
import 'package:sparrowkaizen/features/compliance/presentation/providers/compliance_video_controller.dart';

void main() {
  testWidgets('moves the purple highlight with playback and backward seeks', (tester) async {
    await tester.pumpWidget(_screen('[00:00] Introduction\n[00:05] Main point'));
    final controller = tester.element(find.text('Introduction')).read<ComplianceVideoController>();

    controller.updatePlaybackPosition(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.widget<Text>(find.text('Introduction')).style?.color, AppColors.secondaryColor);
    expect(tester.widget<Text>(find.text('Main point')).style?.color, AppColors.textPrimary);

    controller.updatePlaybackPosition(const Duration(seconds: 5));
    await tester.pump();
    expect(tester.widget<Text>(find.text('Introduction')).style?.color, AppColors.textPrimary);
    expect(tester.widget<Text>(find.text('Main point')).style?.color, AppColors.secondaryColor);
    expect(tester.widget<Text>(find.text('00:05')).style?.color, AppColors.secondaryColor);

    controller.updatePlaybackPosition(Duration.zero);
    await tester.pump();
    expect(tester.widget<Text>(find.text('Introduction')).style?.color, AppColors.secondaryColor);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spaces transcript rows and wraps long text on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const firstLine = 'A long transcript line that wraps naturally on a narrow mobile screen.';
    await tester.pumpWidget(_screen('$firstLine\nSecond line'));

    final first = find.text(firstLine);
    final second = find.text('Second line');
    expect(tester.widget<Text>(first).style?.height, 1.6);
    expect(tester.getTopLeft(second).dy - tester.getBottomLeft(first).dy, greaterThanOrEqualTo(14));
    expect(find.text('00:00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resets the active line when the training content changes', (tester) async {
    await tester.pumpWidget(_screen('[00:00] Old transcript'));
    tester
        .element(find.text('Old transcript'))
        .read<ComplianceVideoController>()
        .updatePlaybackPosition(const Duration(seconds: 2));
    await tester.pump();

    await tester.pumpWidget(_screen('[00:00] New transcript'));
    expect(find.text('Old transcript'), findsNothing);
    expect(tester.widget<Text>(find.text('New transcript')).style?.color, AppColors.textPrimary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the existing empty transcript message', (tester) async {
    await tester.pumpWidget(_screen(null));
    expect(find.text(AppStrings.trainingNoTranscriptAvailable), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
  });

  test('only notifies when the active transcript row changes', () {
    final controller = ComplianceVideoController('[00:00] First\n[00:05] Second');
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.updatePlaybackPosition(Duration.zero);
    controller.updatePlaybackPosition(const Duration(seconds: 1));
    controller.updatePlaybackPosition(const Duration(seconds: 4));
    expect(notifications, 1);
    controller.updatePlaybackPosition(const Duration(seconds: 5));
    expect(notifications, 2);
  });
}

Widget _screen(String? transcript) {
  return MaterialApp(
    home: Scaffold(
      body: ComplianceVideoScreen(
        detail: ComplianceTrackItemDetail(
          uuid: 'item',
          position: 1,
          trainingModuleUuid: 'module',
          title: 'Training',
          quizStatus: '',
          videoUrl: null,
          videoDuration: 10,
          videoTranscript: transcript,
          videoThumbnailLink: null,
          trainingDocument: null,
          quizCompletionPercentage: 0,
        ),
      ),
    ),
  );
}
