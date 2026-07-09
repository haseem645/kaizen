import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../data/datasources/kaizengram_remote_data_source.dart';
import '../../../login/domain/entities/user.dart';
import '../kaizengram_message_attachment.dart';

enum KaizengramFeedType { learningCompliance, documentCompliance }

enum KaizengramPostCategory { audit, learningCompliance, documentCompliance }

enum KaizengramFeedMediaKind { image, video, gallery }

enum KaizengramAuditRating { bad, needsImprovement, good }

enum KaizengramNotificationType {
  assigned,
  commented,
  dueSoon,
  reviewed,
  readyForFollowUp,
  requestedUpload,
}

enum KaizengramNotificationBucket { today, thisWeek, earlier }

class KaizengramController extends ChangeNotifier {
  KaizengramController(this._remoteDataSource, {User? currentUser})
    : _currentUser = currentUser;

  final KaizengramRemoteDataSource _remoteDataSource;
  final Map<String, String> _imageAssignments = <String, String>{};
  final Map<String, List<KaizengramComment>> _socialPostComments =
      <String, List<KaizengramComment>>{};
  final List<KaizengramSocialPost> _socialPosts = <KaizengramSocialPost>[];
  User? _currentUser;
  bool _isLoading = false;
  int _nextImageIndex = 0;
  String? _errorMessage;
  List<KaizengramFeedItem> _posts = const <KaizengramFeedItem>[];

  KaizengramRemoteDataSource get remoteDataSource => _remoteDataSource;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<KaizengramFeedItem> get posts =>
      List<KaizengramFeedItem>.unmodifiable(_posts);
  List<KaizengramSocialPost> get socialPosts =>
      List<KaizengramSocialPost>.unmodifiable(_socialPosts);
  List<KaizengramNotificationItem> get notifications =>
      List<KaizengramNotificationItem>.unmodifiable(_buildNotifications());
  List<KaizengramNotificationSection> get notificationSections =>
      List<KaizengramNotificationSection>.unmodifiable(
        _buildNotificationSections(),
      );
  int get unreadNotificationCount =>
      notifications.where((item) => item.isUnread).length;
  bool get useSeparateFeedDemo => _useSeparateFeedDemo;
  String get currentUserDisplayName {
    final resolvedName = CustomFunctions.resolveName(_currentUser).trim();
    return resolvedName.isEmpty ? 'You' : resolvedName;
  }

  String? get currentUserImageUrl => CustomFunctions.resolveImageUrl(
    _currentUser?.imageUrl ?? _currentUser?.image,
  );
  List<int> get weeklyCheckInSocialInsertAfterCounts =>
      _weeklyCheckInSocialInsertAfterCounts;
  List<KaizengramSocialPost> get seededWeeklyCheckInSocialPosts =>
      _weeklyCheckInSocialPosts;

  List<KaizengramStory> get stories => _posts
      .map(
        (post) => KaizengramStory(
          id: post.id,
          name: post.title.split(' ').first,
          avatarUrl: post.avatarUrl,
        ),
      )
      .toList(growable: false);

  void syncCurrentUser(User? user) {
    if (_currentUser == user) {
      return;
    }

    _currentUser = user;
    notifyListeners();
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = _buildDummyFeedItems();
    } catch (error) {
      _posts = const <KaizengramFeedItem>[];
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleLike(String postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      return;
    }

    final post = _posts[index];
    _posts[index] = post.copyWith(
      isLiked: !post.isLiked,
      likes: post.isLiked ? post.likes - 1 : post.likes + 1,
    );
    notifyListeners();
  }

  void createSocialPost({
    required String authorName,
    required String message,
    required String channelName,
    String? avatarUrl,
    String? mediaImagePath,
    String? mediaImageUrl,
  }) {
    final normalizedMessage = message.trim();
    final normalizedMediaImagePath = mediaImagePath?.trim();
    final normalizedMediaImageUrl = mediaImageUrl?.trim();
    final hasImage =
        (normalizedMediaImagePath != null &&
            normalizedMediaImagePath.isNotEmpty) ||
        (normalizedMediaImageUrl != null && normalizedMediaImageUrl.isNotEmpty);
    if (normalizedMessage.isEmpty && !hasImage) {
      return;
    }

    final seed =
        '$authorName-$normalizedMessage-${DateTime.now().microsecondsSinceEpoch}';
    _socialPosts.insert(
      0,
      KaizengramSocialPost(
        id: 'social-post-$seed',
        authorName: authorName.trim().isEmpty ? 'You' : authorName.trim(),
        avatarUrl: avatarUrl?.trim().isNotEmpty == true
            ? avatarUrl!.trim()
            : _personImage(authorName) ?? _image('social-post-$seed-avatar'),
        channelName: channelName,
        timeLabel: AppStrings.kaizengramComposeTimeLabel,
        message: normalizedMessage,
        mediaImagePath: normalizedMediaImagePath,
        mediaImageUrl: normalizedMediaImageUrl,
      ),
    );
    notifyListeners();
  }

  void createCurrentUserSocialPost({
    required String message,
    String? mediaImagePath,
    String? mediaImageUrl,
  }) {
    createSocialPost(
      authorName: currentUserDisplayName,
      avatarUrl: currentUserImageUrl,
      message: message,
      channelName: AppStrings.kaizengramWeeklySocialChannelOne,
      mediaImagePath: mediaImagePath,
      mediaImageUrl: mediaImageUrl,
    );
  }

  KaizengramSocialPost resolveSocialPost(KaizengramSocialPost post) {
    final comments = _socialPostComments[post.id];
    if (comments == null) {
      return post;
    }

    return post.copyWith(comments: comments);
  }

  String? addSocialPostComment({
    required KaizengramSocialPost post,
    required String authorName,
    required String message,
    String? replyToCommentId,
    List<KaizengramMessageAttachment> attachments =
        const <KaizengramMessageAttachment>[],
  }) {
    final normalizedMessage = message.trim();
    final normalizedAttachments = attachments
        .where((attachment) => attachment.path.trim().isNotEmpty)
        .take(kaizengramMessageAttachmentLimit)
        .toList(growable: false);
    if (normalizedMessage.isEmpty && normalizedAttachments.isEmpty) {
      return null;
    }

    final resolvedPost = resolveSocialPost(post);
    final updatedComments = List<KaizengramComment>.from(resolvedPost.comments);
    final normalizedAuthorName = authorName.trim().isEmpty
        ? 'You'
        : authorName.trim();
    String? sentCommentId;

    if (replyToCommentId != null) {
      final targetIndex = updatedComments.indexWhere(
        (comment) => comment.id == replyToCommentId,
      );
      if (targetIndex != -1) {
        final target = updatedComments[targetIndex];
        final reply = KaizengramComment(
          id: _nextSocialCommentId(post.id, prefix: 'reply'),
          authorName: normalizedAuthorName,
          message: normalizedMessage,
          timestampLabel: 'Now',
          attachments: normalizedAttachments,
        );
        sentCommentId = reply.id;
        updatedComments[targetIndex] = target.copyWith(
          replies: <KaizengramComment>[...target.replies, reply],
        );
      }
    }

    if (sentCommentId == null) {
      final newComment = KaizengramComment(
        id: _nextSocialCommentId(post.id),
        authorName: normalizedAuthorName,
        message: normalizedMessage,
        timestampLabel: 'Now',
        attachments: normalizedAttachments,
      );
      sentCommentId = newComment.id;
      updatedComments.add(newComment);
    }

    _socialPostComments[post.id] = List<KaizengramComment>.unmodifiable(
      updatedComments,
    );
    _syncMutableSocialPostComments(post.id, updatedComments);
    notifyListeners();
    return sentCommentId;
  }

  String? addCurrentUserSocialPostComment({
    required KaizengramSocialPost post,
    required String message,
    String? replyToCommentId,
    List<KaizengramMessageAttachment> attachments =
        const <KaizengramMessageAttachment>[],
  }) {
    return addSocialPostComment(
      post: post,
      authorName: currentUserDisplayName,
      message: message,
      replyToCommentId: replyToCommentId,
      attachments: attachments,
    );
  }

  KaizengramPostCategory categoryForTabIndex(int index) {
    switch (index) {
      case 0:
        return KaizengramPostCategory.audit;
      case 1:
        return KaizengramPostCategory.learningCompliance;
      case 2:
      default:
        return KaizengramPostCategory.documentCompliance;
    }
  }

