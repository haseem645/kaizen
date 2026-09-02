import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/feedback_post.dart';

class FeedbackPostCard extends StatelessWidget {
  const FeedbackPostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLikeTap,
    this.isUpdatingLike = false,
  });

  final FeedbackPost post;
  final VoidCallback? onTap;
  final Future<void> Function()? onLikeTap;
  final bool isUpdatingLike;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.hex14182a,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.fieldBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextView.title1(
                    post.title,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _FeedbackStatusChip(status: post.status),
                const SizedBox(width: 12),
                _LikeCount(
                  post: post,
                  isUpdatingLike: isUpdatingLike,
                  onTap: onLikeTap,
                ),
              ],
            ),
            if (post.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              AppTextView.body(
                post.description,
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _PostMetadata(
                  icon: Icons.photo_library_outlined,
                  label: _pluralize(
                    post.attachments.length,
                    AppStrings.questionsFeedbackAttachmentSingular,
                    AppStrings.questionsFeedbackAttachmentPlural,
                  ),
                  count: post.attachments.length,
                ),
                _PostMetadata(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: _pluralize(
                    post.commentCount,
                    AppStrings.questionsFeedbackCommentSingular,
                    AppStrings.questionsFeedbackCommentPlural,
                  ),
                  count: post.commentCount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _pluralize(int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }
}

class _FeedbackStatusChip extends StatelessWidget {
  const _FeedbackStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty
        ? AppStrings.questionsFeedbackRequestedStatus
        : '${status[0].toUpperCase()}${status.substring(1)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orange2.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.orange2.withValues(alpha: 0.55)),
      ),
      child: AppTextView.body1(
        label,
        color: AppColors.orange2,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LikeCount extends StatelessWidget {
  const _LikeCount({
    required this.post,
    required this.isUpdatingLike,
    this.onTap,
  });

  final FeedbackPost post;
  final bool isUpdatingLike;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Row(
        children: [
          Material(
            color: AppColors.hex252a40,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isUpdatingLike || onTap == null ? null : onTap,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: isUpdatingLike
                        ? const SizedBox(
                            key: ValueKey<String>('like-loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : Icon(
                            post.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey<bool>(post.isLiked),
                            color: post.isLiked
                                ? AppColors.red1
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AppTextView.body1(
            '${post.likeCount}',
            color: AppColors.textSecondary,
            fontSize: 12,
            textAlign: TextAlign.right,
            overflow: TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}

class _PostMetadata extends StatelessWidget {
  const _PostMetadata({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 6),
        AppTextView.body(
          '$count $label',
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ],
    );
  }
}
