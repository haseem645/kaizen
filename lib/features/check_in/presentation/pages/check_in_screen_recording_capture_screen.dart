import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';

class CheckInScreenRecordingCaptureScreen extends StatefulWidget {
  const CheckInScreenRecordingCaptureScreen({super.key});

  @override
  State<CheckInScreenRecordingCaptureScreen> createState() =>
      _CheckInScreenRecordingCaptureScreenState();
}

class _CheckInScreenRecordingCaptureScreenState
    extends State<CheckInScreenRecordingCaptureScreen> {
  File? _recordedMedia;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  var _isProcessing = false;
  var _isRecording = false;

  @override
  void dispose() {
    if (_isRecording) {
      unawaited(FlutterScreenRecording.stopRecordScreen);
    }
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasRecordedMedia = _recordedMedia != null;
    final canSave = hasRecordedMedia && !_isProcessing && !_isRecording;

    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                  child: Row(
                    children: [
                      AppBackButton(
                        onPressed: _isProcessing ? null : _handleBack,
                      ),
                      const Expanded(
                        child: AppTextView.body1(
                          AppStrings.auditScreenRecording,
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        color: AppColors.surfaceDark,
                        child: hasRecordedMedia
                            ? _RecordedMediaPreview(videoFile: _recordedMedia!)
                            : _RecordingPrompt(
                                isBusy: _isProcessing,
                                isRecording: _isRecording,
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
                  child: _buildBottomActions(
                    canSave: canSave,
                    hasRecordedMedia: hasRecordedMedia,
                  ),
                ),
              ],
            ),
          ),
          // if (_isRecording)
          //   IgnorePointer(
          //     child: Container(
          //       decoration: BoxDecoration(border: Border.all(color: AppColors.red1, width: 2)),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Widget _buildBottomActions({
    required bool canSave,
    required bool hasRecordedMedia,
  }) {
    if (_isProcessing) {
      return SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: FastCircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_isRecording) {
      return _RecordingActionButton(
        label:
            '${AppStrings.auditStopRecording} ${_formatRecordingDuration(_recordingDuration)}',
        backgroundColor: AppColors.red1,
        icon: Icons.stop_circle_outlined,
        onTap: _stopScreenRecording,
      );
    }

    if (!hasRecordedMedia) {
      return _RecordingActionButton(
        label: AppStrings.auditStartRecording,
        backgroundColor: AppColors.secondaryColor,
        icon: Icons.fit_screen,
        onTap: _startScreenRecording,
      );
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: AppStrings.auditDelete,
            onPressed: _handleDelete,
            backgroundColor: AppColors.red1,
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            text: AppStrings.auditSave,
            onPressed: canSave ? _handleSave : null,
            backgroundColor: AppColors.secondaryColor,
            textColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _startScreenRecording() async {
    setState(() => _isProcessing = true);
    try {
      final started = await FlutterScreenRecording.startRecordScreen(
        'audit_sr_${DateTime.now().millisecondsSinceEpoch}',
        titleNotification: AppStrings.auditRecordingNotificationTitle,
        messageNotification: AppStrings.auditRecordingNotificationMessage,
      );
      if (!mounted) {
        return;
      }

      if (!started) {
        _showSnackBar(AppStrings.auditStartRecordingError);
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _isProcessing = false;
        _isRecording = true;
        _recordedMedia = null;
        _recordingDuration = Duration.zero;
      });
      _startRecordingTimer();
    } catch (error) {
      debugPrint('Unable to start screen recording: $error');
      if (!mounted) {
        return;
      }

      setState(() => _isProcessing = false);
      _showSnackBar(AppStrings.auditStartRecordingError);
    }
  }

  Future<void> _stopScreenRecording() async {
    setState(() => _isProcessing = true);
    _recordingTimer?.cancel();

    try {
      final recordingPath = await FlutterScreenRecording.stopRecordScreen;
      if (!mounted) {
        return;
      }

      final resolvedPath = recordingPath.trim();
      if (resolvedPath.isEmpty) {
        setState(() {
          _isProcessing = false;
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
        _showSnackBar(AppStrings.auditNoRecordingReturned);
        return;
      }

      final recordingFile = File(resolvedPath);
      final exists = await recordingFile.exists();
      if (!mounted) {
        return;
      }

      if (!exists) {
        setState(() {
          _isProcessing = false;
          _isRecording = false;
          _recordingDuration = Duration.zero;
        });
        _showSnackBar(AppStrings.auditRecordedVideoMissing);
        return;
      }

      setState(() {
        _isProcessing = false;
        _isRecording = false;
        _recordedMedia = recordingFile;
      });
    } catch (error) {
      debugPrint('Unable to stop screen recording: $error');
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
      _showSnackBar(AppStrings.auditStopRecordingError);
    }
  }

  Future<void> _handleBack() async {
    if (_isRecording) {
      _recordingTimer?.cancel();
      try {
        await FlutterScreenRecording.stopRecordScreen;
      } catch (_) {}
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleDelete() {
    setState(() {
      _recordedMedia = null;
      _recordingDuration = Duration.zero;
    });
  }

  void _handleSave() {
    final recordedMedia = _recordedMedia;
    if (recordedMedia == null) {
      return;
    }

    Navigator.of(context).pop(recordedMedia);
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRecording) {
        return;
      }

      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  String _formatRecordingDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecordingPrompt extends StatelessWidget {
  const _RecordingPrompt({required this.isBusy, required this.isRecording});

  final bool isBusy;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isBusy)
              SizedBox(
                width: 30,
                height: 30,
                child: FastCircularProgressIndicator(),
              )
            else ...[
              AppTextView.body1(
                isRecording
                    ? AppStrings.auditRecordingInProgress
                    : AppStrings.auditStartScreenRecordingTitle,
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              AppTextView.body2(
                isRecording
                    ? AppStrings.auditStopPrompt
                    : AppStrings.auditRecordingPrompt,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecordingActionButton extends StatelessWidget {
  const _RecordingActionButton({
    required this.label,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        icon: Icon(icon, size: 18),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AppTextView.body(
            label,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _RecordedMediaPreview extends StatefulWidget {
  const _RecordedMediaPreview({required this.videoFile});

  final File videoFile;

  @override
  State<_RecordedMediaPreview> createState() => _RecordedMediaPreviewState();
}

class _RecordedMediaPreviewState extends State<_RecordedMediaPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant _RecordedMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoFile.path != widget.videoFile.path) {
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
    final controller = VideoPlayerController.file(widget.videoFile);
    _controller = controller;
    _initializeFuture = controller
        .initialize()
        .then((_) async {
          await controller.setLooping(false);
          await controller.setVolume(1);
          if (mounted) {
            setState(() {});
          }
        })
        .catchError((error) {
          debugPrint('Unable to load recorded preview: $error');
          if (mounted) {
            setState(() {});
          }
        });
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    _initializeFuture = null;
    controller?.dispose();
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
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration > Duration.zero && position >= duration) {
      await controller.seekTo(Duration.zero);
    }

    await controller.play();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initializeFuture = _initializeFuture;
    if (controller == null || initializeFuture == null) {
      return const _RecordedMediaFallback();
    }

    return FutureBuilder<void>(
      future: initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError || !controller.value.isInitialized) {
          return const _RecordedMediaFallback();
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _togglePlayback,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.24),
                  child: Center(
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecordedMediaFallback extends StatelessWidget {
  const _RecordedMediaFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white70,
          size: 60,
        ),
      ),
    );
  }
}
