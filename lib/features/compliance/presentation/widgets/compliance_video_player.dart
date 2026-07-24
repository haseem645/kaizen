import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/video_playback_service.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../pages/training/compliance_full_screen_video_view.dart';

class ComplianceVideoPlayer extends StatefulWidget {
  const ComplianceVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.title,
    this.thumbnailLink,
    this.height = 220,
    this.showTitle = true,
    this.showSeekBar = true,
    this.showDuration = true,
    this.fillBounds = false,
  });

  final String videoUrl;
  final String title;
  final String? thumbnailLink;
  final double height;
  final bool showTitle;
  final bool showSeekBar;
  final bool showDuration;
  final bool fillBounds;

  @override
  State<ComplianceVideoPlayer> createState() => _ComplianceVideoPlayerState();
}

class _ComplianceVideoPlayerState extends State<ComplianceVideoPlayer> {
  static const _cacheMaxAge = Duration(days: 30);
  static const _playbackStartWaitTimeout = Duration(milliseconds: 900);

  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  Object? _initializationError;
  int _initializationGeneration = 0;
  VideoViewType _currentViewType = VideoViewType.textureView;
  bool _didRetryWithPlatformView = false;
  late bool _showThumbnailPreview;
  bool _isPreparingPlayback = false;
  bool _isScrubbing = false;
  double? _scrubPositionMillis;

  @override
  void initState() {
    super.initState();
    _showThumbnailPreview = _hasThumbnail;
    _warmUpVideoCache();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant ComplianceVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.thumbnailLink != widget.thumbnailLink) {
      _showThumbnailPreview = _hasThumbnail;
      _isScrubbing = false;
      _scrubPositionMillis = null;
    }

    if (oldWidget.videoUrl != widget.videoUrl) {
      _currentViewType = VideoViewType.textureView;
      _didRetryWithPlatformView = false;
      _disposeController();
      _warmUpVideoCache();
      _setupController();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _warmUpVideoCache() {
    unawaited(
      VideoPlaybackService.warmUp(widget.videoUrl, cacheMaxAge: _cacheMaxAge),
    );
  }

  void _setupController() {
    _initializationError = null;
    _controller = null;
    final generation = ++_initializationGeneration;
    _initializeFuture = _initializeController(
      generation,
      viewType: _currentViewType,
    );
  }

  Future<void> _initializeController(
    int generation, {
    required VideoViewType viewType,
  }) async {
    VideoPlayerController? controller;

    try {
      controller = await VideoPlaybackService.createInitializedController(
        widget.videoUrl,
        cacheMaxAge: _cacheMaxAge,
        viewType: viewType,
      );
      if (controller == null) {
        throw ArgumentError('Invalid video URL');
      }

      if (!mounted || !_isActiveGeneration(generation)) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(false);
      await controller.setVolume(1);
      if (!mounted || !_isActiveGeneration(generation)) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
    } catch (error) {
      if (controller != null) {
        await controller.dispose();
      }
      if (_shouldRetryWithPlatformView(viewType, generation)) {
        _currentViewType = VideoViewType.platformView;
        _didRetryWithPlatformView = true;
        _setupController();
        if (mounted) {
          setState(() {});
        }
        return;
      }
      if (mounted && _isActiveGeneration(generation)) {
        setState(() {
          _initializationError = error;
        });
      }
      rethrow;
    }
  }

  bool _shouldRetryWithPlatformView(
    VideoViewType attemptedViewType,
    int generation,
  ) {
    if (!mounted || !_isActiveGeneration(generation)) {
      return false;
    }

    if (CustomFunctions.isApplePlatform()) {
      return false;
    }

    return attemptedViewType == VideoViewType.textureView &&
        !_didRetryWithPlatformView;
  }

  bool _isActiveGeneration(int generation) {
    return generation == _initializationGeneration;
  }

  void _disposeController() {
    _initializationGeneration++;

    final controller = _controller;
    _controller = null;
    _initializeFuture = null;
    _initializationError = null;
    _isPreparingPlayback = false;
    _isScrubbing = false;
    _scrubPositionMillis = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
  }

  bool get _hasThumbnail {
    return CustomFunctions.resolveImageUrl(widget.thumbnailLink) != null;
  }

  Future<VideoPlayerController?> _ensureControllerReady() async {
    final currentController = _controller;
    if (currentController != null && currentController.value.isInitialized) {
      return currentController;
    }

    try {
      if (_initializeFuture == null || _initializationError != null) {
        _setupController();
        if (mounted) {
          setState(() {});
        }
      }

      final initializeFuture = _initializeFuture;
      if (initializeFuture != null) {
        await initializeFuture;
      }

      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        return null;
      }

      return controller;
    } catch (_) {
      return null;
    }
  }

