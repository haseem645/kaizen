import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../../data/datasources/feedback_remote_data_source.dart';
import '../../data/repositories/feedback_repository_impl.dart';
import '../../domain/entities/feedback_post.dart';
import '../../domain/entities/feedback_image_attachment.dart';
import '../../domain/entities/feedback_post_create_draft.dart';
import '../../domain/usecases/get_feedback_posts_usecase.dart';

enum FeedbackPostCreateResult { created, validationFailed, failed }

class QuestionsFeedbackController extends ChangeNotifier {
  QuestionsFeedbackController(this._getFeedbackPostsUseCase)
    : searchController = TextEditingController() {
    createTitleController.addListener(_handleCreateDraftChanged);
    createDescriptionController.addListener(_handleCreateDraftChanged);
  }

  static const int _pageSize = 10;
  static const int maxImageAttachments = 5;

  final GetFeedbackPostsUseCase _getFeedbackPostsUseCase;
  final TextEditingController searchController;
  final TextEditingController createTitleController = TextEditingController();
  final TextEditingController createDescriptionController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isInitialLoading = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isSearchLoading = false;
  bool _isSearchActive = false;
  bool _isCreatingPost = false;
  bool _showCreateValidationErrors = false;
  bool _hasNextPage = true;
  int _currentPage = 0;
  int _totalCount = 0;
  String? _errorMessage;
  String _searchQuery = '';
  List<FeedbackPost> _posts = const <FeedbackPost>[];
  List<FeedbackImageAttachment> _createAttachments =
      const <FeedbackImageAttachment>[];
  final Set<String> _updatingLikePostIds = <String>{};
  bool _hasPendingSearchRefresh = false;

  bool get isInitialLoading => _isInitialLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSearchLoading => _isSearchLoading;
  bool get isSearchActive => _isSearchActive;
  bool get isCreatingPost => _isCreatingPost;
  bool get hasNextPage => _hasNextPage;
  bool get hasSearchText => searchController.text.trim().isNotEmpty;
  bool get isShowingSearchResults => _searchQuery.isNotEmpty;
  String get searchQuery => _searchQuery;
  int get totalCount => _totalCount;
  String? get errorMessage => _errorMessage;
  List<FeedbackPost> get posts => List<FeedbackPost>.unmodifiable(_posts);
  List<FeedbackImageAttachment> get createAttachments =>
      List<FeedbackImageAttachment>.unmodifiable(_createAttachments);
  bool get canAddImageAttachments =>
      _createAttachments.length < maxImageAttachments;
  String? get createTitleError =>
      _showCreateValidationErrors && createTitleController.text.trim().isEmpty
      ? 'title_required'
      : null;
  String? get createDescriptionError =>
      _showCreateValidationErrors &&
          createDescriptionController.text.trim().isEmpty
      ? 'description_required'
      : null;

  bool isUpdatingLike(String postId) => _updatingLikePostIds.contains(postId);

  void openSearch() {
    if (_isSearchActive) {
      return;
    }

    _isSearchActive = true;
    notifyListeners();
  }

  Future<void> closeSearch() async {
    _isSearchActive = false;
    await clearSearch();
    notifyListeners();
  }

  void updateSearchQuery(String value) {
    notifyListeners();
  }

  Future<void> clearSearch() async {
    final shouldReloadPosts =
        _searchQuery.isNotEmpty || searchController.text.trim().isNotEmpty;
    searchController.clear();
    _searchQuery = '';
    if (!shouldReloadPosts) {
      notifyListeners();
      return;
    }

    await _performSearch();
  }

  Future<void> submitSearch() async {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      return;
    }

