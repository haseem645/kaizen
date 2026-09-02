import 'feedback_author.dart';

class FeedbackPost {
  const FeedbackPost({
    required this.id,
    required this.title,
    required this.status,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.description,
    required this.attachments,
    required this.author,
  });

  final String id;
  final String title;
  final String status;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final String description;
  final List<String> attachments;
  final FeedbackAuthor author;

  FeedbackPost copyWith({
    String? title,
    String? description,
    bool? isLiked,
    int? likeCount,
    int? commentCount,
  }) {
    return FeedbackPost(
      id: id,
      title: title ?? this.title,
      status: status,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      description: description ?? this.description,
      attachments: attachments,
      author: author,
    );
  }
}