  int tabIndexForCategory(KaizengramPostCategory category) {
    switch (category) {
      case KaizengramPostCategory.audit:
        return 0;
      case KaizengramPostCategory.learningCompliance:
        return 1;
      case KaizengramPostCategory.documentCompliance:
        return 2;
    }
  }

  List<KaizengramFeedItem> postsForCategory(KaizengramPostCategory category) {
    return _posts
        .where((post) => post.resolvedPostCategory == category)
        .toList(growable: false);
  }

  KaizengramFeedItem? postById(String postId) {
    for (final post in _posts) {
      if (post.id == postId) {
        return post;
      }
    }

    return null;
  }

  List<KaizengramComment> commentThreadForPost(
    KaizengramFeedItem post, {
    KaizengramAuditMediaItem? selectedAuditMediaItem,
  }) {
    final selectedMediaComments =
        selectedAuditMediaItem?.commentThread ?? const <KaizengramComment>[];
    final rawDescription = CustomFunctions.resolvedText(post.description);
    final resolvedDescription =
        rawDescription == null || post.description == post.status
        ? null
        : post.description;

    if (selectedMediaComments.isNotEmpty) {
      return selectedMediaComments;
    }

    if (post.commentThread.isNotEmpty) {
      return post.commentThread;
    }

    if (resolvedDescription == null) {
      return const <KaizengramComment>[];
    }

    return <KaizengramComment>[
      KaizengramComment(
        id: 'comment-description-${post.id}',
        authorName: resolvePrimaryActorName(post),
        message: resolvedDescription,
        timestampLabel: post.timestampLabel,
        avatarUrl: post.avatarUrl,
        isDescription: true,
      ),
    ];
  }

  String resolvePrimaryActorName(KaizengramFeedItem post) {
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

  double estimatedPostExtent(KaizengramFeedItem post) {
    switch (post.resolvedPostCategory) {
      case KaizengramPostCategory.audit:
        return 760;
      case KaizengramPostCategory.learningCompliance:
        return post.hasVideo || post.hasMultipleImages ? 700 : 620;
      case KaizengramPostCategory.documentCompliance:
        return post.feedImageUrl?.trim().isNotEmpty == true ? 640 : 520;
    }
  }

  int weeklyCheckInSocialCardCountBefore(int postIndex) {
    return _weeklyCheckInSocialInsertAfterCounts
        .where((insertAfterCount) => insertAfterCount <= postIndex)
        .length;
  }

  static const bool _useSeparateFeedDemo = true;
  static const List<int> _weeklyCheckInSocialInsertAfterCounts = <int>[2, 5];
  static const List<KaizengramSocialPost>
  _weeklyCheckInSocialPosts = <KaizengramSocialPost>[
    KaizengramSocialPost(
      id: 'weekly-social-post-1',
      authorName: AppStrings.kaizengramWeeklySocialAuthorOne,
      avatarUrl: 'https://i.pravatar.cc/150?u=kaizengram-social-jordan-miles',
      channelName: AppStrings.kaizengramWeeklySocialChannelOne,
      timeLabel: AppStrings.kaizengramWeeklySocialTimeOne,
      message: AppStrings.kaizengramWeeklySocialPostOne,
      comments: <KaizengramComment>[
        KaizengramComment(
          id: 'weekly-social-1-comment-1',
          authorName: 'Selena Ward',
          message:
              'We shifted the weekly note into the owner handoff and the follow-up conversation became much cleaner right away.',
          timestampLabel: '34m',
          replies: <KaizengramComment>[
            KaizengramComment(
              id: 'weekly-social-1-reply-1',
              authorName: 'Darren Cole',
              message:
                  'That kind of owner context is exactly what made the strongest check-ins easier to verify this week.',
              timestampLabel: '21m',
            ),
          ],
        ),
      ],
    ),
    KaizengramSocialPost(
      id: 'weekly-social-post-2',
      authorName: AppStrings.kaizengramWeeklySocialAuthorTwo,
      avatarUrl: 'https://i.pravatar.cc/150?u=kaizengram-social-alyssa-grant',
      channelName: AppStrings.kaizengramWeeklySocialChannelTwo,
      timeLabel: AppStrings.kaizengramWeeklySocialTimeTwo,
      message: AppStrings.kaizengramWeeklySocialPostTwo,
      comments: <KaizengramComment>[
        KaizengramComment(
          id: 'weekly-social-2-comment-1',
          authorName: 'Harper Lane',
          message:
              'We started pairing the media proof with the follow-up owner name and the review loop moved a lot faster.',
          timestampLabel: '4h',
          replies: <KaizengramComment>[
            KaizengramComment(
              id: 'weekly-social-2-reply-1',
              authorName: 'Nico Bennett',
              message:
                  'That extra context makes the next pass much easier to confirm without another round-trip.',
              timestampLabel: '2h',
            ),
          ],
        ),
      ],
    ),
  ];

  String _nextSocialCommentId(String postId, {String prefix = 'comment'}) {
    return '$postId-$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _syncMutableSocialPostComments(
    String postId,
    List<KaizengramComment> comments,
  ) {
    final socialPostIndex = _socialPosts.indexWhere(
      (post) => post.id == postId,
    );
    if (socialPostIndex == -1) {
      return;
    }

    _socialPosts[socialPostIndex] = _socialPosts[socialPostIndex].copyWith(
      comments: List<KaizengramComment>.unmodifiable(comments),
    );
  }

  List<KaizengramNotificationSection> _buildNotificationSections() {
    final notifications = _buildNotifications();
    if (notifications.isEmpty) {
      return const <KaizengramNotificationSection>[];
    }

    final grouped =
        <KaizengramNotificationBucket, List<KaizengramNotificationItem>>{
          KaizengramNotificationBucket.today: <KaizengramNotificationItem>[],
          KaizengramNotificationBucket.thisWeek: <KaizengramNotificationItem>[],
          KaizengramNotificationBucket.earlier: <KaizengramNotificationItem>[],
        };

    final now = DateTime.now();
    for (final notification in notifications) {
      grouped[_notificationBucketFor(notification.occurredAt, now)]!.add(
        notification,
      );
    }

    return KaizengramNotificationBucket.values
        .where((bucket) => grouped[bucket]!.isNotEmpty)
        .map(
          (bucket) => KaizengramNotificationSection(
            bucket: bucket,
            items: List<KaizengramNotificationItem>.unmodifiable(
              grouped[bucket]!,
            ),
          ),
        )
        .toList(growable: false);
  }

  List<KaizengramNotificationItem> _buildNotifications() {
    if (_posts.isEmpty) {
      return const <KaizengramNotificationItem>[];
    }

    final notifications = <KaizengramNotificationItem>[];
    final now = DateTime.now();
    var timelineIndex = 0;

    for (final post in _posts) {
      for (final notificationSeed in _notificationSeedsFor(post)) {
        final occurredAt = now.subtract(
          _notificationOffsets[timelineIndex % _notificationOffsets.length],
        );
        notifications.add(
          KaizengramNotificationItem(
            id: '${post.id}-notification-$timelineIndex',
            actorName: notificationSeed.actorName,
            type: notificationSeed.type,
            post: post,
            occurredAt: occurredAt,
            isUnread: timelineIndex < 9,
            targetCommentId: notificationSeed.targetCommentId,
          ),
        );
        timelineIndex++;
      }
    }

    notifications.sort(
      (first, second) => second.occurredAt.compareTo(first.occurredAt),
    );
    return notifications;
  }

  List<
    ({
      String actorName,
      KaizengramNotificationType type,
      String? targetCommentId,
    })
  >
  _notificationSeedsFor(KaizengramFeedItem post) {
    switch (post.resolvedPostCategory) {
      case KaizengramPostCategory.audit:
        return <
          ({
            String actorName,
            KaizengramNotificationType type,
            String? targetCommentId,
          })
        >[
          (
            actorName: _notificationActor(
              post.auditedBy,
              fallback: AppStrings.kaizengramNotificationsActorKaizenQa,
            ),
            type: KaizengramNotificationType.commented,
            targetCommentId: _notificationCommentTargetId(post),
          ),
          (
            actorName: _notificationActor(
              post.postedByName,
              fallback: AppStrings.kaizengramNotificationsActorReviewBoard,
            ),
            type: KaizengramNotificationType.readyForFollowUp,
            targetCommentId: null,
          ),
        ];
      case KaizengramPostCategory.learningCompliance:
        return <
          ({
            String actorName,
            KaizengramNotificationType type,
            String? targetCommentId,
          })
        >[
          (
            actorName: _notificationActor(
              post.postedByName,
              fallback: AppStrings.kaizengramNotificationsActorTrainingDesk,
            ),
            type: KaizengramNotificationType.assigned,
            targetCommentId: null,
          ),
          (
            actorName: _notificationActor(
              post.departmentName,
              fallback: AppStrings.kaizengramNotificationsActorTrainingDesk,
            ),
            type: KaizengramNotificationType.dueSoon,
            targetCommentId: null,
          ),
        ];
      case KaizengramPostCategory.documentCompliance:
        final normalizedStatus = post.status?.trim().toLowerCase() ?? '';
        final needsUpload =
            normalizedStatus.isNotEmpty &&
            normalizedStatus != 'compliant' &&
            normalizedStatus != 'no longer required';
        return <
          ({
            String actorName,
            KaizengramNotificationType type,
            String? targetCommentId,
          })
        >[
          (
            actorName: _notificationActor(
              post.postedByName,
              fallback: AppStrings.kaizengramNotificationsActorComplianceDesk,
            ),
            type: needsUpload
                ? KaizengramNotificationType.requestedUpload
                : KaizengramNotificationType.reviewed,
            targetCommentId: null,
          ),
          (
            actorName: _notificationActor(
              post.departmentName,
              fallback: AppStrings.kaizengramNotificationsActorReviewBoard,
            ),
            type: KaizengramNotificationType.reviewed,
            targetCommentId: null,
          ),
        ];
    }
  }

  String? _notificationCommentTargetId(KaizengramFeedItem post) {
    if (post.commentThread.isEmpty) {
      return null;
    }

    return post.commentThread.first.id;
  }

  KaizengramNotificationBucket _notificationBucketFor(
    DateTime occurredAt,
    DateTime now,
  ) {
    if (_isSameCalendarDay(occurredAt, now)) {
      return KaizengramNotificationBucket.today;
    }

    if (now.difference(occurredAt).inDays < 7) {
      return KaizengramNotificationBucket.thisWeek;
    }

    return KaizengramNotificationBucket.earlier;
  }

  bool _isSameCalendarDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _notificationActor(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }

    return trimmed;
  }

