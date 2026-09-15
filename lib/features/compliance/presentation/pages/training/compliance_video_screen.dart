import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../domain/entities/compliance_track_item_detail.dart';
import '../../../domain/entities/compliance_video_transcript.dart';
import '../../providers/compliance_video_controller.dart';
import '../../widgets/compliance_video_player.dart';

class ComplianceVideoScreen extends StatelessWidget {
  const ComplianceVideoScreen({super.key, required this.detail});

  final ComplianceTrackItemDetail detail;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey((detail.uuid, detail.videoUrl, detail.videoTranscript)),
      create: (_) => ComplianceVideoController(detail.videoTranscript),
      child: _ComplianceVideoView(detail: detail),
    );
  }
}

class _ComplianceVideoView extends StatelessWidget {
  const _ComplianceVideoView({required this.detail});

  final ComplianceTrackItemDetail detail;

  @override
  Widget build(BuildContext context) {
    final videoUrl = detail.videoUrl?.trim();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (videoUrl != null && videoUrl.isNotEmpty)
          ComplianceVideoPlayer(
            videoUrl: videoUrl,
            title: detail.title,
            thumbnailLink: detail.videoThumbnailLink,
            onPositionChanged: context.read<ComplianceVideoController>().updatePlaybackPosition,
          )
        else
          FastCircularProgressIndicator(),
        const SizedBox(height: 18),
        const _TranscriptSection(),
      ],
    );
  }
}

class _TranscriptSection extends StatelessWidget {
  const _TranscriptSection();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ComplianceVideoController>();
    final lines = controller.transcriptLines;
    if (lines.isEmpty) {
      return const AppTextView.body3(
        AppStrings.trainingNoTranscriptAvailable,
        color: AppColors.textSecondary,
        height: 1.6,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < lines.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TranscriptItem(
              line: lines[index],
              isHighlighted: controller.activeTranscriptIndex == index,
            ),
          ),
      ],
    );
  }
}

class _TranscriptItem extends StatelessWidget {
  const _TranscriptItem({required this.line, required this.isHighlighted});

  final ComplianceTranscriptLine line;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final start = line.start;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (start != null) ...[
          SizedBox(
            width: 62,
            child: AppTextView.body3(
              CustomFunctions.formatDuration(start.inSeconds),
              color: isHighlighted ? AppColors.secondaryColor : AppColors.textSecondary,
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              height: 1.6,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: AppTextView.body3(
            line.text,
            color: isHighlighted ? AppColors.secondaryColor : AppColors.textPrimary,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
