import '../../domain/entities/feedback_post.dart';
import 'feedback_author_model.dart';

class FeedbackPostModel extends FeedbackPost {
  const FeedbackPostModel({
    required super.id,
    required super.title,
    required super.status,
    required super.isLiked,
    required super.likeCount,
    required super.commentCount,
    required super.description,
    required super.attachments,
    required super.author,
  });

  factory FeedbackPostModel.fromApiJson(Map<String, dynamic> json) {
    final authorJson = json['author'];

    return FeedbackPostModel(
      id: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isLiked: json['is_liked'] == true,
      likeCount: _readInt(json['like_count']),
      commentCount: _readInt(json['comment_count']),
      description: json['description']?.toString() ?? '',
      attachments: _readAttachments(json['attachments']),
      author: FeedbackAuthorModel.fromApiJson(
        authorJson is Map<String, dynamic>
            ? authorJson
            : const <String, dynamic>{},
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _readAttachments(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
