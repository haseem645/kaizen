import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/widgets/app_text_view.dart';
import '../../../../../core/widgets/fast_circular_progress.dart';
import '../../providers/kaizengram_controller.dart';

class KaizengramNotificationsScreen extends StatelessWidget {
  const KaizengramNotificationsScreen({super.key});
  //
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KaizengramController>();
    final sections = controller.notificationSections;

    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      appBar: _buildAppBar(),
      body: SafeArea(top: false, child: _buildBody(controller, sections)),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF111317),
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 18,
      title: AppTextView.title1(
        AppStrings.kaizengramNotificationsTitle,
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBody(
    KaizengramController controller,
    List<KaizengramNotificationSection> sections,
  ) {
    if (controller.isLoading) {
      return Center(child: FastCircularProgressIndicator());
    }

    if (sections.isEmpty) {
      return _NotificationsStateView(
        message: controller.errorMessage != null
            ? AppStrings.kaizengramNotificationsUnableToLoad
            : AppStrings.kaizengramNotificationsEmpty,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 28),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _NotificationSectionView(section: sections[index]),
    );
  }
}

class _NotificationsStateView extends StatelessWidget {
  const _NotificationsStateView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AppTextView.body1(
          message,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NotificationSectionView extends StatelessWidget {
  const _NotificationSectionView({required this.section});

  final KaizengramNotificationSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: AppTextView.body1(
            _sectionTitle(section.bucket),
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        ...section.items.map((item) => _NotificationRow(item: item)),
      ],
    );
  }

