import 'feedback_comment.dart';

class FeedbackCommentPage {
  const FeedbackCommentPage({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.hasNextPage,
  });

  final List<FeedbackComment> items;
  final int totalCount;
  final int currentPage;
  final bool hasNextPage;
}
