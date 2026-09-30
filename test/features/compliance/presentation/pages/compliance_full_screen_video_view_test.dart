import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/widgets/app_back_button.dart';
import 'package:sparrowkaizen/features/compliance/presentation/pages/training/compliance_full_screen_video_view.dart';
import 'package:video_player/video_player.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  const fullscreenChannel = MethodChannel('kaizenteams/video_fullscreen');
  late VideoPlayerPlatform originalPlatform;
  late _VideoPlatform platform;
  late VideoPlayerController controller;
  final orientationRequests = <List<dynamic>>[];
  final fullscreenRequests = <bool>[];
  final systemUiRequests = <String>[];

  setUp(() {
    originalPlatform = VideoPlayerPlatform.instance;
    platform = _VideoPlatform();
    VideoPlayerPlatform.instance = platform;
    orientationRequests.clear();
    fullscreenRequests.clear();
    systemUiRequests.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        orientationRequests.add(call.arguments as List<dynamic>);
      } else if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
        systemUiRequests.add(call.arguments as String);
      }
      return null;
    });
    messenger.setMockMethodCallHandler(fullscreenChannel, (call) async {
      fullscreenRequests.add((call.arguments as Map)['enabled'] as bool);
      return null;
    });
  });

  tearDown(() async {
    await controller.dispose();
    VideoPlayerPlatform.instance = originalPlatform;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    messenger.setMockMethodCallHandler(fullscreenChannel, null);
  });

  Future<void> openPlayer(WidgetTester tester, {bool playing = true}) async {
    controller = VideoPlayerController.networkUrl(
      Uri.parse('https://example.com/video.mp4'),
    );
    await tester.runAsync(() async {
      await controller.initialize();
      await controller.seekTo(const Duration(seconds: 20));
      if (playing) await controller.play();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ComplianceFullScreenVideoView(
                    controller: controller,
                    title: 'Lesson',
                    initialPosition: controller.value.position,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final useSystemBack in [false, true]) {
    testWidgets(
      'wide video stays portrait without rotation controls and restores on ${useSystemBack ? 'system' : 'button'} back',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.padding = FakeViewPadding(
          left: 30,
          right: 30,
          top: 24,
          bottom: 20,
        );
        addTearDown(tester.view.reset);
        await openPlayer(tester);

        expect(orientationRequests.single, ['DeviceOrientation.portraitUp']);
        expect(fullscreenRequests, [true]);
        final video = find.byType(VideoPlayer);
        expect(tester.getSize(video).width, 390);
        expect(find.byIcon(Icons.screen_rotation_outlined), findsNothing);
        final size = tester.getSize(video);
        expect(size.height, closeTo(390 * 9 / 16, 0.01));
        expect(tester.getTopLeft(video).dx, 0);
        expect(
          tester.getTopLeft(find.byType(AppBackButton)).dx,
          greaterThanOrEqualTo(30),
        );
        expect(
          tester.getTopLeft(find.byType(AppBackButton)).dy,
          greaterThanOrEqualTo(24),
        );
        expect(tester.widget<VideoPlayer>(video).controller, same(controller));
        expect(controller.value.position, const Duration(seconds: 20));
        expect(controller.value.isPlaying, isTrue);

        if (useSystemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byType(AppBackButton));
        }
        await tester.pumpAndSettle();
        expect(find.byType(ComplianceFullScreenVideoView), findsNothing);
        expect(
          orientationRequests,
          everyElement(['DeviceOrientation.portraitUp']),
        );
        expect(find.byIcon(Icons.screen_rotation_outlined), findsNothing);
        expect(fullscreenRequests, [true, false]);
        expect(controller.value.isPlaying, isTrue);
        expect(controller.value.position, const Duration(seconds: 20));
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'portrait video fits the screen and remains seekable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      platform.size = const Size(360, 640);
      await openPlayer(tester, playing: false);
      expect(orientationRequests.single, ['DeviceOrientation.portraitUp']);
      final size = tester.getSize(find.byType(VideoPlayer));
      expect(size.width, 390);
      expect(size.height, closeTo(390 * 16 / 9, 0.01));
      expect(controller.value.isPlaying, isFalse);

      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(
        controller.value.position,
        greaterThan(const Duration(seconds: 20)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(orientationRequests.last, ['DeviceOrientation.portraitUp']);
      expect(fullscreenRequests, isEmpty);
      expect(systemUiRequests, [
        'SystemUiMode.immersiveSticky',
        'SystemUiMode.edgeToEdge',
      ]);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}

class _VideoPlatform extends VideoPlayerPlatform {
  final _events = StreamController<VideoEvent>();
  Size size = const Size(640, 360);
  Duration position = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    _events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 1),
        size: size,
      ),
    );
    return 1;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

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
  Future<void> dispose(int playerId) async => _events.close();
}
