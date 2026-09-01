import '../../domain/entities/feedback_author.dart';

class FeedbackAuthorModel extends FeedbackAuthor {
  const FeedbackAuthorModel({
    required super.id,
    required super.name,
    required super.imageUrl,
  });

  factory FeedbackAuthorModel.fromApiJson(Map<String, dynamic> json) {
    return FeedbackAuthorModel(
      id: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: _readNullableString(json['image']),
    );
  }

  static String? _readNullableString(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }
}
