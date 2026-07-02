class ComplianceTrackItemDetail {
  const ComplianceTrackItemDetail({
    required this.uuid,
    required this.position,
    required this.trainingModuleUuid,
    required this.title,
    required this.quizStatus,
    required this.videoUrl,
    required this.videoDuration,
    required this.videoTranscript,
    required this.videoThumbnailLink,
    required this.trainingDocument,
    required this.quizCompletionPercentage,
  });

  final String uuid;
  final int position;
  final String trainingModuleUuid;
  final String title;
  final String quizStatus;
  final String? videoUrl;
  final int videoDuration;
  final String? videoTranscript;
  final String? videoThumbnailLink;
  final String? trainingDocument;
  final int quizCompletionPercentage;
}