  static const List<Duration> _notificationOffsets = <Duration>[
    Duration(minutes: 2),
    Duration(minutes: 11),
    Duration(minutes: 24),
    Duration(minutes: 48),
    Duration(hours: 1, minutes: 18),
    Duration(hours: 2, minutes: 10),
    Duration(hours: 3, minutes: 40),
    Duration(hours: 6, minutes: 15),
    Duration(hours: 10, minutes: 25),
    Duration(hours: 22),
    Duration(days: 2, hours: 3),
    Duration(days: 2, hours: 18),
    Duration(days: 3, hours: 4),
    Duration(days: 4, hours: 7),
    Duration(days: 5, hours: 2),
    Duration(days: 6, hours: 6),
    Duration(days: 8, hours: 4),
    Duration(days: 10, hours: 11),
    Duration(days: 13, hours: 5),
    Duration(days: 16, hours: 9),
    Duration(days: 20, hours: 2),
    Duration(days: 24, hours: 14),
    Duration(days: 29, hours: 6),
    Duration(days: 34, hours: 8),
  ];

  List<KaizengramFeedItem> _buildDummyFeedItems() {
    _imageAssignments.clear();
    _nextImageIndex = 0;

    return List<KaizengramFeedItem>.unmodifiable(<KaizengramFeedItem>[
      _buildAuditPost(
        id: 'audit-001',
        seatName: 'Engineering Manager',
        postedByName: 'Anthony Rivera',
        departmentName: 'Engineering Manager',
        status: 'Good',
        auditedAt: '16 Jun, 2026',
        auditedBy: 'Nina Brooks',
        imageUrls: _gallery('audit-learning-desk', 1),
        descriptionComment: 'Sterilization logs were complete.',
        likes: 6,
        isLiked: false,
      ),
      _buildAuditPost(
        id: 'audit-002',
        seatName: 'Web Developer',
        postedByName: 'Maya Chen',
        departmentName: 'Web Developer',
        status: 'Needs Improvement',
        auditedAt: '18 Jun, 2026',
        auditedBy: 'Sofia Turner',
        imageUrls: _gallery('audit-front-desk', 8),
        descriptionComment:
            'Phones were answered promptly, but two callback notes were still missing. The team logged follow-up actions before closeout. A final verification pass is needed tomorrow morning.',
        likes: 12,
        isLiked: true,
      ),
      _buildLearningPost(
        id: 'learning-001',
        seatName: 'Trainings Manager',
        postedByName: 'Ava Patel',
        departmentName: 'Trainings Manager',
        status: 'Compliant',
        dueBy: '2 days',
        deadlineDate: '22 Jun, 2026',
        schedule: 'Weekly',
        imageUrl: _image('learning-visionary'),
        mediaImageUrls: _gallery('learning-visionary-multi', 3),
        likes: 24,
      ),
      _buildDocumentPost(
        id: 'document-001',
        seatName: 'Supply Chain',
        postedByName: 'Leo Ramirez',
        departmentName: 'Supply Chain',
        status: 'Pending Submission',
        dueBy: '1 day',
        imageUrl: '',
        descriptionComment:
            'Policy acknowledgment is still missing for one shift lead and needs a final review. Once the signature page is uploaded, the compliance desk will close the pending action. Please confirm the revised copy is shared with the team channel before end of day. The department tracker has already been updated with the current owner and due date. A final leadership signoff is still required before the record can be archived.',
        likes: 3,
      ),
      _buildAuditPost(
        id: 'audit-003',
        seatName: 'Management Trainiees',
        postedByName: 'Emma Clarke',
        departmentName: 'Management Trainiees',
        status: 'Bad',
        auditedAt: '20 Jun, 2026',
        auditedBy: 'Jordan White',
        imageUrls: _gallery('audit-marketing', 1),
        descriptionComment:
            'Campaign proof approvals were delayed and two final assets were missing version notes. The team has already updated the file history and added approval checkpoints. One final review is still pending.',
        likes: 7,
      ),
      _buildLearningPost(
        id: 'learning-002',
        seatName: 'Technical Manager',
        postedByName: 'Harper Lewis',
        departmentName: 'Technical Manager',
        status: 'In Progress',
        dueBy: '4 days',
        deadlineDate: '24 Jun, 2026',
        schedule: 'Monthly',
        imageUrl: _image('learning-hr'),
        likes: 10,
      ),
      _buildDocumentPost(
        id: 'document-002',
        seatName: 'Administrative Manager',
        postedByName: 'Noah Foster',
        departmentName: 'Administrative Manager',
        status: 'Compliant',
        dueBy: 'Today',
        imageUrl: _image('document-dental-assist'),
        descriptionComment:
            'Chairside equipment checklist and sterilization signoff forms are fully compliant.',
        likes: 18,
      ),
      _buildLearningPost(
        id: 'learning-003',
        seatName: 'Administrator',
        postedByName: 'Olivia Hall',
        departmentName: 'Administrator',
        status: 'Compliant',
        dueBy: '6 days',
        deadlineDate: '26 Jun, 2026',
        schedule: 'Quarterly',
        imageUrl: _image('learning-it-video-thumb'),
        videoUrl: _sampleVideoUrl,
        likes: 31,
        isLiked: true,
      ),
      _buildAuditPost(
        id: 'audit-004',
        seatName: 'Engineering Manager',
        postedByName: 'Lucas Green',
        departmentName: 'Engineering Manager',
        status: 'Good',
        auditedAt: '21 Jun, 2026',
        auditedBy: 'Grace Kim',
        imageUrls: _gallery('audit-back-desk', 1),
        descriptionComment:
            'Supply labeling, tray setup, and room turnover timing met the expected weekly standard.',
        likes: 15,
      ),
      _buildDocumentPost(
        id: 'document-003',
        seatName: 'Quality Assurance',
        postedByName: 'Mason Adams',
        departmentName: 'Quality Assurance',
        status: 'Pending Approval',
        dueBy: '3 days',
        imageUrl: _image('document-facility'),
        descriptionComment:
            'Emergency shutoff walkthrough was uploaded as video, but the monthly inspection note is incomplete. Maintenance has already attached the clip and updated the routing checklist. The remaining task is a supervisor signoff on the final inspection summary. Once that is uploaded, the record can move to the completed bucket. Please keep the supporting media linked for the next scheduled review cycle. This item is still being tracked in the daily facilities follow-up board.',
        likes: 5,
      ),
      _buildLearningPost(
        id: 'learning-004',
        seatName: 'Trainings Manager',
        postedByName: 'Ella Scott',
        departmentName: 'Trainings Manager',
        status: 'Non-Compliance',
        dueBy: 'Overdue',
        deadlineDate: '12 Jun, 2026',
        schedule: 'Daily',
        imageUrl: _image('learning-front-desk-lead'),
        mediaImageUrls: _gallery('learning-front-desk-lead-multi', 4),
        likes: 2,
      ),
      _buildAuditPost(
        id: 'audit-005',
        seatName: 'Web Developer',
        postedByName: 'Chloe Baker',
        departmentName: 'Web Developer',
        status: 'Needs Improvement',
        auditedAt: '22 Jun, 2026',
        auditedBy: 'Isla Morgan',
        imageUrls: _gallery('audit-dental-assist', 9),
        descriptionComment:
            'Tray organization was strong, but one patient note was signed late after the room turnover.',
        likes: 22,
        isLiked: true,
      ),
      _buildDocumentPost(
        id: 'document-004',
        seatName: 'Supply Chain',
        postedByName: 'Jack Turner',
        departmentName: 'Supply Chain',
        status: 'Rejected',
        dueBy: '5 days',
        imageUrl: _image('document-visionary'),
        descriptionComment:
            'Leadership charter and accountability summary were approved and distributed successfully.',
        likes: 11,
      ),
      _buildLearningPost(
        id: 'learning-005',
        seatName: 'Technical Manager',
        postedByName: 'Mila Rivera',
        departmentName: 'Technical Manager',
        status: 'In Progress',
        dueBy: '8 days',
        deadlineDate: '28 Jun, 2026',
        schedule: 'Bi-Weekly',
        imageUrl: _image('learning-marketing-video-thumb'),
        videoUrl: _sampleVideoUrl,
        likes: 17,
      ),
      _buildAuditPost(
        id: 'audit-006',
        seatName: 'Management Trainiees',
        postedByName: 'Benjamin King',
        departmentName: 'Management Trainiees',
        status: 'Bad',
        auditedAt: '23 Jun, 2026',
        auditedBy: 'Amelia Watson',
        imageUrls: _gallery('audit-it', 2),
        descriptionComment:
            'Device inventory was accurate, but one workstation was missing the required patch verification note.',
        likes: 9,
      ),
      _buildDocumentPost(
        id: 'document-005',
        seatName: 'Administrative Manager',
        postedByName: 'Scarlett Ward',
        departmentName: 'Administrative Manager',
        status: 'Rejected',
        dueBy: 'Tomorrow',
        imageUrl: _image('document-hr-video-thumb'),
        descriptionComment:
            'Candidate privacy acknowledgment needs to be re-uploaded with the missing signature page.',
        likes: 4,
      ),
      _buildLearningPost(
        id: 'learning-006',
        seatName: 'Administrator',
        postedByName: 'Henry Carter',
        departmentName: 'Administrator',
        status: 'Compliant',
        dueBy: '10 days',
        deadlineDate: '30 Jun, 2026',
        schedule: 'Monthly',
        imageUrl: _image('learning-facility'),
        mediaImageUrls: _gallery('learning-facility-multi', 5),
        likes: 13,
      ),
      _buildAuditPost(
        id: 'audit-007',
        seatName: 'Engineering Manager',
        postedByName: 'Lily Evans',
        departmentName: 'Engineering Manager',
        status: 'Good',
        auditedAt: '24 Jun, 2026',
        auditedBy: 'Daniel Ross',
        imageUrls: _gallery('audit-integrator', 1),
        descriptionComment:
            'Morning huddle action items were tracked cleanly and handoff blockers were resolved before noon.',
        likes: 19,
      ),
      _buildDocumentPost(
        id: 'document-006',
        seatName: 'Quality Assurance',
        postedByName: 'Aria Murphy',
        departmentName: 'Quality Assurance',
        status: 'Pending Approval',
        dueBy: '7 days',
        imageUrl: _image('document-front-desk'),
        descriptionComment:
            'Shift expectations document was uploaded, but the customer recovery section still needs signoff.',
        likes: 8,
      ),
      _buildLearningPost(
        id: 'learning-007',
        seatName: 'Administrator',
        postedByName: 'James Cooper',
        departmentName: 'Administrator',
        status: 'Non-Compliance',
        dueBy: '1 day',
        deadlineDate: '21 Jun, 2026',
        schedule: 'Weekly',
        imageUrl: _image('learning-dental-assist'),
        likes: 27,
      ),
    ]);
  }

