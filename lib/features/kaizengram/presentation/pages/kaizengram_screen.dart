import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../routes/app_router.dart';
import '../../../compliance/presentation/widgets/compliance_video_player.dart';
import '../../data/datasources/kaizengram_remote_data_source.dart';
import '../providers/kaizengram_controller.dart';

class KaizenGramScreen extends StatelessWidget {
  const KaizenGramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<KaizengramController>(
      create: (_) => KaizengramController(KaizengramRemoteDataSource())..initialize(),
      child: const _KaizenGramView(),
    );
  }
}

class _KaizenGramView extends StatelessWidget {
  const _KaizenGramView();

  static const bool _useSeparateFeedDemo = true;

  static const List<_PowerListEntry> _powerListEntriesFirstHalf = <_PowerListEntry>[
    _PowerListEntry(
      title: 'Learning Compliances',
      value: '12 Due This Week',
      icon: Icons.school_rounded,
      accentColor: Color(0xFF25D7C2),
      destination: _PowerListDestination.learningCompliance,
    ),
    _PowerListEntry(
      title: 'Document Compliances',
      value: '8 Pending Uploads',
      icon: Icons.description_rounded,
      accentColor: Color(0xFFFFB547),
      destination: _PowerListDestination.documentCompliance,
    ),
  ];

