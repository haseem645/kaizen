import '../../domain/entities/feedback_post_page.dart';
import 'feedback_post_model.dart';

class FeedbackPostPageModel extends FeedbackPostPage {
  const FeedbackPostPageModel({
    required super.items,
    required super.totalCount,
    required super.currentPage,
    required super.hasNextPage,
  });

  factory FeedbackPostPageModel.fromApiJson(
    Map<String, dynamic> json, {
    required int pageSize,
  }) {
    final items = _extractItems(
      json,
    ).map(FeedbackPostModel.fromApiJson).toList(growable: false);
    final totalCount = _readInt(json['count']);
    final currentPage = _readInt(json['current']) == 0
        ? 1
        : _readInt(json['current']);

    return FeedbackPostPageModel(
      items: items,
      totalCount: totalCount,
      currentPage: currentPage,
      hasNextPage: currentPage * pageSize < totalCount,
    );
  }

  static List<Map<String, dynamic>> _extractItems(Map<String, dynamic> json) {
    final results = json['results'];
    if (results is! List) {
      return const <Map<String, dynamic>>[];
    }

    return results.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