  KaizengramFeedItem _buildAuditPost({
    required String id,
    required String seatName,
    required String postedByName,
    required String departmentName,
    required String status,
    required String auditedAt,
    required String auditedBy,
    required List<String> imageUrls,
    required String descriptionComment,
    required int likes,
    bool isLiked = false,
  }) {
    final normalizedImages = imageUrls
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final comments = _buildCommentThread(
      descriptionAuthor: auditedBy,
      descriptionMessage: descriptionComment,
      avatarUrl: normalizedImages.isEmpty ? null : normalizedImages.first,
      replies: _buildAuditReplies(
        seed: id,
        seatName: seatName,
        postedByName: postedByName,
        departmentName: departmentName,
        auditedBy: auditedBy,
        auditedAt: auditedAt,
      ),
    );
    final auditMediaItems = _buildAuditMediaItems(
      seed: id,
      thumbnails: normalizedImages,
      seatName: seatName,
      postedByName: postedByName,
      departmentName: departmentName,
      auditedBy: auditedBy,
    );
    final resolvedStatus = _resolveAuditStatus(auditMediaItems);

    return KaizengramFeedItem(
      id: id,
      type: KaizengramFeedType.learningCompliance,
      postCategory: KaizengramPostCategory.audit,
      mediaKind: normalizedImages.length > 1
          ? KaizengramFeedMediaKind.gallery
          : KaizengramFeedMediaKind.image,
      title: seatName,
      description: descriptionComment,
      status: resolvedStatus,
      seatProfile: departmentName,
      rawDeadline: null,
      dueBy: null,
      deadlineDate: null,
      schedule: null,
      trackAssignmentUuid: null,
      documentPreviewUrl: normalizedImages.isEmpty
          ? null
          : normalizedImages.first,
      feedImageUrl: normalizedImages.isEmpty ? null : normalizedImages.first,
      feedVideoUrl: null,
      subtitle: 'Posted by $postedByName',
      timestampLabel: auditedAt,
      likes: likes,
      comments: comments.length,
      isLiked: isLiked,
      postedByName: postedByName,
      departmentName: departmentName,
      auditedAt: auditedAt,
      auditedBy: auditedBy,
      mediaUrls: normalizedImages,
      headerImageUrl: _personImage(auditedBy),
      commentThread: comments,
      auditMediaItems: auditMediaItems,
    );
  }

