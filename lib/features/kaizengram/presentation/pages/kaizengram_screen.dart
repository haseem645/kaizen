import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../routes/app_router.dart';
import '../../../compliance/presentation/widgets/compliance_video_player.dart';
import '../../data/datasources/kaizengram_remote_data_source.dart';
import '../chat/chat_strings.dart';
import '../chat/pages/kaizengram_channels_screen.dart';
import '../chat/pages/kaizengram_chat_screen.dart';
import '../chat/providers/kaizengram_chat_controller.dart';
import '../chat/widgets/chat_mention_text.dart';
import '../chat/widgets/chat_video_preview.dart';
import '../chat/widgets/share_post_bottom_sheet.dart';
import '../kaizengram_message_attachment.dart';
import '../providers/kaizengram_controller.dart';
import '../widgets/kaizengram_full_screen_attachment_view.dart';
import '../widgets/kaizengram_link_preview_card.dart';
import '../widgets/kaizengram_link_utils.dart';
import 'notifications/kaizengram_notifications_screen.dart';

class KaizenGramScreen extends StatelessWidget {
  const KaizenGramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProxyProvider<AppManager, KaizengramController>(
      create: (context) => KaizengramController(
        KaizengramRemoteDataSource(),
        currentUser: context.read<AppManager>().currentUser,
      )..initialize(),
      update: (_, appManager, controller) {
        controller!.syncCurrentUser(appManager.currentUser);
        return controller;
      },
      child: const _KaizenGramView(),
    );
  }
}

class _KaizenGramView extends StatefulWidget {
  const _KaizenGramView();

  @override
  State<_KaizenGramView> createState() => _KaizenGramViewState();
}

