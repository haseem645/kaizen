import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_back_button.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../../../core/widgets/fast_circular_progress.dart';

class ComplianceFullScreenVideoView extends StatefulWidget {
  const ComplianceFullScreenVideoView({
    super.key,
    required this.controller,
    required this.title,
    this.initialPosition = Duration.zero,
  });

  final VideoPlayerController controller;
  final String title;
  final Duration initialPosition;

  @override
  State<ComplianceFullScreenVideoView> createState() =>
      _ComplianceFullScreenVideoViewState();
}

class _ComplianceFullScreenVideoViewState
    extends State<ComplianceFullScreenVideoView> {
  bool _isScrubbing = false;
  double? _scrubPositionMillis;

  @override
  void initState() {
    super.initState();
    _syncInitialPosition();
  }

  @override
  void didUpdateWidget(covariant ComplianceFullScreenVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _isScrubbing = false;
      _scrubPositionMillis = null;
      _syncInitialPosition();
    }
  }

  Future<void> _syncInitialPosition() async {
    final controller = widget.controller;
    if (!controller.value.isInitialized) {
      return;
    }

    final duration = controller.value.duration;
    final initialPosition = widget.initialPosition;
    if (duration <= Duration.zero || initialPosition <= Duration.zero) {
      return;
    }

    await controller.seekTo(
      initialPosition >= duration ? duration : initialPosition,
    );
  }

  Future<void> _togglePlayback() async {
    final controller = widget.controller;
    if (!controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }

    final duration = controller.value.duration;
    if (duration > Duration.zero && controller.value.position >= duration) {
      await controller.seekTo(Duration.zero);
    }

    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: widget.controller,
          child: VideoPlayer(widget.controller),
          builder: (context, controllerValue, child) {
            final controller = widget.controller;
            final isReady = controllerValue.isInitialized;

            return Stack(
              children: [
                Center(
                  child: isReady
                      ? AspectRatio(
                          aspectRatio: controllerValue.aspectRatio,
                          child: child ?? VideoPlayer(controller),
                        )
                      : FastCircularProgressIndicator(width: 32, height: 32),
                ),
                if (isReady && controllerValue.isBuffering)
                  Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: FastCircularProgressIndicator(),
                    ),
                  ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: AppBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextView.body1(
                        widget.title,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 8),
                      _FullScreenVideoControls(
                        controllerValue: controllerValue,
                        isReady: isReady,
                        isScrubbing: _isScrubbing,
                        scrubPositionMillis: _scrubPositionMillis,
                        onTogglePlayback: _togglePlayback,
                        onScrubStart: (value) {
                          setState(() {
                            _isScrubbing = true;
                            _scrubPositionMillis = value;
                          });
                        },
                        onScrubChanged: (value) {
                          setState(() {
                            _scrubPositionMillis = value;
                          });
                        },
                        onScrubEnd: (value) async {
                          setState(() {
                            _isScrubbing = false;
                            _scrubPositionMillis = null;
                          });
                          await controller.seekTo(
                            Duration(milliseconds: value.round()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FullScreenVideoControls extends StatelessWidget {
  const _FullScreenVideoControls({
    required this.controllerValue,
    required this.isReady,
    required this.isScrubbing,
    required this.scrubPositionMillis,
    required this.onTogglePlayback,
    required this.onScrubStart,
    required this.onScrubChanged,
    required this.onScrubEnd,
  });

  final VideoPlayerValue controllerValue;
  final bool isReady;
  final bool isScrubbing;
  final double? scrubPositionMillis;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onScrubStart;
  final ValueChanged<double> onScrubChanged;
  final ValueChanged<double> onScrubEnd;

  @override
  Widget build(BuildContext context) {
    final duration = controllerValue.duration;
    final position = isScrubbing && scrubPositionMillis != null
        ? Duration(milliseconds: scrubPositionMillis!.round())
        : controllerValue.position;
    final maxMillis = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final currentMillis = position.inMilliseconds
        .clamp(0, duration.inMilliseconds)
        .toDouble();

    return Row(
      children: [
        IconButton(
          onPressed: isReady ? onTogglePlayback : null,
          icon: Icon(
            controllerValue.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: AppColors.textPrimary,
            size: 34,
          ),
        ),
        Expanded(
          child: SliderTheme(
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
              onChangeStart: !isReady ? null : onScrubStart,
              onChanged: !isReady ? null : onScrubChanged,
              onChangeEnd: !isReady ? null : onScrubEnd,
            ),
          ),
        ),
        AppTextView.body4(
          '${CustomFunctions.formatDuration(position.inSeconds)}/${CustomFunctions.formatDuration(duration.inSeconds)}',
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}
