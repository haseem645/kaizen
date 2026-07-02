import 'package:flutter/material.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/custom_functions.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../domain/entities/compliance_track_item_detail.dart';
import '../../widgets/compliance_video_player.dart';

class ComplianceVideoScreen extends StatelessWidget {
  const ComplianceVideoScreen({super.key, required this.detail});

  final ComplianceTrackItemDetail detail;
  @override
  Widget build(BuildContext context) {
    final transcript = CustomFunctions.stripHtmlTags(detail.videoTranscript);
    final videoUrl = detail.videoUrl?.trim();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (videoUrl != null && videoUrl.isNotEmpty)
          ComplianceVideoPlayer(
            videoUrl: videoUrl,
            title: detail.title,
            thumbnailLink: detail.videoThumbnailLink,
          )
        else
          FastCircularProgressIndicator(),
        // Container(
        //   height: 220,
        //   decoration: BoxDecoration(
        //     color: AppColors.surfaceDark,
        //     borderRadius: BorderRadius.circular(8),
        //   ),
        //   alignment: Alignment.center,
        //   child: const AppTextView.body(
        //     'Video is not available.',
        //     color: AppColors.textSecondary,
        //   ),
        // ),
        const SizedBox(height: 18),
        _TranscriptItem(time: '[00:00]', text: transcript, isHighlighted: false),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _TranscriptItem extends StatelessWidget {
  const _TranscriptItem({required this.time, required this.text, required this.isHighlighted});

  final String time;
  final String text;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 62, child: AppTextView.body(time, color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3),
            child: AppTextView.body3(
              text,
              color: isHighlighted ? AppColors.secondaryColor : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
