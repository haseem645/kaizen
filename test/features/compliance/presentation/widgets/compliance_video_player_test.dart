import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/core/widgets/app_back_button.dart';
import 'package:sparrowkaizen/features/compliance/presentation/pages/training/compliance_full_screen_video_view.dart';
import 'package:sparrowkaizen/features/compliance/presentation/providers/compliance_video_controller.dart';
import 'package:sparrowkaizen/features/compliance/presentation/widgets/compliance_video_player.dart';
import 'package:sparrowkaizen/features/compliance/presentation/widgets/compliance_video_transcript_panel.dart';
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

  Future<VideoPlayerController> mountPlayer(
    WidgetTester tester, {
    ValueChanged<Future<bool> Function(Duration)?>? onSeekHandlerChanged,
    String? transcript,
    double textScale = 1,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: transcript == null
                ? ComplianceVideoPlayer(
                    videoUrl: '',
                    localVideoPath: videoPath,
                    title: 'Lesson',
                    onSeekHandlerChanged: onSeekHandlerChanged,
                  )
                : ComplianceVideoTranscriptPanel(
                    videoId: 'lesson',
                    videoUrl: 'https://example.test/video.mp4',
                    localVideoPath: videoPath,
                    title: 'Lesson',
                    transcript: transcript,
                  ),
          ),
        ),
      );
      await platform.initialized.future;
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    await tester.pump(); // Apply the measured video edge to the shared footer.
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

  void expectCaptionActionGap(WidgetTester tester, Finder caption) {
    final actionButton = find.ancestor(
      of: find.text(AppStrings.trainingViewTranscript),
      matching: find.byType(TextButton),
    );
    expect(
      tester.getTopLeft(actionButton).dy - tester.getBottomLeft(caption).dy,
      closeTo(4, 0.01),
    );
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

  void expectSeekActionGap(WidgetTester tester) {
    final actionButton = find.ancestor(
      of: find.text(AppStrings.trainingViewTranscript),
      matching: find.byType(TextButton),
    );
    expect(
      tester.getTopLeft(actionButton).dy -
          tester.getBottomLeft(find.byType(Slider)).dy,
      closeTo(6, 0.01),
    );
  }

  testWidgets(
    'opens compactly before loading and anchors controls below the thumbnail',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      platform.autoInitialize = false;
      final originalImageClientProvider = debugNetworkImageHttpClientProvider;
      final releaseThumbnail = Completer<void>();

      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
        final picture = recorder.endRecording();
        final image = await picture.toImage(640, 360);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        image.dispose();
        picture.dispose();
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          await releaseThumbnail.future;
          request.response.headers.contentType = ContentType('image', 'png');
          request.response.add(bytes);
          unawaited(request.response.close());
        });
        final client = HttpOverrides.runWithHttpOverrides(
          HttpClient.new,
          _LocalImageHttpOverrides(),
        );
        debugNetworkImageHttpClientProvider = () => client;
        addTearDown(() async {
          if (!releaseThumbnail.isCompleted) releaseThumbnail.complete();
          debugNetworkImageHttpClientProvider = originalImageClientProvider;
          client.close(force: true);
          await server.close(force: true);
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComplianceVideoTranscriptPanel(
                videoId: 'lesson',
                videoUrl: 'https://example.test/video.mp4',
                localVideoPath: videoPath,
                title: 'Lesson',
                thumbnailLink: 'http://127.0.0.1:${server.port}/thumbnail.png',
                transcript: '[00:10] Later caption',
              ),
            ),
          ),
        );
        await platform.created.future;
      });
      final frame = find.byKey(const ValueKey('training-video-frame'));
      final frameBounds = tester.getRect(frame);
      final surface = find
          .descendant(
            of: find.byType(ComplianceVideoTranscriptPanel),
            matching: find.byType(Material),
          )
          .first;
      final initialSurfaceBounds = tester.getRect(surface);
      final initialTitleBounds = tester.getRect(find.text('Lesson'));
      expect(initialTitleBounds.top, lessThan(frameBounds.bottom));
      await tester.pump();
      expect(tester.getRect(surface), initialSurfaceBounds);
      expect(tester.getRect(find.text('Lesson')), initialTitleBounds);
      releaseThumbnail.complete();
      final thumbnail = find.descendant(
        of: find.byKey(const ValueKey('video-thumbnail-preview')),
        matching: find.byType(RawImage),
      );
      for (
        var attempt = 0;
        attempt < 100 && tester.widget<RawImage>(thumbnail).image == null;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(tester.widget<RawImage>(thumbnail).image, isNotNull);
      await tester.pump();
      final thumbnailBounds = tester.getRect(thumbnail);
      expect(tester.getRect(surface), initialSurfaceBounds);
      expect(tester.getRect(find.text('Lesson')), initialTitleBounds);
      expect(thumbnailBounds.bottom, lessThan(frameBounds.bottom));
      expect(find.text('Later caption'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Lesson')).dy - thumbnailBounds.bottom,
        closeTo(10, 0.01),
      );
      expectSeekActionGap(tester);
      expect(find.byType(VideoPlayer), findsNothing);

      await tester.runAsync(() async {
        platform.initialize();
        await platform.initialized.future;
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump();
      expect(find.text('Later caption'), findsNothing);
      expect(find.text('01:00'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Lesson')).dy - thumbnailBounds.bottom,
        closeTo(10, 0.01),
      );
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Later caption'), findsNothing);
      final actions = find.ancestor(
        of: find.text(AppStrings.trainingViewTranscript),
        matching: find.byType(TextButton),
      );
      expect(
        tester.getTopLeft(actions).dy -
            tester.getBottomLeft(find.byType(VideoPlayer)).dy,
        closeTo(6, 0.01),
      );
      expect(tester.getRect(frame), frameBounds);
      await disposePlayer(tester);
      debugNetworkImageHttpClientProvider = originalImageClientProvider;
    },
  );

  testWidgets(
    'shared panel keeps its transcript and playback controller in fullscreen',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = await mountPlayer(
        tester,
        transcript: '[00:00] Introduction\n[00:15] Active caption',
      );
      await controller.seekTo(const Duration(seconds: 20));
      await tester.pump();
      final transcript = tester
          .element(find.text('Active caption'))
          .read<ComplianceVideoController>();
      await tester.tap(find.byKey(const ValueKey('video-fullscreen-button')));
      await tester.pumpAndSettle();
      expect(find.byType(ComplianceFullScreenVideoView), findsOneWidget);
      expect(find.text('Active caption'), findsOneWidget);
      expect(
        tester
            .element(find.text(AppStrings.trainingViewTranscript))
            .read<ComplianceVideoController>(),
        same(transcript),
      );
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(controller),
      );
      await tester.tap(find.text(AppStrings.trainingViewTranscript));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Introduction'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(controller.value.position, Duration.zero);
      expect(controller.value.isPlaying, isTrue);
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ComplianceFullScreenVideoView), findsNothing);
      expect(find.text('Introduction'), findsOneWidget);
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(controller),
      );
      await disposePlayer(tester);
    },
  );

  testWidgets(
    'captions replace hidden controls and return below without moving the video',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const secondCaption = 'Second caption\nA second line\nAnd a third line';
      final controller = await mountPlayer(
        tester,
        transcript: '[00:00 --> 00:04] First caption\n[00:10] $secondCaption',
      );
      final player = find.byKey(const ValueKey('training-video-frame'));
      final videoBounds = tester.getRect(player);
      final titleBounds = tester.getRect(find.text('Lesson'));
      final durationBounds = tester.getRect(find.text('01:00'));
      final seekBounds = tester.getRect(find.byType(Slider));
      final mediaBounds = tester.getRect(find.byType(VideoPlayer));
      expect(titleBounds.top - mediaBounds.bottom, closeTo(10, 0.01));
      final surface = find
          .descendant(
            of: find.byType(ComplianceVideoTranscriptPanel),
            matching: find.byType(Material),
          )
          .first;
      final expandedHeight = tester.getSize(surface).height;
      expectCaptionActionGap(tester, find.text('First caption'));

      expect(
        tester.getTopLeft(find.text('First caption')).dy,
        seekBounds.bottom + 10,
      );
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expectControls(visible: false);
      expect(find.text('First caption'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('First caption')).dy,
        closeTo(mediaBounds.bottom + 6, 0.01),
      );
      expectCaptionActionGap(tester, find.text('First caption'));
      final collapsedHeight = tester.getSize(surface).height;
      expect(collapsedHeight, lessThan(expandedHeight));
      expect(tester.getRect(player), videoBounds);
      expect(tester.getRect(find.byType(VideoPlayer)), mediaBounds);

      // Tapping the caption itself must reveal the controls just like a video tap.
      await tester.tap(find.text('First caption'));
      await tester.pump();
      expectControls(visible: true);
      expect(tester.getRect(find.text('Lesson')), titleBounds);
      expect(tester.getRect(find.text('01:00')), durationBounds);
      expect(tester.getRect(find.byType(Slider)), seekBounds);
      expect(
        tester.getTopLeft(find.text('First caption')).dy,
        seekBounds.bottom + 10,
      );
      expect(tester.getSize(surface).height, expandedHeight);
      expectCaptionActionGap(tester, find.text('First caption'));
      await tester.pump(const Duration(milliseconds: 2999));
      expect(
        tester.getTopLeft(find.text('First caption')).dy,
        seekBounds.bottom + 10,
      );
      await tester.pump(const Duration(milliseconds: 1));
      expectControls(visible: false);
      expect(tester.getSize(surface).height, collapsedHeight);

      await controller.seekTo(const Duration(seconds: 15));
      await tester.pump();
      expect(find.text('First caption'), findsNothing);
      expect(find.text(secondCaption), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(secondCaption)).dy,
        closeTo(mediaBounds.bottom + 6, 0.01),
      );
      final multilineHeight = tester.getSize(surface).height;
      expect(multilineHeight, greaterThan(collapsedHeight));
      expectCaptionActionGap(tester, find.text(secondCaption));
      await tester.tap(find.text(AppStrings.trainingCc));
      await tester.pump();
      expect(find.text(secondCaption), findsNothing);
      expectControls(visible: false);
      expect(controller.value.isPlaying, isTrue);
      final ccCollapsedHeight = tester.getSize(surface).height;
      expect(ccCollapsedHeight, lessThan(collapsedHeight));
      expect(tester.getBottomLeft(surface).dy, lessThan(videoBounds.bottom));
      expect(tester.getRect(player), videoBounds);
      final actionButton = find.ancestor(
        of: find.text(AppStrings.trainingViewTranscript),
        matching: find.byType(TextButton),
      );
      expect(
        tester.getTopLeft(actionButton).dy,
        closeTo(mediaBounds.bottom + 6, 0.01),
      );

      // The seek area's space returns only while its controls are visible.
      await tapVideo(tester);
      expectControls(visible: true);
      expectSeekActionGap(tester);
      expect(tester.getSize(surface).height, greaterThan(ccCollapsedHeight));
      expect(tester.getRect(find.text('Lesson')), titleBounds);
      expect(tester.getRect(find.text('01:00')), durationBounds);
      expect(tester.getRect(find.byType(Slider)), seekBounds);
      await tester.pump(const Duration(seconds: 3));
      expectControls(visible: false);
      expect(find.text(secondCaption), findsNothing);
      expect(tester.getSize(surface).height, ccCollapsedHeight);
      expect(tester.getRect(player), videoBounds);
      expect(tester.getRect(find.byType(VideoPlayer)), mediaBounds);

      await tester.tap(find.text(AppStrings.trainingCc));
      await tester.pump();
      expect(find.text(secondCaption), findsOneWidget);
      expect(tester.getSize(surface).height, multilineHeight);
      expectCaptionActionGap(tester, find.text(secondCaption));

      await tapVideo(tester);
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump(const Duration(seconds: 4));
      expectControls(visible: true, playing: false);
      expect(tester.getSize(surface).height, greaterThan(expandedHeight));
      expectCaptionActionGap(tester, find.text(secondCaption));
      expect(
        tester.getTopLeft(find.text(secondCaption)).dy,
        seekBounds.bottom + 10,
      );
      expect(tester.getRect(find.byType(Slider)), seekBounds);
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expectControls(visible: false);
      await completeVideo(tester);
      expectControls(visible: true, playing: false);
      expect(tester.getSize(surface).height, greaterThan(expandedHeight));
      expectCaptionActionGap(tester, find.text(secondCaption));
      expect(
        tester.getTopLeft(find.text(secondCaption)).dy,
        seekBounds.bottom + 10,
      );
      expect(tester.getRect(player), videoBounds);
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(controller),
      );

      // Both a timing gap and CC hiding a current cue leave only 6 dp below the seek bar.
      await controller.seekTo(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text(secondCaption), findsNothing);
      expectSeekActionGap(tester);
      expect(tester.getRect(find.byType(Slider)), seekBounds);
      expect(tester.getRect(player), videoBounds);
      await controller.seekTo(const Duration(seconds: 15));
      await tester.pump();
      expectCaptionActionGap(tester, find.text(secondCaption));
      await tester.tap(find.text(AppStrings.trainingCc));
      await tester.pump();
      expect(find.text(secondCaption), findsNothing);
      expectSeekActionGap(tester);
      expect(tester.getRect(find.byType(Slider)), seekBounds);
      expect(tester.getRect(player), videoBounds);
      await tester.tap(find.text(AppStrings.trainingCc));
      await tester.pump();
      expectCaptionActionGap(tester, find.text(secondCaption));
      await disposePlayer(tester);
    },
  );

  testWidgets(
    'long captions wrap and scroll in the hidden seek area with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cue = List.filled(
        30,
        'A complete long transcript line that wraps naturally',
      ).join('\n');
      final controller = await mountPlayer(
        tester,
        transcript: '[00:00] $cue',
        textScale: 2,
      );
      final player = find.byKey(const ValueKey('training-video-frame'));
      final videoBounds = tester.getRect(player);
      final seekBounds = tester.getRect(find.byType(Slider));
      final mediaBounds = tester.getRect(find.byType(VideoPlayer));
      final controls = find
          .ancestor(of: find.byType(Slider), matching: find.byType(Column))
          .first;
      expect(
        tester.getTopLeft(controls).dy - mediaBounds.bottom,
        closeTo(10, 0.01),
      );
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      final caption = find.text(cue);
      expect(caption, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: caption, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      final viewport = find
          .ancestor(of: caption, matching: find.byType(SingleChildScrollView))
          .first;
      expect(viewport, findsOneWidget);
      final viewportBounds = tester.getRect(viewport);
      expect(viewportBounds.top, closeTo(mediaBounds.bottom + 6, 0.01));
      expect(
        tester.getTopLeft(caption).dy,
        closeTo(mediaBounds.bottom + 6, 0.01),
      );
      expect(viewportBounds.bottom, greaterThan(videoBounds.bottom));
      final scrollable = find.descendant(
        of: viewport,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      await tester.drag(viewport, Offset(0, -position.maxScrollExtent - 100));
      await tester.pump(const Duration(seconds: 1));
      expect(position.pixels, closeTo(position.maxScrollExtent, 1));
      expectCaptionActionGap(tester, caption);
      expect(find.byType(Slider), findsNothing);
      expect(tester.getRect(player), videoBounds);

      await tester.tapAt(viewportBounds.center);
      await tester.pump();
      expect(find.byType(Slider), findsOneWidget);
      expect(tester.getRect(find.byType(Slider)), seekBounds);
      expect(tester.getTopLeft(caption).dy, seekBounds.bottom + 10);
      expect(tester.getRect(player), videoBounds);
      // Scaled controls can extend beyond the fixed frame and remain tappable.
      expect(seekBounds.bottom, greaterThan(videoBounds.bottom));
      await tester.tap(find.byType(Slider));
      await tester.pump();
      expect(controller.value.position, greaterThan(Duration.zero));
      expect(find.byType(Slider), findsOneWidget);
      await disposePlayer(tester);
    },
  );

  testWidgets(
    'transcript jumps retry temporary native seek and play failures',
    (tester) async {
      Future<bool> Function(Duration)? seek;
      final controller = await mountPlayer(
        tester,
        onSeekHandlerChanged: (handler) => seek = handler,
      );
      platform.seekFailures = 1;
      platform.playFailures = 1;
      expect(await seek!(const Duration(seconds: 15)), isTrue);
      await tester.pump();
      expect(controller.value.position, const Duration(seconds: 15));
      expect(controller.value.isPlaying, isTrue);
      expectControls(visible: true);
      expect(
        find.byKey(const ValueKey('video-fullscreen-button')),
        findsOneWidget,
      );
      await disposePlayer(tester);
      expect(seek, isNull);
    },
  );

  testWidgets(
    'failed transcript jumps remain retryable and clamp to the video duration',
    (tester) async {
      Future<bool> Function(Duration)? seek;
      final controller = await mountPlayer(
        tester,
        onSeekHandlerChanged: (handler) => seek = handler,
      );
      platform.seekFailures = 3;
      expect(await seek!(const Duration(seconds: 10)), isFalse);
      expect(await seek!(const Duration(minutes: 2)), isTrue);
      await tester.pump();
      expect(controller.value.position, const Duration(minutes: 1));
      expect(controller.value.isPlaying, isFalse);
      await disposePlayer(tester);
    },
  );

  testWidgets(
    'transcript jumps wait for initialization before seeking and playing',
    (tester) async {
      platform.autoInitialize = false;
      Future<bool> Function(Duration)? seek;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComplianceVideoPlayer(
                videoUrl: '',
                localVideoPath: videoPath,
                title: 'Lesson',
                onSeekHandlerChanged: (handler) => seek = handler,
              ),
            ),
          ),
        );
        final pending = seek!(const Duration(seconds: 12));
        await platform.created.future;
        expect(platform.position, Duration.zero);
        platform.initialize();
        expect(await pending, isTrue);
      });
      await tester.pump();
      final controller = tester
          .widget<VideoPlayer>(find.byType(VideoPlayer))
          .controller;
      expect(controller.value.position, const Duration(seconds: 12));
      expect(controller.value.isPlaying, isTrue);
      await disposePlayer(tester);
    },
  );

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

class _LocalImageHttpOverrides extends HttpOverrides {}

class _FakeVideoPlatform extends VideoPlayerPlatform {
  final initialized = Completer<void>();
  final created = Completer<void>();
  bool autoInitialize = true;
  int seekFailures = 0;
  int playFailures = 0;
  final events = StreamController<VideoEvent>();
  Duration position = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int> createWithOptions(VideoCreationOptions options) async {
    if (autoInitialize) initialize();
    created.complete();
    return 1;
  }

  void initialize() {
    events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(minutes: 1),
        size: const Size(640, 360),
      ),
    );
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
  Future<void> play(int playerId) async {
    if (playFailures > 0) {
      playFailures--;
      throw StateError('Temporary native play failure');
    }
  }

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    if (seekFailures > 0) {
      seekFailures--;
      throw StateError('Temporary native seek failure');
    }
    this.position = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();

  @override
  Future<void> dispose(int playerId) async => events.close();
}
