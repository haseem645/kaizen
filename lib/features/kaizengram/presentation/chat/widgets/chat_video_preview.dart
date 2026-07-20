import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../widgets/kaizengram_notifier_state.dart';

class ChatVideoPreview extends StatefulWidget {
  const ChatVideoPreview({
    super.key,
    required this.videoPath,
    this.maxHeight = 220,
    this.fit = BoxFit.contain,
    this.muted = false,
    this.autoPlay = false,
    this.playButtonSize = 54,
    this.playIconSize = 30,
    this.onTapOverride,
    this.onOpenFullScreen,
  });

  final String videoPath;
  final double maxHeight;
  final BoxFit fit;
  final bool muted;
  final bool autoPlay;
  final double playButtonSize;
  final double playIconSize;
  final VoidCallback? onTapOverride;
  final VoidCallback? onOpenFullScreen;

  @override
  State<ChatVideoPreview> createState() => _ChatVideoPreviewState();
}

class _ChatVideoPreviewState extends State<ChatVideoPreview>
    with KaizengramNotifierState<ChatVideoPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant ChatVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath ||
        oldWidget.muted != widget.muted ||
        oldWidget.autoPlay != widget.autoPlay) {
      _disposeController();
      _setupController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _setupController() {
    final controller = widget.videoPath.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoPath))
        : VideoPlayerController.file(File(widget.videoPath));
    _controller = controller;
    _initializeFuture = controller
        .initialize()
        .then((_) async {
          await controller.setLooping(false);
          await controller.setVolume(widget.muted ? 0 : 1);
          controller.addListener(_handleVideoChanged);
          if (widget.autoPlay) {
            await controller.play();
          }
          if (mounted) {
            notifyView();
          }
        })
        .catchError((_) {
          if (mounted) {
            notifyView();
          }
        });
  }

  void _disposeController() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleVideoChanged);
    }
    _controller = null;
    _initializeFuture = null;
    controller?.dispose();
  }

  void _handleVideoChanged() {
    if (mounted) {
      notifyView();
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    if (!controller.value.isInitialized) {
      try {
        await _initializeFuture;
      } catch (_) {
        return;
      }
    }

    if (!controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration > Duration.zero && position >= duration) {
      await controller.seekTo(Duration.zero);
    }

    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return buildWithNotifier((context) {
      final controller = _controller;
      final initializeFuture = _initializeFuture;
      if (controller == null || initializeFuture == null) {
        return const _ChatVideoPreviewFallback();
      }

      return FutureBuilder<void>(
        future: initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError || !controller.value.isInitialized) {
            return const _ChatVideoPreviewFallback();
          }

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTapOverride ?? _togglePlayback,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final videoSize = controller.value.size;
                  final aspectRatio = controller.value.aspectRatio > 0
                      ? controller.value.aspectRatio
                      : 16 / 9;
                  final maxWidth = constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : MediaQuery.sizeOf(context).width;
                  final naturalHeight = maxWidth / aspectRatio;
                  final displayHeight = naturalHeight > widget.maxHeight
                      ? widget.maxHeight
                      : naturalHeight;
                  final displayWidth = naturalHeight > widget.maxHeight
                      ? widget.maxHeight * aspectRatio
                      : maxWidth;

                  return SizedBox(
                    width: maxWidth,
                    height: displayHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Center(
                          child: FittedBox(
                            fit: widget.fit,
                            child: SizedBox(
                              width: videoSize.width == 0
                                  ? displayWidth
                                  : videoSize.width,
                              height: videoSize.height == 0
                                  ? displayHeight
                                  : videoSize.height,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: controller.value.isPlaying ? 0.12 : 0.28,
                            ),
                          ),
                        ),
                        if (!controller.value.isPlaying)
                          Center(
                            child: Container(
                              width: widget.playButtonSize,
                              height: widget.playButtonSize,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.48),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: widget.playIconSize,
                              ),
                            ),
                          ),
                        if (widget.onOpenFullScreen != null)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: widget.onOpenFullScreen,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    });
  }
}

class _ChatVideoPreviewFallback extends StatelessWidget {
  const _ChatVideoPreviewFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: const Color(0xFF111317),
      alignment: Alignment.center,
      child: const Icon(
        Icons.videocam_rounded,
        color: AppColors.textSecondary,
        size: 34,
      ),
    );
  }
}
