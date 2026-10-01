import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/compliance/presentation/pages/training/compliance_full_screen_video_view.dart';
import 'package:sparrowkaizen/features/compliance/presentation/providers/compliance_video_controller.dart';
import 'package:sparrowkaizen/features/compliance/presentation/widgets/compliance_video_player.dart';
import 'package:video_player/video_player.dart';
// Use video_player's existing platform interface to simulate native playback.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  late VideoPlayerPlatform originalPlatform;
  late _FakeVideoPlatform platform;
  late Directory videoDirectory;
  late String videoPath;

  setUp(() {
    originalPlatform = VideoPlayerPlatform.instance;
    platform = _FakeVideoPlatform();
    VideoPlayerPlatform.instance = platform;
    videoDirectory = Directory.systemTemp.createTempSync('video-controls-test-');
    videoPath = '${videoDirectory.path}/video.mp4';
    File(videoPath).writeAsBytesSync([0]);
  });

  tearDown(() {
    VideoPlayerPlatform.instance = originalPlatform;
    videoDirectory.deleteSync(recursive: true);
  });

  Future<VideoPlayerController> mountPlayer(
    WidgetTester tester, {
    double height = 220,
    String title = 'Lesson',
    double textScale = 1,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(12)),
    bool fillBounds = false,
    BoxFit fit = BoxFit.cover,
    Widget? captionOverlay,
    Widget? bottomRightAction,
    ComplianceVideoController? transcriptController,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: ComplianceVideoPlayer(
              videoUrl: '',
              localVideoPath: videoPath,
              title: title,
              height: height,
              borderRadius: borderRadius,
              fillBounds: fillBounds,
              fit: fit,
              captionOverlay: captionOverlay,
              bottomRightAction: bottomRightAction,
              onSeekHandlerChanged: transcriptController?.setSeekHandler,
              onPositionChanged: transcriptController?.updatePlaybackPosition,
            ),
          ),
        ),
      );
      await platform.initialized.future;
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    return tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller;
  }

  Future<void> disposePlayer(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // The playback service retains released controllers for three minutes.
    await tester.pump(const Duration(minutes: 3));
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  Future<void> tapVideo(WidgetTester tester) async {
    final origin = tester.getTopLeft(find.byType(ComplianceVideoPlayer));
    await tester.tapAt(origin + const Offset(30, 50));
    await tester.pump();
  }

  Future<void> completeVideo(WidgetTester tester) async {
    await tester.runAsync(() async {
      platform.events.add(VideoEvent(eventType: VideoEventType.completed));
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  void expectControls({required bool visible, bool playing = true}) {
    final matcher = visible ? findsOneWidget : findsNothing;
    expect(find.byType(Slider), matcher);
    expect(find.text('Lesson'), matcher);
    expect(find.text('/'), matcher);
    expect(find.text('01:00'), visible ? findsWidgets : findsNothing);
    expect(find.byIcon(Icons.replay_10_rounded), matcher);
    expect(find.byIcon(Icons.forward_10_rounded), matcher);
    expect(find.byIcon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded), matcher);
  }

  testWidgets('fullscreen icon stays visible during playback and opens the same player', (
    tester,
  ) async {
    final controller = await mountPlayer(tester, height: 250, fit: BoxFit.contain);
    final button = find.byKey(const ValueKey('video-fullscreen-button'));
    final icon = find.descendant(of: button, matching: find.byType(SvgPicture));
    expect(tester.getSize(button), const Size(40, 40));
    expect(tester.getSize(icon), const Size(35, 35));
    await controller.play();
    await tester.pump();
    expect(find.byType(Slider), findsNothing);
    expect(button.hitTestable(), findsOneWidget);

    await tester.tap(button);
    await tester.pumpAndSettle();
    final fullscreen = find.byType(ComplianceFullScreenVideoView);
    expect(fullscreen, findsOneWidget);
    expect(tester.widget<ComplianceFullScreenVideoView>(fullscreen).controller, same(controller));
    expect(controller.value.isPlaying, isTrue);

    Navigator.of(tester.element(fullscreen)).pop();
    await tester.pumpAndSettle();
    expect(button.hitTestable(), findsOneWidget);
    await disposePlayer(tester);
  });

  testWidgets('keeps bottom controls compact and bounded with long titles and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(280, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    platform.duration = const Duration(hours: 1, minutes: 32, seconds: 45);
    const title = 'A long training title that must stay clear of the video duration';
    await mountPlayer(tester, height: 250, title: title, textScale: 3);
    final viewport = tester.getRect(
      find
          .descendant(of: find.byType(ComplianceVideoPlayer), matching: find.byType(ClipRRect))
          .first,
    );
    final titleBounds = tester.getRect(find.text(title));
    final slider = tester.getRect(find.byType(Slider));
    expect(slider.height, 24);
    expect(slider.bottom, viewport.bottom);
    expect(viewport.bottom - slider.center.dy, 12);
    expect(titleBounds.bottom, lessThanOrEqualTo(slider.top));
    expect(
      titleBounds.top,
      greaterThan(tester.getBottomRight(find.byIcon(Icons.play_arrow_rounded)).dy),
    );
    expect(titleBounds.right, lessThan(tester.getTopLeft(find.text('01:32:45')).dx));
    expect(tester.getBottomRight(find.text('01:32:45')).dx, lessThanOrEqualTo(viewport.right));
    expect(tester.takeException(), isNull);
    await disposePlayer(tester);
  });

  testWidgets('transcript seeks play from the selected cue on the existing player', (tester) async {
    final transcript = ComplianceVideoController(
      '[00:00] Introduction\n[00:15] Main point\n[02:00] Beyond the video',
    );
    addTearDown(transcript.dispose);
    final controller = await mountPlayer(tester, transcriptController: transcript);
    expect(controller.value.isPlaying, isFalse);

    expect(await transcript.seekToTranscriptLine(1), isTrue);
    await tester.pump();
    expect(controller.value.position, const Duration(seconds: 15));
    expect(controller.value.isPlaying, isTrue);
    expect(transcript.activeTranscriptIndex, 1);

    await controller.pause();
    await controller.seekTo(const Duration(seconds: 25));
    expect(await transcript.seekToTranscriptLine(1), isTrue);
    await tester.pump();
    expect(controller.value.position, const Duration(seconds: 15));
    expect(controller.value.isPlaying, isTrue);
    expect(tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller, same(controller));

    expect(await transcript.seekToTranscriptLine(0), isTrue);
    await tester.pump();
    expect(controller.value.position, Duration.zero);
    expect(transcript.activeTranscriptIndex, 0);

    expect(await transcript.seekToTranscriptLine(2), isTrue);
    await tester.pump();
    expect(controller.value.position, controller.value.duration);
    expect(controller.value.isPlaying, isFalse);
    expect(transcript.activeTranscriptIndex, 1);

    await disposePlayer(tester);
    final unavailableSeek = transcript.seekToTranscriptLine(0);
    await tester.pump(const Duration(seconds: 10));
    expect(await unavailableSeek, isFalse);
    expect(transcript.seekError, AppStrings.trainingTranscriptSeekFailed);
  });

  testWidgets('a transcript seek waits through texture initialization fallback', (tester) async {
    final transcript = ComplianceVideoController('[00:15] Main point');
    addTearDown(transcript.dispose);
    platform.initializationFailures = 1;
    platform.initializationGate = Completer<void>();
    platform.fallbackInitializationGate = Completer<void>();
    var finished = false;

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplianceVideoPlayer(
              videoUrl: '',
              localVideoPath: videoPath,
              title: 'Lesson',
              onSeekHandlerChanged: transcript.setSeekHandler,
              onPositionChanged: transcript.updatePlaybackPosition,
            ),
          ),
        ),
      );
      await platform.created.future.timeout(const Duration(seconds: 5));
      final seek = transcript.seekToTranscriptLine(0).then((value) {
        finished = true;
        return value;
      });
      await Future<void>.delayed(Duration.zero);
      platform.initializationGate!.complete();
      await tester.pump();
      await platform.fallbackCreated.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      expect(transcript.isSeeking, isTrue);
      expect(transcript.seekError, isNull);
      platform.fallbackInitializationGate!.complete();
      await tester.pump();
      expect(await seek, isTrue);
    });
    await tester.pump();
    final controller = tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller;
    expect(controller.value.position, const Duration(seconds: 15));
    expect(controller.value.isPlaying, isTrue);
    expect(platform.createCount, 2);
    expect(transcript.seekError, isNull);
    await disposePlayer(tester);
  });

  testWidgets('retries transient native seek and play failures on the same player', (tester) async {
    final transcript = ComplianceVideoController('[00:15] Main point');
    addTearDown(transcript.dispose);
    final controller = await mountPlayer(tester, transcriptController: transcript);
    platform.seekFailures = 1;
    platform.playFailures = 1;
    expect(await transcript.seekToTranscriptLine(0), isTrue);
    await tester.pump();
    expect(controller.value.position, const Duration(seconds: 15));
    expect(controller.value.isPlaying, isTrue);
    expect(platform.createCount, 1);
    expect(transcript.seekError, isNull);
    expect(tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller, same(controller));
    await disposePlayer(tester);
  });

  testWidgets('persistent seek failures finish loading and allow a later retry', (tester) async {
    final transcript = ComplianceVideoController('[00:15] Main point');
    addTearDown(transcript.dispose);
    await mountPlayer(tester, transcriptController: transcript);
    platform.seekFailures = 3;
    expect(await transcript.seekToTranscriptLine(0), isFalse);
    expect(transcript.isSeeking, isFalse);
    expect(transcript.seekError, AppStrings.trainingTranscriptSeekFailed);
    expect(await transcript.seekToTranscriptLine(0), isTrue);
    expect(transcript.seekError, isNull);
    await disposePlayer(tester);
  });

  testWidgets('removing the player during a seek prevents stale playback', (tester) async {
    final transcript = ComplianceVideoController('[00:15] Main point');
    addTearDown(transcript.dispose);
    await mountPlayer(tester, transcriptController: transcript);
    platform.seekGate = Completer<void>();
    final seek = transcript.seekToTranscriptLine(0);
    await tester.pump();
    expect(platform.seekStarted.isCompleted, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    platform.seekGate!.complete();
    await tester.pump();
    expect(await seek, isFalse);
    expect(platform.playCount, 0);
    expect(transcript.isSeeking, isFalse);
    await disposePlayer(tester);
  });

  testWidgets('fits the complete video inside an enlarged player', (tester) async {
    await mountPlayer(
      tester,
      height: 500,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      fillBounds: true,
      fit: BoxFit.contain,
    );

    final playerBounds = tester.getRect(
      find
          .descendant(of: find.byType(ComplianceVideoPlayer), matching: find.byType(ClipRRect))
          .first,
    );
    final videoBounds = Rect.fromPoints(
      tester.getTopLeft(find.byType(VideoPlayer)),
      tester.getBottomRight(find.byType(VideoPlayer)),
    );
    expect(playerBounds.height, 500);
    expect(
      tester.widget<ClipRRect>(find.byType(ClipRRect).first).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(12)),
    );
    expect(videoBounds.width, playerBounds.width);
    expect(videoBounds.width / videoBounds.height, closeTo(16 / 9, 0.001));
    expect(playerBounds.contains(videoBounds.topLeft), isTrue);
    expect(videoBounds.right, lessThanOrEqualTo(playerBounds.right));
    expect(videoBounds.bottom, lessThanOrEqualTo(playerBounds.bottom));

    await disposePlayer(tester);
  });

  testWidgets('hides on play and reveals controls for exactly three seconds', (tester) async {
    final controller = await mountPlayer(tester);
    expectControls(visible: true, playing: false);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(controller.value.isPlaying, isTrue);
    expectControls(visible: false);

    await tapVideo(tester);
    expectControls(visible: true);
    expect(controller.value.isPlaying, isTrue);
    await tester.pump(const Duration(milliseconds: 2999));
    expectControls(visible: true);
    await tester.pump(const Duration(milliseconds: 1));
    expectControls(visible: false);

    await disposePlayer(tester);
  });

  testWidgets('overlays changing captions without resizing video or blocking controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final caption = ValueNotifier('Short caption');
    addTearDown(caption.dispose);
    var transcriptTaps = 0;
    final controller = await mountPlayer(
      tester,
      height: 500,
      fillBounds: true,
      fit: BoxFit.cover,
      bottomRightAction: TextButton(
        onPressed: () => transcriptTaps++,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 28),
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 1),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(AppStrings.trainingViewTranscript),
      ),
      captionOverlay: ValueListenableBuilder<String>(
        valueListenable: caption,
        builder: (_, text, __) => ColoredBox(
          color: Colors.black,
          child: SingleChildScrollView(
            child: Text(text, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ),
    );
    final video = find.byType(VideoPlayer);
    final originalBounds = Rect.fromPoints(tester.getTopLeft(video), tester.getBottomRight(video));
    expect(originalBounds.top, closeTo(0, 0.001));
    expect(originalBounds.bottom, closeTo(500, 0.001));
    expect(originalBounds.left, lessThanOrEqualTo(0));
    expect(originalBounds.right, greaterThanOrEqualTo(320));
    expect(originalBounds.width / originalBounds.height, closeTo(16 / 9, 0.001));
    expect(
      tester.getBottomRight(find.text(caption.value)).dy,
      lessThan(tester.getTopLeft(find.byType(Slider)).dy),
    );
    final transcriptAction = find.byType(TextButton);
    final actionBounds = tester.getRect(transcriptAction);
    expect(actionBounds.bottom, originalBounds.bottom);
    expect(tester.getBottomRight(find.byType(Slider)).dy, lessThanOrEqualTo(actionBounds.top));
    await tester.tap(transcriptAction);
    expect(transcriptTaps, 1);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(controller.value.isPlaying, isTrue);
    expect(find.text(caption.value), findsOneWidget);
    expect(tester.getBottomRight(find.text(caption.value)).dy, closeTo(actionBounds.top - 8, 1));
    await tester.tap(transcriptAction);
    expect(transcriptTaps, 2);
    expect(controller.value.isPlaying, isTrue);
    expect(tester.getRect(transcriptAction), actionBounds);

    caption.value = List.generate(30, (index) => 'Caption line $index').join('\n');
    await tester.pump();
    expect(Rect.fromPoints(tester.getTopLeft(video), tester.getBottomRight(video)), originalBounds);
    expect(tester.widget<VideoPlayer>(video).controller, same(controller));

    await tapVideo(tester);
    final captionBounds = tester.getRect(find.byType(SingleChildScrollView).first);
    expect(captionBounds.bottom, lessThan(tester.getTopLeft(find.byType(Slider)).dy));
    expect(
      captionBounds.top,
      greaterThan(tester.getBottomRight(find.byIcon(Icons.pause_rounded)).dy),
    );
    await tester.tap(find.byIcon(Icons.forward_10_rounded));
    await tester.pump();
    expect(controller.value.position, const Duration(seconds: 10));
    expect(Rect.fromPoints(tester.getTopLeft(video), tester.getBottomRight(video)), originalBounds);
    await disposePlayer(tester);
  });

  testWidgets('tapping again and skipping restart the three-second timer', (tester) async {
    final controller = await mountPlayer(tester);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tapVideo(tester);
    await tester.pump(const Duration(seconds: 2));
    await tapVideo(tester);
    await tester.pump(const Duration(seconds: 2));
    expectControls(visible: true);

    await tester.tap(find.byIcon(Icons.forward_10_rounded));
    await tester.pump();
    expect(controller.value.position, const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 2));
    expectControls(visible: true);
    await tester.tap(find.byIcon(Icons.replay_10_rounded));
    await tester.pump();
    expect(controller.value.position, Duration.zero);
    await tester.pump(const Duration(milliseconds: 2999));
    expectControls(visible: true);
    await tester.pump(const Duration(milliseconds: 1));
    expectControls(visible: false);

    await disposePlayer(tester);
  });

  testWidgets('keeps paused controls visible and hides them again on resume', (tester) async {
    final controller = await mountPlayer(tester);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tapVideo(tester);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(seconds: 4));
    expect(controller.value.isPlaying, isFalse);
    expectControls(visible: true, playing: false);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expectControls(visible: false);
    await tapVideo(tester);
    // Removing a player with a pending hide timer must also cancel that timer.
    await disposePlayer(tester);
  });

  testWidgets('restores controls at completion and hides them on replay', (tester) async {
    final controller = await mountPlayer(tester);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await completeVideo(tester);
    await tester.pump(const Duration(seconds: 4));
    expectControls(visible: true, playing: false);
    expect(controller.value.position, controller.value.duration);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(controller.value.position, Duration.zero);
    expect(controller.value.isPlaying, isTrue);
    expectControls(visible: false);
    await tapVideo(tester);
    await completeVideo(tester);
    await tester.pump(const Duration(seconds: 4));
    expectControls(visible: true, playing: false);

    await disposePlayer(tester);
  });

  testWidgets('keeps the overlay visible while scrubbing and hides after release', (tester) async {
    final controller = await mountPlayer(tester);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tapVideo(tester);

    final slider = find.byType(Slider);
    final center = tester.getCenter(slider);
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump(const Duration(seconds: 4));
    expectControls(visible: true);
    await gesture.up();
    await tester.pump();
    expect(controller.value.position, greaterThan(Duration.zero));
    expect(controller.value.isPlaying, isTrue);

    await tester.pump(const Duration(milliseconds: 2999));
    expectControls(visible: true);
    await tester.pump(const Duration(milliseconds: 1));
    expectControls(visible: false);
    await disposePlayer(tester);
  });
}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  final initialized = Completer<void>();
  final created = Completer<void>();
  final fallbackCreated = Completer<void>();
  final _events = <int, StreamController<VideoEvent>>{};
  StreamController<VideoEvent> get events => _events[createCount]!;
  Completer<void>? initializationGate;
  Completer<void>? fallbackInitializationGate;
  Completer<void>? seekGate;
  final seekStarted = Completer<void>();
  int initializationFailures = 0;
  int seekFailures = 0;
  int playFailures = 0;
  int createCount = 0;
  int playCount = 0;
  Duration position = Duration.zero;
  Duration duration = const Duration(minutes: 1);

  @override
  Future<void> init() async {}

  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    final id = ++createCount;
    final stream = _events[id] = StreamController<VideoEvent>();
    if (id == 1) {
      created.complete();
      await initializationGate?.future;
    } else {
      if (!fallbackCreated.isCompleted) fallbackCreated.complete();
      await fallbackInitializationGate?.future;
    }
    if (initializationFailures > 0) {
      initializationFailures--;
      stream.addError(
        PlatformException(code: 'texture_initialization_failed', message: 'Texture unavailable'),
      );
    } else {
      stream.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: duration,
          size: const Size(640, 360),
        ),
      );
    }
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {
    if (!initialized.isCompleted) initialized.complete();
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> play(int playerId) async {
    if (playFailures > 0) {
      playFailures--;
      throw PlatformException(code: 'play_temporarily_unavailable');
    }
    playCount++;
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    if (seekGate != null) {
      if (!seekStarted.isCompleted) seekStarted.complete();
      await seekGate!.future;
    }
    if (seekFailures > 0) {
      seekFailures--;
      throw PlatformException(code: 'seek_temporarily_unavailable');
    }
    this.position = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();

  @override
  Future<void> dispose(int playerId) async => _events[playerId]!.close();
}
