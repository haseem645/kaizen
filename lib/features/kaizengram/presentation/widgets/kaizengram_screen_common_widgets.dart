import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';

class KaizengramNotificationActionIcon extends StatelessWidget {
  const KaizengramNotificationActionIcon({
    super.key,
    required this.unreadNotificationCount,
  });

  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        const Icon(Icons.favorite_border_rounded),
        if (unreadNotificationCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppTextView.body4(
                  unreadNotificationCount > 9
                      ? '9+'
                      : '$unreadNotificationCount',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class KaizengramComposePostActionRow extends StatelessWidget {
  const KaizengramComposePostActionRow({
    super.key,
    required this.isPickingImage,
    required this.isPickingAttachment,
    required this.onPickImage,
    required this.onPickAttachment,
  });

  final bool isPickingImage;
  final bool isPickingAttachment;
  final VoidCallback onPickImage;
  final VoidCallback onPickAttachment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: KaizengramComposePostActionButton(
            icon: Icons.photo_library_outlined,
            label: AppStrings.kaizengramComposeActionImage,
            isBusy: isPickingImage,
            onTap: isPickingImage || isPickingAttachment ? null : onPickImage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KaizengramComposePostActionButton(
            icon: Icons.attach_file_rounded,
            label: AppStrings.kaizengramComposeActionAttachment,
            isBusy: isPickingAttachment,
            onTap: isPickingImage || isPickingAttachment
                ? null
                : onPickAttachment,
          ),
        ),
      ],
    );
  }
}

class KaizengramComposePostActionButton extends StatelessWidget {
  const KaizengramComposePostActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isBusy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isBusy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              else
                Icon(icon, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: AppTextView.body3(
                  label,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
