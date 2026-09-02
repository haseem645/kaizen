import 'feedback_author.dart';

class FeedbackComment {
  const FeedbackComment({
    required this.id,
    required this.content,
    required this.author,
    required this.replyCount,
    required this.createdAt,
  });

  final String id;
  final String content;
  final FeedbackAuthor? author;
  final int replyCount;
  final String createdAt;

  FeedbackComment copyWith({String? content}) => FeedbackComment(
    id: id,
    content: content ?? this.content,
    author: author,
    replyCount: replyCount,
    createdAt: createdAt,
  );
}
