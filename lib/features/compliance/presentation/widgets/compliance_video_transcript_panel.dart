import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../providers/compliance_video_controller.dart';
import 'compliance_video_player.dart';
import 'compliance_video_transcript_sheet.dart';

/// Shared by LTC and the lesson editor/viewer so captions and seeking stay aligned.
class ComplianceVideoTranscriptPanel extends StatelessWidget {
  const ComplianceVideoTranscriptPanel({
    super.key,
    required this.videoId,
    required this.videoUrl,
    required this.title,
    required this.transcript,
    this.localVideoPath,
    this.thumbnailLink,
    this.topRightActions = const <Widget>[],
  });

  final Object videoId;
  final String? videoUrl;
  final String title;
  final String? transcript;
  final String? localVideoPath;
  final String? thumbnailLink;
  final List<Widget> topRightActions;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider0<ComplianceVideoController>(
      key: ValueKey((videoId, videoUrl)),
      create: (_) => ComplianceVideoController(transcript),
      update: (_, controller) {
        final captions = controller!;
        // An open transcript sheet listens from a separate route. Notify after build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          captions.updateTranscript(transcript);
        });
        return captions;
      },
      child: _VideoPlayerArea(panel: this),
    );
  }
}

class _VideoTranscriptLayout extends StatelessWidget {
  const _VideoTranscriptLayout({
    required this.panel,
    required this.video,
    required this.videoHeight,
    this.controls,
  });

  final ComplianceVideoTranscriptPanel panel;
  final Widget video;
  final double videoHeight;
  final Widget? controls;

  @override
  Widget build(BuildContext context) {
    final (hasCaption, controlsVisible, videoBounds) = context
        .select<ComplianceVideoController, (bool, bool, Rect?)>(
          (controller) => (
            controller.hasVisibleActiveTranscript,
            controller.arePlaybackControlsVisible,
            controller.videoBounds,
          ),
        );
    final showControls = controlsVisible && controls != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxWidth / (16 / 9)).clamp(
          0.0,
          videoHeight,
        );
        final mediaBounds =
            videoBounds ??
            Rect.fromLTWH(
              0,
              controls == null ? 0 : (videoHeight - previewHeight) / 2,
              constraints.maxWidth,
              controls == null ? videoHeight : previewHeight,
            );
        final footerTop = mediaBounds.bottom;
        final minimumHeight =
            videoHeight + MediaQuery.textScalerOf(context).scale(120) + 80;
        // Training owns its page scroll; LTC also supplies a bounded viewport.
        final availableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height * 0.7;
        return SingleChildScrollView(
          primary: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: availableHeight.clamp(minimumHeight, double.infinity),
            ),
            child: Material(
              color: Colors.black,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: videoHeight,
                    child: SizedBox(
                      key: const ValueKey('training-video-frame'),
                      child: video,
                    ),
                  ),
                  // The footer owns the surface height; captions overlay the image.
                  Padding(
                    padding: EdgeInsets.only(top: footerTop),
                    child: ColoredBox(
                      color: Colors.black,
                      child: Padding(
                        padding: ComplianceVideoPlayer.contentPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: showControls ? 10 : 6),
                            if (showControls) ...[
                              controls!,
                              const SizedBox(height: 6),
                            ],
                            _TranscriptActions(
                              onViewTranscript: () =>
                                  showComplianceVideoTranscriptSheet(context),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasCaption)
                    Positioned(
                      top: mediaBounds.top,
                      left: mediaBounds.left + 8,
                      right: constraints.maxWidth - mediaBounds.right + 8,
                      height: mediaBounds.height,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _ActiveTranscriptLine(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VideoPlayerArea extends StatelessWidget {
  const _VideoPlayerArea({required this.panel});

  final ComplianceVideoTranscriptPanel panel;

  @override
  Widget build(BuildContext context) {
    final animateTranscript = !MediaQuery.disableAnimationsOf(context);
    final height =
        (MediaQuery.sizeOf(context).height * 0.5).clamp(320.0, 520.0) - 39;
    final videoUrl = panel.videoUrl?.trim();
    if (videoUrl == null || videoUrl.isEmpty) {
      return _VideoTranscriptLayout(
        panel: panel,
        videoHeight: height,
        video: const FastCircularProgressIndicator(),
      );
    }
    return ComplianceVideoPlayer(
      videoUrl: videoUrl,
      localVideoPath: panel.localVideoPath,
      title: panel.title,
      thumbnailLink: panel.thumbnailLink,
      height: height,
      fillBounds: true,
      topRightActions: panel.topRightActions,
      onPositionChanged: (position) => context
          .read<ComplianceVideoController>()
          .updatePlaybackPosition(position, animate: animateTranscript),
      onSeekHandlerChanged: context
          .read<ComplianceVideoController>()
          .setSeekHandler,
      onPlaybackControlsVisibilityChanged: context
          .read<ComplianceVideoController>()
          .updatePlaybackControlsVisibility,
      onVideoBoundsChanged: context
          .read<ComplianceVideoController>()
          .updateVideoBounds,
      onRevealControlsHandlerChanged: context
          .read<ComplianceVideoController>()
          .setRevealControlsHandler,
      layoutBuilder: (video, controls) => _VideoTranscriptLayout(
        panel: panel,
        videoHeight: height,
        video: video,
        controls: controls,
      ),
    );
  }
}

class _TranscriptActions extends StatelessWidget {
  const _TranscriptActions({required this.onViewTranscript});

  final VoidCallback onViewTranscript;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _CcToggleButton(),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            heightFactor: 1,
            child: ComplianceVideoTranscriptButton(
              onPressed: onViewTranscript,
              padding: const EdgeInsets.fromLTRB(12, 4, 0, 6),
            ),
          ),
        ),
      ],
    );
  }
}

class _CcToggleButton extends StatelessWidget {
  const _CcToggleButton();

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select<ComplianceVideoController, bool>(
      (controller) => controller.isCcEnabled,
    );
    return Tooltip(
      message: isEnabled
          ? AppStrings.trainingShowActiveTranscript
          : AppStrings.trainingHideActiveTranscript,
      child: Semantics(
        toggled: isEnabled,
        child: TextButton(
          onPressed: context.read<ComplianceVideoController>().toggleCc,
          style: TextButton.styleFrom(
            minimumSize: const Size(30, 22),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            foregroundColor: isEnabled
                ? AppColors.textPrimary
                : AppColors.secondaryColor,
            backgroundColor: isEnabled
                ? AppColors.secondaryColor
                : Colors.transparent,
            side: const BorderSide(color: AppColors.secondaryColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text(AppStrings.trainingCc),
        ),
      ),
    );
  }
}

class _ActiveTranscriptLine extends StatelessWidget {
  const _ActiveTranscriptLine();

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final (text, isCcEnabled, controlsVisible) = context
        .select<ComplianceVideoController, (String?, bool, bool)>(
          (controller) => (
            disableAnimations
                ? controller.activeTranscriptLine?.text
                : controller.activeTranscriptText,
            controller.isCcEnabled,
            controller.arePlaybackControlsVisible,
          ),
        );
    if (isCcEnabled || text == null) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controlsVisible
          ? null
          : context.read<ComplianceVideoController>().revealPlaybackControls,
      child: Container(
        key: const ValueKey('active-video-caption'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: AppTextView.body3(
          text,
          color: AppColors.textPrimary,
          height: 1.4,
          textAlign: TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
