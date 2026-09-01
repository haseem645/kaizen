import '../entities/feedback_post_page.dart';
import '../entities/feedback_post.dart';
import '../entities/feedback_post_create_draft.dart';
import '../entities/feedback_comment.dart';
import '../entities/feedback_comment_page.dart';

abstract class FeedbackRepository {
  Future<FeedbackPostPage> getFeedbackPosts({
    required int page,
    int pageSize = 10,
    String search = '',
  });

  Future<void> updateFeedbackPostLike({
    required String feedbackId,
    required bool isLiked,
  });

  Future<FeedbackPost?> createFeedbackPost(FeedbackPostCreateDraft draft);

  Future<FeedbackCommentPage> getFeedbackComments({
    required String feedbackId,
    required int page,
    int pageSize = 10,
    String? parentId,
  });

  Future<FeedbackComment> addFeedbackComment({
    required String feedbackId,
    required String content,
    String? parentId,
  });

  Future<void> deleteFeedbackComment({required String commentId});

  Future<FeedbackComment> updateFeedbackComment({
    required String commentId,
    required String content,
  });
}
