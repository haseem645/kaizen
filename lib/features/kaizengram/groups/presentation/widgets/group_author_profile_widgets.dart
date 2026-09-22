import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_text_view.dart';

class GroupAuthorProfileHeroCard extends StatelessWidget {
  const GroupAuthorProfileHeroCard({
    super.key,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.authorRole,
    required this.timeLabel,
  });

  final String authorName;
  final String authorAvatarUrl;
  final String authorRole;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.hex1b1e27,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.85),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 38,
                backgroundImage: NetworkImage(authorAvatarUrl),
              ),
            ),
            const SizedBox(height: 18),
            AppTextView.body1(
              authorName,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.secondaryColor.withValues(alpha: 0.30),
                ),
              ),
              child: AppTextView.body4(
                authorRole,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            AppTextView.body4(
              AppStrings.profileLatestActivityLabel(timeLabel),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class GroupAuthorProfileDetailRow extends StatelessWidget {
  const GroupAuthorProfileDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppTextView.body4(
                label,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 4),
              AppTextView.body2(
                value.trim().isEmpty
                    ? AppStrings.profileValueUnavailable
                    : value,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GroupAuthorProfileInfoCard extends StatelessWidget {
  const GroupAuthorProfileInfoCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.hex1b1e27,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppTextView.body3(
            title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
