import 'feedback_image_attachment.dart';

class FeedbackPostCreateDraft {
  const FeedbackPostCreateDraft({
    required this.title,
    required this.description,
    required this.attachments,
  });

  final String title;
  final String description;
  final List<FeedbackImageAttachment> attachments;
}
