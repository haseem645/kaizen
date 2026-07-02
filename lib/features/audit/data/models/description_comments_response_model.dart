import '../../domain/entities/description_comments_response.dart';

class DescriptionCommentsResponseModel extends DescriptionCommentsResponse {
  const DescriptionCommentsResponseModel({
    required super.uuid,
    required super.media,
    required super.type,
    required super.comments,
    required super.totalComments,
  });

  factory DescriptionCommentsResponseModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    final commentsJson = json['comments'];

    return DescriptionCommentsResponseModel(
      uuid: _readString(json['uuid']) ?? '',
      media: _readString(json['media']) ?? '',
      type: _readString(json['type']) ?? '',
      comments: commentsJson is List
          ? commentsJson
                .map(_readMap)
                .whereType<Map<String, dynamic>>()
                .map(DescriptionCommentModel.fromApiJson)
                .toList(growable: false)
          : const <DescriptionComment>[],
      totalComments: _readInt(json['total_comments']) ?? 0,
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}

class DescriptionCommentModel extends DescriptionComment {
  const DescriptionCommentModel({
    required super.uuid,
    required super.comment,
    required super.createdAt,
    required super.parent,
    required super.author,
    required super.replies,
    required super.isRead,
  });

  factory DescriptionCommentModel.fromApiJson(Map<String, dynamic> json) {
    final author = _readMap(json['author']);
    final repliesJson = json['replies'];

    return DescriptionCommentModel(
      uuid: _readString(json['uuid']) ?? '',
      comment: _readString(json['comment']) ?? '',
      createdAt: _readString(json['created_at']) ?? '',
      parent: _readString(json['parent']),
      author: author == null
          ? null
          : DescriptionCommentAuthorModel.fromApiJson(author),
      replies: repliesJson is List
          ? repliesJson
                .map(_readMap)
                .whereType<Map<String, dynamic>>()
                .map(DescriptionCommentModel.fromApiJson)
                .toList(growable: false)
          : const <DescriptionComment>[],
      isRead: _readBool(json['is_read']) ?? false,
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }

    return null;
  }
}

class DescriptionCommentAuthorModel extends DescriptionCommentAuthor {
  const DescriptionCommentAuthorModel({
    required super.uuid,
    required super.name,
    required super.email,
    required super.image,
    required super.onboarded,
  });

  factory DescriptionCommentAuthorModel.fromApiJson(Map<String, dynamic> json) {
    return DescriptionCommentAuthorModel(
      uuid: _readString(json['uuid']) ?? '',
      name: _readString(json['name']) ?? '',
      email: _readString(json['email']) ?? '',
      image: _readString(json['image']),
      onboarded: _readBool(json['onboarded']) ?? true,
    );
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }

    return null;
  }
}

class CommentAdditionResponseModel extends CommentAdditionResponse {
  const CommentAdditionResponseModel({
    required super.uuid,
    required super.comment,
    required super.createdAt,
    required super.parent,
    required super.author,
  });

  factory CommentAdditionResponseModel.fromApiJson(Map<String, dynamic> json) {
    final author = _readMap(json['author']);

    return CommentAdditionResponseModel(
      uuid: _readString(json['uuid']) ?? '',
      comment: _readString(json['comment']) ?? '',
      createdAt: _readString(json['created_at']) ?? '',
      parent: _readString(json['parent']),
      author: author == null
          ? null
          : DescriptionCommentAuthorModel.fromApiJson(author),
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }
}