  static const List<_PowerListEntry> _powerListEntriesSecondHalf = <_PowerListEntry>[
    _PowerListEntry(
      title: 'Check-ins',
      value: '5 Active Check-ins',
      icon: Icons.fact_check_rounded,
      accentColor: Color(0xFF7EA6FF),
      destination: _PowerListDestination.audit,
    ),
    _PowerListEntry(
      title: 'Check-in Reports',
      value: '3 Ready For Review',
      icon: Icons.assignment_turned_in_rounded,
      accentColor: Color(0xFFFF7D7D),
      destination: _PowerListDestination.audit,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KaizengramController>();

    return DrawerMainScreen(
      title: AppStrings.homeKaizengram,
      selectedMenu: AppMenuType.home,
      appBarActions: <Widget>[
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            // Notification icon click is temporarily disabled.
            onTap: null,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.favorite_border_rounded),
            ),
          ),
        ),
      ],
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF252A40), Color(0xFF1B1F31)],
          ),
        ),
        child: controller.isLoading
            ? Center(child: FastCircularProgressIndicator())
            : (_useSeparateFeedDemo
                  ? showSeparateFeed(context, controller)
                  : showMixedFeed(context, controller)),
      ),
    );
  }

  Widget showMixedFeed(BuildContext context, KaizengramController controller) {
    return RefreshIndicator(
      color: AppColors.secondaryColor,
      onRefresh: () => context.read<KaizengramController>().initialize(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: <Widget>[
          _StoriesRow(stories: controller.stories),
          const SizedBox(height: 8),
          ..._buildFeedStateChildren(controller),
          ..._buildMixedFeedChildren(context, controller),
        ],
      ),
    );
  }

  Widget showSeparateFeed(BuildContext context, KaizengramController controller) {
    final auditPosts = controller.posts
        .where((post) => post.resolvedPostCategory == KaizengramPostCategory.audit)
        .toList(growable: false);
    final learningPosts = controller.posts
        .where((post) => post.resolvedPostCategory == KaizengramPostCategory.learningCompliance)
        .toList(growable: false);
    final documentPosts = controller.posts
        .where((post) => post.resolvedPostCategory == KaizengramPostCategory.documentCompliance)
        .toList(growable: false);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          _StoriesRow(stories: controller.stories),
          if (controller.errorMessage != null && controller.posts.isEmpty)
            const Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: _FeedStateMessage(message: 'Unable to load Kaizen feed right now.'),
              ),
            )
          else if (controller.posts.isEmpty)
            const Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: _FeedStateMessage(message: 'No feed items are available yet.'),
              ),
            )
          else ...<Widget>[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                tabAlignment: TabAlignment.fill,
                labelPadding: EdgeInsets.zero,
                indicator: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.mainBg,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                tabs: const <Widget>[
                  SizedBox(height: 32, child: Tab(text: 'Weekly Check-In')),
                  SizedBox(height: 32, child: Tab(text: 'Learning')),
                  SizedBox(height: 32, child: Tab(text: 'Document')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _FeedTabList(
                    posts: auditPosts,
                    onRefresh: () =>
                        context.read<KaizengramController>().initialize(forceRefresh: true),
                    itemBuilder: (post) => _buildPostCard(context, controller, post),
                  ),
                  _FeedTabList(
                    posts: learningPosts,
                    onRefresh: () =>
                        context.read<KaizengramController>().initialize(forceRefresh: true),
                    itemBuilder: (post) => _buildPostCard(context, controller, post),
                  ),
                  _FeedTabList(
                    posts: documentPosts,
                    onRefresh: () =>
                        context.read<KaizengramController>().initialize(forceRefresh: true),
                    itemBuilder: (post) => _buildPostCard(context, controller, post),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFeedStateChildren(KaizengramController controller) {
    return <Widget>[
      if (controller.errorMessage != null && controller.posts.isEmpty)
        const _FeedStateMessage(message: 'Unable to load Kaizen feed right now.'),
      if (controller.posts.isEmpty && controller.errorMessage == null)
        const _FeedStateMessage(message: 'No feed items are available yet.'),
    ];
  }

  Widget _buildPostCard(
    BuildContext context,
    KaizengramController controller,
    KaizengramFeedItem post,
  ) {
    return _PostCard(
      post: post,
      onTap: () => _openPost(context, post),
      onLikeTap: () => controller.toggleLike(post.id),
      onCommentTap: () => _openComments(context, post),
    );
  }

  List<Widget> _buildMixedFeedChildren(BuildContext context, KaizengramController controller) {
    final widgets = <Widget>[];
    final firstInsertionIndex = controller.posts.length > 1 ? 2 : 1;
    final secondInsertionIndex = controller.posts.length > 4 ? 5 : null;

    for (var index = 0; index < controller.posts.length; index++) {
      final post = controller.posts[index];
      widgets.add(_buildPostCard(context, controller, post));

      if (index + 1 == firstInsertionIndex) {
        widgets.add(
          const _PowerListCard(
            title: 'Power List',
            subtitle: 'Insights across compliances and audits',
            entries: _powerListEntriesFirstHalf,
            onEntryTap: _handlePowerListTap,
          ),
        );
      }

      if (secondInsertionIndex != null && index + 1 == secondInsertionIndex) {
        widgets.add(
          const _PowerListCard(
            title: 'Power List Continued',
            subtitle: 'More highlights inside the feed',
            entries: _powerListEntriesSecondHalf,
            onEntryTap: _handlePowerListTap,
          ),
        );
      }
    }

    return widgets;
  }

  Future<void> _openComments(BuildContext context, KaizengramFeedItem post) async {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit &&
        post.auditMediaItems.isNotEmpty) {
      await _showAuditMediaSheet(context, post);
      return;
    }

    await _showCommentsThreadSheet(context, post);
  }

  Future<void> _showCommentsThreadSheet(
    BuildContext context,
    KaizengramFeedItem post, {
    KaizengramAuditMediaItem? selectedAuditMediaItem,
  }) {
    final comments = post.commentThread.isNotEmpty
        ? post.commentThread
        : <KaizengramComment>[
            KaizengramComment(
              authorName: _resolvePrimaryActorName(post),
              message: post.description,
              timestampLabel: post.timestampLabel,
              avatarUrl: post.avatarUrl,
              isDescription: true,
            ),
          ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CommentsThreadBottomSheet(
        post: post,
        comments: comments,
        selectedAuditMediaItem: selectedAuditMediaItem,
      ),
    );
  }

  Future<void> _showAuditMediaSheet(BuildContext context, KaizengramFeedItem post) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _AuditMediaBottomSheet(
        post: post,
        onMediaTap: (selectedMediaItem) {
          Navigator.of(sheetContext).pop();
          Future<void>.delayed(Duration.zero, () {
            if (!context.mounted) {
              return;
            }

            _showCommentsThreadSheet(context, post, selectedAuditMediaItem: selectedMediaItem);
          });
        },
      ),
    );
  }

  String _resolvePrimaryActorName(KaizengramFeedItem post) {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit) {
      final auditedBy = post.auditedBy?.trim();
      if (auditedBy != null && auditedBy.isNotEmpty) {
        return auditedBy;
      }
    }

    final postedBy = post.postedByName.trim();
    if (postedBy.isNotEmpty) {
      return postedBy;
    }

    return post.subtitle;
  }

  static Future<void> _handlePowerListTap(BuildContext context, _PowerListEntry entry) async {
    switch (entry.destination) {
      case _PowerListDestination.learningCompliance:
        await AppRouter.pushNamed<void>(context, AppRouter.learningTracks);
        return;
      case _PowerListDestination.documentCompliance:
        await AppRouter.pushNamed<void>(context, AppRouter.compliance);
        return;
      case _PowerListDestination.audit:
        await AppRouter.pushNamed<void>(context, AppRouter.audit);
        return;
    }
  }

  Future<void> _openPost(BuildContext context, KaizengramFeedItem post) async {
    switch (post.type) {
      case KaizengramFeedType.learningCompliance:
        if (CustomFunctions.isDeadlineOverdue(post.rawDeadline)) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('You cannot access this compliance')));
          return;
        }

        if (post.status != null && CustomFunctions.isCancelledStatus(post.status!)) {
          CustomFunctions.showCustomAlert(
            context,
            'Restricted',
            'You cannot access this compliance',
          );
          return;
        }

        final trackAssignmentUuid = post.trackAssignmentUuid?.trim();
        if (trackAssignmentUuid == null || trackAssignmentUuid.isEmpty) {
          return;
        }
        await AppRouter.pushNamed<void>(
          context,
          AppRouter.complianceTracks,
          arguments: ComplianceTracksRouteArgs(
            trackAssignmentUuid: trackAssignmentUuid,
            title: post.title,
          ),
        );
        return;
      case KaizengramFeedType.documentCompliance:
        await AppRouter.pushNamed<void>(context, AppRouter.compliance);
        return;
    }
  }
}