  Future<void> _togglePlayback() async {
    final activeController = _controller;
    final wasReadyBeforeTap =
        activeController != null && activeController.value.isInitialized;
    if (!wasReadyBeforeTap && mounted) {
      setState(() {
        _isPreparingPlayback = true;
      });
    }

    final controller = await _ensureControllerReady();
    if (controller == null || !controller.value.isInitialized) {
      if (mounted) {
        setState(() {
          _isPreparingPlayback = false;
        });
      }
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
      if (mounted) {
        setState(() {
          _isPreparingPlayback = false;
        });
      }
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;
    if (duration > Duration.zero && position >= duration) {
      await controller.seekTo(Duration.zero);
    }

    await controller.play();
    await _waitForPlaybackToStart(controller, initialPosition: position);
    if (_showThumbnailPreview && mounted) {
      setState(() {
        _showThumbnailPreview = false;
      });
    }
    if (mounted) {
      setState(() {
        _isPreparingPlayback = false;
      });
    }
  }

  Future<void> _seekBy(Duration offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;
    final nextPosition = position + offset;

    if (nextPosition <= Duration.zero) {
      await controller.seekTo(Duration.zero);
      return;
    }

    if (nextPosition >= duration) {
      await controller.seekTo(duration);
      return;
    }

    await controller.seekTo(nextPosition);
  }

  Future<void> _openFullScreenVideo() async {
    final wasReadyBeforeOpen =
        _controller != null && _controller!.value.isInitialized;
    if (!wasReadyBeforeOpen && mounted) {
      setState(() {
        _isPreparingPlayback = true;
      });
    }

    final controller = await _ensureControllerReady();
    if (controller == null || !controller.value.isInitialized || !mounted) {
      if (mounted) {
        setState(() {
          _isPreparingPlayback = false;
        });
      }
      return;
    }

    final initialPosition = controller.value.position;
    if (mounted) {
      setState(() {
        _isPreparingPlayback = false;
      });
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ComplianceFullScreenVideoView(
          controller: controller,
          title: widget.title,
          initialPosition: initialPosition,
        ),
      ),
    );
  }