  KaizengramFeedItem _buildLearningPost({
    required String id,
    required String seatName,
    required String postedByName,
    required String departmentName,
    required String status,
    required String dueBy,
    required String deadlineDate,
    required String schedule,
    required String imageUrl,
    required int likes,
    List<String>? mediaImageUrls,
    String? videoUrl,
    bool isLiked = false,
  }) {
    final normalizedImageUrl = imageUrl.trim().isEmpty ? null : imageUrl.trim();
    final normalizedVideoUrl = videoUrl?.trim();
    final normalizedMediaUrls = (mediaImageUrls ?? <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final resolvedPrimaryImageUrl =
        normalizedImageUrl ??
        (normalizedMediaUrls.isEmpty ? null : normalizedMediaUrls.first);
    final comments = _buildCommentThread(
      descriptionAuthor: null,
      descriptionMessage: null,
      avatarUrl: resolvedPrimaryImageUrl,
      replies: _buildLearningReplies(
        seed: id,
        seatName: seatName,
        postedByName: postedByName,
        departmentName: departmentName,
        status: status,
        deadlineDate: deadlineDate,
        schedule: schedule,
      ),
    );

    return KaizengramFeedItem(
      id: id,
      type: KaizengramFeedType.learningCompliance,
      postCategory: KaizengramPostCategory.learningCompliance,
      mediaKind: normalizedVideoUrl != null && normalizedVideoUrl.isNotEmpty
          ? KaizengramFeedMediaKind.video
          : normalizedMediaUrls.length > 1
          ? KaizengramFeedMediaKind.gallery
          : KaizengramFeedMediaKind.image,
      title: seatName,
      description: '',
      status: status,
      seatProfile: departmentName,
      rawDeadline: deadlineDate,
      dueBy: dueBy,
      deadlineDate: deadlineDate,
      schedule: schedule,
      trackAssignmentUuid: null,
      documentPreviewUrl: null,
      feedImageUrl: resolvedPrimaryImageUrl,
      feedVideoUrl: normalizedVideoUrl?.isEmpty == true
          ? null
          : normalizedVideoUrl,
      subtitle: 'Posted by $postedByName',
      timestampLabel: dueBy,
      likes: likes,
      comments: comments.length,
      isLiked: isLiked,
      postedByName: postedByName,
      departmentName: departmentName,
      mediaUrls: normalizedMediaUrls.isNotEmpty
          ? normalizedMediaUrls
          : resolvedPrimaryImageUrl == null
          ? const <String>[]
          : <String>[resolvedPrimaryImageUrl],
      headerImageUrl: _personImage(postedByName),
      commentThread: comments,
    );
  }

  KaizengramFeedItem _buildDocumentPost({
    required String id,
    required String seatName,
    required String postedByName,
    required String departmentName,
    required String status,
    required String dueBy,
    required String imageUrl,
    required String descriptionComment,
    required int likes,
    String? videoUrl,
    bool isLiked = false,
  }) {
    final normalizedImageUrl = imageUrl.trim().isEmpty ? null : imageUrl.trim();
    final normalizedVideoUrl = videoUrl?.trim();
    final comments = _buildCommentThread(
      descriptionAuthor: postedByName,
      descriptionMessage: descriptionComment,
      avatarUrl: normalizedImageUrl,
      replies: _buildDocumentReplies(
        seed: id,
        seatName: seatName,
        postedByName: postedByName,
        departmentName: departmentName,
        status: status,
        dueBy: dueBy,
      ),
    );

    return KaizengramFeedItem(
      id: id,
      type: KaizengramFeedType.documentCompliance,
      postCategory: KaizengramPostCategory.documentCompliance,
      mediaKind: normalizedVideoUrl != null && normalizedVideoUrl.isNotEmpty
          ? KaizengramFeedMediaKind.video
          : KaizengramFeedMediaKind.image,
      title: seatName,
      description: descriptionComment,
      status: status,
      seatProfile: departmentName,
      rawDeadline: dueBy,
      dueBy: dueBy,
      deadlineDate: null,
      schedule: null,
      trackAssignmentUuid: null,
      documentPreviewUrl:
          normalizedVideoUrl != null && normalizedVideoUrl.isNotEmpty
          ? normalizedVideoUrl
          : normalizedImageUrl,
      feedImageUrl: normalizedImageUrl,
      feedVideoUrl: normalizedVideoUrl?.isEmpty == true
          ? null
          : normalizedVideoUrl,
      subtitle: 'Posted by $postedByName',
      timestampLabel: dueBy,
      likes: likes,
      comments: comments.length,
      isLiked: isLiked,
      postedByName: postedByName,
      departmentName: departmentName,
      mediaUrls: normalizedImageUrl == null
          ? const <String>[]
          : <String>[normalizedImageUrl],
      headerImageUrl: _personImage(postedByName),
      commentThread: comments,
    );
  }

  List<KaizengramComment> _buildCommentThread({
    required String? descriptionAuthor,
    required String? descriptionMessage,
    required String? avatarUrl,
    required List<({String author, String message, String time})> replies,
    bool descriptionFirst = true,
  }) {
    final threadedReplies = replies
        .map(
          (reply) => KaizengramComment(
            id: 'comment-reply-${reply.author}-${reply.time}-${reply.message.hashCode}',
            authorName: reply.author,
            message: reply.message,
            timestampLabel: reply.time,
            avatarUrl: avatarUrl,
          ),
        )
        .toList(growable: false);

    final comments = <KaizengramComment>[
      if (threadedReplies.isNotEmpty)
        KaizengramComment(
          id: 'comment-root-${threadedReplies.first.authorName}-${threadedReplies.first.timestampLabel}-${threadedReplies.first.message.hashCode}',
          authorName: threadedReplies.first.authorName,
          message: threadedReplies.first.message,
          timestampLabel: threadedReplies.first.timestampLabel,
          avatarUrl: threadedReplies.first.avatarUrl,
          replies: threadedReplies.skip(1).toList(growable: false),
        ),
    ];

    final normalizedDescription = descriptionMessage?.trim();
    final normalizedAuthor = descriptionAuthor?.trim();
    if (normalizedDescription != null &&
        normalizedDescription.isNotEmpty &&
        normalizedAuthor != null &&
        normalizedAuthor.isNotEmpty) {
      final descriptionComment = KaizengramComment(
        id: 'comment-description-$normalizedAuthor-${normalizedDescription.hashCode}',
        authorName: normalizedAuthor,
        message: normalizedDescription,
        timestampLabel: 'Now',
        avatarUrl: avatarUrl,
        isDescription: true,
      );
      if (descriptionFirst) {
        comments.insert(0, descriptionComment);
      } else {
        comments.add(descriptionComment);
      }
    }

    return comments;
  }

  T _seededValue<T>(String seed, List<T> values, {int offset = 0}) {
    return values[(seed.hashCode.abs() + offset) % values.length];
  }

  List<({String author, String message, String time})> _buildLearningReplies({
    required String seed,
    required String seatName,
    required String postedByName,
    required String departmentName,
    required String status,
    required String deadlineDate,
    required String schedule,
  }) {
    const followUpOwners = <String>[
      'Nora Bennett',
      'Ethan Cole',
      'Sana Malik',
      'Liam Porter',
      'Ariana West',
      'Jude Mercer',
      'Clara Vaughn',
    ];
    const supportReviewers = <String>[
      'Mira Lawson',
      'Theo Ramsey',
      'Isabel Hart',
      'Rowan Blake',
      'Carter Flynn',
      'Leah Dixon',
      'Miles Avery',
    ];
    const completionFocuses = <String>[
      'checkpoint signoff',
      'coach acknowledgment',
      'team confirmation',
      'attendance detail',
      'manager review',
      'module summary',
      'final quiz note',
    ];
    const handoffActions = <String>[
      'queued the remaining module for the next handoff',
      'marked the remaining checkpoint for tomorrow morning',
      'assigned the final acknowledgment before the next review',
      'added the completion note to the team board',
      'moved the last confirmation into the current training queue',
      'lined up the final approval in the department tracker',
      'flagged the remaining review for the next learning sync',
    ];
    const supportClosures = <String>[
      'The next sync will verify the completion snapshot before the dashboard refreshes again.',
      'The training desk will confirm the updated progress after the next submission window closes.',
      'We will recheck the completion status once the final checkpoint lands in the queue.',
      'The reviewer will validate the updated learning log during the next scheduled pass.',
      'The dashboard will pick up the latest completion note after the review team signs off.',
      'The next follow-up will compare the updated module status against the department tracker.',
      'The support review will close this out after the final confirmation is attached.',
    ];
    const ownerTimes = <String>['1h', '53m', '46m', '39m', '31m', '24m', '18m'];
    const reviewerTimes = <String>[
      '26m',
      '21m',
      '16m',
      '12m',
      '9m',
      '6m',
      '3m',
    ];

    final ownerName = _seededValue('$seed-learning-owner', followUpOwners);
    final reviewerName = _seededValue(
      '$seed-learning-reviewer',
      supportReviewers,
      offset: 1,
    );
    final focusIndex = seed.hashCode.abs() % completionFocuses.length;

    return <({String author, String message, String time})>[
      (
        author: ownerName,
        message:
            'I reviewed the $seatName learning assignment with $postedByName and ${handoffActions[focusIndex]} before the $deadlineDate $schedule cycle. The main focus is the ${completionFocuses[focusIndex]}.',
        time: ownerTimes[focusIndex],
      ),
      (
        author: reviewerName,
        message:
            '$departmentName is currently marked as $status, and ${supportClosures[focusIndex]}',
        time: reviewerTimes[focusIndex],
      ),
    ];
  }

  List<({String author, String message, String time})> _buildDocumentReplies({
    required String seed,
    required String seatName,
    required String postedByName,
    required String departmentName,
    required String status,
    required String dueBy,
  }) {
    const coordinators = <String>[
      'Brooke Ellis',
      'Caleb Foster',
      'Naomi Pierce',
      'Gavin Reid',
      'Elise Warren',
      'Jonah Fields',
      'Tessa Monroe',
    ];
    const reviewers = <String>[
      'Priya Dalton',
      'Marcus Hale',
      'Daphne Cruz',
      'Owen Barrett',
      'Sienna Watts',
      'Grant Palmer',
      'Lola Mercer',
    ];
    const documentNeeds = <String>[
      'the updated attachment owner',
      'the missing signature page',
      'the final supervisor note',
      'the corrected upload timestamp',
      'the revised approval copy',
      'the department handoff file',
      'the last verification detail',
    ];
    const coordinationActions = <String>[
      'The file owner has already been pinged and the replacement upload is being tracked in the shared board.',
      'The follow-up has been assigned and the revised document is now part of today\'s closeout list.',
      'The current owner note is in place and the team is waiting on the final upload window.',
      'The re-upload step is now assigned, and the department tracker already reflects the updated owner.',
      'The outstanding attachment has been requested and the review team is monitoring the submission window.',
      'The supporting file has been queued for recheck and the owner has the next-action reminder.',
      'The pending document step is already assigned and the team is watching for the updated proof.',
    ];
    const reviewerClosures = <String>[
      'Once the corrected file lands, I will move the record into the next verification pass.',
      'After the latest upload is attached, this status will be rechecked against the compliance queue.',
      'As soon as the revised copy is submitted, I will update the record and close the follow-up loop.',
      'The next review pass will compare the new attachment against the pending compliance note.',
      'I will reopen the document review as soon as the remaining proof is attached.',
      'The compliance queue will refresh after the updated record is uploaded and verified.',
      'The next validation pass will start once the missing proof is added to this thread.',
    ];
    const coordinatorTimes = <String>[
      '58m',
      '49m',
      '42m',
      '35m',
      '27m',
      '19m',
      '14m',
    ];
    const reviewerTimes = <String>['18m', '15m', '11m', '8m', '6m', '4m', '2m'];

    final offset = seed.hashCode.abs() % documentNeeds.length;
    final coordinatorName = _seededValue(
      '$seed-document-owner',
      coordinators,
      offset: 1,
    );
    final reviewerName = _seededValue(
      '$seed-document-reviewer',
      reviewers,
      offset: 2,
    );

    return <({String author, String message, String time})>[
      (
        author: coordinatorName,
        message:
            'I checked the $seatName document request with $postedByName. We are still waiting on ${documentNeeds[offset]}, and $coordinationActions[offset]',
        time: coordinatorTimes[offset],
      ),
      (
        author: reviewerName,
        message:
            '$departmentName is currently $status with $dueBy remaining. ${reviewerClosures[offset]}',
        time: reviewerTimes[offset],
      ),
    ];
  }

  List<({String author, String message, String time})> _buildAuditReplies({
    required String seed,
    required String seatName,
    required String postedByName,
    required String departmentName,
    required String auditedBy,
    required String auditedAt,
  }) {
    const followUpOwners = <String>[
      'Mira Collins',
      'Jonah Scott',
      'Piper Adams',
      'Reid Hudson',
      'Nina Flores',
      'Cole Bennett',
      'Talia Brooks',
    ];
    const qaReviewers = <String>[
      'Rhea Morgan',
      'Dylan Price',
      'Avery Sutton',
      'Miles Cross',
      'Lena Walsh',
      'Noel Harper',
      'Zara Quinn',
    ];
    const departmentCoordinators = <String>[
      'Ivy Richardson',
      'Logan Pierce',
      'Sophie Randall',
      'Eli Donovan',
      'Cora Griffin',
      'Wyatt Turner',
      'Mila Sanders',
    ];
    const ownerClosures = <String>[
      'reassigned the missed handoff step',
      'updated the checklist owner',
      'moved the follow-up to the shift lead',
      'posted the revised closeout note',
      'queued the final verification step',
      'logged the missing calibration item',
      'assigned the room-readiness recheck',
    ];
    const qaRequests = <String>[
      'recheck the updated workflow against the attached media',
      'compare the corrected process with this week\'s evidence',
      'verify the closeout changes using the uploaded captures',
      'review the before-and-after proof on the next pass',
      'confirm the corrected handoff flow from the attached media',
      'validate the revised sequence with the current evidence set',
      'confirm the team update against this thread\'s supporting media',
    ];
    const teamFocuses = <String>[
      'handoff notes',
      'checklist updates',
      'photo proof',
      'closing tasks',
      'shift-owner follow-up',
      'verification steps',
      'signoff items',
    ];
    const teamTimelines = <String>[
      'before the next audit window.',
      'during tomorrow morning\'s huddle.',
      'before the next weekly check-in opens.',
      'by the end of today\'s closeout.',
      'during the next team walkthrough.',
      'before the next reviewer pass.',
      'in the next shift handoff.',
    ];
    const ownerTimes = <String>[
      '47m',
      '43m',
      '39m',
      '34m',
      '29m',
      '24m',
      '19m',
    ];
    const qaTimes = <String>['26m', '22m', '17m', '14m', '11m', '8m', '5m'];
    const teamTimes = <String>[
      'Just now',
      '3m',
      '6m',
      '9m',
      '12m',
      '15m',
      '18m',
    ];

    final index = seed.hashCode.abs();
    final normalizedAuditDate = auditedAt.trim().isEmpty
        ? 'this week'
        : auditedAt;
    final ownerName = _seededValue('$seed-audit-owner', followUpOwners);
    final reviewerName = _seededValue(
      '$seed-audit-reviewer',
      qaReviewers,
      offset: 1,
    );
    final coordinatorName = _seededValue(
      '$seed-audit-coordinator',
      departmentCoordinators,
      offset: 2,
    );

    return <({String author, String message, String time})>[
      (
        author: ownerName,
        message:
            'I reviewed the $seatName findings with $postedByName and the $departmentName team, then ${ownerClosures[index % ownerClosures.length]} after $auditedBy\'s check-in.',
        time: ownerTimes[index % ownerTimes.length],
      ),
      (
        author: reviewerName,
        message:
            'Please keep the supporting media attached so $auditedBy can ${qaRequests[index % qaRequests.length]} from the $normalizedAuditDate review.',
        time: qaTimes[index % qaTimes.length],
      ),
      (
        author: coordinatorName,
        message:
            'The $departmentName action items are now tracked, and the team will close the remaining ${teamFocuses[index % teamFocuses.length]} ${teamTimelines[index % teamTimelines.length]}',
        time: teamTimes[index % teamTimes.length],
      ),
    ];
  }

  List<KaizengramAuditMediaItem> _buildAuditMediaItems({
    required String seed,
    required List<String> thumbnails,
    required String seatName,
    required String postedByName,
    required String departmentName,
    required String auditedBy,
  }) {
    final previewImages = thumbnails.isEmpty
        ? <String>[
            _image('$seed-preview-1'),
            _image('$seed-preview-2'),
            _image('$seed-preview-3'),
          ]
        : thumbnails;

    String imageAt(int index) {
      if (previewImages.isEmpty) {
        return _image('$seed-fallback-$index');
      }

      return previewImages[index % previewImages.length];
    }

    const titles = <String>[
      'setup area review',
      'handoff walkthrough',
      'documentation closeout',
      'patient flow snapshot',
      'weekly station check',
      'team coordination note',
      'final compliance capture',
      'workspace readiness shot',
      'review summary media',
    ];
    const ratings = <KaizengramAuditRating>[
      KaizengramAuditRating.good,
      KaizengramAuditRating.needsImprovement,
      KaizengramAuditRating.bad,
      KaizengramAuditRating.good,
      KaizengramAuditRating.needsImprovement,
      KaizengramAuditRating.good,
      KaizengramAuditRating.bad,
      KaizengramAuditRating.good,
      KaizengramAuditRating.needsImprovement,
    ];

    return List<KaizengramAuditMediaItem>.generate(previewImages.length, (
      index,
    ) {
      final isVideoItem = previewImages.length > 1 && index % 4 == 1;
      final title = '$seatName ${titles[index % titles.length]}';
      final rating = ratings[index % ratings.length];
      return KaizengramAuditMediaItem(
        id: '$seed-media-${index + 1}',
        title: title,
        thumbnailUrl: imageAt(index),
        videoUrl: isVideoItem ? _sampleVideoUrl : null,
        rating: rating,
        commentThread: _buildAuditMediaCommentThread(
          seed: seed,
          index: index,
          title: title,
          thumbnailUrl: imageAt(index),
          postedByName: postedByName,
          departmentName: departmentName,
          auditedBy: auditedBy,
          rating: rating,
        ),
      );
    }, growable: false);
  }

  List<KaizengramComment> _buildAuditMediaCommentThread({
    required String seed,
    required int index,
    required String title,
    required String thumbnailUrl,
    required String postedByName,
    required String departmentName,
    required String auditedBy,
    required KaizengramAuditRating rating,
  }) {
    const mediaOwners = <String>[
      'Kara Bennett',
      'Lucas Shaw',
      'Mina Lawson',
      'Evan Drake',
      'Ruby Clarke',
      'Hugo Bennett',
      'Sara Medina',
    ];
    const mediaReviewers = <String>[
      'Paige Nolan',
      'Tristan Cole',
      'Nadia Ross',
      'Graham Wells',
      'Ayla Dean',
      'Mason Reed',
      'Farah Lane',
    ];
    const mediaCoordinators = <String>[
      'Olive Grant',
      'Declan Reese',
      'Celia Hart',
      'Beau Fisher',
      'Remi Stone',
      'Julian Parks',
      'Esme Ford',
    ];
    const findingDetails = <String>[
      'The captured handoff looked aligned, but one verification detail still needed a clearer owner note.',
      'This evidence highlighted a partial closeout where the final confirmation step was still missing.',
      'The media showed the team sequence clearly, but one checkpoint was still out of order during review.',
      'This snapshot confirmed the update was started, though the final signoff detail had not been logged yet.',
      'The evidence was strong overall, but one follow-up detail still needed to be attached before closeout.',
      'The captured workflow was mostly correct, although one readiness step needed another pass.',
      'This media made the gap easy to spot because the last documented check had not been reflected yet.',
    ];
    const ownerResponses = <String>[
      'I reviewed this specific item with the team and reassigned the correction before closeout.',
      'I walked through this finding with the shift lead and updated the owner note immediately after the review.',
      'I used this capture in the follow-up huddle and logged the missing step with the current owner.',
      'I shared this evidence with the team and added the correction plan to today\'s action board.',
      'I reviewed this exact point with the team lead and moved the remaining task into the next handoff list.',
      'I closed the gap review on this item and assigned the remaining check to the current owner.',
      'I used this media during follow-up and documented the correction path for the next reviewer pass.',
    ];
    const qaFollowUps = <String>[
      'Please keep this media linked so the next weekly check-in can verify the corrected step.',
      'Leave this evidence attached so the next reviewer can compare the updated workflow side by side.',
      'Keep this capture in the thread so the follow-up pass can confirm the corrected handoff.',
      'Please retain this media in the thread so the next audit can validate the closeout detail.',
      'Hold onto this proof so the next weekly review can verify the documented update.',
      'Keep this item attached because it will be used to confirm the next verification pass.',
      'Please preserve this evidence so the next walkthrough can compare the updated sequence.',
    ];
    const departmentClosures = <String>[
      'The remaining action item is now on the team board and will be confirmed in the next huddle.',
      'The team has already logged the follow-up and will confirm completion during the next shift handoff.',
      'This item is now assigned and will be rechecked before the next audit window opens.',
      'The team captured the follow-up owner and will confirm it in the next closeout review.',
      'The current action is documented and will be verified during the next team walkthrough.',
      'The final check is assigned and will be revalidated before the next reviewer pass.',
      'The team logged the next step and will confirm closure in the upcoming weekly check-in.',
    ];
    const ownerTimes = <String>[
      '42m',
      '38m',
      '33m',
      '27m',
      '22m',
      '17m',
      '13m',
    ];
    const qaTimes = <String>['24m', '19m', '15m', '12m', '9m', '6m', '4m'];
    const departmentTimes = <String>[
      'Just now',
      '2m',
      '5m',
      '7m',
      '10m',
      '14m',
      '18m',
    ];

    final offset = (seed.hashCode.abs() + index) % findingDetails.length;
    final ownerName = _seededValue(
      '$seed-media-owner-$index',
      mediaOwners,
      offset: 1,
    );
    final reviewerName = _seededValue(
      '$seed-media-reviewer-$index',
      mediaReviewers,
      offset: 2,
    );
    final coordinatorName = _seededValue(
      '$seed-media-coordinator-$index',
      mediaCoordinators,
      offset: 3,
    );
    final ratingLabel = switch (rating) {
      KaizengramAuditRating.good => 'Good',
      KaizengramAuditRating.needsImprovement => 'Needs Improvement',
      KaizengramAuditRating.bad => 'Bad',
    };

    return _buildCommentThread(
      descriptionAuthor: auditedBy,
      descriptionMessage:
          '$title was marked as $ratingLabel. ${findingDetails[offset]}',
      avatarUrl: thumbnailUrl,
      descriptionFirst: false,
      replies: <({String author, String message, String time})>[
        (
          author: ownerName,
          message:
              '${ownerResponses[offset]} $postedByName already reviewed this thread for $title.',
          time: ownerTimes[offset],
        ),
        (
          author: reviewerName,
          message: qaFollowUps[offset],
          time: qaTimes[offset],
        ),
        (
          author: coordinatorName,
          message:
              '${departmentClosures[offset]} $departmentName is tracking $title separately.',
          time: departmentTimes[offset],
        ),
      ],
    );
  }

  String _resolveAuditStatus(List<KaizengramAuditMediaItem> mediaItems) {
    var badCount = 0;
    var needsImprovementCount = 0;
    var goodCount = 0;

    for (final item in mediaItems) {
      switch (item.rating) {
        case KaizengramAuditRating.bad:
          badCount++;
        case KaizengramAuditRating.needsImprovement:
          needsImprovementCount++;
        case KaizengramAuditRating.good:
          goodCount++;
      }
    }

    if (goodCount >= badCount && goodCount >= needsImprovementCount) {
      return 'Excellent';
    }

    if (needsImprovementCount >= badCount) {
      return 'Needs Improvement';
    }

    return 'Bad';
  }

  List<String> _gallery(String seed, int count) {
    return List<String>.generate(
      count,
      (index) => _image('$seed-${index + 1}'),
      growable: false,
    );
  }

  String? _personImage(String value) {
    final normalizedValue = value.trim();
    if (normalizedValue.isEmpty) {
      return null;
    }

    return 'https://i.pravatar.cc/150?u=${Uri.encodeComponent(normalizedValue.toLowerCase())}';
  }

  String _image(String seed) {
    return _imageAssignments.putIfAbsent(seed, () {
      final image = _workplaceImages[_nextImageIndex % _workplaceImages.length];
      _nextImageIndex++;
      return image;
    });
  }

  static const String _sampleVideoUrl =
      'https://videos.pexels.com/video-files/3209828/3209828-uhd_2560_1440_25fps.mp4';

  static const List<String> _workplaceImages = <String>[
    'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1553877522-43269d4ea984?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1516321497487-e288fb19713f?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1573164713714-d95e436ab8d6?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1556761175-b413da4baf72?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1553028826-f4804a6dba3b?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1552581234-26160f608093?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1573496773905-f5b17e717f05?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1559136555-9303baea8ebd?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1551836022-deb4988cc6c0?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1600880292089-90a7e086ee0c?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1604328698692-f76ea9498e76?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1497215842964-222b430dc094?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1497366412874-3415097a27e7?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1497366811353-6870744d04b2?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1541534401786-2077eed87a72?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1517502884422-41eaead166d4?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1559136653-1c7f2d2e37f5?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1504384764586-bb4cdc1707b0?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1557800636-894a64c1696f?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1557804503-669a67965ba0?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1573497491208-6b1acb260507?auto=format&fit=crop&w=1200&q=80',
    'https://images.unsplash.com/photo-1487014679447-9f8336841d58?auto=format&fit=crop&w=1200&q=80',
  ];
}

class KaizengramStory {
  const KaizengramStory({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;
}

class KaizengramFeedItem {
  const KaizengramFeedItem({
    required this.id,
    required this.type,
    this.postCategory,
    this.mediaKind,
    required this.title,
    required this.description,
    this.status,
    required this.seatProfile,
    this.rawDeadline,
    this.dueBy,
    this.deadlineDate,
    this.schedule,
    this.trackAssignmentUuid,
    this.documentPreviewUrl,
    required this.feedImageUrl,
    required this.feedVideoUrl,
    required this.subtitle,
    required this.timestampLabel,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.postedByName = '',
    this.departmentName,
    this.auditedAt,
    this.auditedBy,
    this.mediaUrls = const <String>[],
    this.headerImageUrl,
    this.commentThread = const <KaizengramComment>[],
    this.auditMediaItems = const <KaizengramAuditMediaItem>[],
  });

  final String id;
  final KaizengramFeedType type;
  final KaizengramPostCategory? postCategory;
  final KaizengramFeedMediaKind? mediaKind;
  final String title;
  final String description;
  final String? status;
  final String seatProfile;
  final String? rawDeadline;
  final String? dueBy;
  final String? deadlineDate;
  final String? schedule;
  final String? trackAssignmentUuid;
  final String? documentPreviewUrl;
  final String? feedImageUrl;
  final String? feedVideoUrl;
  final String subtitle;
  final String timestampLabel;
  final int likes;
  final int comments;
  final bool isLiked;
  final String postedByName;
  final String? departmentName;
  final String? auditedAt;
  final String? auditedBy;
  final List<String> mediaUrls;
  final String? headerImageUrl;
  final List<KaizengramComment> commentThread;
  final List<KaizengramAuditMediaItem> auditMediaItems;

  KaizengramPostCategory get resolvedPostCategory {
    if (postCategory != null) {
      return postCategory!;
    }

    switch (type) {
      case KaizengramFeedType.learningCompliance:
        return KaizengramPostCategory.learningCompliance;
      case KaizengramFeedType.documentCompliance:
        return KaizengramPostCategory.documentCompliance;
    }
  }

  KaizengramFeedMediaKind get resolvedMediaKind {
    if (mediaKind != null) {
      return mediaKind!;
    }

    if (hasVideo) {
      return KaizengramFeedMediaKind.video;
    }

    if (mediaUrls.length > 1) {
      return KaizengramFeedMediaKind.gallery;
    }

    return KaizengramFeedMediaKind.image;
  }

  String? get avatarUrl {
    final normalizedImage = feedImageUrl?.trim();
    if (normalizedImage != null && normalizedImage.isNotEmpty) {
      return normalizedImage;
    }

    if (mediaUrls.isEmpty) {
      return null;
    }

    return mediaUrls.first.trim().isEmpty ? null : mediaUrls.first.trim();
  }

  String? get postHeaderAvatarUrl {
    final normalizedHeader = headerImageUrl?.trim();
    if (normalizedHeader != null && normalizedHeader.isNotEmpty) {
      return normalizedHeader;
    }

    return avatarUrl;
  }

  bool get hasVideo => (feedVideoUrl?.trim().isNotEmpty ?? false);
  bool get hasMultipleImages => mediaUrls.length > 1;

  KaizengramFeedItem copyWith({
    String? id,
    KaizengramFeedType? type,
    KaizengramPostCategory? postCategory,
    KaizengramFeedMediaKind? mediaKind,
    String? title,
    String? description,
    String? status,
    String? seatProfile,
    String? rawDeadline,
    String? dueBy,
    String? deadlineDate,
    String? schedule,
    String? trackAssignmentUuid,
    String? documentPreviewUrl,
    String? feedImageUrl,
    String? feedVideoUrl,
    String? subtitle,
    String? timestampLabel,
    int? likes,
    int? comments,
    bool? isLiked,
    String? postedByName,
    String? departmentName,
    String? auditedAt,
    String? auditedBy,
    List<String>? mediaUrls,
    String? headerImageUrl,
    List<KaizengramComment>? commentThread,
    List<KaizengramAuditMediaItem>? auditMediaItems,
  }) {
    return KaizengramFeedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      postCategory: postCategory ?? this.postCategory,
      mediaKind: mediaKind ?? this.mediaKind,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      seatProfile: seatProfile ?? this.seatProfile,
      rawDeadline: rawDeadline ?? this.rawDeadline,
      dueBy: dueBy ?? this.dueBy,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      schedule: schedule ?? this.schedule,
      trackAssignmentUuid: trackAssignmentUuid ?? this.trackAssignmentUuid,
      documentPreviewUrl: documentPreviewUrl ?? this.documentPreviewUrl,
      feedImageUrl: feedImageUrl ?? this.feedImageUrl,
      feedVideoUrl: feedVideoUrl ?? this.feedVideoUrl,
      subtitle: subtitle ?? this.subtitle,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      postedByName: postedByName ?? this.postedByName,
      departmentName: departmentName ?? this.departmentName,
      auditedAt: auditedAt ?? this.auditedAt,
      auditedBy: auditedBy ?? this.auditedBy,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      commentThread: commentThread ?? this.commentThread,
      auditMediaItems: auditMediaItems ?? this.auditMediaItems,
    );
  }
}

class KaizengramComment {
  const KaizengramComment({
    required this.id,
    required this.authorName,
    required this.message,
    required this.timestampLabel,
    this.avatarUrl,
    this.isDescription = false,
    this.attachments = const <KaizengramMessageAttachment>[],
    this.replies = const <KaizengramComment>[],
  });

