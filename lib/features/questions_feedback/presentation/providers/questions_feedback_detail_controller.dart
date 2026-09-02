import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../../login/domain/entities/user.dart';
import '../../domain/entities/feedback_comment.dart';
import '../../domain/entities/feedback_image_attachment.dart';
import '../../domain/entities/feedback_post.dart';
import '../../domain/usecases/get_feedback_posts_usecase.dart';

class QuestionsFeedbackDetailController extends ChangeNotifier {
  QuestionsFeedbackDetailController(
    this._useCase,
    FeedbackPost post, {
    User? currentUser,
  }) : _post = post,
       _currentUser = currentUser,
       commentController = TextEditingController();

  static const int _commentPageSize = 10;
  static const int maxEditImageAttachments = 5;

  final GetFeedbackPostsUseCase _useCase;
  final User? _currentUser;
  final TextEditingController commentController;
  final TextEditingController editCommentController = TextEditingController();
  final TextEditingController editPostTitleController = TextEditingController();
  final TextEditingController editPostDescriptionController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  FeedbackPost _post;
  List<FeedbackComment> _comments = const <FeedbackComment>[];
  List<FeedbackImageAttachment> _editPostAttachments =
      const <FeedbackImageAttachment>[];
  final Map<String, List<FeedbackComment>> _repliesByParentId =
      <String, List<FeedbackComment>>{};
  final Set<String> _loadingReplyParentIds = <String>{};
  final Set<String> _expandedReplyParentIds = <String>{};
  final Set<String> _deletingCommentIds = <String>{};
  bool _isCommentsLoading = false;
  bool _isLoadingMoreComments = false;
  bool _isSendingComment = false;
  bool _isUpdatingLike = false;
  bool _isComposerVisible = false;
  String? _replyParentId;
  String? _replyAuthorName;
  String? _editingCommentId;
  bool _isSavingEdit = false;
  bool _isSavingPostEdit = false;
  bool _isDeletingPost = false;
  bool _hasNextCommentPage = true;
  int _currentCommentPage = 0;

  FeedbackPost get post => _post;
  List<FeedbackComment> get comments =>
      List<FeedbackComment>.unmodifiable(_comments);
  bool get isCommentsLoading => _isCommentsLoading;
  bool get isLoadingMoreComments => _isLoadingMoreComments;
  bool get isSendingComment => _isSendingComment;
  bool get isUpdatingLike => _isUpdatingLike;
  bool get isComposerVisible => _isComposerVisible;
  String? get replyParentId => _replyParentId;
  String? get replyAuthorName => _replyAuthorName;
  String? get editingCommentId => _editingCommentId;
  bool get isSavingEdit => _isSavingEdit;
  bool get isSavingPostEdit => _isSavingPostEdit;
  bool get isDeletingPost => _isDeletingPost;
  List<FeedbackImageAttachment> get editPostAttachments =>
      List<FeedbackImageAttachment>.unmodifiable(_editPostAttachments);
  int get editPostAttachmentCount =>
      _post.attachments.length + _editPostAttachments.length;
  bool get canAddEditPostAttachments =>
      !_isSavingPostEdit && editPostAttachmentCount < maxEditImageAttachments;
  bool isEditingComment(String commentId) => _editingCommentId == commentId;
  bool get canSendComment =>
      commentController.text.trim().isNotEmpty && !_isSendingComment;
  bool get hasNextCommentPage => _hasNextCommentPage;
  List<FeedbackComment> repliesFor(String parentId) =>
      List<FeedbackComment>.unmodifiable(
        _repliesByParentId[parentId] ?? const <FeedbackComment>[],
      );
  bool isLoadingReplies(String parentId) =>
      _loadingReplyParentIds.contains(parentId);
  bool hasLoadedReplies(String parentId) =>
      _repliesByParentId.containsKey(parentId);
  bool isRepliesVisible(String parentId) =>
      _expandedReplyParentIds.contains(parentId);
  bool isDeletingComment(String commentId) =>
      _deletingCommentIds.contains(commentId);
  bool get canModifyPost => _canModifyAuthor(_post.author.id);
  bool canModifyComment(FeedbackComment comment) {
    return _canModifyAuthor(comment.author?.id);
  }

  bool _canModifyAuthor(String? authorId) {
    final normalizedAuthorId = _normalizeIdentifier(authorId);
    if (normalizedAuthorId.isEmpty) {
      return false;
    }

    final currentUserIds = <String>{
      _normalizeIdentifier(_currentUser?.userUuid),
      _normalizeIdentifier(_currentUser?.uuid),
    }..removeWhere((identifier) => identifier.isEmpty);

    return currentUserIds.contains(normalizedAuthorId);
  }

  Future<void> initialize() async {
    if (_isCommentsLoading || _comments.isNotEmpty) {
      return;
    }
    _isCommentsLoading = true;
    notifyListeners();
    try {
      await _loadComments(1, replace: true);
    } finally {
      _isCommentsLoading = false;
      notifyListeners();
    }
  }