  Future<void> _waitForPlaybackToStart(
    VideoPlayerController controller, {
    required Duration initialPosition,
  }) async {
    final value = controller.value;
    if (_hasPlaybackStarted(value, initialPosition)) {
      return;
    }

    final completer = Completer<void>();
    late VoidCallback listener;
    listener = () {
      final nextValue = controller.value;
      if (_hasPlaybackStarted(nextValue, initialPosition)) {
        controller.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    };

    controller.addListener(listener);
    try {
      await completer.future.timeout(
        _playbackStartWaitTimeout,
        onTimeout: () {},
      );
    } finally {
      controller.removeListener(listener);
    }
  }

  bool _hasPlaybackStarted(VideoPlayerValue value, Duration initialPosition) {
    return value.position > initialPosition ||
        (value.isPlaying && !value.isBuffering);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (controller == null) {
          return _buildPlayerContent(
            snapshot: snapshot,
            controller: null,
            controllerValue: null,
          );
        }

        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, controllerValue, child) {
            return _buildPlayerContent(
              snapshot: snapshot,
              controller: controller,
              controllerValue: controllerValue,
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerContent({
    required AsyncSnapshot<void> snapshot,
    required VideoPlayerController? controller,
    required VideoPlayerValue? controllerValue,
  }) {
    final thumbnailUrl = CustomFunctions.resolveImageUrl(widget.thumbnailLink);
    final initializationError = _initializationError ?? snapshot.error;
    final isReady =
        controller != null &&
        controllerValue?.isInitialized == true &&
        initializationError == null;
    final isBuffering = isReady && (controllerValue?.isBuffering ?? false);
    final showThumbnailPreview =
        _showThumbnailPreview &&
        thumbnailUrl != null &&
        !(controllerValue?.isPlaying ?? false) &&
        initializationError == null;
    final isLoading =
        _isPreparingPlayback ||
        (!showThumbnailPreview &&
            initializationError == null &&
            !isReady &&
            snapshot.connectionState == ConnectionState.waiting);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: widget.fillBounds
                ? SizedBox.expand(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: showThumbnailPreview
                              ? Image.network(
                                  thumbnailUrl,
                                  key: const ValueKey(
                                    'video-thumbnail-preview',
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const ColoredBox(
                                      key: ValueKey('video-loading-background'),
                                      color: Colors.black,
                                    );
                                  },
                                )
                              : isReady
                              ? FittedBox(
                                  key: ValueKey(controller),
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: controllerValue!.size.width,
                                    height: controllerValue.size.height,
                                    child: VideoPlayer(controller),
                                  ),
                                )
                              : const ColoredBox(
                                  key: ValueKey('video-loading-background'),
                                  color: Colors.black,
                                ),
                        ),
                        _buildOverlay(
                          controller: controller,
                          controllerValue: controllerValue,
                          initializationError: initializationError,
                          isReady: isReady,
                          isLoading: isLoading,
                          isBuffering: isBuffering,
                          showThumbnailPreview: showThumbnailPreview,
                        ),
                      ],
                    ),
                  )
                : AspectRatio(
                    aspectRatio: isReady ? controllerValue!.aspectRatio : 1.7,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: showThumbnailPreview
                              ? Image.network(
                                  thumbnailUrl,
                                  key: const ValueKey(
                                    'video-thumbnail-preview',
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const ColoredBox(
                                      key: ValueKey('video-loading-background'),
                                      color: Colors.black,
                                    );
                                  },
                                )
                              : isReady
                              ? VideoPlayer(
                                  controller,
                                  key: ValueKey(controller),
                                )
                              : const ColoredBox(
                                  key: ValueKey('video-loading-background'),
                                  color: Colors.black,
                                ),
                        ),
                        _buildOverlay(
                          controller: controller,
                          controllerValue: controllerValue,
                          initializationError: initializationError,
                          isReady: isReady,
                          isLoading: isLoading,
                          isBuffering: isBuffering,
                          showThumbnailPreview: showThumbnailPreview,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay({
    required VideoPlayerController? controller,
    required VideoPlayerValue? controllerValue,
    required Object? initializationError,
    required bool isReady,
    required bool isLoading,
    required bool isBuffering,
    required bool showThumbnailPreview,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.10),
                Colors.black.withValues(alpha: 0.45),
              ],
            ),
          ),
        ),
        if (initializationError != null)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: AppTextView.body(
                'Video could not be loaded.',
                color: AppColors.textPrimary,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (isReady && isBuffering && !showThumbnailPreview)
          Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: FastCircularProgressIndicator(),
            ),
          ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _openFullScreenVideo,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                '${AppStrings.imagePath}expand.svg',
                width: 35,
                height: 35,
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 0,
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleIconButton(
                icon: Icons.replay_10_rounded,
                onTap: isReady
                    ? () => _seekBy(const Duration(seconds: -10))
                    : null,
              ),
              const SizedBox(width: 8),
              _PlayButton(
                isLoading: isLoading,
                isPlaying: controllerValue?.isPlaying ?? false,
                onTap: initializationError != null ? null : _togglePlayback,
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.forward_10_rounded,
                onTap: isReady
                    ? () => _seekBy(const Duration(seconds: 10))
                    : null,
              ),
            ],
          ),
        ),
        if (widget.showSeekBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSeekBar(controller, controllerValue),
          ),
        if (widget.showTitle)
          Positioned(
            left: 20,
            bottom: 35,
            child: AppTextView.body1(
              widget.title,
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (widget.showDuration)
          Positioned(
            right: 23,
            bottom: 35,
            child: _buildDurationRow(controllerValue),
          ),
      ],
    );
  }

  Widget _buildSeekBar(
    VideoPlayerController? controller,
    VideoPlayerValue? controllerValue,
  ) {
    final duration = controllerValue?.duration ?? Duration.zero;
    final position = _resolvedDisplayedPosition(controllerValue);
    final maxMillis = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final currentMillis = position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.secondaryColor,
        inactiveTrackColor: AppColors.textPrimary.withValues(alpha: 0.35),
        thumbColor: AppColors.textPrimary,
        overlayColor: AppColors.secondaryColor.withValues(alpha: 0.18),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
      ),
      child: Slider(
        value: currentMillis,
        min: 0,
        max: maxMillis,
        onChangeStart:
            controller == null || controllerValue?.isInitialized != true
            ? null
            : (value) {
                setState(() {
                  _isScrubbing = true;
                  _scrubPositionMillis = value;
                });
              },
        onChanged: controller == null || controllerValue?.isInitialized != true
            ? null
            : (value) {
                setState(() {
                  _scrubPositionMillis = value;
                });
              },
        onChangeEnd:
            controller == null || controllerValue?.isInitialized != true
            ? null
            : (value) async {
                setState(() {
                  _isScrubbing = false;
                  _scrubPositionMillis = null;
                });
                await controller.seekTo(Duration(milliseconds: value.round()));
              },
      ),
    );
  }

  Duration _resolvedDisplayedPosition(VideoPlayerValue? controllerValue) {
    if (_isScrubbing && _scrubPositionMillis != null) {
      return Duration(milliseconds: _scrubPositionMillis!.round());
    }

    return controllerValue?.position ?? Duration.zero;
  }

  Widget _buildDurationRow(VideoPlayerValue? controllerValue) {
    final position = _resolvedDisplayedPosition(controllerValue);
    final duration = controllerValue?.duration ?? Duration.zero;

    return Row(
      children: [
        AppTextView.body4(
          CustomFunctions.formatDuration(position.inSeconds),
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        AppTextView.body4(
          '/',
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        AppTextView.body4(
          CustomFunctions.formatDuration(duration.inSeconds),
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;
  static const double _diameter = 36;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _diameter,
        height: _diameter,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onTap == null ? AppColors.grey1 : AppColors.textPrimary,
          size: _diameter * 0.7,
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isLoading,
    required this.isPlaying,
    required this.onTap,
  });

  final bool isLoading;
  final bool isPlaying;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.secondaryColor,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? FastCircularProgressIndicator(width: 24, height: 24)
            : Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: AppColors.textPrimary,
                size: 42,
              ),
      ),
    );
  }
}
