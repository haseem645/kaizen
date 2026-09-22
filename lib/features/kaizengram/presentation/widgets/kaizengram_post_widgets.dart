part of 'package:sparrowkaizen/features/kaizengram/presentation/pages/kaizengram_screen.dart';

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    this.fallbackText,
    required this.onTap,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onFallbackMoreTap,
    required this.onShareTap,
    required this.onAuditMediaTap,
  });

  final KaizengramFeedItem post;
  final String? fallbackText;
  final VoidCallback onTap;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onFallbackMoreTap;
  final VoidCallback onShareTap;
  final ValueChanged<KaizengramAuditMediaItem> onAuditMediaTap;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with KaizengramNotifierState<_PostCard> {
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
    return buildWithNotifier((context) {
      final post = widget.post;
      final headerAvatarUrl = post.postHeaderAvatarUrl;
      final shouldUseTextMediaFallback = _shouldUseTextMediaFallback(post);

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
                  fallbackText: widget.fallbackText,
                  onFallbackMoreTap: widget.onFallbackMoreTap,
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
                              ? AppColors.hexff4d67
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
                if (!shouldUseTextMediaFallback &&
                    _resolvedDescription(post) != null) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: _ExpandableDescriptionText(
                      text: _resolvedDescription(post)!,
                      isExpanded: _isDescriptionExpanded,
                      onToggle: () {
                        updateView(() {
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
                        KaizengramStatusLine(
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
    });
  }

  String? _resolvedDescription(KaizengramFeedItem post) {
    return _resolvedPostDescription(post);
  }

  List<Widget> _buildMetaSection(KaizengramFeedItem post) {
    if (post.resolvedPostCategory == KaizengramPostCategory.audit) {
      return <Widget>[
        KaizengramMetaLine(
          label: AppStrings.kaizengramLabelAuditedAt,
          value: post.auditedAt ?? post.timestampLabel,
        ),
        const SizedBox(height: 6),
        KaizengramMetaLine(
          label: AppStrings.kaizengramLabelAuditedBy,
          value: _headerRelationName(post),
        ),
      ];
    }

    return <Widget>[
      KaizengramMetaLine(
        label: AppStrings.kaizengramLabelSeat,
        value: post.departmentName ?? post.seatProfile,
      ),
      if ((post.dueBy ?? post.deadlineDate)?.trim().isNotEmpty ==
          true) ...<Widget>[
        const SizedBox(height: 6),
        KaizengramMetaLine(
          label: AppStrings.kaizengramLabelDueBy,
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
  const _PostMediaSection({
    required this.post,
    this.fallbackText,
    this.onFallbackMoreTap,
    required this.onAuditMediaTap,
  });

  final KaizengramFeedItem post;
  final String? fallbackText;
  final VoidCallback? onFallbackMoreTap;
  final ValueChanged<KaizengramAuditMediaItem> onAuditMediaTap;

  @override
  Widget build(BuildContext context) {
    final resolvedFallbackText =
        fallbackText ?? _resolvedPostMediaFallbackText(post);

    if (post.resolvedPostCategory == KaizengramPostCategory.audit) {
      final mediaItems = _buildAuditThreadItems(post);
      if (mediaItems.isEmpty) {
        if (resolvedFallbackText == null) {
          return const SizedBox.shrink();
        }

        return AspectRatio(
          aspectRatio: 1,
          child: KaizengramPostTextMediaFallbackCard(
            key: ValueKey<String>('post-fallback-${post.id}'),
            text: resolvedFallbackText,
            onMoreTap: onFallbackMoreTap,
          ),
        );
      }

      return _AuditPostMediaPager(
        mediaItems: mediaItems,
        onMediaTap: onAuditMediaTap,
        onMoreTap: onFallbackMoreTap,
      );
    }

    if (post.mediaUrls.length > 1) {
      return _ImagePostMediaPager(
        imageUrls: post.mediaUrls,
        emptyState: resolvedFallbackText == null
            ? null
            : KaizengramPostTextMediaFallbackCard(
                key: ValueKey<String>('post-fallback-${post.id}'),
                text: resolvedFallbackText,
                onMoreTap: onFallbackMoreTap,
              ),
      );
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

    final normalizedImageUrl = post.feedImageUrl?.trim();
    if (normalizedImageUrl == null || normalizedImageUrl.isEmpty) {
      if (resolvedFallbackText == null) {
        return const SizedBox.shrink();
      }

      return AspectRatio(
        aspectRatio: 1,
        child: KaizengramPostTextMediaFallbackCard(
          key: ValueKey<String>('post-fallback-${post.id}'),
          text: resolvedFallbackText,
          onMoreTap: onFallbackMoreTap,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: KaizengramNetworkPostImage(
        imageUrl: normalizedImageUrl,
        emptyState: resolvedFallbackText == null
            ? null
            : KaizengramPostTextMediaFallbackCard(
                key: ValueKey<String>('post-fallback-${post.id}'),
                text: resolvedFallbackText,
                onMoreTap: onFallbackMoreTap,
              ),
      ),
    );
  }
}

class _ImagePostMediaPager extends StatefulWidget {
  const _ImagePostMediaPager({required this.imageUrls, this.emptyState});

  final List<String> imageUrls;
  final Widget? emptyState;

  @override
  State<_ImagePostMediaPager> createState() => _ImagePostMediaPagerState();
}

class _ImagePostMediaPagerState extends State<_ImagePostMediaPager>
    with KaizengramNotifierState<_ImagePostMediaPager> {
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
    return buildWithNotifier((context) {
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
                    updateView(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return AspectRatio(
                      aspectRatio: 1,
                      child: KaizengramNetworkPostImage(
                        imageUrl: imageUrls[index],
                        emptyState: widget.emptyState,
                      ),
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
    });
  }
}

class _AuditPostMediaPager extends StatefulWidget {
  const _AuditPostMediaPager({
    required this.mediaItems,
    required this.onMediaTap,
    this.onMoreTap,
  });

  final List<KaizengramAuditMediaItem> mediaItems;
  final ValueChanged<KaizengramAuditMediaItem> onMediaTap;
  final VoidCallback? onMoreTap;

  @override
  State<_AuditPostMediaPager> createState() => _AuditPostMediaPagerState();
}

class _AuditPostMediaPagerState extends State<_AuditPostMediaPager>
    with KaizengramNotifierState<_AuditPostMediaPager> {
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
    return buildWithNotifier((context) {
      final mediaItems = widget.mediaItems;
      if (mediaItems.length == 1) {
        return _AuditPostMediaPage(
          item: mediaItems.first,
          onTap: () => widget.onMediaTap(mediaItems.first),
          onMoreTap: widget.onMoreTap,
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
                    updateView(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _AuditPostMediaPage(
                      item: mediaItems[index],
                      onTap: () => widget.onMediaTap(mediaItems[index]),
                      onMoreTap: widget.onMoreTap,
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
    });
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
  const _AuditPostMediaPage({
    required this.item,
    required this.onTap,
    this.onMoreTap,
  });

  final KaizengramAuditMediaItem item;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

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
            child: KaizengramNetworkPostImage(
              imageUrl: item.hasThumbnail ? item.thumbnailUrl : null,
              emptyState: _resolvedAuditMediaFallbackText(item) == null
                  ? null
                  : KaizengramPostTextMediaFallbackCard(
                      key: ValueKey<String>('audit-fallback-${item.id}'),
                      text: _resolvedAuditMediaFallbackText(item)!,
                      onMoreTap: onTap,
                    ),
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: child),
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

class _CommentsThreadBottomSheetState extends State<_CommentsThreadBottomSheet>
    with KaizengramNotifierState<_CommentsThreadBottomSheet> {
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
  bool _isPickingAttachments = false;
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
    updateView(() {
      _replyingTo = comment;
    });
  }

  void _clearReply() {
    updateView(() {
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

    updateView(() {
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
      updateView(() => _highlightedCommentId = commentId);
    }

    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted || sequence != _highlightSequence) {
        return;
      }
      updateView(() => _highlightedCommentId = null);
    });
  }

  Future<void> _pickAttachments() async {
    if (_isPickingAttachments) {
      return;
    }

    final availableSlots =
        kaizengramMessageAttachmentLimit - _draftAttachments.length;
    if (availableSlots <= 0) {
      _showAttachmentSnackBar(AppStrings.mediaLimitError);
      return;
    }

    updateView(() => _isPickingAttachments = true);

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

      updateView(() {
        _draftAttachments = <KaizengramMessageAttachment>[
          ..._draftAttachments,
          ...nextAttachments,
        ];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showAttachmentSnackBar(AppStrings.pickMediaError);
    } finally {
      if (mounted) {
        updateView(() => _isPickingAttachments = false);
      }
    }
  }

  void _removeAttachment(String attachmentPath) {
    updateView(() {
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

    updateView(() {
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

      updateView(() {
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
        updateView(() {
          _isPickingDocumentImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildWithNotifier((context) {
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
                isPickingAttachment: _isPickingAttachments,
                onPickAttachment: _pickAttachments,
                onOpenAttachment: _openAttachmentViewer,
                onRemoveAttachment: _removeAttachment,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget loadMessagesNormally() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          child: _CommentSheetMediaPreview(
            post: widget.post,
            selectedAuditMediaItem: widget.selectedAuditMediaItem,
            fallbackText: _resolvedCommentPreviewText(_comments),
            onFallbackMoreTap: _comments.isEmpty
                ? null
                : () => _scrollToComment(_comments.first.id),
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
        updateView(() {
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
                    fallbackText: _resolvedCommentPreviewText(
                      _commentsForMedia(mediaItem.id),
                    ),
                    onFallbackMoreTap: _commentsForMedia(mediaItem.id).isEmpty
                        ? null
                        : () => _scrollToComment(
                            _commentsForMedia(mediaItem.id).first.id,
                          ),
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