    _searchQuery = query;
    await _performSearch();
  }

  Future<void> pickImageAttachments() async {
    if (_isCreatingPost || !canAddImageAttachments) {
      return;
    }

    final selectedImages = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      limit: maxImageAttachments - _createAttachments.length,
    );
    if (selectedImages.isEmpty) {
      return;
    }

    final attachments = <FeedbackImageAttachment>[..._createAttachments];
    for (final image in selectedImages) {
      if (attachments.length == maxImageAttachments) {
        break;
      }

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        continue;
      }

      final fileName = image.name.trim().isEmpty
          ? 'attachment_${attachments.length + 1}.jpg'
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

    _createAttachments = List<FeedbackImageAttachment>.unmodifiable(
      attachments,
    );
    notifyListeners();
  }

  void removeImageAttachment(int index) {
    if (_isCreatingPost || index < 0 || index >= _createAttachments.length) {
      return;
    }

    final attachments = List<FeedbackImageAttachment>.of(_createAttachments)
      ..removeAt(index);
    _createAttachments = List<FeedbackImageAttachment>.unmodifiable(
      attachments,
    );
    notifyListeners();
  }

  Future<FeedbackPostCreateResult> createPost() async {
    _showCreateValidationErrors = true;
    if (createTitleError != null || createDescriptionError != null) {
      notifyListeners();
      return FeedbackPostCreateResult.validationFailed;
    }

    _isCreatingPost = true;
    notifyListeners();

    try {
      await _getFeedbackPostsUseCase.createPost(
        FeedbackPostCreateDraft(
          title: createTitleController.text.trim(),
          description: createDescriptionController.text.trim(),
          attachments: _createAttachments,
        ),
      );
      // Read back the server's post so attachment URLs come from its source of truth.
      _searchQuery = '';
      searchController.clear();
      await _loadPage(1, replace: true);
      _clearCreateDraft();
      return FeedbackPostCreateResult.created;
    } catch (_) {
      return FeedbackPostCreateResult.failed;
    } finally {
      _isCreatingPost = false;
      notifyListeners();
    }
  }

  Future<bool> toggleLike(String postId) async {
    if (_updatingLikePostIds.contains(postId)) {
      return true;
    }

    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) {
      return false;
    }

    final originalPost = _posts[postIndex];
    final isLiked = !originalPost.isLiked;
    final optimisticPost = originalPost.copyWith(
      isLiked: isLiked,
      likeCount: isLiked
          ? originalPost.likeCount + 1
          : (originalPost.likeCount - 1)
                .clamp(0, originalPost.likeCount)
                .toInt(),
    );

    _updatingLikePostIds.add(postId);
    _replacePost(postIndex, optimisticPost);
    notifyListeners();

    try {
      await _getFeedbackPostsUseCase.updateLike(
        feedbackId: postId,
        isLiked: isLiked,
      );
      return true;
    } catch (_) {
      _replacePost(postIndex, originalPost);
      return false;
    } finally {
      _updatingLikePostIds.remove(postId);
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_isInitialLoading || _posts.isNotEmpty) {
      return;
    }

    _isInitialLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadPage(1, replace: true);
    } catch (_) {
      _errorMessage = 'load_failed';
    } finally {
      _isInitialLoading = false;
      notifyListeners();
      await _runPendingSearchIfNeeded();
    }
  }

  Future<void> refresh() async {
    if (_isInitialLoading ||
        _isRefreshing ||
        _isLoadingMore ||
        _isSearchLoading) {
      _hasPendingSearchRefresh = true;
      return;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadPage(1, replace: true);
    } catch (_) {
      _errorMessage = 'load_failed';
    } finally {
      _isRefreshing = false;
      notifyListeners();
      await _runPendingSearchIfNeeded();
    }
  }

  Future<void> loadNextPage() async {
    if (_isInitialLoading ||
        _isRefreshing ||
        _isLoadingMore ||
        _isSearchLoading ||
        !_hasNextPage) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _loadPage(_currentPage + 1);
    } catch (_) {
      _errorMessage = 'load_failed';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
      await _runPendingSearchIfNeeded();
    }
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    final response = await _getFeedbackPostsUseCase(
      page: page,
      pageSize: _pageSize,
      search: _searchQuery,
    );
    _currentPage = response.currentPage;
    _totalCount = response.totalCount;
    _hasNextPage = response.hasNextPage && response.items.isNotEmpty;
    _posts = List<FeedbackPost>.unmodifiable(
      replace ? response.items : <FeedbackPost>[..._posts, ...response.items],
    );
  }

  void _replacePost(int index, FeedbackPost post) {
    final updatedPosts = List<FeedbackPost>.of(_posts);
    updatedPosts[index] = post;
    _posts = List<FeedbackPost>.unmodifiable(updatedPosts);
  }

  void _clearCreateDraft() {
    createTitleController.clear();
    createDescriptionController.clear();
    _createAttachments = const <FeedbackImageAttachment>[];
    _showCreateValidationErrors = false;
  }

  void _handleCreateDraftChanged() {
    if (_showCreateValidationErrors) {
      notifyListeners();
    }
  }

  Future<void> _performSearch() async {
    if (_isInitialLoading ||
        _isRefreshing ||
        _isLoadingMore ||
        _isSearchLoading) {
      return;
    }

    _isSearchLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentPage = 0;
      _hasNextPage = true;
      await _loadPage(1, replace: true);
    } catch (_) {
      _errorMessage = 'load_failed';
    } finally {
      _isSearchLoading = false;
      notifyListeners();
    }

    await _runPendingSearchIfNeeded();
  }

  Future<void> _runPendingSearchIfNeeded() async {
    if (!_hasPendingSearchRefresh) {
      return;
    }

    _hasPendingSearchRefresh = false;
    await _performSearch();
  }

  @override
  void dispose() {
    searchController.dispose();
    createTitleController.dispose();
    createDescriptionController.dispose();
    super.dispose();
  }
}

FeedbackRepositoryImpl createFeedbackRepository(
  FeedbackRemoteDataSource remoteDataSource,
) {
  return FeedbackRepositoryImpl(remoteDataSource);
}

GetFeedbackPostsUseCase createGetFeedbackPostsUseCase(
  FeedbackRepositoryImpl repository,
) {
  return GetFeedbackPostsUseCase(repository);
}
