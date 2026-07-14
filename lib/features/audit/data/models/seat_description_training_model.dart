import '../../domain/entities/seat_description_training.dart';

class SeatDescriptionTrainingModuleModel extends SeatDescriptionTrainingModule {
  const SeatDescriptionTrainingModuleModel({
    required super.uuid,
    required super.title,
    required super.thumbnailLink,
  });

  factory SeatDescriptionTrainingModuleModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionTrainingModuleModel(
      uuid: _readString(json['uuid']) ?? '',
      title: _readString(json['title']) ?? '',
      thumbnailLink: _readString(json['thumbnail_link']),
    );
  }
}

class SeatDescriptionTrainingModuleDetailModel
    extends SeatDescriptionTrainingModuleDetail {
  const SeatDescriptionTrainingModuleDetailModel({
    required super.uuid,
    required super.title,
    required super.thumbnails,
    required super.description,
    required super.thumbnailLink,
    required super.trainingVideo,
    required super.isPubliclyAvailable,
    required super.learningTrackCount,
  });

  factory SeatDescriptionTrainingModuleDetailModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    final trainingVideo = _readMap(json['training_video']);

    return SeatDescriptionTrainingModuleDetailModel(
      uuid: _readString(json['uuid']) ?? '',
      title: _readString(json['title']) ?? '',
      thumbnails: _readStringList(json['thumbnails']),
      description: _readString(json['description']),
      thumbnailLink: _readString(json['thumbnail_link']),
      trainingVideo: trainingVideo == null
          ? null
          : SeatDescriptionTrainingVideoModel.fromApiJson(trainingVideo),
      isPubliclyAvailable: _readBool(json['is_publicly_available']) ?? false,
      learningTrackCount: _readInt(json['learning_track_count']) ?? 0,
    );
  }
}

class SeatDescriptionTrainingVideoModel extends SeatDescriptionTrainingVideo {
  const SeatDescriptionTrainingVideoModel({
    required super.uuid,
    required super.title,
    required super.url,
    required super.duration,
    required super.transcript,
  });

  factory SeatDescriptionTrainingVideoModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionTrainingVideoModel(
      uuid: _readString(json['uuid']) ?? '',
      title: _readString(json['title']) ?? '',
      url: _readString(json['url']),
      duration: _readInt(json['duration']) ?? 0,
      transcript: _readString(json['transcript']),
    );
  }
}

class SeatDescriptionTrainingDocumentModel
    extends SeatDescriptionTrainingDocument {
  const SeatDescriptionTrainingDocumentModel({
    required super.uuid,
    required super.text,
  });

  factory SeatDescriptionTrainingDocumentModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionTrainingDocumentModel(
      uuid: _readString(json['uuid']) ?? '',
      text: _readString(json['text']),
    );
  }
}

Map<String, dynamic>? _readMap(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : null;
}

String? _readString(dynamic value) {
  final resolved = value?.toString().trim();
  if (resolved == null || resolved.isEmpty) {
    return null;
  }
  return resolved;
}

int? _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

bool? _readBool(dynamic value) {
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

List<String> _readStringList(dynamic value) {
  if (value is! List) {
    return const <String>[];
  }

  return value.map(_readString).whereType<String>().toList(growable: false);
}
