import '../entities/feedback_post_page.dart';
import '../entities/feedback_post.dart';
import '../entities/feedback_post_create_draft.dart';
import '../entities/feedback_image_attachment.dart';
import '../entities/feedback_comment.dart';
import '../entities/feedback_comment_page.dart';
import '../repositories/feedback_repository.dart';

class GetFeedbackPostsUseCase {
  const GetFeedbackPostsUseCase(this._repository);

  final FeedbackRepository _repository;

  Future<FeedbackPostPage> call({
    required int page,
    int pageSize = 10,
    String search = '',
  }) {
    return _repository.getFeedbackPosts(
      page: page,
      pageSize: pageSize,
      search: search,
    );
  }

  Future<void> updateLike({required String feedbackId, required bool isLiked}) {
    return _repository.updateFeedbackPostLike(
      feedbackId: feedbackId,
      isLiked: isLiked,
    );
  }

  Future<FeedbackPost?> createPost(FeedbackPostCreateDraft draft) {
    return _repository.createFeedbackPost(draft);
  }

  Future<FeedbackPost?> updatePost({
    required String feedbackId,
    required String title,
    required String description,
    List<FeedbackImageAttachment> attachments =
        const <FeedbackImageAttachment>[],
  }) => _repository.updateFeedbackPost(
    feedbackId: feedbackId,
    title: title,
    description: description,
    attachments: attachments,
  );

  Future<void> deletePost({required String feedbackId}) =>
      _repository.deleteFeedbackPost(feedbackId: feedbackId);

  Future<FeedbackCommentPage> getComments({
    required String feedbackId,
    required int page,
    int pageSize = 10,
    String? parentId,
  }) => _repository.getFeedbackComments(
    feedbackId: feedbackId,
    page: page,
    pageSize: pageSize,
    parentId: parentId,
  );

  Future<FeedbackComment> addComment({
    required String feedbackId,
    required String content,
    String? parentId,
  }) => _repository.addFeedbackComment(
    feedbackId: feedbackId,
    content: content,
    parentId: parentId,
  );

  Future<void> deleteComment({required String commentId}) =>
      _repository.deleteFeedbackComment(commentId: commentId);

  Future<FeedbackComment> updateComment({
    required String commentId,
    required String content,
  }) =>
      _repository.updateFeedbackComment(commentId: commentId, content: content);
}
