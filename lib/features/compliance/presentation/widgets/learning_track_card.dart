import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/learning_module_detail_track.dart';

class LearningTrackCard extends StatelessWidget {
  const LearningTrackCard({super.key, required this.track, this.onTap});

  final LearningTrackModuleDetail track;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progressPercent = '${track.completionPercentage ?? 0}%';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrackImage(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow(),
                  const SizedBox(height: 6),
                  AppTextView.body(
                    track.displayName,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  _buildProgressRow(progressPercent),
                  const SizedBox(height: 8),
                  _buildStatusRow(),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackImage() {
    final thumbnailLink = CustomFunctions.resolveImageUrl(track.thumbnailLink);
    return SizedBox(
      width: 106,
      height: 106,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: thumbnailLink != null && thumbnailLink.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: thumbnailLink,
                fit: BoxFit.cover,
                placeholder: (_, __) {
                  return Image.asset(
                    'lib/assets/images/no_image.png',
                    fit: BoxFit.cover,
                  );
                },
                errorWidget: (_, __, ___) {
                  return Image.asset(
                    'lib/assets/images/no_image.png',
                    fit: BoxFit.cover,
                  );
                },
              )
            : Image.asset('lib/assets/images/no_image.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMetaRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        AppTextView.body3(
          track.displayJob,
          color: AppColors.grey1,
          fontSize: 11,
        ),
        AppTextView.body3(
          track.displaySchedule,
          color: AppColors.textPrimary,
          fontSize: 11,
        ),
      ],
    );
  }

  Widget _buildProgressRow(String progressPercent) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: track.progressValue,
              minHeight: 6,
              backgroundColor: AppColors.textPrimary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.progressColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AppTextView.body3(
          progressPercent,
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    final isCompliant = CustomFunctions.isPassedStatus(track.displayStatus);
    final deadlineText = _truncateDeadlineText(
      CustomFunctions.formatDeadlineInDays(track.deadline),
    );
    final isOverdue = CustomFunctions.isDeadlineOverdue(track.deadline);
    final statusStyle = _resolveStatusStyle(track.displayStatus);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
          decoration: BoxDecoration(
            color: statusStyle.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusStyle.borderColor, width: 1),
          ),
          child: AppTextView.body3(
            track.displayStatus,
            color: statusStyle.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        if (isCompliant)
          const Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: AppTextView.body3(
                'Finished',
                color: AppColors.green1,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.right,
              ),
            ),
          )
        else
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: isOverdue ? 'Overdue: ' : 'Finish By: ',
                    style: TextStyle(
                      color: isOverdue
                          ? AppColors.red
                          : AppColors.textSecondary.withValues(alpha: 0.78),
                      fontSize: 10,
                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  TextSpan(
                    text: deadlineText,
                    style: TextStyle(
                      color: isOverdue
                          ? AppColors.red
                          : AppColors.secondaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  _TrackStatusStyle _resolveStatusStyle(String status) {
    final normalized = CustomFunctions.normalizedStatus(status);

    if (normalized == 'due' || normalized == 'due by') {
      return const _TrackStatusStyle(
        backgroundColor: AppColors.hexffe8d9,
        borderColor: AppColors.orange1,
        textColor: AppColors.orange1,
      );
    }

    if (normalized == 'non compliant') {
      return const _TrackStatusStyle(
        backgroundColor: AppColors.hexffe1e1,
        borderColor: AppColors.red,
        textColor: AppColors.red,
      );
    }

    if (CustomFunctions.isCancelledStatus(normalized)) {
      return const _TrackStatusStyle(
        backgroundColor: AppColors.hexffe1e1,
        borderColor: AppColors.red,
        textColor: AppColors.red,
      );
    }

    if (CustomFunctions.isPassedStatus(normalized)) {
      return const _TrackStatusStyle(
        backgroundColor: AppColors.hexe3f8f4,
        borderColor: AppColors.green1,
        textColor: AppColors.green1,
      );
    }

    return const _TrackStatusStyle(
      backgroundColor: AppColors.textPrimary,
      borderColor: AppColors.secondaryColor,
      textColor: AppColors.secondaryColor,
    );
  }

  String _truncateDeadlineText(String value) {
    const maxLength = 17;
    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength - 3)}...';
  }
}

class _TrackStatusStyle {
  const _TrackStatusStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}