enum _PowerListDestination { learningCompliance, documentCompliance, audit }

class _PowerListEntry {
  const _PowerListEntry({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.destination,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final _PowerListDestination destination;
}

class _PowerListCard extends StatelessWidget {
  const _PowerListCard({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.onEntryTap,
  });

  final String title;
  final String subtitle;
  final List<_PowerListEntry> entries;
  final Future<void> Function(BuildContext context, _PowerListEntry entry) onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF20253A),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: AppColors.secondaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextView.body1(
                      title,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                    const SizedBox(height: 2),
                    AppTextView.body2(subtitle, color: AppColors.textSecondary, fontSize: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => _PowerListRow(entry: entry, onTap: () => onEntryTap(context, entry)),
          ),
        ],
      ),
    );
  }
}

class _PowerListRow extends StatelessWidget {
  const _PowerListRow({required this.entry, required this.onTap});

  final _PowerListEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: entry.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, color: entry.accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextView.body1(
                      entry.title,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    const SizedBox(height: 4),
                    AppTextView.body2(entry.value, color: AppColors.textSecondary, fontSize: 12),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedStateMessage extends StatelessWidget {
  const _FeedStateMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      child: AppTextView.body1(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _FeedTabList extends StatelessWidget {
  const _FeedTabList({required this.posts, required this.onRefresh, required this.itemBuilder});

  final List<KaizengramFeedItem> posts;
  final Future<void> Function() onRefresh;
  final Widget Function(KaizengramFeedItem post) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.secondaryColor,
      onRefresh: onRefresh,
      child: posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: const <Widget>[
                _FeedStateMessage(message: 'No feed items are available in this tab.'),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                return itemBuilder(posts[index]);
              },
            ),
    );
  }
}

class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.stories});

  final List<KaizengramStory> stories;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.64),
        border: Border(bottom: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final story = stories[index];
          return Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(2.4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFFF9CE34), Color(0xFFEE2A7B), Color(0xFF6228D7)],
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.surfaceDark,
                  child: story.avatarUrl == null
                      ? const CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.surfaceDark3,
                          child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
                        )
                      : CircleAvatar(radius: 25, backgroundImage: NetworkImage(story.avatarUrl!)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 58,
                child: AppTextView.body2(
                  story.name,
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onLikeTap,
    required this.onCommentTap,
  });

  final KaizengramFeedItem post;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isDescriptionExpanded = false;

  String _headerTitle(KaizengramFeedItem post) {
    final seatProfile = post.seatProfile.trim();
    if (seatProfile.isNotEmpty) {
      return seatProfile;
    }

    return post.title;
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 18),
          color: AppColors.surfaceDark.withValues(alpha: 0.76),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: <Widget>[
                    post.avatarUrl == null
                        ? const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceDark3,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          )
                        : CircleAvatar(radius: 18, backgroundImage: NetworkImage(post.avatarUrl!)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AppTextView.body1(
                            _headerTitle(post),
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: <Widget>[
                              Flexible(
                                child: AppTextView.body2(
                                  _headerRelationLabel(post),
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: AppTextView.body2(
                                  _headerRelationName(post),
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              _PostMediaSection(post: post),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: widget.onLikeTap,
                      icon: Icon(
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: post.isLiked ? const Color(0xFFFF4D67) : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCommentTap,
                      icon: const Icon(Icons.mode_comment_outlined, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send_outlined, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border_rounded, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              if (_resolvedDescription(post) != null) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: _ExpandableDescriptionText(
                    text: _resolvedDescription(post)!,
                    isExpanded: _isDescriptionExpanded,
                    onToggle: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppTextView.body1(
                  '${post.likes} likes',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ..._buildMetaSection(post),
                    if (post.status != null) ...<Widget>[
                      const SizedBox(height: 6),
                      _StatusLine(status: post.status!, postCategory: post.resolvedPostCategory),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolvedDescription(KaizengramFeedItem post) {
    if (CustomFunctions.resolvedText(post.description) == null || post.description == post.status) {
      return null;
    }

    return post.description;
  }

  List<Widget> _buildMetaSection(KaizengramFeedItem post) {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit) {
      return <Widget>[
        _MetaLine(label: 'Audited At', value: post.auditedAt ?? post.timestampLabel),
        const SizedBox(height: 6),
        _MetaLine(label: 'Audited By', value: _headerRelationName(post)),
      ];
    }

    return <Widget>[
      _MetaLine(label: 'Seat ', value: post.departmentName ?? post.seatProfile),
      if ((post.dueBy ?? post.deadlineDate)?.trim().isNotEmpty == true) ...<Widget>[
        const SizedBox(height: 6),
        _MetaLine(
          label: 'Due By ',
          value: post.dueBy?.trim().isNotEmpty == true ? post.dueBy! : post.deadlineDate!,
        ),
      ],
    ];
  }

  String _headerRelationLabel(KaizengramFeedItem post) {
    return post.resolvedPostCategory == KaizengramPostCategory.audit ? 'Audited By' : 'Assigned By';
  }

  String _headerRelationName(KaizengramFeedItem post) {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit) {
      final auditedBy = post.auditedBy?.trim();
      if (auditedBy != null && auditedBy.isNotEmpty) {
        return auditedBy;
      }
    }

    final postedBy = post.postedByName.trim();
    if (postedBy.isNotEmpty) {
      return postedBy;
    }

    return post.subtitle;
  }
}

class _PostMediaSection extends StatelessWidget {
  const _PostMediaSection({required this.post});

  final KaizengramFeedItem post;

  @override
  Widget build(BuildContext context) {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit &&
        post.auditMediaItems.isNotEmpty) {
      return _AuditPostMediaPager(mediaItems: post.auditMediaItems);
    }

    if (post.mediaUrls.length > 1) {
      return _ImagePostMediaPager(imageUrls: post.mediaUrls);
    }

    if (post.hasVideo && post.feedVideoUrl != null) {
      return SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).width,
        child: ComplianceVideoPlayer(
          videoUrl: post.feedVideoUrl!,
          title: post.title,
          thumbnailLink: post.feedImageUrl,
          height: MediaQuery.sizeOf(context).width,
          showTitle: false,
          showSeekBar: false,
          showDuration: false,
          fillBounds: true,
        ),
      );
    }

    if (post.resolvedPostCategory == KaizengramPostCategory.documentCompliance &&
        post.feedImageUrl == null) {
      return const AspectRatio(aspectRatio: 1, child: _UploadDocPlaceholder());
    }

    return AspectRatio(aspectRatio: 1, child: _NetworkPostImage(imageUrl: post.feedImageUrl));
  }
}

class _ImagePostMediaPager extends StatefulWidget {
  const _ImagePostMediaPager({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ImagePostMediaPager> createState() => _ImagePostMediaPagerState();
}

class _ImagePostMediaPagerState extends State<_ImagePostMediaPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.imageUrls;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).width,
              child: PageView.builder(
                controller: _pageController,
                itemCount: imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return AspectRatio(
                    aspectRatio: 1,
                    child: _NetworkPostImage(imageUrl: imageUrls[index]),
                  );
                },
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppTextView.body4(
                  '${_currentPage + 1}/${imageUrls.length}',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(imageUrls.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }, growable: false),
        ),
      ],
    );
  }
}

class _AuditPostMediaPager extends StatefulWidget {
  const _AuditPostMediaPager({required this.mediaItems});

  final List<KaizengramAuditMediaItem> mediaItems;

  @override
  State<_AuditPostMediaPager> createState() => _AuditPostMediaPagerState();
}

class _AuditPostMediaPagerState extends State<_AuditPostMediaPager> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = widget.mediaItems;
    if (mediaItems.length == 1) {
      return _AuditPostMediaPage(item: mediaItems.first);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            SizedBox(
              height: MediaQuery.sizeOf(context).width,
              child: PageView.builder(
                controller: _pageController,
                itemCount: mediaItems.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _AuditPostMediaPage(item: mediaItems[index]);
                },
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AppTextView.body4(
                  '${_currentPage + 1}/${mediaItems.length}',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(mediaItems.length, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.textPrimary
                    : AppColors.textPrimary.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }, growable: false),
        ),
      ],
    );
  }
}