  final String id;
  final String authorName;
  final String message;
  final String timestampLabel;
  final String? avatarUrl;
  final bool isDescription;
  final List<KaizengramMessageAttachment> attachments;
  final List<KaizengramComment> replies;

  KaizengramComment copyWith({
    String? id,
    String? authorName,
    String? message,
    String? timestampLabel,
    String? avatarUrl,
    bool? isDescription,
    List<KaizengramMessageAttachment>? attachments,
    List<KaizengramComment>? replies,
  }) {
    return KaizengramComment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      message: message ?? this.message,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDescription: isDescription ?? this.isDescription,
      attachments: attachments ?? this.attachments,
      replies: replies ?? this.replies,
    );
  }
}

class KaizengramSocialPost {
  const KaizengramSocialPost({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.channelName,
    required this.timeLabel,
    required this.message,
    this.mediaImagePath,
    this.mediaImageUrl,
    this.comments = const <KaizengramComment>[],
  });

  final String id;
  final String authorName;
  final String avatarUrl;
  final String channelName;
  final String timeLabel;
  final String message;
  final String? mediaImagePath;
  final String? mediaImageUrl;
  final List<KaizengramComment> comments;

  bool get hasMediaImage =>
      mediaImagePath?.trim().isNotEmpty == true ||
      mediaImageUrl?.trim().isNotEmpty == true;

