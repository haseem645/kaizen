class SeatDescriptionTrainingModule {
  const SeatDescriptionTrainingModule({
    required this.uuid,
    required this.title,
    required this.thumbnailLink,
  });

  final String uuid;
  final String title;
  final String? thumbnailLink;
}

class SeatDescriptionTrainingModuleDetail {
  const SeatDescriptionTrainingModuleDetail({
    required this.uuid,
    required this.title,
    required this.thumbnails,
    required this.description,
    required this.thumbnailLink,
    required this.trainingVideo,
    required this.isPubliclyAvailable,
    required this.learningTrackCount,
  });

  final String uuid;
  final String title;
  final List<String> thumbnails;
  final String? description;
  final String? thumbnailLink;
  final SeatDescriptionTrainingVideo? trainingVideo;
  final bool isPubliclyAvailable;
  final int learningTrackCount;

  String? get previewThumbnailLink {
    if (thumbnailLink != null && thumbnailLink!.trim().isNotEmpty) {
      return thumbnailLink;
    }
    if (thumbnails.isEmpty) {
      return null;
    }
    return thumbnails.first;
  }
}

class SeatDescriptionTrainingVideo {
  const SeatDescriptionTrainingVideo({
    required this.uuid,
    required this.title,
    required this.url,
    required this.duration,
    required this.transcript,
  });

  final String uuid;
  final String title;
  final String? url;
  final int duration;
  final String? transcript;
}

class SeatDescriptionTrainingDocument {
  const SeatDescriptionTrainingDocument({
    required this.uuid,
    required this.text,
  });

  final String uuid;
  final String? text;
}
