import '../../domain/entities/feedback_post_page.dart';
import '../../domain/entities/feedback_post.dart';
import '../../domain/entities/feedback_post_create_draft.dart';
import '../../domain/entities/feedback_comment.dart';
import '../../domain/entities/feedback_comment_page.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_data_source.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  const FeedbackRepositoryImpl(this._remoteDataSource);

  final FeedbackRemoteDataSource _remoteDataSource;

  @override
  Future<FeedbackPostPage> getFeedbackPosts({
    required int page,
    int pageSize = 10,
    String search = '',
  }) {
    return _remoteDataSource.getFeedbackPosts(
      page: page,
      pageSize: pageSize,
      search: search,
    );
  }

  @override
  Future<void> updateFeedbackPostLike({
    required String feedbackId,
    required bool isLiked,
  }) {
    return _remoteDataSource.updateFeedbackPostLike(
      feedbackId: feedbackId,
      isLiked: isLiked,
    );
  }

  @override
  Future<FeedbackPost?> createFeedbackPost(FeedbackPostCreateDraft draft) {
    return _remoteDataSource.createFeedbackPost(draft);
  }

  @override
  Future<FeedbackCommentPage> getFeedbackComments({
    required String feedbackId,
    required int page,
    int pageSize = 10,
    String? parentId,
  }) => _remoteDataSource.getFeedbackComments(
    feedbackId: feedbackId,
    page: page,
    pageSize: pageSize,
    parentId: parentId,
  );

  @override
  Future<FeedbackComment> addFeedbackComment({
    required String feedbackId,
    required String content,
    String? parentId,
  }) => _remoteDataSource.addFeedbackComment(
    feedbackId: feedbackId,
    content: content,
    parentId: parentId,
  );

  @override
  Future<void> deleteFeedbackComment({required String commentId}) =>
      _remoteDataSource.deleteFeedbackComment(commentId: commentId);

  @override
  Future<FeedbackComment> updateFeedbackComment({
    required String commentId,
    required String content,
  }) => _remoteDataSource.updateFeedbackComment(
    commentId: commentId,
    content: content,
  );
}