  String _sectionTitle(KaizengramNotificationBucket bucket) {
    switch (bucket) {
      case KaizengramNotificationBucket.today:
        return AppStrings.kaizengramNotificationsToday;
      case KaizengramNotificationBucket.thisWeek:
        return AppStrings.kaizengramNotificationsThisWeek;
      case KaizengramNotificationBucket.earlier:
        return AppStrings.kaizengramNotificationsEarlier;
    }
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final KaizengramNotificationItem item;

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColorFor(item);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            Navigator.of(context).pop<KaizengramNotificationItem>(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _buildRowContent(accentColor),
        ),
      ),
    );
  }

  Widget _buildRowContent(Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _NotificationAvatar(item: item, accentColor: accentColor),
        const SizedBox(width: 12),
        Expanded(child: _buildMessageColumn(accentColor)),
        const SizedBox(width: 12),
        _NotificationPostPreview(item: item, accentColor: accentColor),
      ],
    );
  }

  Widget _buildMessageColumn(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildMessageText(),
          const SizedBox(height: 6),
          _buildMetaRow(accentColor),
        ],
      ),
    );
  }

  Widget _buildMessageText() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.38),
        children: <InlineSpan>[
          TextSpan(
            text: '${item.actorName} ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: _messageFor(item)),
          TextSpan(
            text: ' ${_timeLabelFor(item.occurredAt)}',
            style: const TextStyle(
              color: Color(0xFF8D93A6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(Color accentColor) {
    return Row(
      children: <Widget>[
        if (item.isUnread) _UnreadDot(accentColor: accentColor),
        Expanded(
          child: AppTextView.body2(
            _postMeta(item.post),
            color: AppColors.textSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item, required this.accentColor});

  final KaizengramNotificationItem item;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[accentColor, accentColor.withValues(alpha: 0.35)],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1B1E27),
            ),
            child: Center(
              child: AppTextView.body1(
                _initialsFor(item.actorName),
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -1,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF111317), width: 2),
            ),
            child: Icon(_iconFor(item.type), size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _NotificationPostPreview extends StatelessWidget {
  const _NotificationPostPreview({
    required this.item,
    required this.accentColor,
  });

  final KaizengramNotificationItem item;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final previewUrl = item.post.feedImageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (previewUrl != null && previewUrl.isNotEmpty)
              Image.network(
                previewUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PreviewFallback(
                  icon: _postCategoryIcon(item.post),
                  accentColor: accentColor,
                ),
              )
            else
              _PreviewFallback(
                icon: _postCategoryIcon(item.post),
                accentColor: accentColor,
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
            if (item.post.hasVideo)
              Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.52),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _postCategoryIcon(item.post),
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.icon, required this.accentColor});

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accentColor.withValues(alpha: 0.9),
            const Color(0xFF262B3E),
          ],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }
}

String _messageFor(KaizengramNotificationItem item) {
  final title = item.post.title;

  switch (item.type) {
    case KaizengramNotificationType.assigned:
      return AppStrings.kaizengramNotificationAssigned(title);
    case KaizengramNotificationType.commented:
      return AppStrings.kaizengramNotificationCommented(title);
    case KaizengramNotificationType.dueSoon:
      return _dueSoonMessage(title, item.post.dueBy ?? item.post.deadlineDate);
    case KaizengramNotificationType.reviewed:
      return AppStrings.kaizengramNotificationReviewed(
        title,
        (item.post.status ?? '').toLowerCase(),
      );
    case KaizengramNotificationType.readyForFollowUp:
      return AppStrings.kaizengramNotificationReadyForFollowUp(title);
    case KaizengramNotificationType.requestedUpload:
      return AppStrings.kaizengramNotificationRequestedUpload(title);
  }
}

String _dueSoonMessage(String title, String? dueLabel) {
  final normalized = dueLabel?.trim();
  if (normalized == null || normalized.isEmpty) {
    return AppStrings.kaizengramNotificationAssigned(title);
  }

  final lower = normalized.toLowerCase();
  if (lower == 'overdue') {
    return AppStrings.kaizengramNotificationMarkedOverdue(title);
  }

  if (lower == 'today' || lower == 'tomorrow') {
    return AppStrings.kaizengramNotificationDueBy(title, lower);
  }

  return AppStrings.kaizengramNotificationDueIn(title, normalized);
}

String _postMeta(KaizengramFeedItem post) {
  final parts = <String>[_postCategoryLabel(post), post.title];

  final status = post.status?.trim();
  if (status != null && status.isNotEmpty) {
    parts.add(status);
  }

  final dueBy = post.dueBy?.trim();
  if (post.resolvedPostCategory == KaizengramPostCategory.learningCompliance &&
      dueBy != null &&
      dueBy.isNotEmpty) {
    parts.add(dueBy);
  }

  return parts.join(' • ');
}

String _postCategoryLabel(KaizengramFeedItem post) {
  switch (post.resolvedPostCategory) {
    case KaizengramPostCategory.audit:
      return AppStrings.kaizengramTabWeeklyCheckIn;
    case KaizengramPostCategory.learningCompliance:
      return AppStrings.kaizengramTabLearning;
    case KaizengramPostCategory.documentCompliance:
      return AppStrings.kaizengramTabDocument;
  }
}

IconData _postCategoryIcon(KaizengramFeedItem post) {
  switch (post.resolvedPostCategory) {
    case KaizengramPostCategory.audit:
      return Icons.fact_check_rounded;
    case KaizengramPostCategory.learningCompliance:
      return Icons.school_rounded;
    case KaizengramPostCategory.documentCompliance:
      return Icons.description_rounded;
  }
}

Color _accentColorFor(KaizengramNotificationItem item) {
  switch (item.post.resolvedPostCategory) {
    case KaizengramPostCategory.audit:
      return item.type == KaizengramNotificationType.readyForFollowUp
          ? const Color(0xFFFF7D7D)
          : const Color(0xFF7EA6FF);
    case KaizengramPostCategory.learningCompliance:
      return const Color(0xFF25D7C2);
    case KaizengramPostCategory.documentCompliance:
      return item.type == KaizengramNotificationType.requestedUpload
          ? const Color(0xFFFF9A62)
          : const Color(0xFFFFB547);
  }
}

IconData _iconFor(KaizengramNotificationType type) {
  switch (type) {
    case KaizengramNotificationType.assigned:
      return Icons.assignment_ind_rounded;
    case KaizengramNotificationType.commented:
      return Icons.chat_bubble_rounded;
    case KaizengramNotificationType.dueSoon:
      return Icons.schedule_rounded;
    case KaizengramNotificationType.reviewed:
      return Icons.verified_rounded;
    case KaizengramNotificationType.readyForFollowUp:
      return Icons.fact_check_rounded;
    case KaizengramNotificationType.requestedUpload:
      return Icons.upload_file_rounded;
  }
}

String _timeLabelFor(DateTime occurredAt) {
  final difference = DateTime.now().difference(occurredAt);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(1, 59)}m';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d';
  }

  if (difference.inDays < 30) {
    return '${(difference.inDays / 7).floor()}w';
  }

  return '${(difference.inDays / 30).floor()}mo';
}

String _initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'K';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
