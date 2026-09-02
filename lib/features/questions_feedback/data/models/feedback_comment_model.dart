import '../../domain/entities/feedback_comment.dart';
import 'feedback_author_model.dart';

class FeedbackCommentModel extends FeedbackComment {
  const FeedbackCommentModel({
    required super.id,
    required super.content,
    required super.author,
    required super.replyCount,
    required super.createdAt,
  });

  factory FeedbackCommentModel.fromApiJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    return FeedbackCommentModel(
      id: json['uuid']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      author: authorJson is Map<String, dynamic>
          ? FeedbackAuthorModel.fromApiJson(authorJson)
          : null,
      replyCount: _readInt(json['reply_count']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
