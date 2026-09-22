import '../../domain/entities/seat_description_audit_report_comments.dart';

class SeatDescriptionAuditReportCommentsModel
    extends SeatDescriptionAuditReportComments {
  const SeatDescriptionAuditReportCommentsModel({required super.items});

  factory SeatDescriptionAuditReportCommentsModel.fromApiJson(dynamic json) {
    final items = _extractList(json)
        .expand(SeatDescriptionAuditReportCommentModel.fromUnknown)
        .where(
          (item) =>
              item.comment.trim().isNotEmpty ||
              (item.media?.trim().isNotEmpty ?? false) ||
              (item.thumbnailUrl?.trim().isNotEmpty ?? false),
        )
        .toList(growable: false);

    return SeatDescriptionAuditReportCommentsModel(items: items);
  }

  static List<dynamic> _extractList(dynamic json) {
    if (json is List) {
      return json;
    }

    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      for (final key in const [
        'results',
        'comments',
        'audit_media',
        'items',
        'data',
      ]) {
        final value = map[key];
        if (value is List) {
          return value;
        }
      }

      return [map];
    }

    return const <dynamic>[];
  }
}

class SeatDescriptionAuditReportCommentModel
    extends SeatDescriptionAuditReportComment {
  const SeatDescriptionAuditReportCommentModel({
    required super.uuid,
    required super.comment,
    required super.media,
    required super.thumbnailUrl,
    required super.type,
    required super.authorName,
    required super.createdAt,
  });

  static List<SeatDescriptionAuditReportCommentModel> fromUnknown(
    dynamic value,
  ) {
    if (value is String) {
      final comment = value.trim();
      return comment.isEmpty
          ? const <SeatDescriptionAuditReportCommentModel>[]
          : [
              SeatDescriptionAuditReportCommentModel(
                uuid: '',
                comment: comment,
                media: null,
                thumbnailUrl: null,
                type: null,
                authorName: null,
                createdAt: null,
              ),
            ];
    }

    if (value is! Map) {
      return const <SeatDescriptionAuditReportCommentModel>[];
    }

    final map = Map<String, dynamic>.from(value);
    final author = _readMap(map['author']);
    final comment =
        _readString(map['comment']) ??
        _readString(map['text']) ??
        _readString(map['body']) ??
        _readString(map['message']) ??
        '';

    final mediaUrl = _readString(map['media']) ?? _readString(map['media_url']);
    final thumbnailUrl = _readString(map['thumbnail_url']);
    final type = _readString(map['type']) ?? _readString(map['media_type']);
    final current = comment.isEmpty && mediaUrl == null && thumbnailUrl == null
        ? const <SeatDescriptionAuditReportCommentModel>[]
        : [
            SeatDescriptionAuditReportCommentModel(
              uuid: _readString(map['uuid']) ?? '',
              comment: comment,
              media: mediaUrl,
              thumbnailUrl: thumbnailUrl,
              type: type,
              authorName:
                  _readString(author?['name']) ?? _readString(map['name']),
              createdAt:
                  _readString(map['created_at']) ?? _readString(map['date']),
            ),
          ];

    final nested = <SeatDescriptionAuditReportCommentModel>[];
    for (final key in const ['comments', 'replies']) {
      final raw = map[key];
      if (raw is List) {
        nested.addAll(raw.expand(fromUnknown));
      }
    }

    return [...current, ...nested];
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
