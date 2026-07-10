import 'dart:async';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
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

  CachedVideoPlayerPlus? _cachedPlayer;
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  Object? _initializationError;
  int _initializationGeneration = 0;
  late bool _showThumbnailPreview;

  @override
  void initState() {
    super.initState();
    _showThumbnailPreview = _hasThumbnail;
    _setupController();
  }

  @override
  void didUpdateWidget(covariant ComplianceVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.thumbnailLink != widget.thumbnailLink) {
      _showThumbnailPreview = _hasThumbnail;
    }

    if (oldWidget.videoUrl != widget.videoUrl) {
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
    final resolvedVideoUrl = CustomFunctions.resolveNetworkUrl(widget.videoUrl);
    if (resolvedVideoUrl == null) {
      _initializationError = ArgumentError('Invalid video URL');
      _initializeFuture = Future<void>.error(_initializationError!);
      return;
    }

    _initializationError = null;
    _controller = null;
    final generation = ++_initializationGeneration;
    _initializeFuture = _initializeWithCacheFallback(
      Uri.parse(resolvedVideoUrl),
      generation,
    );
  }

  Future<void> _initializeWithCacheFallback(
    Uri videoUri,
    int generation,
  ) async {
    try {
      await _initializeCachedPlayer(videoUri, generation);
    } catch (error) {
      if (!_isActiveGeneration(generation)) {
        return;
      }

      await _clearFailedCachedPlayer(videoUri, generation);
      if (!_isActiveGeneration(generation)) {
        return;
      }

      try {
        await _initializeCachedPlayer(videoUri, generation);
      } catch (retryError) {
        if (mounted && _isActiveGeneration(generation)) {
          setState(() {
            _initializationError = retryError;
          });
        }

        rethrow;
      }
    }
  }

  Future<void> _initializeCachedPlayer(Uri videoUri, int generation) async {
    final cachedPlayer = CachedVideoPlayerPlus.networkUrl(
      videoUri,
      invalidateCacheIfOlderThan: _cacheMaxAge,
    );
    if (!_isActiveGeneration(generation)) {
      unawaited(cachedPlayer.dispose());
      return;
    }

    _cachedPlayer = cachedPlayer;

    await cachedPlayer.initialize();
    if (!mounted ||
        !_isActiveGeneration(generation) ||
        !identical(_cachedPlayer, cachedPlayer)) {
      unawaited(cachedPlayer.dispose());
      return;
    }

    final controller = cachedPlayer.controller;
    controller.addListener(_handleVideoChanged);
    setState(() {
      _controller = controller;
    });
  }

  Future<void> _clearFailedCachedPlayer(Uri videoUri, int generation) async {
    if (!_isActiveGeneration(generation)) {
      return;
    }

    final cachedPlayer = _cachedPlayer;
    if (cachedPlayer != null) {
      unawaited(cachedPlayer.dispose());
      if (identical(_cachedPlayer, cachedPlayer)) {
        _cachedPlayer = null;
      }
    }

    await CachedVideoPlayerPlus.removeFileFromCache(videoUri);
  }

  bool _isActiveGeneration(int generation) {
    return generation == _initializationGeneration;
  }

  void _disposeController() {
    _initializationGeneration++;

    final cachedPlayer = _cachedPlayer;
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleVideoChanged);
      _controller = null;
    }

    if (cachedPlayer != null) {
      unawaited(cachedPlayer.dispose());
      _cachedPlayer = null;
    }

    _initializeFuture = null;
    _initializationError = null;
  }

  void _handleVideoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasThumbnail {
    return CustomFunctions.resolveImageUrl(widget.thumbnailLink) != null;
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

    final position = controller.value.position;
    final duration = controller.value.duration;
    if (duration > Duration.zero && position >= duration) {
      await controller.seekTo(Duration.zero);
    }

    await controller.play();
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
    if (!controller.value.isInitialized || !mounted) {
      return;
    }
    final initialPosition = controller.value.position;

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        final controller = _controller;
        final thumbnailUrl = CustomFunctions.resolveImageUrl(
          widget.thumbnailLink,
        );
        final initializationError = _initializationError ?? snapshot.error;
        final isReady =
            snapshot.connectionState == ConnectionState.done &&
            controller != null &&
            controller.value.isInitialized &&
            initializationError == null;
        final showThumbnailPreview =
            _showThumbnailPreview &&
            thumbnailUrl != null &&
            !(controller?.value.isPlaying ?? false) &&
            initializationError == null;

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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const ColoredBox(
                                              key: ValueKey(
                                                'video-loading-background',
                                              ),
                                              color: Colors.black,
                                            );
                                          },
                                    )
                                  : isReady
                                  ? FittedBox(
                                      key: ValueKey(controller),
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: controller.value.size.width,
                                        height: controller.value.size.height,
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
                              initializationError: initializationError,
                              isReady: isReady,
                              showThumbnailPreview: showThumbnailPreview,
                            ),
                          ],
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: isReady
                            ? controller.value.aspectRatio
                            : 1.7,
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
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const ColoredBox(
                                              key: ValueKey(
                                                'video-loading-background',
                                              ),
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
                              initializationError: initializationError,
                              isReady: isReady,
                              showThumbnailPreview: showThumbnailPreview,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverlay({
    required VideoPlayerController? controller,
    required Object? initializationError,
    required bool isReady,
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
                isLoading:
                    !showThumbnailPreview &&
                    initializationError == null &&
                    !isReady,
                isPlaying: controller?.value.isPlaying ?? false,
                onTap: initializationError != null
                    ? null
                    : () async {
                        if (_showThumbnailPreview) {
                          setState(() {
                            _showThumbnailPreview = false;
                          });
                        }
                        await _togglePlayback();
                      },
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
            child: _buildSeekBar(controller),
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
            child: _buildDurationRow(controller),
          ),
      ],
    );
  }

  Widget _buildSeekBar(VideoPlayerController? controller) {
    final duration = controller?.value.duration ?? Duration.zero;
    final position = controller?.value.position ?? Duration.zero;
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
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4.0),
      ),
      child: Slider(
        value: currentMillis,
        min: 0,
        max: maxMillis,
        onChanged: controller == null || !controller.value.isInitialized
            ? null
            : (value) {
                controller.seekTo(Duration(milliseconds: value.round()));
              },
      ),
    );
  }

  Widget _buildDurationRow(VideoPlayerController? controller) {
    final position = controller?.value.position ?? Duration.zero;
    final duration = controller?.value.duration ?? Duration.zero;

    return Row(
      children: [
        AppTextView.body4(
          CustomFunctions.formatDuration(position.inSeconds),
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        AppTextView.body4(
          "/",
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