class _ExpandableDescriptionText extends StatelessWidget {
  const _ExpandableDescriptionText({
    required this.text,
    required this.isExpanded,
    required this.onToggle,
  });

  final String text;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
    );
    const toggleStyle = TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700);
    final maxWidth = MediaQuery.sizeOf(context).width - 32;
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final shouldShowToggle = textPainter.didExceedMaxLines;
    final collapsedText = shouldShowToggle
        ? _collapsedText(maxWidth: maxWidth, style: textStyle, toggleStyle: toggleStyle)
        : text;

    if (isExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          RichText(
            text: TextSpan(
              style: textStyle,
              children: <InlineSpan>[TextSpan(text: text)],
            ),
          ),
          if (shouldShowToggle) ...<Widget>[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onToggle,
              child: AppTextView.body3(
                'Hide',
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.clip,
      text: TextSpan(
        style: textStyle,
        children: <InlineSpan>[
          TextSpan(text: collapsedText),
          if (shouldShowToggle)
            TextSpan(
              text: ' more',
              style: toggleStyle,
              recognizer: TapGestureRecognizer()..onTap = onToggle,
            ),
        ],
      ),
    );
  }

  String _collapsedText({
    required double maxWidth,
    required TextStyle style,
    required TextStyle toggleStyle,
  }) {
    var low = 0;
    var high = text.length;
    var best = '';

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final painter = TextPainter(
        text: TextSpan(
          style: style,
          children: <InlineSpan>[
            TextSpan(text: '${text.substring(0, mid).trimRight()}...'),
            TextSpan(text: ' more', style: toggleStyle),
          ],
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (painter.didExceedMaxLines) {
        high = mid - 1;
      } else {
        best = text.substring(0, mid).trimRight();
        low = mid + 1;
      }
    }

    if (best.isEmpty) {
      return '...';
    }

    return '$best...';
  }
}

class _AuditPostMediaPage extends StatelessWidget {
  const _AuditPostMediaPage({required this.item});

  final KaizengramAuditMediaItem item;

  @override
  Widget build(BuildContext context) {
    if (item.hasVideo && item.videoUrl != null) {
      return SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).width,
        child: ComplianceVideoPlayer(
          videoUrl: item.videoUrl!,
          title: item.title,
          thumbnailLink: item.thumbnailUrl,
          height: MediaQuery.sizeOf(context).width,
          showTitle: false,
          showSeekBar: false,
          showDuration: false,
          fillBounds: true,
        ),
      );
    }

    return AspectRatio(aspectRatio: 1, child: _NetworkPostImage(imageUrl: item.thumbnailUrl));
  }
}

