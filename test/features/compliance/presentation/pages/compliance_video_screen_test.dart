import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/constants/app_colors.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';
import 'package:sparrowkaizen/features/compliance/domain/entities/compliance_track_item_detail.dart';
import 'package:sparrowkaizen/features/compliance/presentation/pages/training/compliance_video_screen.dart';
import 'package:sparrowkaizen/features/compliance/presentation/providers/compliance_video_controller.dart';
import 'package:sparrowkaizen/features/compliance/presentation/widgets/compliance_video_player.dart';

void main() {
  testWidgets('keeps the player and its container at the same height on load failure', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(null, videoUrl: 'http://['));
    await tester.pump();
    final player = find.byType(ComplianceVideoPlayer);
    expect(tester.widget<ComplianceVideoPlayer>(player).height, 250);
    expect(tester.getSize(player).height, 250);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('centers active cues without leaving blank space at the list start', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final texts = List.generate(
      90,
      (index) =>
          'Line $index ${List.filled(index % 3 + 1, 'with wrapping transcript text').join(' ')}',
    );
    final transcript = List.generate(90, (index) {
      final minutes = (index ~/ 60).toString().padLeft(2, '0');
      final seconds = (index % 60).toString().padLeft(2, '0');
      return '[$minutes:$seconds] ${texts[index]}';
    }).join('\n');
    await tester.pumpWidget(_screen(transcript, textScale: 1.5));
    final controller = tester
        .element(find.text(AppStrings.trainingViewTranscript))
        .read<ComplianceVideoController>();

    for (final index in [70, 0, 89]) {
      controller.updatePlaybackPosition(Duration(seconds: index));
      await tester.pump();
      await _openTranscript(tester);
      final cue = _sheetText(texts[index]);
      expect(cue, findsOneWidget);
      final list = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(CustomScrollView),
      );
      final row = find.ancestor(of: cue, matching: find.byType(InkWell)).first;
      if (index == 0) {
        expect(tester.getTopLeft(row).dy, closeTo(tester.getTopLeft(list).dy + 4, 1));
      } else {
        expect(tester.getCenter(row).dy, closeTo(tester.getCenter(list).dy, 1));
      }
      expect(tester.widget<Text>(cue).style?.color, AppColors.secondaryColor);

      final scrollable = find.descendant(of: list, matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(
        _sheetText(texts.first),
        -400,
        scrollable: scrollable,
        maxScrolls: 100,
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.minScrollExtent);
      await tester.pump();
      final firstRow = find
          .ancestor(of: _sheetText(texts.first), matching: find.byType(InkWell))
          .first;
      expect(tester.getTopLeft(firstRow).dy, closeTo(tester.getTopLeft(list).dy + 4, 1));
      await _closeTranscript(tester);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('CC starts off and collapses only the active transcript area when enabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _screen('[00:00 --> 00:04] First caption\n[00:05 --> 00:07] Second caption', textScale: 2),
    );
    final cc = find.text(AppStrings.trainingCc);
    final ccButton = find.ancestor(of: cc, matching: find.byType(TextButton));
    final action = find.text(AppStrings.trainingViewTranscript);
    final actionButton = find.ancestor(of: action, matching: find.byType(TextButton));
    final controller = tester.element(cc).read<ComplianceVideoController>();
    final video = find.byType(FastCircularProgressIndicator);
    final videoBounds = tester.getRect(video);
    expect(controller.isCcEnabled, isFalse);
    expect(tester.getTopLeft(ccButton).dx, videoBounds.left);
    expect(tester.getBottomRight(actionButton).dx, videoBounds.right);
    expect(tester.getBottomRight(cc).dx, lessThan(tester.getTopLeft(action).dx));
    controller.updatePlaybackPosition(Duration.zero);
    await tester.pump();
    expect(_videoText('First caption'), findsOneWidget);

    await tester.tap(cc);
    await tester.pump();
    expect(controller.isCcEnabled, isTrue);
    expect(_videoText('First caption'), findsNothing);
    expect(tester.getTopLeft(actionButton).dy, videoBounds.bottom + 4);
    expect(tester.getRect(video), videoBounds);
    controller.updatePlaybackPosition(const Duration(seconds: 5));
    await tester.pump();
    expect(_videoText('Second caption'), findsNothing);

    await _openTranscript(tester);
    expect(_sheetText('Second caption'), findsOneWidget);
    expect(
      tester.widget<Text>(_sheetText('Second caption')).style?.color,
      AppColors.secondaryColor,
    );
    await _closeTranscript(tester);
    expect(controller.isCcEnabled, isTrue);
    await tester.tap(cc);
    await tester.pump();
    expect(controller.isCcEnabled, isFalse);
    expect(_videoText('Second caption'), findsOneWidget);
    expect(tester.getRect(video), videoBounds);

    controller.updatePlaybackPosition(const Duration(seconds: 7));
    await tester.pump();
    expect(tester.getTopLeft(actionButton).dy, videoBounds.bottom + 12);
    await tester.tap(cc);
    await tester.pump();
    expect(tester.getTopLeft(actionButton).dy, videoBounds.bottom + 4);
    expect(tester.getRect(video), videoBounds);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a timed line seeks before dismissing the sheet', (tester) async {
    await tester.pumpWidget(_screen('[00:00] Introduction\n[00:05] Main point'));
    final controller = tester
        .element(find.text(AppStrings.trainingViewTranscript))
        .read<ComplianceVideoController>();
    final completion = Completer<bool>();
    final positions = <Duration>[];
    controller.setSeekHandler((position) async {
      positions.add(position);
      final didSeek = await completion.future;
      if (didSeek) controller.updatePlaybackPosition(position);
      return didSeek;
    });
    await _openTranscript(tester);
    final rowBounds = tester.getRect(_sheetText('Main point'));

    await tester.tap(_sheetText('Main point'));
    await tester.pump();
    expect(positions, [const Duration(seconds: 5)]);
    expect(controller.isSeeking, isTrue);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.getRect(_sheetText('Main point')), rowBounds);
    final loader = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(FastCircularProgressIndicator),
    );
    expect(loader, findsOneWidget);
    final durationBounds = tester.getRect(_sheetText('00:05'));
    final loaderBounds = tester.getRect(loader);
    expect(loaderBounds.left, closeTo(durationBounds.right + 6, 0.01));
    expect(loaderBounds.center.dy, closeTo(durationBounds.center.dy, 0.01));
    expect(loaderBounds.right, lessThan(rowBounds.left));
    await tester.tap(_sheetText('Introduction'));
    expect(positions, hasLength(1));

    completion.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BottomSheet), findsNothing);
    expect(_videoText('Main point'), findsOneWidget);
    expect(controller.isSeeking, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('untimed rows stay readable and a failed seek can be retried', (tester) async {
    await tester.pumpWidget(_screen('Untimed notes\n[00:05] Main point'));
    final controller = tester
        .element(find.text(AppStrings.trainingViewTranscript))
        .read<ComplianceVideoController>();
    var attempts = 0;
    controller.setSeekHandler((position) async {
      attempts++;
      if (attempts == 1) throw StateError('Seek failed');
      controller.updatePlaybackPosition(position);
      return true;
    });
    await _openTranscript(tester);
    await tester.tap(_sheetText('Untimed notes'));
    await tester.pump();
    expect(attempts, 0);

    await tester.tap(_sheetText('Main point'));
    await tester.pump();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text(AppStrings.trainingTranscriptSeekFailed), findsOneWidget);
    expect(controller.isSeeking, isFalse);

    await tester.tap(_sheetText('00:05'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(attempts, 2);
    expect(find.byType(BottomSheet), findsNothing);
    expect(controller.seekError, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moves the purple highlight with playback and backward seeks', (tester) async {
    await tester.pumpWidget(_screen('[00:00] Introduction\n[00:05] Main point'));
    expect(find.text('Introduction'), findsNothing);
    expect(
      tester.widget<Text>(find.text(AppStrings.trainingViewTranscript)).style?.decoration,
      TextDecoration.underline,
    );
    await _openTranscript(tester);
    final controller = tester.element(find.text('Introduction')).read<ComplianceVideoController>();

    controller.updatePlaybackPosition(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.widget<Text>(_sheetText('Introduction')).style?.color, AppColors.secondaryColor);
    expect(tester.widget<Text>(_sheetText('Main point')).style?.color, AppColors.textPrimary);
    expect(_videoText('Introduction'), findsOneWidget);

    controller.updatePlaybackPosition(const Duration(seconds: 5));
    await tester.pump();
    expect(tester.widget<Text>(_sheetText('Introduction')).style?.color, AppColors.textPrimary);
    expect(tester.widget<Text>(_sheetText('Main point')).style?.color, AppColors.secondaryColor);
    expect(_videoText('Introduction'), findsNothing);
    expect(_videoText('Main point'), findsOneWidget);
    expect(tester.widget<Text>(find.text('00:05')).style?.color, AppColors.secondaryColor);

    controller.updatePlaybackPosition(Duration.zero);
    await tester.pump();
    expect(tester.widget<Text>(_sheetText('Introduction')).style?.color, AppColors.secondaryColor);
    expect(_videoText('Introduction'), findsOneWidget);

    await _closeTranscript(tester);
    expect(_videoText('Introduction'), findsOneWidget);
    controller.updatePlaybackPosition(const Duration(seconds: 6));
    await _openTranscript(tester);
    expect(tester.widget<Text>(_sheetText('Main point')).style?.color, AppColors.secondaryColor);
    expect(_videoText('Main point'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the complete current line below the video and clears timing gaps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const line = 'An active transcript line that is long enough to wrap on a small screen.';
    await tester.pumpWidget(_screen('[00:02 --> 00:04] $line', textScale: 2));
    final action = find.text(AppStrings.trainingViewTranscript);
    final controller = tester.element(action).read<ComplianceVideoController>();

    controller.updatePlaybackPosition(const Duration(seconds: 2));
    await tester.pump();
    final caption = _videoText(line);
    expect(caption, findsOneWidget);
    final captionViewport = tester.getRect(_captionScrollView());
    expect(captionViewport.bottom, lessThanOrEqualTo(tester.getTopLeft(action).dy));
    final videoBounds = tester.getRect(find.byType(FastCircularProgressIndicator));
    expect(videoBounds.height, 250);
    expect(captionViewport.top, videoBounds.bottom);
    expect(tester.widget<Text>(caption).style?.color, AppColors.textPrimary);
    expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(640));

    controller.updatePlaybackPosition(const Duration(seconds: 4));
    await tester.pump();
    expect(caption, findsNothing);
    controller.updatePlaybackPosition(const Duration(seconds: 3));
    await tester.pump();
    expect(caption, findsOneWidget);

    await _openTranscript(tester);
    expect(_sheetText(line), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resizes the transcript panel without changing the video bounds', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cue = List.generate(40, (index) => 'Active transcript line $index').join('\n');
    await tester.pumpWidget(
      _screen('[00:02] $cue\n[00:05 --> 00:07] Following caption', textScale: 2),
    );
    final action = find.text(AppStrings.trainingViewTranscript);
    final controller = tester.element(action).read<ComplianceVideoController>();
    // The loading placeholder occupies the same viewport as the ready player.
    final video = find.byType(FastCircularProgressIndicator);
    final videoBounds = tester.getRect(video);
    final screenBounds = tester.getRect(find.byType(ComplianceVideoScreen));
    expect(videoBounds.height, 250);
    expect(videoBounds.topLeft, screenBounds.topLeft);
    expect(videoBounds.width, screenBounds.width);
    final actionButton = find.ancestor(of: action, matching: find.byType(TextButton));
    final emptyActionBounds = tester.getRect(actionButton);
    expect(emptyActionBounds.top - videoBounds.bottom, 12);
    expect(screenBounds.right - tester.getRect(action).right, 12);
    final surfaceFinder = find
        .descendant(of: find.byType(ComplianceVideoScreen), matching: find.byType(Material))
        .first;
    final surface = tester.widget<Material>(surfaceFinder);
    final emptySurfaceBounds = tester.getRect(surfaceFinder);
    expect(emptySurfaceBounds.bottom, emptyActionBounds.bottom + 4);
    expect(emptySurfaceBounds.height, lessThan(screenBounds.height));
    expect(surface.color, Colors.black);
    expect(surface.borderRadius, BorderRadius.circular(12));
    controller.updatePlaybackPosition(const Duration(seconds: 2));
    await tester.pump();
    expect(tester.getRect(video), videoBounds);
    final longSurfaceBounds = tester.getRect(surfaceFinder);
    final longActionBounds = tester.getRect(actionButton);
    expect(longSurfaceBounds.height, greaterThan(emptySurfaceBounds.height));
    expect(longSurfaceBounds.bottom, screenBounds.bottom);
    expect(longActionBounds.bottom, longSurfaceBounds.bottom - 4);

    final caption = _videoText(cue);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: caption, matching: find.byType(RichText)),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    final scrollView = _captionScrollView();
    final viewport = tester.getRect(scrollView);
    expect(viewport.top, videoBounds.bottom);
    expect(viewport.bottom, longActionBounds.top - 4);
    final scrollable = find.descendant(of: scrollView, matching: find.byType(Scrollable));
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));

    await tester.drag(scrollView, Offset(0, -position.maxScrollExtent - 100));
    await tester.pump(const Duration(seconds: 1));
    expect(position.pixels, closeTo(position.maxScrollExtent, 1));
    expect(tester.getBottomRight(caption).dy, closeTo(viewport.bottom - 8, 1));
    expect(longSurfaceBounds.bottom - tester.getBottomRight(action).dy, 10);

    controller.updatePlaybackPosition(const Duration(seconds: 5));
    await tester.pump();
    expect(_videoText('Following caption'), findsOneWidget);
    expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
    expect(tester.getRect(video), videoBounds);
    final shortSurfaceBounds = tester.getRect(surfaceFinder);
    expect(shortSurfaceBounds.height, lessThan(longSurfaceBounds.height));
    expect(shortSurfaceBounds.height, greaterThan(emptySurfaceBounds.height));
    expect(tester.getBottomRight(actionButton).dy, shortSurfaceBounds.bottom - 4);
    expect(
      tester.getSize(scrollView).height,
      tester.getSize(_videoText('Following caption')).height + 16,
    );

    controller.updatePlaybackPosition(const Duration(seconds: 7));
    await tester.pump();
    expect(_videoText('Following caption'), findsNothing);
    expect(tester.getRect(video), videoBounds);
    expect(tester.getRect(surfaceFinder), emptySurfaceBounds);
    expect(tester.getRect(actionButton), emptyActionBounds);

    controller.updatePlaybackPosition(const Duration(seconds: 2));
    await tester.pump();
    expect(_videoText(cue), findsOneWidget);
    expect(tester.getRect(video), videoBounds);
    expect(tester.getRect(scrollView), viewport);
    expect(tester.takeException(), isNull);

    // The same panel stays usable in a short tab viewport with enlarged text.
    await tester.pumpWidget(
      _screen('[00:02] $cue\n[00:05 --> 00:07] Following caption', textScale: 2, height: 300),
    );
    expect(_videoText(cue), findsOneWidget);
    expect(tester.getRect(video), videoBounds);
    expect(tester.getTopLeft(scrollView).dy, tester.getBottomLeft(video).dy);
    expect(tester.getSize(scrollView).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(action);
    await tester.pump();
    expect(tester.getBottomRight(action).dy, lessThanOrEqualTo(300));
    expect(tester.getSize(video).height, 250);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spaces transcript rows and wraps long text on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const firstLine = 'A long transcript line that wraps naturally on a narrow mobile screen.';
    final remainingLines = List.generate(40, (index) => 'Transcript row $index').join('\n');
    await tester.pumpWidget(_screen('$firstLine\nSecond line\n$remainingLines', textScale: 1.5));
    await _openTranscript(tester);

    final first = find.text(firstLine);
    final second = find.text('Second line');
    expect(tester.widget<Text>(first).style?.height, 1.6);
    expect(tester.getTopLeft(second).dy - tester.getBottomLeft(first).dy, greaterThanOrEqualTo(14));
    expect(find.text('00:00'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Transcript row 39'),
      250,
      scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)),
    );
    expect(find.text('Transcript row 39'), findsOneWidget);
    expect(find.text(AppStrings.trainingTranscriptTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resets the active line when the training content changes', (tester) async {
    await tester.pumpWidget(_screen('[00:00] Old transcript'));
    await _openTranscript(tester);
    tester
        .element(find.text('Old transcript'))
        .read<ComplianceVideoController>()
        .updatePlaybackPosition(const Duration(seconds: 2));
    await tester.pump();

    await _closeTranscript(tester);
    await tester.pumpWidget(_screen('[00:00] New transcript'));
    expect(_videoText('Old transcript'), findsNothing);
    expect(_videoText('New transcript'), findsNothing);
    await _openTranscript(tester);
    expect(find.text('Old transcript'), findsNothing);
    expect(tester.widget<Text>(find.text('New transcript')).style?.color, AppColors.textPrimary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the existing empty transcript message', (tester) async {
    await tester.pumpWidget(_screen(null));
    expect(find.text(AppStrings.trainingNoTranscriptAvailable), findsNothing);
    await _openTranscript(tester);
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

  test('a transcript tap waits for the player to register its seek handler', () async {
    final controller = ComplianceVideoController('[00:15] Main point');
    addTearDown(controller.dispose);
    final seek = controller.seekToTranscriptLine(0);
    expect(controller.isSeeking, isTrue);
    expect(controller.seekError, isNull);
    final positions = <Duration>[];
    controller.setSeekHandler((position) async {
      positions.add(position);
      return true;
    });
    expect(await seek, isTrue);
    expect(positions, [const Duration(seconds: 15)]);
    expect(controller.isSeeking, isFalse);
    expect(controller.seekError, isNull);
  });

  test('disposing while waiting for a player cancels the pending transcript jump', () async {
    final controller = ComplianceVideoController('[00:15] Main point');
    final seek = controller.seekToTranscriptLine(0);
    controller.dispose();
    expect(await seek, isFalse);
  });

  test('ignores completion of a seek after its lesson has been disposed', () async {
    final controller = ComplianceVideoController('[00:00] Introduction');
    final completion = Completer<bool>();
    controller.setSeekHandler((_) => completion.future);
    final seek = controller.seekToTranscriptLine(0);
    controller.dispose();
    completion.complete(true);
    expect(await seek, isFalse);
  });
}

Finder _sheetText(String text) {
  return find.descendant(of: find.byType(BottomSheet), matching: find.text(text));
}

Finder _videoText(String text) {
  return find.descendant(of: find.byType(ComplianceVideoScreen), matching: find.text(text));
}

Finder _captionScrollView() {
  return find
      .descendant(
        of: find.byType(ComplianceVideoScreen),
        matching: find.byType(SingleChildScrollView),
      )
      .last;
}

Future<void> _openTranscript(WidgetTester tester) async {
  await tester.tap(find.text(AppStrings.trainingViewTranscript));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _closeTranscript(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close_rounded));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _screen(String? transcript, {double textScale = 1, double? height, String? videoUrl}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SizedBox(
        height: height ?? double.infinity,
        child: ComplianceVideoScreen(
          detail: ComplianceTrackItemDetail(
            uuid: 'item',
            position: 1,
            trainingModuleUuid: 'module',
            title: 'Training',
            quizStatus: '',
            videoUrl: videoUrl,
            videoDuration: 10,
            videoTranscript: transcript,
            videoThumbnailLink: null,
            trainingDocument: null,
            quizCompletionPercentage: 0,
          ),
        ),
      ),
    ),
  );
}
