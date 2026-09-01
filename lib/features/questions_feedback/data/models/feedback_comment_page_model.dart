import '../../domain/entities/feedback_comment_page.dart';
import 'feedback_comment_model.dart';

class FeedbackCommentPageModel extends FeedbackCommentPage {
  const FeedbackCommentPageModel({
    required super.items,
    required super.totalCount,
    required super.currentPage,
    required super.hasNextPage,
  });

  factory FeedbackCommentPageModel.fromApiJson(
    Map<String, dynamic> json, {
    required int pageSize,
  }) {
    final items = (json['results'] as List? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(FeedbackCommentModel.fromApiJson)
        .toList(growable: false);
    final totalCount = _readInt(json['count']);
    final currentPage = _readInt(json['current']) == 0
        ? 1
        : _readInt(json['current']);
    return FeedbackCommentPageModel(
      items: items,
      totalCount: totalCount,
      currentPage: currentPage,
      hasNextPage: json['next'] != null || currentPage * pageSize < totalCount,
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
