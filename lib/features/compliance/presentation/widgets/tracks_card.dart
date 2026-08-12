import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/learning_module_detail_track.dart';

class TracksCard extends StatelessWidget {
  const TracksCard({
    super.key,
    required this.track,
    this.isDisabled = false,
    this.headerText,
    this.onTap,
  });

  final LearningTrackModuleDetail track;
  final bool isDisabled;
  final String? headerText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDisabled
        ? AppColors.textSecondary.withValues(alpha: 0.65)
        : AppColors.textPrimary;
    final trailingTextColor = isDisabled
        ? AppColors.textSecondary
        : AppColors.textPrimary;
    final statusStyle = _resolveStatusStyle();

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.surfaceDark.withValues(alpha: 0.55)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // if (headerText != null) ...[
            //   AppTextView.body3(
            //     headerText!,
            //     color: AppColors.secondaryColor,
            //     fontSize: 12,
            //     fontWeight: FontWeight.w700,
            //   ),
            //   const SizedBox(height: 10),
            // ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrackImage(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      AppTextView.body(
                        track.displayName,
                        color: foregroundColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(statusStyle, trailingTextColor),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackImage() {
    final thumbnailLink = CustomFunctions.resolveImageUrl(track.thumbnailLink);

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: thumbnailLink != null && thumbnailLink.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: thumbnailLink,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
              placeholder: (_, __) {
                return Image.asset(
                  'lib/assets/images/no_image.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                );
              },
              errorWidget: (_, __, ___) {
                return Image.asset(
                  'lib/assets/images/no_image.png',
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                );
              },
            )
          : Image.asset(
              'lib/assets/images/no_image.png',
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildStatusRow(
    _TrackStatusStyle statusStyle,
    Color trailingTextColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 6, bottom: 2, right: 6),
          decoration: BoxDecoration(
            color: statusStyle.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusStyle.borderColor, width: 1),
          ),
          child: AppTextView.body3(
            track.displayStatus,
            color: statusStyle.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  _TrackStatusStyle _resolveStatusStyle() {
    if (isDisabled) {
      return _TrackStatusStyle(
        backgroundColor: AppColors.fieldBorder.withValues(alpha: 0.18),
        borderColor: AppColors.fieldBorder,
        textColor: AppColors.textSecondary,
      );
    }

    if (CustomFunctions.isFailedStatus(track.displayStatus)) {
      return const _TrackStatusStyle(
        backgroundColor: AppColors.hexffe1e1,
        borderColor: AppColors.red,
        textColor: AppColors.red,
      );
    }

    if (CustomFunctions.isPassedStatus(track.displayStatus)) {
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
