import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    videoDirectory = Directory.systemTemp.createTempSync(
      'video-controls-test-',
    );
    videoPath = '${videoDirectory.path}/video.mp4';
    File(videoPath).writeAsBytesSync([0]);
  });

  tearDown(() {
    VideoPlayerPlatform.instance = originalPlatform;
    videoDirectory.deleteSync(recursive: true);
  });

  Future<VideoPlayerController> mountPlayer(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComplianceVideoPlayer(
              videoUrl: '',
              localVideoPath: videoPath,
              title: 'Lesson',
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
    expect(
      find.byIcon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
      matcher,
    );
  }

  testWidgets('hides on play and reveals controls for exactly three seconds', (
    tester,
  ) async {
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

  testWidgets('tapping again and skipping restart the three-second timer', (
    tester,
  ) async {
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

  testWidgets('keeps paused controls visible and hides them again on resume', (
    tester,
  ) async {
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

  testWidgets('restores controls at completion and hides them on replay', (
    tester,
  ) async {
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

  testWidgets(
    'keeps the overlay visible while scrubbing and hides after release',
    (tester) async {
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
    },
  );
}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  final initialized = Completer<void>();
  final events = StreamController<VideoEvent>();
  Duration position = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 1),
        size: const Size(640, 360),
      ),
    );
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {
    if (!initialized.isCompleted) initialized.complete();
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    this.position = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();

  @override
  Future<void> dispose(int playerId) async => events.close();
}
