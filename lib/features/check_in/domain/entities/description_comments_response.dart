class DescriptionCommentsResponse {
  const DescriptionCommentsResponse({
    required this.uuid,
    required this.media,
    required this.type,
    required this.comments,
    required this.totalComments,
  });

  final String uuid;
  final String media;
  final String type;
  final List<DescriptionComment> comments;
  final int totalComments;
}

class DescriptionComment {
  const DescriptionComment({
    required this.uuid,
    required this.comment,
    required this.createdAt,
    required this.parent,
    required this.author,
    required this.replies,
    required this.isRead,
  });

  final String uuid;
  final String comment;
  final String createdAt;
  final String? parent;
  final DescriptionCommentAuthor? author;
  final List<DescriptionComment> replies;
  final bool isRead;
}

class DescriptionCommentAuthor {
  const DescriptionCommentAuthor({
    required this.uuid,
    required this.name,
    required this.email,
    required this.image,
    required this.onboarded,
  });

  final String uuid;
  final String name;
  final String email;
  final String? image;
  final bool onboarded;
}

class CommentAdditionResponse extends DescriptionComment {
  const CommentAdditionResponse({
    required super.uuid,
    required super.comment,
    required super.createdAt,
    required super.parent,
    required super.author,
  }) : super(replies: const <DescriptionComment>[], isRead: true);
}