  void showComposer({String? parentId, String? parentAuthorName}) {
    _replyParentId = parentId;
    _replyAuthorName = parentAuthorName;
    _isComposerVisible = true;
    notifyListeners();
  }

  void cancelComposer() {
    commentController.clear();
    _replyParentId = null;
    _replyAuthorName = null;
    _isComposerVisible = false;
    notifyListeners();
  }

  void onCommentChanged() => notifyListeners();

  void startEditing(FeedbackComment comment) {
    _editingCommentId = comment.id;
    editCommentController.text = comment.content;
    notifyListeners();
  }

  void cancelEditing() {
    editCommentController.clear();
    _editingCommentId = null;
    notifyListeners();
  }

  void startEditingPost() {
    if (!canModifyPost) {
      return;
    }
    editPostTitleController.text = _post.title;
    editPostDescriptionController.text = _post.description;
    _editPostAttachments = const <FeedbackImageAttachment>[];
    notifyListeners();
  }

  void cancelPostEditing() {
    editPostTitleController.clear();
    editPostDescriptionController.clear();
    _editPostAttachments = const <FeedbackImageAttachment>[];
    notifyListeners();
  }

  Future<void> pickEditPostAttachments() async {
    if (!canModifyPost || !canAddEditPostAttachments) {
      return;
    }

    final remaining = maxEditImageAttachments - editPostAttachmentCount;
    final selectedImages = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      limit: remaining,
    );
    if (selectedImages.isEmpty) {
      return;
    }

    final attachments = <FeedbackImageAttachment>[..._editPostAttachments];
    for (final image in selectedImages) {
      if (_post.attachments.length + attachments.length ==
          maxEditImageAttachments) {
        break;
      }

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        continue;
      }