class _KaizenGramViewState extends State<_KaizenGramView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final KaizengramChatController _chatController;
  final ImagePicker _composeImagePicker = ImagePicker();
  final ScrollController _mixedFeedScrollController = ScrollController();
  final ScrollController _auditFeedScrollController = ScrollController();
  final ScrollController _learningFeedScrollController = ScrollController();
  final ScrollController _documentFeedScrollController = ScrollController();
  final Map<String, GlobalKey> _postKeys = <String, GlobalKey>{};
  var _isPickingComposeImage = false;

  static const List<_PowerListEntry> _powerListEntriesFirstHalf =
      <_PowerListEntry>[
        _PowerListEntry(
          title: AppStrings.kaizengramLearningCompliancesTitle,
          value: AppStrings.kaizengramLearningCompliancesDue,
          icon: Icons.school_rounded,
          accentColor: Color(0xFF25D7C2),
          destination: _PowerListDestination.learningCompliance,
        ),
        _PowerListEntry(
          title: AppStrings.kaizengramDocumentCompliancesTitle,
          value: AppStrings.kaizengramDocumentCompliancesPending,
          icon: Icons.description_rounded,
          accentColor: Color(0xFFFFB547),
          destination: _PowerListDestination.documentCompliance,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _chatController = KaizengramChatController();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _chatController.dispose();
    _tabController.dispose();
    _mixedFeedScrollController.dispose();
    _auditFeedScrollController.dispose();
    _learningFeedScrollController.dispose();
    _documentFeedScrollController.dispose();
    super.dispose();
  }

  static const List<_PowerListEntry> _powerListEntriesSecondHalf =
      <_PowerListEntry>[
        _PowerListEntry(
          title: AppStrings.kaizengramCheckInsTitle,
          value: AppStrings.kaizengramCheckInsActive,
          icon: Icons.fact_check_rounded,
          accentColor: Color(0xFF7EA6FF),
          destination: _PowerListDestination.audit,
        ),
        _PowerListEntry(
          title: AppStrings.kaizengramCheckInReportsTitle,
          value: AppStrings.kaizengramCheckInReportsReady,
          icon: Icons.assignment_turned_in_rounded,
          accentColor: Color(0xFFFF7D7D),
          destination: _PowerListDestination.audit,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KaizengramController>();
    final unreadNotificationCount = controller.unreadNotificationCount;

    return DrawerMainScreen(
      title: AppStrings.homeKaizengram,
      selectedMenu: AppMenuType.home,
      appBarActions: _buildAppBarActions(context, unreadNotificationCount),
      child: _buildScreenBody(context, controller),
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    int unreadNotificationCount,
  ) {
    return <Widget>[
      _buildChatAction(context),
      _buildNotificationAction(context, unreadNotificationCount),
    ];
  }

  Widget _buildChatAction(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _openChat(context),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.forum_rounded),
        ),
      ),
    );
  }

  Widget _buildNotificationAction(
    BuildContext context,
    int unreadNotificationCount,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _openNotifications(context),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: _NotificationActionIcon(
            unreadNotificationCount: unreadNotificationCount,
          ),
        ),
      ),
    );
  }

  Widget _buildScreenBody(
    BuildContext context,
    KaizengramController controller,
  ) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF252A40), Color(0xFF1B1F31)],
        ),
      ),
      child: controller.isLoading
          ? Center(child: FastCircularProgressIndicator())
          : _buildFeedBody(context, controller),
    );
  }

  Widget _buildFeedBody(BuildContext context, KaizengramController controller) {
    return controller.useSeparateFeedDemo
        ? showSeparateFeed(context, controller)
        : showMixedFeed(context, controller);
  }

  Widget showMixedFeed(BuildContext context, KaizengramController controller) {
    return RefreshIndicator(
      color: AppColors.secondaryColor,
      onRefresh: () =>
          context.read<KaizengramController>().initialize(forceRefresh: true),
      child: ListView(
        controller: _mixedFeedScrollController,
        padding: const EdgeInsets.only(bottom: 20),
        children: <Widget>[
          _buildComposeHeader(context, controller),
          _buildStoriesRow(context, controller),
          ..._buildFeedStateChildren(controller),
          ..._buildMixedFeedChildren(context, controller),
        ],
      ),
    );
  }

  Widget showSeparateFeed(
    BuildContext context,
    KaizengramController controller,
  ) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final category = controller.categoryForTabIndex(_tabController.index);
        final posts = controller.postsForCategory(category);

        return _FeedTabList(
          posts: posts,
          onRefresh: () => context.read<KaizengramController>().initialize(
            forceRefresh: true,
          ),
          scrollController: _scrollControllerFor(category),
          itemBuilder: (post) => _buildPostCard(context, controller, post),
          children: _buildSeparateFeedContent(
            context,
            controller,
            posts: posts,
            category: category,
          ),
        );
      },
    );
  }

  List<Widget> _buildSeparateFeedContent(
    BuildContext context,
    KaizengramController controller, {
    required List<KaizengramFeedItem> posts,
    required KaizengramPostCategory category,
  }) {
    final children = <Widget>[
      _buildComposeHeader(context, controller),
      _buildStoriesRow(context, controller),
      _buildFeedTabs(),
      const SizedBox(height: 12),
    ];

    if (controller.errorMessage != null && controller.posts.isEmpty) {
      children.add(
        const _FeedStateMessage(
          message: AppStrings.kaizengramMessageUnableLoadFeed,
        ),
      );
      return children;
    }

    if (controller.posts.isEmpty) {
      children.add(
        const _FeedStateMessage(
          message: AppStrings.kaizengramMessageNoFeedItems,
        ),
      );
      return children;
    }

    if (category == KaizengramPostCategory.audit) {
      children.addAll(
        _buildWeeklyCheckInFeedChildren(context, controller, posts),
      );
      return children;
    }

    if (posts.isEmpty) {
      children.add(
        const _FeedStateMessage(
          message: 'No feed items are available in this tab.',
        ),
      );
      return children;
    }

    children.addAll(
      posts.map((post) => _buildPostCard(context, controller, post)),
    );
    return children;
  }

  Widget _buildFeedTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        tabAlignment: TabAlignment.fill,
        labelPadding: const EdgeInsets.only(top: 3),
        indicator: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.mainBg,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        tabs: const <Widget>[
          SizedBox(
            height: 32,
            child: Tab(text: AppStrings.kaizengramTabWeeklyCheckIn),
          ),
          SizedBox(
            height: 32,
            child: Tab(text: AppStrings.kaizengramTabLearning),
          ),
          SizedBox(
            height: 32,
            child: Tab(text: AppStrings.kaizengramTabDocument),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyCheckInFeedChildren(
    BuildContext context,
    KaizengramController controller,
    List<KaizengramFeedItem> posts,
  ) {
    final widgets = <Widget>[];
    for (final socialPost in controller.socialPosts) {
      widgets.add(_buildSocialPostCard(context, controller, socialPost));
    }
    var socialPostIndex = 0;

    for (var index = 0; index < posts.length; index++) {
      widgets.add(_buildPostCard(context, controller, posts[index]));

      final afterPostCount = index + 1;
      final shouldInsertSocialPost =
          socialPostIndex < controller.seededWeeklyCheckInSocialPosts.length &&
          controller.weeklyCheckInSocialInsertAfterCounts.contains(
            afterPostCount,
          );
      if (!shouldInsertSocialPost) {
        continue;
      }

      final socialPost =
          controller.seededWeeklyCheckInSocialPosts[socialPostIndex];
      widgets.add(_buildSocialPostCard(context, controller, socialPost));
      socialPostIndex++;
    }

    return widgets;
  }

  Widget _buildComposeHeader(
    BuildContext context,
    KaizengramController controller,
  ) {
    return _KaizengramComposeHeader(
      displayName: controller.currentUserDisplayName,
      imageUrl: controller.currentUserImageUrl,
      isPickingImage: _isPickingComposeImage,
      onTap: () => _openCreatePostSheet(context),
      onImageTap: _pickComposeImageAndOpenSheet,
    );
  }

  Widget _buildStoriesRow(
    BuildContext context,
    KaizengramController controller,
  ) {
    return ListenableBuilder(
      listenable: _chatController,
      builder: (context, _) {
        return _StoriesRow(
          stories: _storyEntries(controller),
          onStoryTap: (story) => _handleStoryTap(context, controller, story),
        );
      },
    );
  }

  List<_StoryEntry> _storyEntries(KaizengramController controller) {
    final channelStories = _chatController.channels
        .map(
          (channel) => _StoryEntry.channel(
            id: 'channel-${channel.name}',
            name: _displayStoryChannelName(channel.name),
            channelName: channel.name,
            imagePath: channel.imagePath,
          ),
        )
        .toList(growable: false);
    final feedStories = controller.stories
        .map(
          (story) => _StoryEntry.feed(
            id: story.id,
            name: story.name,
            imagePath: story.avatarUrl,
          ),
        )
        .toList(growable: false);
    return <_StoryEntry>[...channelStories, ...feedStories];
  }

  String _displayStoryChannelName(String channelName) {
    final normalizedChannelName = channelName.trim().replaceFirst('#', '');
    if (normalizedChannelName.isEmpty) {
      return channelName;
    }

    return normalizedChannelName
        .split(RegExp(r'[-_\s]+'))
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<void> _handleStoryTap(
    BuildContext context,
    KaizengramController controller,
    _StoryEntry story,
  ) async {
    if (story.isChannel) {
      await _openChatChannel(context, story.channelName!);
      return;
    }

    final post = controller.postById(story.id);
    if (post == null) {
      return;
    }

    await _openPost(context, post);
  }

  List<Widget> _buildFeedStateChildren(KaizengramController controller) {
    return <Widget>[
      if (controller.errorMessage != null && controller.posts.isEmpty)
        const _FeedStateMessage(
          message: AppStrings.kaizengramMessageUnableLoadFeed,
        ),
      if (controller.posts.isEmpty && controller.errorMessage == null)
        const _FeedStateMessage(
          message: AppStrings.kaizengramMessageNoFeedItems,
        ),
    ];
  }

  Widget _buildPostCard(
    BuildContext context,
    KaizengramController controller,
    KaizengramFeedItem post,
  ) {
    return KeyedSubtree(
      key: _postKeyFor(post.id),
      child: _PostCard(
        post: post,
        onTap: () => _openPost(context, post),
        onLikeTap: () => controller.toggleLike(post.id),
        onCommentTap: () => _openComments(context, post),
        onShareTap: () => _sharePost(context, post),
        onAuditMediaTap: (selectedMediaItem) {
          _showCommentsThreadSheet(
            context,
            post,
            selectedAuditMediaItem: selectedMediaItem,
          );
        },
      ),
    );
  }

  List<Widget> _buildMixedFeedChildren(
    BuildContext context,
    KaizengramController controller,
  ) {
    final widgets = <Widget>[];
    for (final socialPost in controller.socialPosts) {
      widgets.add(_buildSocialPostCard(context, controller, socialPost));
    }
    final firstInsertionIndex = controller.posts.length > 1 ? 2 : 1;
    final secondInsertionIndex = controller.posts.length > 4 ? 5 : null;

    for (var index = 0; index < controller.posts.length; index++) {
      final post = controller.posts[index];
      widgets.add(_buildPostCard(context, controller, post));

      if (index + 1 == firstInsertionIndex) {
        widgets.add(
          const _PowerListCard(
            title: AppStrings.kaizengramPowerListTitle,
            subtitle: AppStrings.kaizengramPowerListSubtitle,
            entries: _powerListEntriesFirstHalf,
            onEntryTap: _handlePowerListTap,
          ),
        );
      }

      if (secondInsertionIndex != null && index + 1 == secondInsertionIndex) {
        widgets.add(
          const _PowerListCard(
            title: AppStrings.kaizengramPowerListContinuedTitle,
            subtitle: AppStrings.kaizengramPowerListContinuedSubtitle,
            entries: _powerListEntriesSecondHalf,
            onEntryTap: _handlePowerListTap,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildSocialPostCard(
    BuildContext context,
    KaizengramController controller,
    KaizengramSocialPost post,
  ) {
    final resolvedPost = controller.resolveSocialPost(post);

    return _WeeklyCheckInSocialTextCard(
      post: resolvedPost,
      loggedInUserName: controller.currentUserDisplayName,
      onInlineCommentSend: (message, attachments) {
        controller.addCurrentUserSocialPostComment(
          post: resolvedPost,
          message: message,
          attachments: attachments,
        );
      },
      onCommentTap: () => _openSocialCommentsSheet(
        context,
        controller,
        resolvedPost,
        controller.currentUserDisplayName,
      ),
    );
  }

  GlobalKey _postKeyFor(String postId) {
    return _postKeys.putIfAbsent(postId, () => GlobalObjectKey(postId));
  }

  Future<void> _openNotifications(BuildContext context) async {
    final selectedNotification = await Navigator.of(context)
        .push<KaizengramNotificationItem>(
          MaterialPageRoute<KaizengramNotificationItem>(
            builder: (_) => ChangeNotifierProvider<KaizengramController>.value(
              value: context.read<KaizengramController>(),
              child: const KaizengramNotificationsScreen(),
            ),
          ),
        );

    if (!context.mounted || selectedNotification == null) {
      return;
    }

    await _handleNotificationSelection(context, selectedNotification);
  }

  Future<void> _openChat(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KaizengramChannelsScreen(controller: _chatController),
      ),
    );
  }

  Future<void> _openChatChannel(BuildContext context, String channelName) {
    _chatController.selectChannel(channelName);
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KaizengramChatScreen(controller: _chatController),
      ),
    );
  }

  Future<void> _sharePost(BuildContext context, KaizengramFeedItem post) async {
    final conversation =
        await showModalBottomSheet<KaizengramChatConversationTarget>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              ShareKaizengramPostBottomSheet(controller: _chatController),
        );

    if (conversation == null || !context.mounted) {
      return;
    }

    final didSend = _chatController.sendPresetMessage(
      conversation: conversation,
      message: _buildSharedPostMessage(post),
    );
    if (!didSend || !context.mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KaizengramChatScreen(controller: _chatController),
      ),
    );
  }

  String _buildSharedPostMessage(KaizengramFeedItem post) {
    final lines = <String>[
      KaizengramChatStrings.sharePostOriginLabel,
      post.title.trim(),
    ];
    final contextLine = _buildSharedPostContextLine(post);
    if (contextLine != null) {
      lines.add(contextLine);
    }

    final summary = _sharedPostSummary(post);
    if (summary != null) {
      lines
        ..add('')
        ..add(summary);
    }

    final shareableLinks = _shareableLinksForPost(post);
    if (shareableLinks.isNotEmpty) {
      lines.add('');
      for (final link in shareableLinks) {
        lines.add('${KaizengramChatStrings.sharePostLinkLabel}: $link');
      }
    }

    return lines.join('\n');
  }

  String? _buildSharedPostContextLine(KaizengramFeedItem post) {
    final parts = <String>[];
    final seatProfile = post.seatProfile.trim();
    final title = post.title.trim();
    final status = post.status?.trim();
    final dueBy = post.dueBy?.trim();

    if (seatProfile.isNotEmpty && seatProfile != title) {
      parts.add(seatProfile);
    }

    if (status != null && status.isNotEmpty) {
      parts.add(status);
    } else if (dueBy != null && dueBy.isNotEmpty) {
      parts.add(dueBy);
    }

    return parts.isEmpty ? null : parts.join(' • ');
  }

  String? _sharedPostSummary(KaizengramFeedItem post) {
    final description = _resolvedPostDescription(post)?.trim();
    if (description == null || description.isEmpty) {
      return null;
    }

    const maxLength = 180;
    if (description.length <= maxLength) {
      return description;
    }

    return '${description.substring(0, maxLength).trimRight()}...';
  }

  List<String> _shareableLinksForPost(KaizengramFeedItem post) {
    final links = <String>[];
    final previewCandidates = <String?>[
      _buildTrackAssignmentShareUrl(post.trackAssignmentUuid),
      post.documentPreviewUrl,
      post.feedVideoUrl,
      post.feedImageUrl,
    ];

    for (final candidate in previewCandidates) {
      final resolvedLink = candidate == null
          ? null
          : CustomFunctions.resolveNetworkUrl(candidate);
      if (resolvedLink == null || links.contains(resolvedLink)) {
        continue;
      }

      links.add(resolvedLink);
    }

    return List<String>.unmodifiable(links);
  }

  String? _buildTrackAssignmentShareUrl(String? rawTrackAssignmentUuid) {
    final trackAssignmentUuid = rawTrackAssignmentUuid?.trim();
    if (trackAssignmentUuid == null || trackAssignmentUuid.isEmpty) {
      return null;
    }

    final apiUri = Uri.tryParse(ApiEndPoints.baseUrl);
    final scheme = apiUri?.scheme.isNotEmpty == true ? apiUri!.scheme : 'https';
    final host = _shareableTrackHost(apiUri?.host);
    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: <String>['ltc', 'assigned-track', trackAssignmentUuid],
    ).toString();
  }

  String _shareableTrackHost(String? apiHost) {
    switch (apiHost?.toLowerCase()) {
      case 'dev-api.kaizenteams.ai':
      case 'dev.kaizenteams.ai':
        return 'dev.kaizenteams.ai';
      case 'api.kaizenteams.ai':
        return 'api.kaizenteams.ai';
      default:
        return 'dev.kaizenteams.ai';
    }
  }

  Future<void> _pickComposeImageAndOpenSheet() async {
    if (_isPickingComposeImage) {
      return;
    }

    setState(() {
      _isPickingComposeImage = true;
    });

    try {
      final pickedImage = await _composeImagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedImage == null || !mounted) {
        return;
      }

      await _openCreatePostSheet(context, initialImagePath: pickedImage.path);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(AppStrings.kaizengramErrorPickImageFailed),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingComposeImage = false;
        });
      } else {
        _isPickingComposeImage = false;
      }
    }
  }

  Future<void> _openCreatePostSheet(
    BuildContext context, {
    String? initialImagePath,
  }) {
    final controller = context.read<KaizengramController>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _CreateSocialPostBottomSheet(
        authorName: controller.currentUserDisplayName,
        avatarUrl: controller.currentUserImageUrl,
        initialImagePath: initialImagePath,
        onPostSubmitted: (message, imagePath) {
          controller.createCurrentUserSocialPost(
            message: message,
            mediaImagePath: imagePath,
          );
          if (controller.useSeparateFeedDemo && _tabController.index != 0) {
            _tabController.animateTo(0);
          }
        },
      ),
    );
  }

  Future<void> _handleNotificationSelection(
    BuildContext context,
    KaizengramNotificationItem notification,
  ) async {
    final controller = context.read<KaizengramController>();
    final post = controller.postById(notification.post.id);
    if (post == null) {
      return;
    }

    await _focusPostInFeed(controller, post);
    if (!context.mounted) {
      return;
    }

    if (notification.type == KaizengramNotificationType.commented) {
      await _showCommentsThreadSheet(
        context,
        post,
        highlightCommentId: notification.targetCommentId,
      );
    }
  }

  Future<void> _focusPostInFeed(
    KaizengramController controller,
    KaizengramFeedItem post,
  ) async {
    if (!controller.useSeparateFeedDemo) {
      await _scrollToPost(
        controller: controller,
        posts: controller.posts,
        post: post,
        scrollController: _mixedFeedScrollController,
      );
      return;
    }

    _tabController.animateTo(
      controller.tabIndexForCategory(post.resolvedPostCategory),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) {
      return;
    }

    await _scrollToPost(
      controller: controller,
      posts: controller.postsForCategory(post.resolvedPostCategory),
      post: post,
      scrollController: _scrollControllerFor(post.resolvedPostCategory),
    );
  }

  ScrollController _scrollControllerFor(KaizengramPostCategory category) {
    switch (category) {
      case KaizengramPostCategory.audit:
        return _auditFeedScrollController;
      case KaizengramPostCategory.learningCompliance:
        return _learningFeedScrollController;
      case KaizengramPostCategory.documentCompliance:
        return _documentFeedScrollController;
    }
  }

  Future<void> _scrollToPost({
    required KaizengramController controller,
    required List<KaizengramFeedItem> posts,
    required KaizengramFeedItem post,
    required ScrollController scrollController,
  }) async {
    final postIndex = posts.indexWhere((item) => item.id == post.id);
    if (postIndex == -1) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted || !scrollController.hasClients) {
      return;
    }

    final insertedCardOffset =
        post.resolvedPostCategory == KaizengramPostCategory.audit
        ? controller.weeklyCheckInSocialCardCountBefore(postIndex) * 196
        : 0;
    final estimatedOffset =
        ((controller.estimatedPostExtent(post) * postIndex) +
                insertedCardOffset)
            .clamp(0.0, scrollController.position.maxScrollExtent)
            .toDouble();
    scrollController.jumpTo(estimatedOffset);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) {
      return;
    }

    final targetContext = _postKeyFor(post.id).currentContext;
    if (targetContext != null && targetContext.mounted) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.04,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _openComments(
    BuildContext context,
    KaizengramFeedItem post,
  ) async {
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
    String? highlightCommentId,
  }) {
    final comments = context.read<KaizengramController>().commentThreadForPost(
      post,
      selectedAuditMediaItem: selectedAuditMediaItem,
    );

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
        highlightCommentId: highlightCommentId,
      ),
    );
  }

  Future<void> _showAuditMediaSheet(
    BuildContext context,
    KaizengramFeedItem post,
  ) {
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

            _showCommentsThreadSheet(
              context,
              post,
              selectedAuditMediaItem: selectedMediaItem,
            );
          });
        },
      ),
    );
  }

  Future<void> _openSocialCommentsSheet(
    BuildContext context,
    KaizengramController controller,
    KaizengramSocialPost post,
    String loggedInUserName,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => ChangeNotifierProvider<KaizengramController>.value(
        value: controller,
        child: _SocialPostCommentsBottomSheet(
          post: post,
          loggedInUserName: loggedInUserName,
        ),
      ),
    );
  }

  static Future<void> _handlePowerListTap(
    BuildContext context,
    _PowerListEntry entry,
  ) async {
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
            ..showSnackBar(
              const SnackBar(
                content: Text(AppStrings.kaizengramErrorCannotAccessCompliance),
              ),
            );
          return;
        }

        if (post.status != null &&
            CustomFunctions.isCancelledStatus(post.status!)) {
          CustomFunctions.showCustomAlert(
            context,
            AppStrings.kaizengramErrorRestrictedTitle,
            AppStrings.kaizengramErrorCannotAccessCompliance,
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

class _NotificationActionIcon extends StatelessWidget {
  const _NotificationActionIcon({required this.unreadNotificationCount});

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

List<KaizengramAuditMediaItem> _buildAuditThreadItems(KaizengramFeedItem post) {
  if (post.resolvedPostCategory != KaizengramPostCategory.audit ||
      post.commentThread.isEmpty) {
    return post.auditMediaItems;
  }

  return List<KaizengramAuditMediaItem>.unmodifiable(<KaizengramAuditMediaItem>[
    ...post.auditMediaItems,
    KaizengramAuditMediaItem(
      id: '${post.id}-thread-no-image',
      title: AppStrings.kaizengramNoImageThreadTitle,
      thumbnailUrl: '',
      rating: _resolveAuditThreadRating(post.status),
      commentThread: post.commentThread,
    ),
  ]);
}

KaizengramAuditRating _resolveAuditThreadRating(String? status) {
  final normalizedStatus = status?.trim().toLowerCase();
  if (normalizedStatus == null || normalizedStatus.isEmpty) {
    return KaizengramAuditRating.good;
  }
  if (normalizedStatus.contains('bad')) {
    return KaizengramAuditRating.bad;
  }
  if (normalizedStatus.contains('need')) {
    return KaizengramAuditRating.needsImprovement;
  }
  return KaizengramAuditRating.good;
}

String? _resolvedPostDescription(KaizengramFeedItem post) {
  final description = CustomFunctions.resolvedText(post.description);
  if (description == null || description == post.status) {
    return null;
  }

  return description;
}

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
  final Future<void> Function(BuildContext context, _PowerListEntry entry)
  onEntryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF20253A),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
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
                    AppTextView.body2(
                      subtitle,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...entries.map(
            (entry) => _PowerListRow(
              entry: entry,
              onTap: () => onEntryTap(context, entry),
            ),
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
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
            ),
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
                    AppTextView.body2(
                      entry.value,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyCheckInSocialTextCard extends StatelessWidget {
  const _WeeklyCheckInSocialTextCard({
    required this.post,
    required this.loggedInUserName,
    required this.onInlineCommentSend,
    required this.onCommentTap,
  });

  final KaizengramSocialPost post;
  final String loggedInUserName;
  final void Function(
    String message,
    List<KaizengramMessageAttachment> attachments,
  )
  onInlineCommentSend;
  final VoidCallback onCommentTap;

  @override
  Widget build(BuildContext context) {
    final previewComment = post.comments.isEmpty ? null : post.comments.last;
    final previewReply =
        previewComment == null || previewComment.replies.isEmpty
        ? null
        : previewComment.replies.last;
    final hasMessage = post.message.trim().isNotEmpty;
    final hasMediaImage = post.hasMediaImage;

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF20253A),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 21,
                backgroundColor: AppColors.surfaceDark3,
                backgroundImage: NetworkImage(post.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AppTextView.body1(
                      post.authorName,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    const SizedBox(height: 2),
                    AppTextView.body2(
                      '${post.channelName} • ${post.timeLabel}',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasMessage) ...<Widget>[
            const SizedBox(height: 14),
            AppTextView.body1(
              post.message,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ],
          if (hasMediaImage) ...<Widget>[
            SizedBox(height: hasMessage ? 14 : 12),
            _SocialPostMediaPreview(post: post),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: onCommentTap,
                  icon: const Icon(
                    Icons.mode_comment_outlined,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          if (previewComment != null) ...<Widget>[
            const SizedBox(height: 14),
            _SocialPostCommentPreview(
              comment: previewComment,
              reply: previewReply,
              onTap: onCommentTap,
            ),
          ],
          const SizedBox(height: 12),
          _InlineSocialCommentComposer(
            loggedInUserName: loggedInUserName,
            onSend: onInlineCommentSend,
          ),
        ],
      ),
    );
  }
}

class _SocialPostMediaPreview extends StatelessWidget {
  const _SocialPostMediaPreview({required this.post});

  final KaizengramSocialPost post;

  @override
  Widget build(BuildContext context) {
    final mediaImagePath = post.mediaImagePath?.trim();
    final mediaImageUrl = post.mediaImageUrl?.trim();
    Widget imageChild;

    if (mediaImagePath != null && mediaImagePath.isNotEmpty) {
      imageChild = ColoredBox(
        color: AppColors.surfaceDark3,
        child: Image.file(
          File(mediaImagePath),
          fit: BoxFit.contain,
          width: double.infinity,
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
    } else if (mediaImageUrl != null && mediaImageUrl.isNotEmpty) {
      imageChild = ColoredBox(
        color: AppColors.surfaceDark3,
        child: Image.network(
          mediaImageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return Container(
              color: AppColors.surfaceDark3,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: AppColors.secondaryColor,
              ),
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
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(height: 220, width: double.infinity, child: imageChild),
    );
  }
}

class _SocialPostCommentPreview extends StatelessWidget {
  const _SocialPostCommentPreview({
    required this.comment,
    required this.reply,
    required this.onTap,
  });

  final KaizengramComment comment;
  final KaizengramComment? reply;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
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
                        _CommentMessageText(
                          message: comment.message,
                          attachments: comment.attachments,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (reply != null) ...<Widget>[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.textPrimary.withValues(alpha: 0.14),
                          width: 2,
                        ),
                      ),
                    ),
                    child: _ReplyCommentRow(
                      comment: reply!,
                      onReplyTap: (_) => onTap(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentMessageText extends StatelessWidget {
  const _CommentMessageText({
    required this.message,
    required this.style,
    this.attachments = const <KaizengramMessageAttachment>[],
  });

  final String message;
  final TextStyle style;
  final List<KaizengramMessageAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final trimmedMessage = message.trim();
    final hasMessage = trimmedMessage.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasMessage)
          ChatMentionText(
            text: message,
            users: const <KaizengramChatUser>[],
            defaultStyle: style,
          ),
        if (hasMessage) KaizengramTextLinkPreview(text: message),
        if (attachments.isNotEmpty)
          _CommentAttachmentPreviewStrip(
            attachments: attachments,
            onOpenAttachment: (index) {
              final selectedAttachment = attachments[index];
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => KaizengramFullScreenAttachmentView(
                    attachments: attachments,
                    initialIndex: index,
                    autoPlayInitialVideo: selectedAttachment.isVideo,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _InlineSocialCommentComposer extends StatefulWidget {
  const _InlineSocialCommentComposer({
    required this.loggedInUserName,
    required this.onSend,
  });

  final String loggedInUserName;
  final void Function(
    String message,
    List<KaizengramMessageAttachment> attachments,
  )
  onSend;

  @override
  State<_InlineSocialCommentComposer> createState() =>
      _InlineSocialCommentComposerState();
}

class _InlineSocialCommentComposerState
    extends State<_InlineSocialCommentComposer> {
  late final TextEditingController _controller;
  List<KaizengramMessageAttachment> _draftAttachments =
      <KaizengramMessageAttachment>[];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty && _draftAttachments.isEmpty) {
      return;
    }

    widget.onSend(
      message,
      List<KaizengramMessageAttachment>.unmodifiable(_draftAttachments),
    );
    _controller.clear();
    setState(() {
      _draftAttachments = <KaizengramMessageAttachment>[];
    });
  }

  Future<void> _pickAttachments() async {
    final availableSlots =
        kaizengramMessageAttachmentLimit - _draftAttachments.length;
    if (availableSlots <= 0) {
      _showAttachmentSnackBar(KaizengramChatStrings.mediaLimitError);
      return;
    }

    try {
      final source = await KaizengramMessageAttachmentPicker.pickSource(
        context,
      );
      if (!mounted || source == null) {
        return;
      }

      final nextAttachments = await KaizengramMessageAttachmentPicker.pick(
        source: source,
        availableSlots: availableSlots,
        existingPaths: _draftAttachments.map((attachment) => attachment.path),
      );
      if (!mounted || nextAttachments.isEmpty) {
        return;
      }

      setState(() {
        _draftAttachments = <KaizengramMessageAttachment>[
          ..._draftAttachments,
          ...nextAttachments,
        ];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showAttachmentSnackBar(KaizengramChatStrings.pickMediaError);
    }
  }

  void _removeAttachment(String attachmentPath) {
    setState(() {
      _draftAttachments = _draftAttachments
          .where((attachment) => attachment.path != attachmentPath)
          .toList(growable: false);
    });
  }

  void _openAttachmentViewer(int index) {
    if (_draftAttachments.isEmpty) {
      return;
    }

    final selectedAttachment = _draftAttachments[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KaizengramFullScreenAttachmentView(
          attachments: _draftAttachments,
          initialIndex: index,
          autoPlayInitialVideo: selectedAttachment.isVideo,
        ),
      ),
    );
  }

  void _showAttachmentSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        _controller.text.trim().isNotEmpty || _draftAttachments.isNotEmpty;
    final draftText = _controller.text;
    final hasLinkPreview = kaizengramFirstLinkInText(draftText) != null;
    final currentUserComment = KaizengramComment(
      id: 'social-comment-preview-${widget.loggedInUserName}',
      authorName: widget.loggedInUserName,
      message: '',
      timestampLabel: '',
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (_draftAttachments.isNotEmpty) ...<Widget>[
          _CommentAttachmentPreviewStrip(
            attachments: _draftAttachments,
            removable: true,
            onOpenAttachment: _openAttachmentViewer,
            onRemoveAttachment: _removeAttachment,
          ),
          const SizedBox(height: 10),
        ],
        if (hasLinkPreview) ...<Widget>[
          KaizengramTextLinkPreview(text: draftText, topSpacing: 0),
          const SizedBox(height: 10),
        ],
        Row(
          children: <Widget>[
            _CommentAvatar(comment: currentUserComment),
            const SizedBox(width: 10),
            _CommentComposerActionButton(
              onTap: _pickAttachments,
              icon: Icons.attach_file_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  cursorHeight: 15,
                  cursorColor: AppColors.textPrimary,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.commentAsUser(widget.loggedInUserName),
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _CommentComposerSendButton(
              onTap: canSend ? _handleSend : null,
              canSend: canSend,
            ),
          ],
        ),
      ],
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
  const _FeedTabList({
    required this.posts,
    required this.onRefresh,
    required this.scrollController,
    required this.itemBuilder,
    this.children,
  });

  final List<KaizengramFeedItem> posts;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final Widget Function(KaizengramFeedItem post) itemBuilder;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.secondaryColor,
      onRefresh: onRefresh,
      child: children != null
          ? ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              children: children!,
            )
          : posts.isEmpty
          ? ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: const <Widget>[
                _FeedStateMessage(
                  message: 'No feed items are available in this tab.',
                ),
              ],
            )
          : ListView.separated(
              controller: scrollController,
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
  const _StoriesRow({required this.stories, required this.onStoryTap});

  final List<_StoryEntry> stories;
  final ValueChanged<_StoryEntry> onStoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 1),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.64),
        border: Border(
          bottom: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final story = stories[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onStoryTap(story),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(2.4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFFF9CE34),
                              Color(0xFFEE2A7B),
                              Color(0xFF6228D7),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.surfaceDark,
                          child: _StoryAvatar(story: story),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 16,
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
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.story});

  final _StoryEntry story;

  @override
  Widget build(BuildContext context) {
    final imagePath = story.imagePath?.trim();
    if (imagePath != null && imagePath.isNotEmpty) {
      final networkUrl = CustomFunctions.resolveNetworkUrl(imagePath);
      final ImageProvider<Object> imageProvider = networkUrl != null
          ? NetworkImage(networkUrl)
          : FileImage(File(imagePath));
      return CircleAvatar(radius: 25, backgroundImage: imageProvider);
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor: AppColors.surfaceDark3,
      child: Icon(
        story.isChannel ? Icons.tag_rounded : Icons.image_outlined,
        color: story.isChannel
            ? AppColors.secondaryColor
            : AppColors.textSecondary,
        size: story.isChannel ? 22 : 20,
      ),
    );
  }
}

enum _StoryEntryKind { feed, channel }

class _StoryEntry {
  const _StoryEntry.feed({required this.id, required this.name, this.imagePath})
    : kind = _StoryEntryKind.feed,
      channelName = null;

  const _StoryEntry.channel({
    required this.id,
    required this.name,
    required this.channelName,
    this.imagePath,
  }) : kind = _StoryEntryKind.channel;

  final String id;
  final String name;
  final String? imagePath;
  final String? channelName;
  final _StoryEntryKind kind;

  bool get isChannel => kind == _StoryEntryKind.channel;
}

class _KaizengramComposeHeader extends StatelessWidget {
  const _KaizengramComposeHeader({
    required this.displayName,
    required this.imageUrl,
    required this.isPickingImage,
    required this.onTap,
    required this.onImageTap,
  });

  final String displayName;
  final String? imageUrl;
  final bool isPickingImage;
  final VoidCallback onTap;
  final VoidCallback onImageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _ComposerHeaderAvatar(
                displayName: displayName,
                imageUrl: imageUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: AppTextView.body2(
                        AppStrings.kaizengramComposePrompt,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: AppStrings.kaizengramButtonUploadImage,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isPickingImage ? null : onImageTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: isPickingImage
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.textPrimary,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppTextView.body4(
            AppStrings.kaizengramComposeSubtitle,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _ComposerHeaderAvatar extends StatelessWidget {
  const _ComposerHeaderAvatar({
    required this.displayName,
    required this.imageUrl,
  });

  final String displayName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initials = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.16),
      backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      child: imageUrl != null
          ? null
          : AppTextView.body3(
              initials.isEmpty ? 'Y' : initials,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
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
    required this.onShareTap,
    required this.onAuditMediaTap,
  });

  final KaizengramFeedItem post;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final ValueChanged<KaizengramAuditMediaItem> onAuditMediaTap;

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
    final headerAvatarUrl = post.postHeaderAvatarUrl;

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
                    headerAvatarUrl == null
                        ? const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceDark3,
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          )
                        : CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(headerAvatarUrl),
                          ),
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
                  ],
                ),
              ),
              _PostMediaSection(
                post: post,
                onAuditMediaTap: widget.onAuditMediaTap,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: widget.onLikeTap,
                      icon: Icon(
                        post.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: post.isLiked
                            ? const Color(0xFFFF4D67)
                            : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCommentTap,
                      icon: const Icon(
                        Icons.mode_comment_outlined,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onShareTap,
                      icon: const Icon(
                        Icons.send_outlined,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.bookmark_border_rounded,
                        color: AppColors.textPrimary,
                      ),
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
                      _StatusLine(
                        status: post.status!,
                        postCategory: post.resolvedPostCategory,
                      ),
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
    return _resolvedPostDescription(post);
  }

  List<Widget> _buildMetaSection(KaizengramFeedItem post) {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit) {
      return <Widget>[
        _MetaLine(
          label: 'Audited At',
          value: post.auditedAt ?? post.timestampLabel,
        ),
        const SizedBox(height: 6),
        _MetaLine(
          label: AppStrings.kaizengramLabelAuditedBy,
          value: _headerRelationName(post),
        ),
      ];
    }

    return <Widget>[
      _MetaLine(label: 'Seat ', value: post.departmentName ?? post.seatProfile),
      if ((post.dueBy ?? post.deadlineDate)?.trim().isNotEmpty ==
          true) ...<Widget>[
        const SizedBox(height: 6),
        _MetaLine(
          label: 'Due By ',
          value: post.dueBy?.trim().isNotEmpty == true
              ? post.dueBy!
              : post.deadlineDate!,
        ),
      ],
    ];
  }

  String _headerRelationLabel(KaizengramFeedItem post) {
    return post.resolvedPostCategory == KaizengramPostCategory.audit
        ? AppStrings.kaizengramLabelAuditedBy
        : AppStrings.kaizengramLabelAssignedBy;
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
  const _PostMediaSection({required this.post, required this.onAuditMediaTap});

  final KaizengramFeedItem post;
  final ValueChanged<KaizengramAuditMediaItem> onAuditMediaTap;

  @override
  Widget build(BuildContext context) {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit &&
        post.auditMediaItems.isNotEmpty) {
      return _AuditPostMediaPager(
        mediaItems: post.auditMediaItems,
        onMediaTap: onAuditMediaTap,
      );
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

    if (post.resolvedPostCategory ==
            KaizengramPostCategory.documentCompliance &&
        post.feedImageUrl == null) {
      return const AspectRatio(aspectRatio: 1, child: _UploadDocPlaceholder());
    }

    return AspectRatio(
      aspectRatio: 1,
      child: _NetworkPostImage(imageUrl: post.feedImageUrl),
    );
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
  const _AuditPostMediaPager({
    required this.mediaItems,
    required this.onMediaTap,
  });

  final List<KaizengramAuditMediaItem> mediaItems;
  final ValueChanged<KaizengramAuditMediaItem> onMediaTap;

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
      return _AuditPostMediaPage(
        item: mediaItems.first,
        onTap: () => widget.onMediaTap(mediaItems.first),
      );
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
                  return _AuditPostMediaPage(
                    item: mediaItems[index],
                    onTap: () => widget.onMediaTap(mediaItems[index]),
                  );
                },
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
    const toggleStyle = TextStyle(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
    );
    final maxWidth = MediaQuery.sizeOf(context).width - 32;
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final shouldShowToggle = textPainter.didExceedMaxLines;
    final collapsedText = shouldShowToggle
        ? _collapsedText(
            maxWidth: maxWidth,
            style: textStyle,
            toggleStyle: toggleStyle,
          )
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
  const _AuditPostMediaPage({required this.item, required this.onTap});

  final KaizengramAuditMediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = item.hasVideo && item.videoUrl != null
        ? SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).width,
            child: ComplianceVideoPlayer(
              videoUrl: item.videoUrl!,
              title: item.title,
              thumbnailLink: item.hasThumbnail ? item.thumbnailUrl : null,
              height: MediaQuery.sizeOf(context).width,
              showTitle: false,
              showSeekBar: false,
              showDuration: false,
              fillBounds: true,
            ),
          )
        : AspectRatio(
            aspectRatio: 1,
            child: _NetworkPostImage(
              imageUrl: item.hasThumbnail ? item.thumbnailUrl : null,
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _NetworkPostImage extends StatelessWidget {
  const _NetworkPostImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim();
    if (normalizedImageUrl == null || normalizedImageUrl.isEmpty) {
      return const _NoImageAvailableAsset();
    }

    return Image.network(
      normalizedImageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: AppColors.surfaceDark3,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: AppColors.secondaryColor,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const _NoImageAvailableAsset();
      },
    );
  }
}

class _NoImageAvailableAsset extends StatelessWidget {
  const _NoImageAvailableAsset();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Image.asset(
        '${AppStrings.imagePath}no_image.png',
        fit: BoxFit.contain,
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
          Icon(
            Icons.upload_file_rounded,
            color: AppColors.textSecondary,
            size: 36,
          ),
          SizedBox(height: 10),
          AppTextView.body1(
            AppStrings.kaizengramLabelUploadDoc,
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
    this.highlightCommentId,
  });

  final KaizengramFeedItem post;
  final List<KaizengramComment> comments;
  final KaizengramAuditMediaItem? selectedAuditMediaItem;
  final String? highlightCommentId;

  @override
  State<_CommentsThreadBottomSheet> createState() =>
      _CommentsThreadBottomSheetState();
}

class _CommentsThreadBottomSheetState
    extends State<_CommentsThreadBottomSheet> {
  late final TextEditingController _commentController;
  late final ScrollController _scrollController;
  late final PageController _threadPageController;
  final ImagePicker _imagePicker = ImagePicker();
  late List<KaizengramComment> _comments;
  late final Map<String, List<KaizengramComment>> _pagedCommentsByMediaId;
  final Map<String, GlobalKey> _commentKeys = <String, GlobalKey>{};
  final Map<String, ScrollController> _pagedScrollControllers =
      <String, ScrollController>{};
  List<KaizengramMessageAttachment> _draftAttachments =
      <KaizengramMessageAttachment>[];
  KaizengramComment? _replyingTo;
  String? _highlightedCommentId;
  File? _documentImageFile;
  int _highlightSequence = 0;
  int _currentThreadPage = 0;
  var _isPickingDocumentImage = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _scrollController = ScrollController();
    _comments = List<KaizengramComment>.from(widget.comments);
    _pagedCommentsByMediaId = <String, List<KaizengramComment>>{
      for (final mediaItem in _auditThreadItems)
        mediaItem.id: List<KaizengramComment>.from(mediaItem.commentThread),
    };
    _currentThreadPage = _initialThreadPageIndex();
    _threadPageController = PageController(initialPage: _currentThreadPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToComment(widget.highlightCommentId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _threadPageController.dispose();
    for (final controller in _pagedScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _shouldShowPagedMessages {
    return widget.post.resolvedPostCategory == KaizengramPostCategory.audit &&
        _auditThreadItems.isNotEmpty &&
        widget.selectedAuditMediaItem != null &&
        widget.highlightCommentId == null;
  }

  List<KaizengramAuditMediaItem> get _auditThreadItems =>
      _buildAuditThreadItems(widget.post);

  KaizengramAuditMediaItem get _currentPagedMediaItem {
    final mediaItems = _auditThreadItems;
    final boundedIndex = _currentThreadPage
        .clamp(0, mediaItems.length - 1)
        .toInt();
    return mediaItems[boundedIndex];
  }

  List<KaizengramComment> get _activeComments {
    if (!_shouldShowPagedMessages) {
      return _comments;
    }

    return _commentsForMedia(_currentPagedMediaItem.id);
  }

  ScrollController get _activeScrollController {
    if (!_shouldShowPagedMessages) {
      return _scrollController;
    }

    return _scrollControllerForMedia(_currentPagedMediaItem.id);
  }

  int _initialThreadPageIndex() {
    final selectedMediaItemId = widget.selectedAuditMediaItem?.id;
    if (selectedMediaItemId == null) {
      return 0;
    }

    final selectedIndex = _auditThreadItems.indexWhere(
      (mediaItem) => mediaItem.id == selectedMediaItemId,
    );
    return selectedIndex < 0 ? 0 : selectedIndex;
  }

  List<KaizengramComment> _commentsForMedia(String mediaId) {
    return _pagedCommentsByMediaId[mediaId] ?? const <KaizengramComment>[];
  }

  ScrollController _scrollControllerForMedia(String mediaId) {
    return _pagedScrollControllers.putIfAbsent(mediaId, ScrollController.new);
  }

  void _setActiveComments(List<KaizengramComment> updatedComments) {
    if (_shouldShowPagedMessages) {
      _pagedCommentsByMediaId[_currentPagedMediaItem.id] = updatedComments;
      return;
    }

    _comments = updatedComments;
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
    if (message.isEmpty && _draftAttachments.isEmpty) {
      return;
    }

    String? sentCommentId;
    final updatedComments = List<KaizengramComment>.from(_activeComments);
    final nextAttachments = List<KaizengramMessageAttachment>.unmodifiable(
      _draftAttachments,
    );

    setState(() {
      var didReplyToExistingComment = false;

      if (_replyingTo != null) {
        final target = _replyingTo!;
        final index = updatedComments.indexWhere(
          (comment) => comment.id == target.id,
        );
        if (index != -1) {
          final updatedReplies = List<KaizengramComment>.from(target.replies)
            ..add(
              KaizengramComment(
                id: _nextLocalCommentId(prefix: 'reply'),
                authorName: 'You',
                message: message,
                timestampLabel: 'Now',
                attachments: nextAttachments,
              ),
            );
          sentCommentId = updatedReplies.last.id;
          updatedComments[index] = KaizengramComment(
            id: target.id,
            authorName: target.authorName,
            message: target.message,
            timestampLabel: target.timestampLabel,
            avatarUrl: target.avatarUrl,
            isDescription: target.isDescription,
            attachments: target.attachments,
            replies: updatedReplies,
          );
          didReplyToExistingComment = true;
        }
      }

      if (!didReplyToExistingComment) {
        final newComment = KaizengramComment(
          id: _nextLocalCommentId(),
          authorName: 'You',
          message: message,
          timestampLabel: 'Now',
          attachments: nextAttachments,
        );
        sentCommentId = newComment.id;
        updatedComments.add(newComment);
      }

      _setActiveComments(updatedComments);
      _commentController.clear();
      _draftAttachments = <KaizengramMessageAttachment>[];
      _replyingTo = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToLatestComment();
      _highlightComment(sentCommentId);
    });
  }

  String _nextLocalCommentId({String prefix = 'comment'}) {
    return 'local-$prefix-${DateTime.now().microsecondsSinceEpoch}-${_activeComments.length}';
  }

  GlobalKey _commentKeyFor(String commentId) {
    return _commentKeys.putIfAbsent(
      commentId,
      () => GlobalObjectKey(commentId),
    );
  }

  Future<void> _scrollToComment(String? commentId) async {
    final controller = _activeScrollController;
    if (commentId == null || !controller.hasClients) {
      return;
    }

    var targetContext = _commentKeys[commentId]?.currentContext;
    if (targetContext == null) {
      await controller.animateTo(
        controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      await Future<void>.delayed(const Duration(milliseconds: 90));
      targetContext = _commentKeys[commentId]?.currentContext;
    }

    if (targetContext == null || !targetContext.mounted) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      alignment: 0.18,
    );
    _highlightComment(commentId);
  }

  void _jumpToLatestComment() {
    final controller = _activeScrollController;
    if (!controller.hasClients) {
      return;
    }

    controller.jumpTo(controller.position.maxScrollExtent);
  }

  void _highlightComment(String? commentId) {
    if (commentId == null) {
      return;
    }

    final sequence = ++_highlightSequence;
    if (mounted) {
      setState(() => _highlightedCommentId = commentId);
    }

    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted || sequence != _highlightSequence) {
        return;
      }
      setState(() => _highlightedCommentId = null);
    });
  }

  Future<void> _pickAttachments() async {
    final availableSlots =
        kaizengramMessageAttachmentLimit - _draftAttachments.length;
    if (availableSlots <= 0) {
      _showAttachmentSnackBar(KaizengramChatStrings.mediaLimitError);
      return;
    }

    try {
      final source = await KaizengramMessageAttachmentPicker.pickSource(
        context,
      );
      if (!mounted || source == null) {
        return;
      }

      final nextAttachments = await KaizengramMessageAttachmentPicker.pick(
        source: source,
        availableSlots: availableSlots,
        existingPaths: _draftAttachments.map((attachment) => attachment.path),
      );
      if (!mounted || nextAttachments.isEmpty) {
        return;
      }

      setState(() {
        _draftAttachments = <KaizengramMessageAttachment>[
          ..._draftAttachments,
          ...nextAttachments,
        ];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showAttachmentSnackBar(KaizengramChatStrings.pickMediaError);
    }
  }

  void _removeAttachment(String attachmentPath) {
    setState(() {
      _draftAttachments = _draftAttachments
          .where((attachment) => attachment.path != attachmentPath)
          .toList(growable: false);
    });
  }

  void _openAttachmentViewer(int index) {
    if (_draftAttachments.isEmpty) {
      return;
    }

    final selectedAttachment = _draftAttachments[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KaizengramFullScreenAttachmentView(
          attachments: _draftAttachments,
          initialIndex: index,
          autoPlayInitialVideo: selectedAttachment.isVideo,
        ),
      ),
    );
  }

  void _showAttachmentSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        ..showSnackBar(
          const SnackBar(
            content: Text(AppStrings.kaizengramErrorPickImageFailed),
          ),
        );
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
                    AppStrings.kaizengramButtonComments,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  const SizedBox(height: 4),
                  AppTextView.body2(
                    _sheetTitle(),
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _shouldShowPagedMessages
                  ? loadMessagesByPages()
                  : loadMessagesNormally(),
            ),
            _CommentComposer(
              controller: _commentController,
              replyingTo: _replyingTo,
              onCancelReply: _clearReply,
              onSend: _sendComment,
              attachments: _draftAttachments,
              allowAttachments: true,
              onPickAttachment: _pickAttachments,
              onOpenAttachment: _openAttachmentViewer,
              onRemoveAttachment: _removeAttachment,
            ),
          ],
        ),
      ),
    );
  }

  Widget loadMessagesNormally() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: _CommentSheetMediaPreview(
            post: widget.post,
            selectedAuditMediaItem: widget.selectedAuditMediaItem,
            documentImageFile: _documentImageFile,
            onUploadTap:
                widget.post.resolvedPostCategory ==
                    KaizengramPostCategory.documentCompliance
                ? _pickDocumentImage
                : null,
            isUploading: _isPickingDocumentImage,
          ),
        ),
        Expanded(
          child: _buildCommentsListView(
            comments: _comments,
            controller: _scrollController,
          ),
        ),
      ],
    );
  }

  Widget loadMessagesByPages() {
    final mediaItems = _auditThreadItems;

    return PageView.builder(
      controller: _threadPageController,
      itemCount: mediaItems.length,
      onPageChanged: (index) {
        setState(() {
          _currentThreadPage = index;
          _replyingTo = null;
        });
      },
      itemBuilder: (context, index) {
        final mediaItem = mediaItems[index];
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Column(
                children: <Widget>[
                  _CommentSheetMediaPreview(
                    post: widget.post,
                    selectedAuditMediaItem: mediaItem,
                  ),
                  if (mediaItems.length > 1) ...<Widget>[
                    const SizedBox(height: 8),
                    _buildPagedThreadsIndicator(mediaItems.length),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Expanded(
              child: _buildCommentsListView(
                comments: _commentsForMedia(mediaItem.id),
                controller: _scrollControllerForMedia(mediaItem.id),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentsListView({
    required List<KaizengramComment> comments,
    required ScrollController controller,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(18, 8, 18, 24),
  }) {
    return ListView.separated(
      controller: controller,
      padding: padding,
      itemCount: comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _CommentThreadCard(
          key: _commentKeyFor(comments[index].id),
          comment: comments[index],
          onReplyTap: _startReply,
          highlightedCommentId: _highlightedCommentId,
        );
      },
    );
  }

  Widget _buildPagedThreadsIndicator(int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(itemCount, (index) {
        final isActive = index == _currentThreadPage;
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
    );
  }
}

class _CreateSocialPostBottomSheet extends StatefulWidget {
  const _CreateSocialPostBottomSheet({
    required this.authorName,
    required this.avatarUrl,
    this.initialImagePath,
    required this.onPostSubmitted,
  });

  final String authorName;
  final String? avatarUrl;
  final String? initialImagePath;
  final void Function(String message, String? imagePath) onPostSubmitted;

  @override
  State<_CreateSocialPostBottomSheet> createState() =>
      _CreateSocialPostBottomSheetState();
}

class _CreateSocialPostBottomSheetState
    extends State<_CreateSocialPostBottomSheet> {
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _controller;
  File? _selectedImageFile;
  var _draftText = '';
  var _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    final initialImagePath = widget.initialImagePath?.trim();
    if (initialImagePath != null && initialImagePath.isNotEmpty) {
      _selectedImageFile = File(initialImagePath);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _controller.text.trim();
    if (message.isEmpty && _selectedImageFile == null) {
      return;
    }

    widget.onPostSubmitted(message, _selectedImageFile?.path);
    Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) {
      return;
    }

    setState(() {
      _isPickingImage = true;
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
        _selectedImageFile = File(pickedImage.path);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(AppStrings.kaizengramErrorPickImageFailed),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      } else {
        _isPickingImage = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _draftText.trim().isNotEmpty || _selectedImageFile != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.18),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppTextView.body1(
              AppStrings.kaizengramComposeSheetTitle,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _ComposerHeaderAvatar(
                  displayName: widget.authorName,
                  imageUrl: widget.avatarUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextView.body2(
                    widget.authorName,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_selectedImageFile != null) ...<Widget>[
              _ComposePostImagePreview(
                imageFile: _selectedImageFile!,
                isPickingImage: _isPickingImage,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 14),
            ] else ...<Widget>[
              _ComposeImagePickerButton(
                isPickingImage: _isPickingImage,
                onTap: _pickImage,
              ),
              const SizedBox(height: 14),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                ),
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                minLines: 5,
                cursorHeight: 17,
                cursorColor: AppColors.textPrimary,
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (value) => setState(() => _draftText = value),
                decoration: const InputDecoration(
                  hintText: AppStrings.kaizengramComposeSheetHint,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            AppTextView.body4(
              AppStrings.kaizengramComposeSubtitle,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: AppTextView.body3(
                        AppStrings.kaizengramComposeButtonCancel,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: canPost ? _submit : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: canPost
                            ? AppColors.secondaryColor
                            : AppColors.surfaceDark3.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: canPost
                              ? AppColors.secondaryColor
                              : AppColors.textPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      child: AppTextView.body3(
                        AppStrings.kaizengramComposeButtonPost,
                        color: canPost
                            ? AppColors.mainBg
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _ComposeImagePickerButton extends StatelessWidget {
  const _ComposeImagePickerButton({
    required this.isPickingImage,
    required this.onTap,
  });

  final bool isPickingImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isPickingImage ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
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
              if (isPickingImage)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                )
              else
                const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.textPrimary,
                ),
              const SizedBox(width: 8),
              AppTextView.body3(
                AppStrings.kaizengramButtonUploadImage,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposePostImagePreview extends StatelessWidget {
  const _ComposePostImagePreview({
    required this.imageFile,
    required this.isPickingImage,
    required this.onPickImage,
  });

  final File imageFile;
  final bool isPickingImage;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: ColoredBox(
              color: AppColors.surfaceDark3,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
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
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isPickingImage ? null : onPickImage,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (isPickingImage)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    else
                      const Icon(
                        Icons.upload_rounded,
                        color: AppColors.textPrimary,
                        size: 16,
                      ),
                    const SizedBox(width: 6),
                    AppTextView.body3(
                      AppStrings.kaizengramButtonChangeImage,
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

class _SocialPostCommentsBottomSheet extends StatefulWidget {
  const _SocialPostCommentsBottomSheet({
    required this.post,
    required this.loggedInUserName,
  });

  final KaizengramSocialPost post;
  final String loggedInUserName;

  @override
  State<_SocialPostCommentsBottomSheet> createState() =>
      _SocialPostCommentsBottomSheetState();
}

class _SocialPostCommentsBottomSheetState
    extends State<_SocialPostCommentsBottomSheet> {
  late final TextEditingController _commentController;
  late final ScrollController _scrollController;
  final Map<String, GlobalKey> _commentKeys = <String, GlobalKey>{};
  List<KaizengramMessageAttachment> _draftAttachments =
      <KaizengramMessageAttachment>[];
  String? _replyingToCommentId;
  String? _highlightedCommentId;
  int _highlightSequence = 0;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startReply(KaizengramComment comment) {
    setState(() {
      _replyingToCommentId = comment.id;
    });
  }

  void _clearReply() {
    setState(() {
      _replyingToCommentId = null;
    });
  }

  void _sendComment() {
    final message = _commentController.text.trim();
    if (message.isEmpty && _draftAttachments.isEmpty) {
      return;
    }

    final sentCommentId = context
        .read<KaizengramController>()
        .addSocialPostComment(
          post: widget.post,
          authorName: widget.loggedInUserName,
          message: message,
          replyToCommentId: _replyingToCommentId,
          attachments: _draftAttachments,
        );
    if (sentCommentId == null) {
      return;
    }

    _commentController.clear();
    setState(() {
      _draftAttachments = <KaizengramMessageAttachment>[];
      _replyingToCommentId = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToLatestComment();
      _highlightComment(sentCommentId);
    });
  }

  GlobalKey _commentKeyFor(String commentId) {
    return _commentKeys.putIfAbsent(
      commentId,
      () => GlobalObjectKey(commentId),
    );
  }

  void _jumpToLatestComment() {
    if (!_scrollController.hasClients) {
      return;
    }

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _highlightComment(String? commentId) {
    if (commentId == null) {
      return;
    }

    final sequence = ++_highlightSequence;
    if (mounted) {
      setState(() => _highlightedCommentId = commentId);
    }

    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted || sequence != _highlightSequence) {
        return;
      }
      setState(() => _highlightedCommentId = null);
    });
  }

  Future<void> _pickAttachments() async {
    final availableSlots =
        kaizengramMessageAttachmentLimit - _draftAttachments.length;
    if (availableSlots <= 0) {
      _showAttachmentSnackBar(KaizengramChatStrings.mediaLimitError);
      return;
    }

    try {
      final source = await KaizengramMessageAttachmentPicker.pickSource(
        context,
      );
      if (!mounted || source == null) {
        return;
      }

      final nextAttachments = await KaizengramMessageAttachmentPicker.pick(
        source: source,
        availableSlots: availableSlots,
        existingPaths: _draftAttachments.map((attachment) => attachment.path),
      );
      if (!mounted || nextAttachments.isEmpty) {
        return;
      }

      setState(() {
        _draftAttachments = <KaizengramMessageAttachment>[
          ..._draftAttachments,
          ...nextAttachments,
        ];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showAttachmentSnackBar(KaizengramChatStrings.pickMediaError);
    }
  }

  void _removeAttachment(String attachmentPath) {
    setState(() {
      _draftAttachments = _draftAttachments
          .where((attachment) => attachment.path != attachmentPath)
          .toList(growable: false);
    });
  }

  void _openAttachmentViewer(int index) {
    if (_draftAttachments.isEmpty) {
      return;
    }

    final selectedAttachment = _draftAttachments[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KaizengramFullScreenAttachmentView(
          attachments: _draftAttachments,
          initialIndex: index,
          autoPlayInitialVideo: selectedAttachment.isVideo,
        ),
      ),
    );
  }

  void _showAttachmentSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  KaizengramComment? _replyingToComment(List<KaizengramComment> comments) {
    final replyingToCommentId = _replyingToCommentId;
    if (replyingToCommentId == null) {
      return null;
    }

    for (final comment in comments) {
      if (comment.id == replyingToCommentId) {
        return comment;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<KaizengramController>();
    final resolvedPost = controller.resolveSocialPost(widget.post);
    final comments = resolvedPost.comments;
    final replyingToComment = _replyingToComment(comments);

    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.74,
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
                    AppStrings.kaizengramButtonComments,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  return _CommentThreadCard(
                    key: _commentKeyFor(comments[index].id),
                    comment: comments[index],
                    onReplyTap: _startReply,
                    highlightedCommentId: _highlightedCommentId,
                  );
                },
              ),
            ),
            _CommentComposer(
              controller: _commentController,
              replyingTo: replyingToComment,
              onCancelReply: _clearReply,
              onSend: _sendComment,
              hintText: AppStrings.commentAsUser(widget.loggedInUserName),
              attachments: _draftAttachments,
              allowAttachments: true,
              onPickAttachment: _pickAttachments,
              onOpenAttachment: _openAttachmentViewer,
              onRemoveAttachment: _removeAttachment,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentSheetMediaPreview extends StatefulWidget {
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
  State<_CommentSheetMediaPreview> createState() =>
      _CommentSheetMediaPreviewState();
}

class _CommentSheetMediaPreviewState extends State<_CommentSheetMediaPreview> {
  late final PageController _pageController;
  var _currentPage = 0;

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
    final auditMediaItem = widget.selectedAuditMediaItem;

    if (widget.documentImageFile != null) {
      return _buildDocumentPreviewCard(
        child: Image.file(widget.documentImageFile!, fit: BoxFit.cover),
      );
    }

    if (widget.post.resolvedPostCategory ==
            KaizengramPostCategory.learningCompliance &&
        widget.post.mediaUrls.length > 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                children: <Widget>[
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.post.mediaUrls.length,
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) {
                      return _NetworkPostImage(
                        imageUrl: widget.post.mediaUrls[index],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(widget.post.mediaUrls.length, (
              index,
            ) {
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

    if (auditMediaItem != null) {
      if (auditMediaItem.hasVideo && auditMediaItem.videoUrl != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            child: ComplianceVideoPlayer(
              videoUrl: auditMediaItem.videoUrl!,
              title: auditMediaItem.title,
              thumbnailLink: auditMediaItem.hasThumbnail
                  ? auditMediaItem.thumbnailUrl
                  : null,
            ),
          ),
        );
      }

      if (!auditMediaItem.hasThumbnail) {
        return _buildThreadWithoutImagePreview();
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

    if (widget.post.resolvedPostCategory == KaizengramPostCategory.audit &&
        widget.post.auditMediaItems.isNotEmpty) {
      final primaryMedia = widget.post.auditMediaItems.first;

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

    if (widget.post.hasVideo && widget.post.feedVideoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 220,
          child: ComplianceVideoPlayer(
            videoUrl: widget.post.feedVideoUrl!,
            title: widget.post.title,
            thumbnailLink: widget.post.feedImageUrl,
          ),
        ),
      );
    }

    if (widget.post.resolvedPostCategory ==
            KaizengramPostCategory.documentCompliance &&
        widget.post.feedImageUrl == null) {
      return _buildDocumentPreviewCard(child: const _UploadDocPlaceholder());
    }

    if (widget.post.resolvedPostCategory ==
        KaizengramPostCategory.documentCompliance) {
      return _buildDocumentPreviewCard(
        child: _NetworkPostImage(imageUrl: widget.post.feedImageUrl),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: _NetworkPostImage(imageUrl: widget.post.feedImageUrl),
      ),
    );
  }

  Widget _buildDocumentPreviewCard({required Widget child}) {
    final canUpload =
        widget.post.resolvedPostCategory ==
            KaizengramPostCategory.documentCompliance &&
        widget.onUploadTap != null;

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
                onTap: widget.isUploading ? null : widget.onUploadTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (widget.isUploading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      else
                        const Icon(
                          Icons.upload_rounded,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                      const SizedBox(width: 6),
                      AppTextView.body3(
                        widget.documentImageFile == null
                            ? AppStrings.kaizengramButtonUploadImage
                            : AppStrings.kaizengramButtonChangeImage,
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

  Widget _buildThreadWithoutImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: const _NoImageAvailableAsset(),
      ),
    );
  }
}

class _CommentThreadCard extends StatefulWidget {
  const _CommentThreadCard({
    super.key,
    required this.comment,
    required this.onReplyTap,
    required this.highlightedCommentId,
  });

  final KaizengramComment comment;
  final ValueChanged<KaizengramComment> onReplyTap;
  final String? highlightedCommentId;

  @override
  State<_CommentThreadCard> createState() => _CommentThreadCardState();
}

class _CommentThreadCardState extends State<_CommentThreadCard> {
  bool _showReplies = true;

  List<Widget> _buildReplyWidgets(List<KaizengramComment> replies) {
    return List<Widget>.generate(replies.length, (int index) {
      return Padding(
        padding: EdgeInsets.only(bottom: index == replies.length - 1 ? 0 : 10),
        child: _ReplyCommentRow(
          comment: replies[index],
          onReplyTap: widget.onReplyTap,
        ),
      );
    }, growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final replies = comment.replies;
    final isHighlighted = widget.highlightedCommentId == comment.id;

    return AnimatedScale(
      scale: isHighlighted ? 1.02 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted
                ? AppColors.blue.withValues(alpha: 0.75)
                : comment.isDescription
                ? AppColors.secondaryColor.withValues(alpha: 0.30)
                : AppColors.textPrimary.withValues(alpha: 0.08),
          ),
          boxShadow: isHighlighted
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.20),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : const <BoxShadow>[],
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
                  _CommentMessageText(
                    message: comment.message,
                    attachments: comment.attachments,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
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
                          AppStrings.kaizengramRepliesToggleText(
                            replies.length,
                            _showReplies,
                          ),
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
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.14,
                            ),
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
      child: AppTextView.body3(
        initials,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
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
              _CommentMessageText(
                message: comment.message,
                attachments: comment.attachments,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
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
          AppTextView.body4(
            'Reply',
            color: AppColors.secondaryColor,
            fontWeight: FontWeight.w600,
          ),
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
    this.hintText = AppStrings.writeCommentHint,
    this.attachments = const <KaizengramMessageAttachment>[],
    this.allowAttachments = false,
    this.onPickAttachment,
    this.onOpenAttachment,
    this.onRemoveAttachment,
  });

  final TextEditingController controller;
  final KaizengramComment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final String hintText;
  final List<KaizengramMessageAttachment> attachments;
  final bool allowAttachments;
  final VoidCallback? onPickAttachment;
  final ValueChanged<int>? onOpenAttachment;
  final ValueChanged<String>? onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final draftText = value.text;
        final hasLinkPreview = kaizengramFirstLinkInText(draftText) != null;
        final canSend = draftText.trim().isNotEmpty || attachments.isNotEmpty;

        return SafeArea(
          top: false,
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                top: BorderSide(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (replyingTo != null) ...<Widget>[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark3.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondaryColor.withValues(alpha: 0.18),
                      ),
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
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (hasLinkPreview) ...<Widget>[
                  KaizengramTextLinkPreview(text: draftText, topSpacing: 0),
                  const SizedBox(height: 10),
                ],
                if (attachments.isNotEmpty) ...<Widget>[
                  _CommentAttachmentPreviewStrip(
                    attachments: attachments,
                    removable: allowAttachments,
                    onOpenAttachment: onOpenAttachment,
                    onRemoveAttachment: onRemoveAttachment,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: <Widget>[
                    if (allowAttachments) ...<Widget>[
                      _CommentComposerActionButton(
                        onTap: onPickAttachment,
                        icon: Icons.attach_file_rounded,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          cursorHeight: 17,
                          cursorColor: AppColors.textPrimary,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => onSend(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _CommentComposerSendButton(
                      onTap: canSend ? onSend : null,
                      canSend: canSend,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentComposerActionButton extends StatelessWidget {
  const _CommentComposerActionButton({required this.onTap, required this.icon});

  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _CommentComposerSendButton extends StatelessWidget {
  const _CommentComposerSendButton({
    required this.onTap,
    required this.canSend,
  });

  final VoidCallback? onTap;
  final bool canSend;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 54,
        height: 44,
        decoration: BoxDecoration(
          color: canSend
              ? AppColors.secondaryColor
              : AppColors.surfaceDark3.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: canSend
                ? AppColors.secondaryColor
                : AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          Icons.send_rounded,
          color: canSend ? AppColors.mainBg : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}

class _CommentAttachmentPreviewStrip extends StatelessWidget {
  const _CommentAttachmentPreviewStrip({
    required this.attachments,
    this.removable = false,
    this.onOpenAttachment,
    this.onRemoveAttachment,
  });

  final List<KaizengramMessageAttachment> attachments;
  final bool removable;
  final ValueChanged<int>? onOpenAttachment;
  final ValueChanged<String>? onRemoveAttachment;

  @override
  Widget build(BuildContext context) {
    if (attachments.length == 1) {
      return _CommentAttachmentPreviewCard(
        attachment: attachments.first,
        height: attachments.first.isPdf ? 98 : 164,
        onOpen: onOpenAttachment == null ? null : () => onOpenAttachment!(0),
        onRemove: removable && onRemoveAttachment != null
            ? () => onRemoveAttachment!(attachments.first.path)
            : null,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        const maxSquareSide = 92.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final rawSquareSide =
            (availableWidth - (spacing * (attachments.length - 1))) /
            attachments.length;
        final squareSide = rawSquareSide > maxSquareSide
            ? maxSquareSide
            : rawSquareSide;

        return SizedBox(
          height: squareSide,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(attachments.length * 2 - 1, (
              index,
            ) {
              if (index.isOdd) {
                return const SizedBox(width: spacing);
              }

              final attachmentIndex = index ~/ 2;
              final attachment = attachments[attachmentIndex];
              return _CommentAttachmentPreviewCard(
                attachment: attachment,
                width: squareSide,
                height: squareSide,
                onOpen: onOpenAttachment == null
                    ? null
                    : () => onOpenAttachment!(attachmentIndex),
                onRemove: removable && onRemoveAttachment != null
                    ? () => onRemoveAttachment!(attachment.path)
                    : null,
              );
            }),
          ),
        );
      },
    );
  }
}

class _CommentAttachmentPreviewCard extends StatelessWidget {
  const _CommentAttachmentPreviewCard({
    required this.attachment,
    required this.height,
    this.width,
    this.onOpen,
    this.onRemove,
  });

  final KaizengramMessageAttachment attachment;
  final double height;
  final double? width;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final mediaChild = attachment.isPdf
        ? _CommentPdfPreviewCard(attachment: attachment, onOpen: onOpen)
        : attachment.isVideo
        ? ChatVideoPreview(
            videoPath: attachment.path,
            maxHeight: height,
            muted: true,
            playButtonSize: width == null ? 48 : 34,
            playIconSize: width == null ? 26 : 18,
            onTapOverride: onOpen,
            onOpenFullScreen: onOpen,
          )
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpen,
              child: attachment.isNetworkPath
                  ? Image.network(
                      attachment.path,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const _CommentAttachmentFallback(),
                    )
                  : Image.file(
                      File(attachment.path),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const _CommentAttachmentFallback(),
                    ),
            ),
          );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: AppColors.surfaceDark3,
                child: mediaChild,
              ),
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.44),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentPdfPreviewCard extends StatelessWidget {
  const _CommentPdfPreviewCard({required this.attachment, this.onOpen});

  final KaizengramMessageAttachment attachment;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.secondaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                CustomFunctions.fileNameFromPath(
                  attachment.path,
                  fallback: KaizengramChatStrings.documentMessageLabel,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentAttachmentFallback extends StatelessWidget {
  const _CommentAttachmentFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: AppColors.textSecondary,
        size: 26,
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
    final threadItems = _buildAuditThreadItems(post);
    final badCount = mediaItems
        .where((item) => item.rating == KaizengramAuditRating.bad)
        .length;
    final improvementCount = mediaItems
        .where((item) => item.rating == KaizengramAuditRating.needsImprovement)
        .length;
    final goodCount = mediaItems
        .where((item) => item.rating == KaizengramAuditRating.good)
        .length;

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
                    AppStrings.kaizengramLabelCheckInComments,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  const SizedBox(height: 4),
                  AppTextView.body2(
                    _sheetSeatName(),
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
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
                      _RatingSummaryBlock(
                        count: badCount,
                        color: const Color(0xFFF04438),
                      ),
                      const SizedBox(width: 12),
                      _RatingSummaryBlock(
                        count: improvementCount,
                        color: const Color(0xFFFF8A4C),
                      ),
                      const SizedBox(width: 12),
                      _RatingSummaryBlock(
                        count: goodCount,
                        color: const Color(0xFF15B79F),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: threadItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = threadItems[index];
                  return _AuditMediaListTile(
                    item: item,
                    onTap: () => onMediaTap(item),
                  );
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
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
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
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              width: 0.8,
            ),
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
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: _NetworkPostImage(
                        imageUrl: item.hasThumbnail ? item.thumbnailUrl : null,
                      ),
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
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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
          child: AppTextView.body2(
            label,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: AppTextView.body2(
            value,
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
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
          child: AppTextView.body2(
            'Status ',
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
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

  _TrackStatusStyle _resolveTrackStatusStyle(
    String status,
    KaizengramPostCategory postCategory,
  ) {
    final normalized = CustomFunctions.normalizedStatus(
      status,
    ).replaceAll('-', ' ');

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
        postCategory == KaizengramPostCategory.audit &&
            normalized == 'improvement needed') {
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