class _NetworkPostImage extends StatelessWidget {
  const _NetworkPostImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return Container(
        color: AppColors.surfaceDark3,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 40),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            color: AppColors.surfaceDark3,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.secondaryColor),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.surfaceDark3,
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: AppColors.textSecondary,
              size: 40,
            ),
          );
        },
      ),
    );
  }
}

class _UploadDocPlaceholder extends StatelessWidget {
  const _UploadDocPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark3,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(Icons.upload_file_rounded, color: AppColors.textSecondary, size: 36),
          SizedBox(height: 10),
          AppTextView.body1(
            'Upload Doc',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ],
      ),
    );
  }
}

class _CommentsThreadBottomSheet extends StatefulWidget {
  const _CommentsThreadBottomSheet({
    required this.post,
    required this.comments,
    this.selectedAuditMediaItem,
  });

  final KaizengramFeedItem post;
  final List<KaizengramComment> comments;
  final KaizengramAuditMediaItem? selectedAuditMediaItem;

  @override
  State<_CommentsThreadBottomSheet> createState() => _CommentsThreadBottomSheetState();
}

class _CommentsThreadBottomSheetState extends State<_CommentsThreadBottomSheet> {
  late final TextEditingController _commentController;
  final ImagePicker _imagePicker = ImagePicker();
  late List<KaizengramComment> _comments;
  KaizengramComment? _replyingTo;
  File? _documentImageFile;
  var _isPickingDocumentImage = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _comments = List<KaizengramComment>.from(widget.comments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _sheetTitle() {
    final seatName = widget.post.title.trim();
    if (seatName.isNotEmpty) {
      return seatName;
    }

    return widget.post.seatProfile;
  }

  void _startReply(KaizengramComment comment) {
    setState(() {
      _replyingTo = comment;
    });
  }

  void _clearReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _sendComment() {
    final message = _commentController.text.trim();
    if (message.isEmpty) {
      return;
    }

    setState(() {
      if (_replyingTo != null) {
        final target = _replyingTo!;
        final index = _comments.indexOf(target);
        if (index != -1) {
          final updatedReplies = List<KaizengramComment>.from(target.replies)
            ..add(const KaizengramComment(authorName: 'You', message: '', timestampLabel: 'Now'));
          updatedReplies[updatedReplies.length - 1] = KaizengramComment(
            authorName: 'You',
            message: message,
            timestampLabel: 'Now',
          );
          _comments[index] = KaizengramComment(
            authorName: target.authorName,
            message: target.message,
            timestampLabel: target.timestampLabel,
            avatarUrl: target.avatarUrl,
            isDescription: target.isDescription,
            replies: updatedReplies,
          );
        }
      } else {
        _comments.add(
          const KaizengramComment(authorName: 'You', message: '', timestampLabel: 'Now'),
        );
        _comments[_comments.length - 1] = KaizengramComment(
          authorName: 'You',
          message: message,
          timestampLabel: 'Now',
        );
      }

      _commentController.clear();
      _replyingTo = null;
    });
  }

  Future<void> _pickDocumentImage() async {
    if (_isPickingDocumentImage) {
      return;
    }

    setState(() {
      _isPickingDocumentImage = true;
    });

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedImage == null || !mounted) {
        return;
      }

      setState(() {
        _documentImageFile = File(pickedImage.path);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Unable to pick image right now')));
    } finally {
      if (mounted) {
        setState(() {
          _isPickingDocumentImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.93,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppTextView.body1(
                    'Comments',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  const SizedBox(height: 4),
                  AppTextView.body2(_sheetTitle(), color: AppColors.textSecondary, fontSize: 13),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
              child: _CommentSheetMediaPreview(
                post: widget.post,
                selectedAuditMediaItem: widget.selectedAuditMediaItem,
                documentImageFile: _documentImageFile,
                onUploadTap:
                    widget.post.resolvedPostCategory == KaizengramPostCategory.documentCompliance
                    ? _pickDocumentImage
                    : null,
                isUploading: _isPickingDocumentImage,
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                itemCount: _comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _CommentThreadCard(comment: _comments[index], onReplyTap: _startReply);
                },
              ),
            ),
            _CommentComposer(
              controller: _commentController,
              replyingTo: _replyingTo,
              onCancelReply: _clearReply,
              onSend: _sendComment,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentSheetMediaPreview extends StatelessWidget {
  const _CommentSheetMediaPreview({
    required this.post,
    this.selectedAuditMediaItem,
    this.documentImageFile,
    this.onUploadTap,
    this.isUploading = false,
  });

  final KaizengramFeedItem post;
  final KaizengramAuditMediaItem? selectedAuditMediaItem;
  final File? documentImageFile;
  final VoidCallback? onUploadTap;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    final auditMediaItem = selectedAuditMediaItem;

    if (documentImageFile != null) {
      return _buildDocumentPreviewCard(child: Image.file(documentImageFile!, fit: BoxFit.cover));
    }

    if (auditMediaItem != null) {
      if (auditMediaItem.hasVideo && auditMediaItem.videoUrl != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: ComplianceVideoPlayer(
              videoUrl: auditMediaItem.videoUrl!,
              title: auditMediaItem.title,
              thumbnailLink: auditMediaItem.thumbnailUrl,
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: _NetworkPostImage(imageUrl: auditMediaItem.thumbnailUrl),
        ),
      );
    }

    if (post.resolvedPostCategory == KaizengramPostCategory.audit &&
        post.auditMediaItems.isNotEmpty) {
      final primaryMedia = post.auditMediaItems.first;

      if (primaryMedia.hasVideo && primaryMedia.videoUrl != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: ComplianceVideoPlayer(
              videoUrl: primaryMedia.videoUrl!,
              title: primaryMedia.title,
              thumbnailLink: primaryMedia.thumbnailUrl,
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: _NetworkPostImage(imageUrl: primaryMedia.thumbnailUrl),
        ),
      );
    }

    if (post.hasVideo && post.feedVideoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 220,
          child: ComplianceVideoPlayer(
            videoUrl: post.feedVideoUrl!,
            title: post.title,
            thumbnailLink: post.feedImageUrl,
          ),
        ),
      );
    }

    if (post.resolvedPostCategory == KaizengramPostCategory.documentCompliance &&
        post.feedImageUrl == null) {
      return _buildDocumentPreviewCard(child: const _UploadDocPlaceholder());
    }

    if (post.resolvedPostCategory == KaizengramPostCategory.documentCompliance) {
      return _buildDocumentPreviewCard(child: _NetworkPostImage(imageUrl: post.feedImageUrl));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: _NetworkPostImage(imageUrl: post.feedImageUrl),
      ),
    );
  }

  Widget _buildDocumentPreviewCard({required Widget child}) {
    final canUpload =
        post.resolvedPostCategory == KaizengramPostCategory.documentCompliance &&
        onUploadTap != null;

    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(height: 220, width: double.infinity, child: child),
        ),
        if (canUpload)
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isUploading ? null : onUploadTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (isUploading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      else
                        const Icon(Icons.upload_rounded, color: AppColors.textPrimary, size: 16),
                      const SizedBox(width: 6),
                      AppTextView.body3(
                        documentImageFile == null ? 'Upload Image' : 'Change Image',
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CommentThreadCard extends StatefulWidget {
  const _CommentThreadCard({required this.comment, required this.onReplyTap});

  final KaizengramComment comment;
  final ValueChanged<KaizengramComment> onReplyTap;

  @override
  State<_CommentThreadCard> createState() => _CommentThreadCardState();
}

class _CommentThreadCardState extends State<_CommentThreadCard> {
  bool _showReplies = true;

  List<Widget> _buildReplyWidgets(List<KaizengramComment> replies) {
    return List<Widget>.generate(replies.length, (int index) {
      return Padding(
        padding: EdgeInsets.only(bottom: index == replies.length - 1 ? 0 : 10),
        child: _ReplyCommentRow(comment: replies[index], onReplyTap: widget.onReplyTap),
      );
    }, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final replies = comment.replies;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark3.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: comment.isDescription
              ? AppColors.secondaryColor.withValues(alpha: 0.30)
              : AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CommentAvatar(comment: comment),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextView.body2(
                        comment.authorName,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    AppTextView.body4(
                      comment.timestampLabel,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AppTextView.body2(comment.message, color: AppColors.textPrimary, fontSize: 13),
                const SizedBox(height: 8),
                _ReplyAction(onTap: () => widget.onReplyTap(comment)),
                if (replies.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => setState(() => _showReplies = !_showReplies),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: AppTextView.body4(
                        _showReplies ? 'Hide replies' : 'Show replies (${replies.length})',
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (_showReplies && replies.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.textPrimary.withValues(alpha: 0.14),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(children: _buildReplyWidgets(replies)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({required this.comment});

  final KaizengramComment comment;

  @override
  Widget build(BuildContext context) {
    final initials = comment.authorName.trim().isEmpty
        ? 'K'
        : comment.authorName
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.22),
      child: AppTextView.body3(initials, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
    );
  }
}

class _ReplyCommentRow extends StatelessWidget {
  const _ReplyCommentRow({required this.comment, required this.onReplyTap});

  final KaizengramComment comment;
  final ValueChanged<KaizengramComment> onReplyTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CommentAvatar(comment: comment),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextView.body3(
                      comment.authorName,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppTextView.body4(
                    comment.timestampLabel,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AppTextView.body3(
                comment.message,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 6),
              _ReplyAction(onTap: () => onReplyTap(comment)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReplyAction extends StatelessWidget {
  const _ReplyAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const <Widget>[
          Icon(Icons.reply_rounded, color: AppColors.secondaryColor, size: 16),
          SizedBox(width: 4),
          AppTextView.body4('Reply', color: AppColors.secondaryColor, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final KaizengramComment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border(top: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.08))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (replyingTo != null) ...<Widget>[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark3.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondaryColor.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextView.body3(
                        'Reply to ${replyingTo!.authorName}',
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: onCancelReply,
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08)),
                    ),
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      cursorHeight: 17,
                      cursorColor: AppColors.textPrimary,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onSend,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: AppColors.mainBg, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditMediaBottomSheet extends StatelessWidget {
  const _AuditMediaBottomSheet({required this.post, required this.onMediaTap});

  final KaizengramFeedItem post;
  final ValueChanged<KaizengramAuditMediaItem> onMediaTap;

  String _sheetSeatName() {
    final seatName = post.title.trim();
    if (seatName.isNotEmpty) {
      return seatName;
    }

    return post.seatProfile;
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = post.auditMediaItems;
    final badCount = mediaItems.where((item) => item.rating == KaizengramAuditRating.bad).length;
    final improvementCount = mediaItems
        .where((item) => item.rating == KaizengramAuditRating.needsImprovement)
        .length;
    final goodCount = mediaItems.where((item) => item.rating == KaizengramAuditRating.good).length;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppTextView.body1(
                    'Check-In Comments',
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  const SizedBox(height: 4),
                  AppTextView.body2(_sheetSeatName(), color: AppColors.textSecondary, fontSize: 13),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppTextView.body3(
                    'Ratings',
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _RatingSummaryBlock(count: badCount, color: const Color(0xFFF04438)),
                      const SizedBox(width: 12),
                      _RatingSummaryBlock(count: improvementCount, color: const Color(0xFFFF8A4C)),
                      const SizedBox(width: 12),
                      _RatingSummaryBlock(count: goodCount, color: const Color(0xFF15B79F)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: mediaItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = mediaItems[index];
                  return _AuditMediaListTile(item: item, onTap: () => onMediaTap(item));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSummaryBlock extends StatelessWidget {
  const _RatingSummaryBlock({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppTextView.body1(
              count.toString(),
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditMediaListTile extends StatelessWidget {
  const _AuditMediaListTile({required this.item, required this.onTap});

  final KaizengramAuditMediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.08), width: 0.8),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.thumbnailUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (item.hasVideo)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.54),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    AppTextView.body1(
                      item.title,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 70,
          child: AppTextView.body2(label, color: AppColors.textSecondary, fontSize: 12),
        ),
        Expanded(child: AppTextView.body2(value, color: AppColors.textPrimary, fontSize: 12)),
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status, required this.postCategory});

  final String status;
  final KaizengramPostCategory postCategory;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _resolveTrackStatusStyle(status, postCategory);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 70,
          child: AppTextView.body2('Status ', color: AppColors.textSecondary, fontSize: 12),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.4),
          decoration: BoxDecoration(
            color: statusStyle.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusStyle.borderColor, width: 1),
          ),
          child: AppTextView.body3(
            status,
            color: statusStyle.textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  _TrackStatusStyle _resolveTrackStatusStyle(String status, KaizengramPostCategory postCategory) {
    final normalized = CustomFunctions.normalizedStatus(status).replaceAll('-', ' ');

    if (postCategory == KaizengramPostCategory.learningCompliance) {
      if (normalized == 'compliant') {
        return const _TrackStatusStyle(
          backgroundColor: Color(0xFFE3F8F4),
          borderColor: AppColors.green1,
          textColor: AppColors.green1,
        );
      }

      if (normalized == 'non compliance') {
        return const _TrackStatusStyle(
          backgroundColor: Color(0xFFFFE1E1),
          borderColor: AppColors.red,
          textColor: AppColors.red,
        );
      }

      if (normalized == 'in progress') {
        return const _TrackStatusStyle(
          backgroundColor: Color(0xFFF0E9FF),
          borderColor: AppColors.purple1,
          textColor: AppColors.purple1,
        );
      }
    }

    if (postCategory == KaizengramPostCategory.documentCompliance) {
      if (normalized == 'pending approval') {
        return const _TrackStatusStyle(
          backgroundColor: Color(0xFFF0E9FF),
          borderColor: AppColors.purple1,
          textColor: AppColors.purple1,
        );
      }

      if (normalized == 'pending submission') {
        return const _TrackStatusStyle(
          backgroundColor: Color(0xFFE8F2FF),
          borderColor: Color(0xFF2F80ED),
          textColor: Color(0xFF2F80ED),
        );
      }

      if (normalized == 'compliant') {
        return const _TrackStatusStyle(
          backgroundColor: Color(0xFFE3F8F4),
          borderColor: AppColors.green1,
          textColor: AppColors.green1,
        );
      }

      if (normalized == 'rejected') {
        return const _TrackStatusStyle(
          backgroundColor: Color(0xFFFFE1E1),
          borderColor: AppColors.red,
          textColor: AppColors.red,
        );
      }
    }

    if (normalized == 'excellent' ||
        normalized == 'good' ||
        CustomFunctions.isPassedStatus(normalized)) {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFE3F8F4),
        borderColor: AppColors.green1,
        textColor: AppColors.green1,
      );
    }

    if (normalized == 'bad' ||
        normalized == 'rejected' ||
        normalized == 'non compliant' ||
        CustomFunctions.isFailedStatus(normalized) ||
        CustomFunctions.isCancelledStatus(normalized)) {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFFFE1E1),
        borderColor: AppColors.red,
        textColor: AppColors.red,
      );
    }

    if (normalized == 'needs improvement' ||
        normalized == 'due' ||
        normalized == 'due by' ||
        normalized == 'pending submission' ||
        CustomFunctions.isPendingStatus(normalized) ||
        CustomFunctions.isPendingApprovalStatus(normalized) ||
        postCategory == KaizengramPostCategory.audit && normalized == 'improvement needed') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFFFE8D9),
        borderColor: AppColors.orange1,
        textColor: AppColors.orange1,
      );
    }

    if (CustomFunctions.isNoLongerNeededStatus(normalized)) {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFE4E7EC),
        borderColor: AppColors.grey1,
        textColor: AppColors.grey2,
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
