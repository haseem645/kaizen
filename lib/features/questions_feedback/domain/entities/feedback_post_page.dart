import 'feedback_post.dart';

class FeedbackPostPage {
  const FeedbackPostPage({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.hasNextPage,
  });

  final List<FeedbackPost> items;
  final int totalCount;
  final int currentPage;
  final bool hasNextPage;
}
