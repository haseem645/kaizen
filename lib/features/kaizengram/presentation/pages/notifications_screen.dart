import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../providers/kaizengram_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const List<_NotificationSection> _sections = <_NotificationSection>[
    _NotificationSection(
      title: 'Today',
      items: <_NotificationItem>[
        _NotificationItem(
          name: 'Areeba Malik',
          message: 'liked your learning compliance update.',
          timeLabel: '2m',
          accentColor: Color(0xFFFF5F7A),
          icon: Icons.favorite_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Hamza Khan',
          message: 'commented: "Great progress on this one!"',
          timeLabel: '18m',
          accentColor: Color(0xFF63D1FF),
          icon: Icons.chat_bubble_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Nimra',
          message: 'started following you.',
          timeLabel: '42m',
          accentColor: Color(0xFF9B8CFF),
          icon: Icons.person_add_alt_1_rounded,
          trailing: _NotificationTrailing.followBack,
          buttonLabel: 'Follow',
        ),
        _NotificationItem(
          name: 'Zain Ali',
          message: 'liked your post.',
          timeLabel: '55m',
          accentColor: Color(0xFFFF8B5E),
          icon: Icons.favorite_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Mahnoor',
          message: 'mentioned you in a story reply.',
          timeLabel: '1h',
          accentColor: Color(0xFF72C3FF),
          icon: Icons.alternate_email_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Team Ops',
          message: 'shared a new check-in highlight.',
          timeLabel: '3h',
          accentColor: Color(0xFF68D7A8),
          icon: Icons.insights_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
      ],
    ),
    _NotificationSection(
      title: 'This Week',
      items: <_NotificationItem>[
        _NotificationItem(
          name: 'Audit Team',
          message: 'mentioned you in a check-in discussion.',
          timeLabel: '2d',
          accentColor: Color(0xFFFFB15D),
          icon: Icons.alternate_email_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Usman R.',
          message: 'liked your compliance completion streak.',
          timeLabel: '4d',
          accentColor: Color(0xFF58D6A4),
          icon: Icons.favorite_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Sana Ali',
          message: 'and 3 others started following you.',
          timeLabel: '6d',
          accentColor: Color(0xFFFF8AB3),
          icon: Icons.groups_rounded,
          trailing: _NotificationTrailing.following,
          buttonLabel: 'Following',
        ),
        _NotificationItem(
          name: 'Ammar',
          message: 'commented: "This format looks much cleaner."',
          timeLabel: '6d',
          accentColor: Color(0xFF7BE0C2),
          icon: Icons.chat_bubble_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Rida Noor',
          message: 'requested to follow you.',
          timeLabel: '6d',
          accentColor: Color(0xFFFF7BA5),
          icon: Icons.person_add_alt_1_rounded,
          trailing: _NotificationTrailing.followBack,
          buttonLabel: 'Follow',
        ),
        _NotificationItem(
          name: 'Learning Circle',
          message: 'liked your compliance streak update.',
          timeLabel: '1w',
          accentColor: Color(0xFF9F90FF),
          icon: Icons.favorite_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Sarah J.',
          message: 'and 12 others reacted to your story.',
          timeLabel: '1w',
          accentColor: Color(0xFFFFB566),
          icon: Icons.auto_awesome_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
      ],
    ),
    _NotificationSection(
      title: 'Earlier',
      items: <_NotificationItem>[
        _NotificationItem(
          name: 'Compliance Desk',
          message: 'shared a new document update for your review.',
          timeLabel: '2w',
          accentColor: Color(0xFF75B6FF),
          icon: Icons.description_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Danish',
          message: 'started following you.',
          timeLabel: '2w',
          accentColor: Color(0xFF8F86FF),
          icon: Icons.person_add_alt_1_rounded,
          trailing: _NotificationTrailing.following,
          buttonLabel: 'Following',
        ),
        _NotificationItem(
          name: 'Kiran Fatima',
          message: 'liked your learning progress story.',
          timeLabel: '3w',
          accentColor: Color(0xFFFF718C),
          icon: Icons.favorite_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Review Board',
          message: 'mentioned you in a compliance recap.',
          timeLabel: '3w',
          accentColor: Color(0xFF64D0FF),
          icon: Icons.alternate_email_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
        _NotificationItem(
          name: 'Hina & Bilal',
          message: 'started following you.',
          timeLabel: '1mo',
          accentColor: Color(0xFF62DBB5),
          icon: Icons.groups_rounded,
          trailing: _NotificationTrailing.followBack,
          buttonLabel: 'Follow',
        ),
        _NotificationItem(
          name: 'Internal Audit',
          message: 'liked your report summary.',
          timeLabel: '1mo',
          accentColor: Color(0xFFFFA45E),
          icon: Icons.favorite_rounded,
          trailing: _NotificationTrailing.postPreview,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<KaizengramController>();

    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111317),
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        title: AppTextView.title1(
          'Notifications',
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 28),
          itemCount: _sections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _NotificationSectionView(section: _sections[index]);
          },
        ),
      ),
    );
  }
}

class _NotificationSectionView extends StatelessWidget {
  const _NotificationSectionView({required this.section});

  final _NotificationSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: AppTextView.body1(
            section.title,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        ...section.items.map((item) => _NotificationRow(item: item)),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _NotificationAvatar(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.38,
                ),
                children: <InlineSpan>[
                  TextSpan(
                    text: '${item.name} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: item.message),
                  TextSpan(
                    text: ' ${item.timeLabel}',
                    style: const TextStyle(
                      color: Color(0xFF8D93A6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _NotificationTrailingView(item: item),
        ],
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item});

  final _NotificationItem item;

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
              colors: <Color>[
                item.accentColor,
                item.accentColor.withValues(alpha: 0.35),
              ],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1B1E27),
            ),
            child: Center(
              child: AppTextView.body1(
                _initialsFor(item.name),
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
              color: item.accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF111317), width: 2),
            ),
            child: Icon(item.icon, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _NotificationTrailingView extends StatelessWidget {
  const _NotificationTrailingView({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    switch (item.trailing) {
      case _NotificationTrailing.postPreview:
        return Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                item.accentColor.withValues(alpha: 0.85),
                const Color(0xFF262B3E),
              ],
            ),
          ),
          child: const Icon(
            Icons.playlist_play_rounded,
            color: Colors.white,
            size: 22,
          ),
        );
      case _NotificationTrailing.followBack:
        return _FollowButton(
          label: item.buttonLabel ?? 'Follow',
          isFilled: true,
        );
      case _NotificationTrailing.following:
        return _FollowButton(
          label: item.buttonLabel ?? 'Following',
          isFilled: false,
        );
    }
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.label, required this.isFilled});

  final String label;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isFilled ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: AppTextView.body2(
        label,
        color: isFilled ? const Color(0xFF12151D) : Colors.white,
        textAlign: TextAlign.center,
        fontWeight: FontWeight.w700,
      ),
    );
  }
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

class _NotificationSection {
  const _NotificationSection({required this.title, required this.items});

  final String title;
  final List<_NotificationItem> items;
}

enum _NotificationTrailing { postPreview, followBack, following }

class _NotificationItem {
  const _NotificationItem({
    required this.name,
    required this.message,
    required this.timeLabel,
    required this.accentColor,
    required this.icon,
    required this.trailing,
    this.buttonLabel,
  });

  final String name;
  final String message;
  final String timeLabel;
  final Color accentColor;
  final IconData icon;
  final _NotificationTrailing trailing;
  final String? buttonLabel;
}