      final fileName = image.name.trim().isEmpty
          ? 'attachment_${_post.attachments.length + attachments.length + 1}.jpg'
          : image.name.trim();
      attachments.add(
        FeedbackImageAttachment(
          fileName: fileName,
          bytes: bytes,
          contentType:
              lookupMimeType(fileName, headerBytes: bytes) ?? 'image/jpeg',
        ),
      );
    }

    _editPostAttachments = List<FeedbackImageAttachment>.unmodifiable(
      attachments,
    );
    notifyListeners();
  }

  void removeEditPostAttachment(int index) {
    if (_isSavingPostEdit ||
        index < 0 ||
        index >= _editPostAttachments.length) {
      return;
    }

    final attachments = List<FeedbackImageAttachment>.of(_editPostAttachments)
      ..removeAt(index);
    _editPostAttachments = List<FeedbackImageAttachment>.unmodifiable(
      attachments,
    );
    notifyListeners();
  }

  void onPostEditChanged(String _) => notifyListeners();

  bool get canSavePostEdit =>
      canModifyPost &&
      editPostTitleController.text.trim().isNotEmpty &&
      editPostDescriptionController.text.trim().isNotEmpty &&
      !_isSavingPostEdit;

  Future<bool> savePostEditing() async {
    final title = editPostTitleController.text.trim();
    final description = editPostDescriptionController.text.trim();
    if (!canModifyPost ||
        title.isEmpty ||
        description.isEmpty ||
        _isSavingPostEdit) {
      return false;
    }

    _isSavingPostEdit = true;
    notifyListeners();
    try {
      final updatedPost = await _useCase.updatePost(
        feedbackId: _post.id,
        title: title,
        description: description,
        attachments: _editPostAttachments,
      );
      final responseAttachments = updatedPost?.attachments;
      final responseAuthor = updatedPost?.author;
      _post = (updatedPost ?? _post).copyWith(
        title: title,
        description: description,
        attachments: responseAttachments?.isNotEmpty == true
            ? responseAttachments
            : _post.attachments,
        author: responseAuthor?.id.trim().isNotEmpty == true
            ? responseAuthor
            : _post.author,
      );
      cancelPostEditing();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSavingPostEdit = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost() async {
    if (!canModifyPost || _isDeletingPost) {
      return false;
    }

    _isDeletingPost = true;
    notifyListeners();
    try {
      await _useCase.deletePost(feedbackId: _post.id);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isDeletingPost = false;
      notifyListeners();
    }
  }

  Future<bool> saveEditing() async {
    final commentId = _editingCommentId;
    final content = editCommentController.text.trim();
    if (commentId == null || content.isEmpty || _isSavingEdit) return false;
    _isSavingEdit = true;
    notifyListeners();
    try {
      await _useCase.updateComment(commentId: commentId, content: content);
      _comments = _replaceComment(
        _comments,
        commentId: commentId,
        content: content,
      );
      for (final entry in _repliesByParentId.entries.toList()) {
        _repliesByParentId[entry.key] = _replaceComment(
          entry.value,
          commentId: commentId,
          content: content,
        );
      }
      cancelEditing();
      return true;
    } finally {
      _isSavingEdit = false;
      notifyListeners();
    }
  }

  List<FeedbackComment> _replaceComment(
    List<FeedbackComment> comments, {
    required String commentId,
    required String content,
  }) => List<FeedbackComment>.unmodifiable(
    comments.map(
      (comment) => comment.id == commentId
          ? comment.copyWith(content: content)
          : comment,
    ),
  );

  Future<bool> toggleLike() async {
    if (_isUpdatingLike) return true;
    final original = _post;
    final isLiked = !original.isLiked;
    _post = original.copyWith(
      isLiked: isLiked,
      likeCount: isLiked
          ? original.likeCount + 1
          : (original.likeCount - 1).clamp(0, original.likeCount).toInt(),
    );
    _isUpdatingLike = true;
    notifyListeners();
    try {
      await _useCase.updateLike(feedbackId: _post.id, isLiked: isLiked);
      return true;
    } catch (_) {
      _post = original;
      return false;
    } finally {
      _isUpdatingLike = false;
      notifyListeners();
    }
  }

  Future<bool> sendComment() async {
    final content = commentController.text.trim();
    if (content.isEmpty || _isSendingComment) {
      return false;
    }
    final parentId = _replyParentId;
    _isSendingComment = true;
    notifyListeners();
    try {
      final comment = await _useCase.addComment(
        feedbackId: _post.id,
        content: content,
        parentId: parentId,
      );
      if (parentId == null) {
        _comments = List<FeedbackComment>.unmodifiable(<FeedbackComment>[
          comment,
          ..._comments,
        ]);
      } else {
        final existingReplies =
            _repliesByParentId[parentId] ?? const <FeedbackComment>[];
        _repliesByParentId[parentId] = List<FeedbackComment>.unmodifiable(
          <FeedbackComment>[...existingReplies, comment],
        );
        _expandedReplyParentIds.add(parentId);
      }
      _post = _post.copyWith(commentCount: _post.commentCount + 1);
      commentController.clear();
      _replyParentId = null;
      _replyAuthorName = null;
      _isComposerVisible = false;
      return true;
    } finally {
      _isSendingComment = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreComments() async {
    if (_isCommentsLoading || _isLoadingMoreComments || !_hasNextCommentPage) {
      return;
    }
    _isLoadingMoreComments = true;
    notifyListeners();
    try {
      await _loadComments(_currentCommentPage + 1);
    } finally {
      _isLoadingMoreComments = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment(String commentId) async {
    if (commentId.trim().isEmpty || _deletingCommentIds.contains(commentId)) {
      return false;
    }
    _deletingCommentIds.add(commentId);
    notifyListeners();
    try {
      await _useCase.deleteComment(commentId: commentId);
      _comments = List<FeedbackComment>.unmodifiable(
        _comments.where((comment) => comment.id != commentId),
      );
      for (final entry in _repliesByParentId.entries.toList()) {
        _repliesByParentId[entry.key] = List<FeedbackComment>.unmodifiable(
          entry.value.where((comment) => comment.id != commentId),
        );
      }
      await _loadComments(1, replace: true);
      _post = _post.copyWith(
        commentCount: (_post.commentCount - 1)
            .clamp(0, _post.commentCount)
            .toInt(),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      _deletingCommentIds.remove(commentId);
      notifyListeners();
    }
  }

  Future<void> toggleReplies(String parentId) async {
    if (_expandedReplyParentIds.contains(parentId)) {
      _expandedReplyParentIds.remove(parentId);
      notifyListeners();
      return;
    }

    _expandedReplyParentIds.add(parentId);
    if (_repliesByParentId.containsKey(parentId)) {
      notifyListeners();
      return;
    }

    await loadReplies(parentId);
  }

  Future<void> loadReplies(String parentId) async {
    if (parentId.trim().isEmpty ||
        _loadingReplyParentIds.contains(parentId) ||
        _repliesByParentId.containsKey(parentId)) {
      return;
    }

    _loadingReplyParentIds.add(parentId);
    notifyListeners();
    try {
      final response = await _useCase.getComments(
        feedbackId: _post.id,
        page: 1,
        pageSize: _commentPageSize,
        parentId: parentId,
      );
      _repliesByParentId[parentId] = List<FeedbackComment>.unmodifiable(
        response.items,
      );
    } finally {
      _loadingReplyParentIds.remove(parentId);
      notifyListeners();
    }
  }

  Future<void> _loadComments(int page, {bool replace = false}) async {
    final response = await _useCase.getComments(
      feedbackId: _post.id,
      page: page,
      pageSize: _commentPageSize,
    );
    _currentCommentPage = response.currentPage;
    _hasNextCommentPage = response.hasNextPage;
    _comments = List<FeedbackComment>.unmodifiable(
      replace
          ? response.items
          : <FeedbackComment>[..._comments, ...response.items],
    );
  }

  static String _normalizeIdentifier(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  @override
  void dispose() {
    commentController.dispose();
    editCommentController.dispose();
    editPostTitleController.dispose();
    editPostDescriptionController.dispose();
    super.dispose();
  }
}
