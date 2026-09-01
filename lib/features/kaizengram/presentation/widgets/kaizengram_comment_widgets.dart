part of 'package:sparrowkaizen/features/kaizengram/presentation/pages/kaizengram_screen.dart';

class _CreateSocialPostBottomSheet extends StatefulWidget {
  const _CreateSocialPostBottomSheet({
    required this.authorName,
    this.avatarImagePath,
    required this.avatarUrl,
    this.initialAttachments = const <KaizengramMessageAttachment>[],
    required this.onPostSubmitted,
  });

  final String authorName;
  final String? avatarImagePath;
  final String? avatarUrl;
  final List<KaizengramMessageAttachment> initialAttachments;
  final void Function(
    String message,
    List<KaizengramMessageAttachment> attachments,
  )
  onPostSubmitted;

  @override
  State<_CreateSocialPostBottomSheet> createState() =>
      _CreateSocialPostBottomSheetState();
}

class _CreateSocialPostBottomSheetState
    extends State<_CreateSocialPostBottomSheet>
    with KaizengramNotifierState<_CreateSocialPostBottomSheet> {
  late final TextEditingController _controller;
  List<KaizengramMessageAttachment> _draftAttachments =
      <KaizengramMessageAttachment>[];
  var _draftText = '';
  var _isPickingImage = false;
  var _isPickingAttachment = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _draftAttachments = widget.initialAttachments
        .where((attachment) => attachment.path.trim().isNotEmpty)
        .take(kaizengramMessageAttachmentLimit)
        .toList(growable: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _controller.text.trim();
    if (message.isEmpty && _draftAttachments.isEmpty) {
      return;
    }

    widget.onPostSubmitted(
      message,
      List<KaizengramMessageAttachment>.unmodifiable(_draftAttachments),
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickImages() async {
    if (_isPickingImage || _isPickingAttachment) {
      return;
    }

    final availableSlots =
        kaizengramMessageAttachmentLimit - _draftAttachments.length;
    if (availableSlots <= 0) {
      _showDraftSnackBar(AppStrings.mediaLimitError);
      return;
    }

    updateView(() {
      _isPickingImage = true;
    });

    try {
      final nextAttachments =
          await KaizengramMessageAttachmentPicker.pickImages(
            availableSlots: availableSlots,
            existingPaths: _draftAttachments.map(
              (attachment) => attachment.path,
            ),
          );
      if (nextAttachments.isEmpty || !mounted) {
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

      _showDraftSnackBar(AppStrings.kaizengramErrorPickImageFailed);
    } finally {
      if (mounted) {
        updateView(() {
          _isPickingImage = false;
        });
      } else {
        _isPickingImage = false;
      }
    }
  }

  Future<void> _pickAttachments() async {
    if (_isPickingImage || _isPickingAttachment) {
      return;
    }

    final availableSlots =
        kaizengramMessageAttachmentLimit - _draftAttachments.length;
    if (availableSlots <= 0) {
      _showDraftSnackBar(AppStrings.mediaLimitError);
      return;
    }

    updateView(() {
      _isPickingAttachment = true;
    });

    try {
      final nextAttachments = await KaizengramMessageAttachmentPicker.pickPdfs(
        availableSlots: availableSlots,
        existingPaths: _draftAttachments.map((attachment) => attachment.path),
      );
      if (nextAttachments.isEmpty || !mounted) {
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

      _showDraftSnackBar(AppStrings.kaizengramErrorPickAttachmentFailed);
    } finally {
      if (mounted) {
        updateView(() {
          _isPickingAttachment = false;
        });
      } else {
        _isPickingAttachment = false;
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

  void _showDraftSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return buildWithNotifier((context) {
      final canPost =
          _draftText.trim().isNotEmpty || _draftAttachments.isNotEmpty;
      final hasLinkPreview = kaizengramFirstLinkInText(_draftText) != null;

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
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
                    imagePath: widget.avatarImagePath,
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
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.hex20253a,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                  ),
                ),
                child: KaizengramComposePostActionRow(
                  isPickingImage: _isPickingImage,
                  isPickingAttachment: _isPickingAttachment,
                  onPickImage: _pickImages,
                  onPickAttachment: _pickAttachments,
                ),
              ),
              if (_draftAttachments.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                _CommentAttachmentPreviewStrip(
                  attachments: _draftAttachments,
                  removable: true,
                  onOpenAttachment: _openAttachmentViewer,
                  onRemoveAttachment: _removeAttachment,
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
                  maxLines: 8,
                  minLines: 7,
                  cursorHeight: 17,
                  cursorColor: AppColors.textPrimary,
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (value) => updateView(() => _draftText = value),
                  decoration: const InputDecoration(
                    hintText: AppStrings.kaizengramComposeSheetHint,
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(16, 18, 16, 18),
                  ),
                ),
              ),
              if (hasLinkPreview) ...<Widget>[
                const SizedBox(height: 12),
                KaizengramTextLinkPreview(text: _draftText, topSpacing: 0),
              ],
              const SizedBox(height: 12),
              AppTextView.body4(
                AppStrings.kaizengramComposeSubtitle,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
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
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.08,
                            ),
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
    });
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
    extends State<_SocialPostCommentsBottomSheet>
    with KaizengramNotifierState<_SocialPostCommentsBottomSheet> {
  late final TextEditingController _commentController;
  late final ScrollController _scrollController;
  final Map<String, GlobalKey> _commentKeys = <String, GlobalKey>{};
  List<KaizengramMessageAttachment> _draftAttachments =
      <KaizengramMessageAttachment>[];
  bool _isPickingAttachments = false;
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
    updateView(() {
      _replyingToCommentId = comment.id;
    });
  }

  void _clearReply() {
    updateView(() {
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
    updateView(() {
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
    return buildWithNotifier((context) {
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
}

class _CommentSheetMediaPreview extends StatefulWidget {
  const _CommentSheetMediaPreview({
    required this.post,
    this.selectedAuditMediaItem,
    this.fallbackText,
    this.onFallbackMoreTap,
    this.documentImageFile,
    this.onUploadTap,
    this.isUploading = false,
  });

  final KaizengramFeedItem post;
  final KaizengramAuditMediaItem? selectedAuditMediaItem;
  final String? fallbackText;
  final VoidCallback? onFallbackMoreTap;
  final File? documentImageFile;
  final VoidCallback? onUploadTap;
  final bool isUploading;

  @override
  State<_CommentSheetMediaPreview> createState() =>
      _CommentSheetMediaPreviewState();
}

class _CommentSheetMediaPreviewState extends State<_CommentSheetMediaPreview>
    with KaizengramNotifierState<_CommentSheetMediaPreview> {
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
    return buildWithNotifier((context) {
      final auditMediaItem = widget.selectedAuditMediaItem;
      final fallbackText =
          widget.fallbackText ??
          (auditMediaItem != null
              ? _resolvedAuditMediaFallbackText(auditMediaItem)
              : _resolvedPostMediaFallbackText(widget.post));

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
                          updateView(() => _currentPage = page),
                      itemBuilder: (context, index) {
                        return KaizengramNetworkPostImage(
                          imageUrl: widget.post.mediaUrls[index],
                          emptyState: fallbackText == null
                              ? null
                              : KaizengramPostTextMediaFallbackCard(
                                  text: fallbackText,
                                  onMoreTap: widget.onFallbackMoreTap,
                                ),
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
                showTitle: false,
                showSeekBar: false,
                showDuration: false,
              ),
            ),
          );
        }

        if (!auditMediaItem.hasThumbnail) {
          return _buildThreadWithoutImagePreview(fallbackText: fallbackText);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: KaizengramNetworkPostImage(
              imageUrl: auditMediaItem.thumbnailUrl,
              emptyState: fallbackText == null
                  ? null
                  : KaizengramPostTextMediaFallbackCard(
                      text: fallbackText,
                      onMoreTap: widget.onFallbackMoreTap,
                    ),
            ),
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
                showTitle: false,
                showSeekBar: false,
                showDuration: false,
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: KaizengramNetworkPostImage(
              imageUrl: primaryMedia.thumbnailUrl,
              emptyState: fallbackText == null
                  ? null
                  : KaizengramPostTextMediaFallbackCard(
                      text: fallbackText,
                      onMoreTap: widget.onFallbackMoreTap,
                    ),
            ),
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
              showTitle: false,
              showSeekBar: false,
              showDuration: false,
            ),
          ),
        );
      }

      final normalizedPostImageUrl = widget.post.feedImageUrl?.trim();
      if (widget.post.resolvedPostCategory ==
              KaizengramPostCategory.documentCompliance &&
          (normalizedPostImageUrl == null || normalizedPostImageUrl.isEmpty)) {
        return _buildDocumentPreviewCard(
          child: fallbackText == null
              ? const KaizengramUploadDocPlaceholder()
              : KaizengramPostTextMediaFallbackCard(
                  text: fallbackText,
                  onMoreTap: widget.onFallbackMoreTap,
                ),
        );
      }

      if (widget.post.resolvedPostCategory ==
          KaizengramPostCategory.documentCompliance) {
        return _buildDocumentPreviewCard(
          child: KaizengramNetworkPostImage(
            imageUrl: widget.post.feedImageUrl,
            emptyState: fallbackText == null
                ? null
                : KaizengramPostTextMediaFallbackCard(
                    text: fallbackText,
                    onMoreTap: widget.onFallbackMoreTap,
                  ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: KaizengramNetworkPostImage(
            imageUrl: widget.post.feedImageUrl,
            emptyState: fallbackText == null
                ? null
                : KaizengramPostTextMediaFallbackCard(
                    text: fallbackText,
                    onMoreTap: widget.onFallbackMoreTap,
                  ),
          ),
        ),
      );
    });
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

  Widget _buildThreadWithoutImagePreview({String? fallbackText}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: fallbackText == null
            ? const KaizengramNoImageAvailableAsset()
            : KaizengramPostTextMediaFallbackCard(
                text: fallbackText,
                onMoreTap: widget.onFallbackMoreTap,
              ),
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

class _CommentThreadCardState extends State<_CommentThreadCard>
    with KaizengramNotifierState<_CommentThreadCard> {
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
    return buildWithNotifier((context) {
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
                        onTap: () =>
                            updateView(() => _showReplies = !_showReplies),
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
    });
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
    this.isPickingAttachment = false,
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
  final bool isPickingAttachment;
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
                        onTap: isPickingAttachment ? null : onPickAttachment,
                        icon: Icons.attach_file_rounded,
                        isBusy: isPickingAttachment,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: _commentComposerControlHeight,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(
                            _commentComposerCornerRadius,
                          ),
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
                          textAlignVertical: TextAlignVertical.center,
                          cursorHeight: 17,
                          cursorColor: AppColors.textPrimary,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: hintText,
                            hintStyle: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
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
  const _CommentComposerActionButton({
    required this.onTap,
    required this.icon,
    this.isBusy = false,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_commentComposerCornerRadius),
      child: Container(
        width: _commentComposerActionWidth,
        height: _commentComposerControlHeight,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(_commentComposerCornerRadius),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: isBusy
            ? const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textPrimary,
                  ),
                ),
              )
            : Icon(icon, color: AppColors.textPrimary, size: 20),
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
      borderRadius: BorderRadius.circular(_commentComposerCornerRadius),
      child: Container(
        width: _commentComposerActionWidth,
        height: _commentComposerControlHeight,
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(_commentComposerCornerRadius),
          border: Border.all(
            color: canSend
                ? AppColors.secondaryColor
                : AppColors.textPrimary.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          Icons.send_rounded,
          color: canSend ? AppColors.secondaryColor : AppColors.textSecondary,
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
    if (removable) {
      const spacing = 8.0;
      const mediaCardSize = 92.0;
      const pdfCardWidth = 220.0;

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppTextView.body4(
              AppStrings.selectedMediaLabel(
                attachments.length,
                kaizengramMessageAttachmentLimit,
              ),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: mediaCardSize,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
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
                      width: attachment.isPdf ? pdfCardWidth : mediaCardSize,
                      height: mediaCardSize,
                      useDraftStyle: true,
                      onOpen: onOpenAttachment == null
                          ? null
                          : () => onOpenAttachment!(attachmentIndex),
                      onRemove: onRemoveAttachment == null
                          ? null
                          : () => onRemoveAttachment!(attachment.path),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
    this.useDraftStyle = false,
    this.onOpen,
    this.onRemove,
  });

  final KaizengramMessageAttachment attachment;
  final double height;
  final double? width;
  final bool useDraftStyle;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final useCompactStyle = !useDraftStyle && width != null;
    final mediaChild = attachment.isPdf
        ? _CommentPdfPreviewCard(
            attachment: attachment,
            onOpen: onOpen,
            useDraftStyle: useDraftStyle,
            useCompactStyle: useCompactStyle,
          )
        : attachment.isVideo
        ? ChatVideoPreview(
            videoPath: attachment.path,
            maxHeight: height,
            muted: true,
            playButtonSize: useDraftStyle
                ? 30
                : width == null
                ? 48
                : 34,
            playIconSize: useDraftStyle
                ? 16
                : width == null
                ? 26
                : 18,
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
                color: useDraftStyle
                    ? AppColors.hex111317
                    : AppColors.surfaceDark3,
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
  const _CommentPdfPreviewCard({
    required this.attachment,
    this.onOpen,
    this.useDraftStyle = false,
    this.useCompactStyle = false,
  });

  final KaizengramMessageAttachment attachment;
  final VoidCallback? onOpen;
  final bool useDraftStyle;
  final bool useCompactStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (useDraftStyle) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.secondaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        CustomFunctions.fileNameFromPath(
                          attachment.path,
                          fallback: AppStrings.documentMessageLabel,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (useCompactStyle) {
              final isTight = constraints.maxHeight < 86;
              final cardPadding = isTight ? 8.0 : 10.0;
              final iconBoxSize = isTight ? 32.0 : 36.0;
              final iconSize = isTight ? 18.0 : 20.0;
              final spacing = isTight ? 6.0 : 8.0;
              final titleLines = isTight ? 1 : 2;

              return Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf_rounded,
                        color: AppColors.secondaryColor,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(height: spacing),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          CustomFunctions.fileNameFromPath(
                            attachment.path,
                            fallback: AppStrings.documentMessageLabel,
                          ),
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: isTight ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
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
                      fallback: AppStrings.documentMessageLabel,
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
            );
          },
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