  KaizengramSocialPost copyWith({
    String? id,
    String? authorName,
    String? avatarUrl,
    String? channelName,
    String? timeLabel,
    String? message,
    String? mediaImagePath,
    String? mediaImageUrl,
    List<KaizengramComment>? comments,
  }) {
    return KaizengramSocialPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      channelName: channelName ?? this.channelName,
      timeLabel: timeLabel ?? this.timeLabel,
      message: message ?? this.message,
      mediaImagePath: mediaImagePath ?? this.mediaImagePath,
      mediaImageUrl: mediaImageUrl ?? this.mediaImageUrl,
      comments: comments ?? this.comments,
    );
  }
}

class KaizengramNotificationSection {
  const KaizengramNotificationSection({
    required this.bucket,
    required this.items,
  });

  final KaizengramNotificationBucket bucket;
  final List<KaizengramNotificationItem> items;
}

class KaizengramNotificationItem {
  const KaizengramNotificationItem({
    required this.id,
    required this.actorName,
    required this.type,
    required this.post,
    required this.occurredAt,
    this.isUnread = false,
    this.targetCommentId,
  });

  final String id;
  final String actorName;
  final KaizengramNotificationType type;
  final KaizengramFeedItem post;
  final DateTime occurredAt;
  final bool isUnread;
  final String? targetCommentId;
}

class KaizengramAuditMediaItem {
  const KaizengramAuditMediaItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.rating,
    this.videoUrl,
    this.commentThread = const <KaizengramComment>[],
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final KaizengramAuditRating rating;
  final String? videoUrl;
  final List<KaizengramComment> commentThread;

  bool get hasThumbnail => thumbnailUrl.trim().isNotEmpty;
  bool get hasVideo => videoUrl?.trim().isNotEmpty ?? false;
}
