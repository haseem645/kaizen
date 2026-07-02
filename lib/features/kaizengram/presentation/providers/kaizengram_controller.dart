import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../data/datasources/kaizengram_remote_data_source.dart';

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
  KaizengramController(this._remoteDataSource);

  final KaizengramRemoteDataSource _remoteDataSource;
  final Map<String, String> _imageAssignments = <String, String>{};
  bool _isLoading = false;
  int _nextImageIndex = 0;
  String? _errorMessage;
  List<KaizengramFeedItem> _posts = const <KaizengramFeedItem>[];

  KaizengramRemoteDataSource get remoteDataSource => _remoteDataSource;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<KaizengramFeedItem> get posts =>
      List<KaizengramFeedItem>.unmodifiable(_posts);
  List<KaizengramNotificationItem> get notifications =>
      List<KaizengramNotificationItem>.unmodifiable(_buildNotifications());
  List<KaizengramNotificationSection> get notificationSections =>
      List<KaizengramNotificationSection>.unmodifiable(
        _buildNotificationSections(),
      );
  int get unreadNotificationCount =>
      notifications.where((item) => item.isUnread).length;

  List<KaizengramStory> get stories => _posts
      .map(
        (post) => KaizengramStory(
          id: post.id,
          name: post.title.split(' ').first,
          avatarUrl: post.avatarUrl,
        ),
      )
      .toList(growable: false);

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

  List<({String actorName, KaizengramNotificationType type})>
  _notificationSeedsFor(KaizengramFeedItem post) {
    switch (post.resolvedPostCategory) {
      case KaizengramPostCategory.audit:
        return <({String actorName, KaizengramNotificationType type})>[
          (
            actorName: _notificationActor(
              post.auditedBy,
              fallback: AppStrings.kaizengramNotificationsActorKaizenQa,
            ),
            type: KaizengramNotificationType.commented,
          ),
          (
            actorName: _notificationActor(
              post.postedByName,
              fallback: AppStrings.kaizengramNotificationsActorReviewBoard,
            ),
            type: KaizengramNotificationType.readyForFollowUp,
          ),
        ];
      case KaizengramPostCategory.learningCompliance:
        return <({String actorName, KaizengramNotificationType type})>[
          (
            actorName: _notificationActor(
              post.postedByName,
              fallback: AppStrings.kaizengramNotificationsActorTrainingDesk,
            ),
            type: KaizengramNotificationType.assigned,
          ),
          (
            actorName: _notificationActor(
              post.departmentName,
              fallback: AppStrings.kaizengramNotificationsActorTrainingDesk,
            ),
            type: KaizengramNotificationType.dueSoon,
          ),
        ];
      case KaizengramPostCategory.documentCompliance:
        final normalizedStatus = post.status?.trim().toLowerCase() ?? '';
        final needsUpload =
            normalizedStatus.isNotEmpty &&
            normalizedStatus != 'compliant' &&
            normalizedStatus != 'no longer required';
        return <({String actorName, KaizengramNotificationType type})>[
          (
            actorName: _notificationActor(
              post.postedByName,
              fallback: AppStrings.kaizengramNotificationsActorComplianceDesk,
            ),
            type: needsUpload
                ? KaizengramNotificationType.requestedUpload
                : KaizengramNotificationType.reviewed,
          ),
          (
            actorName: _notificationActor(
              post.departmentName,
              fallback: AppStrings.kaizengramNotificationsActorReviewBoard,
            ),
            type: KaizengramNotificationType.reviewed,
          ),
        ];
    }
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
      replies: <({String author, String message, String time})>[
        (
          author: postedByName,
          message:
              'Thanks, I have already reviewed the findings with the team and updated the checklist owner.',
          time: '45m',
        ),
        (
          author: 'Kaizen QA',
          message:
              'Please keep the supporting media attached so the next weekly check-in can compare progress.',
          time: '18m',
        ),
        (
          author: departmentName,
          message:
              'Action items are logged and follow-up will be completed before the next audit window.',
          time: 'Just now',
        ),
      ],
    );
    final auditMediaItems = _buildAuditMediaItems(
      seed: id,
      thumbnails: normalizedImages,
      seatName: seatName,
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
      headerImageUrl: normalizedImages.isEmpty ? null : normalizedImages.first,
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
      replies: <({String author, String message, String time})>[
        (
          author: departmentName,
          message:
              'The department review is complete and the team has acknowledged the assigned learning task.',
          time: '1h',
        ),
        (
          author: 'Kaizen Support',
          message:
              'Completion progress will reflect automatically after the final checkpoint is submitted.',
          time: '24m',
        ),
      ],
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
      headerImageUrl: resolvedPrimaryImageUrl,
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
      replies: <({String author, String message, String time})>[
        (
          author: departmentName,
          message:
              'The document owner has been notified and the department is tracking the update window.',
          time: '58m',
        ),
        (
          author: 'Compliance Desk',
          message:
              'Once the latest file is uploaded, the document status will update in the compliance tab.',
          time: '9m',
        ),
      ],
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
      headerImageUrl: normalizedImageUrl,
      commentThread: comments,
    );
  }

  List<KaizengramComment> _buildCommentThread({
    required String? descriptionAuthor,
    required String? descriptionMessage,
    required String? avatarUrl,
    required List<({String author, String message, String time})> replies,
  }) {
    final threadedReplies = replies
        .map(
          (reply) => KaizengramComment(
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
      comments.insert(
        0,
        KaizengramComment(
          authorName: normalizedAuthor,
          message: normalizedDescription,
          timestampLabel: 'Now',
          avatarUrl: avatarUrl,
          isDescription: true,
        ),
      );
    }

    return comments;
  }

  List<KaizengramAuditMediaItem> _buildAuditMediaItems({
    required String seed,
    required List<String> thumbnails,
    required String seatName,
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
      return KaizengramAuditMediaItem(
        id: '$seed-media-${index + 1}',
        title: '$seatName ${titles[index % titles.length]}',
        thumbnailUrl: imageAt(index),
        videoUrl: isVideoItem ? _sampleVideoUrl : null,
        rating: ratings[index % ratings.length],
      );
    }, growable: false);
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
    final normalizedHeader = headerImageUrl?.trim();
    if (normalizedHeader != null && normalizedHeader.isNotEmpty) {
      return normalizedHeader;
    }

    final normalizedImage = feedImageUrl?.trim();
    if (normalizedImage != null && normalizedImage.isNotEmpty) {
      return normalizedImage;
    }

    if (mediaUrls.isEmpty) {
      return null;
    }

    return mediaUrls.first.trim().isEmpty ? null : mediaUrls.first.trim();
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
    required this.authorName,
    required this.message,
    required this.timestampLabel,
    this.avatarUrl,
    this.isDescription = false,
    this.replies = const <KaizengramComment>[],
  });

  final String authorName;
  final String message;
  final String timestampLabel;
  final String? avatarUrl;
  final bool isDescription;
  final List<KaizengramComment> replies;
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
  });

  final String id;
  final String actorName;
  final KaizengramNotificationType type;
  final KaizengramFeedItem post;
  final DateTime occurredAt;
  final bool isUnread;
}

class KaizengramAuditMediaItem {
  const KaizengramAuditMediaItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.rating,
    this.videoUrl,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final KaizengramAuditRating rating;
  final String? videoUrl;

  bool get hasVideo => videoUrl?.trim().isNotEmpty ?? false;
}
