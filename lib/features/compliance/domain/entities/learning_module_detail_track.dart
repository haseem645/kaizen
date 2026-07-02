import '../../../../core/utils/custom_functions.dart';

class LearningTrackModuleDetail {
  const LearningTrackModuleDetail({
    this.trainingModuleItemId,
    this.uuid,
    this.name,
    this.job,
    this.status,
    this.deadline,
    this.schedule,
    this.createdAt,
    this.thumbnailLink,
    this.videoUrl,
    this.videoThumbnailLink,
    this.completionPercentage,
    this.passingPercentage,
    this.breakPointTitle,
    this.breakPointSubtitle,
  });

  final String? trainingModuleItemId;
  final String? uuid;
  final String? name;
  final String? job;
  final String? status;
  final String? deadline;
  final String? schedule;
  final String? createdAt;
  final String? thumbnailLink;
  final String? videoUrl;
  final String? videoThumbnailLink;
  final int? completionPercentage;
  final int? passingPercentage;
  final String? breakPointTitle;
  final String? breakPointSubtitle;

  factory LearningTrackModuleDetail.fromJson(Map<String, dynamic> json) {
    final jobMap = _readMap(json['job']);
    final trainingModuleMap = _readMap(json['training_module']);
    final trainingVideoMap = _readMap(trainingModuleMap?['training_video']);

    return LearningTrackModuleDetail(
      trainingModuleItemId:
          _readString(json['trainingModuleItemId']) ??
          _readString(json['training_module_item_id']),
      uuid:
          _readString(json['uuid']) ?? _readString(trainingModuleMap?['uuid']),
      name:
          _readString(json['name']) ?? _readString(trainingModuleMap?['title']),
      job: _readString(json['job']) ?? _readString(jobMap?['title']),
      status:
          _readString(json['status']) ??
          _readString(trainingModuleMap?['status']),
      deadline: _readString(json['deadline']),
      schedule: _readString(json['schedule']),
      createdAt: _readString(json['created_at']),
      thumbnailLink:
          _readString(json['thumbnail_link']) ??
          _readString(trainingModuleMap?['thumbnail_link']),
      videoUrl:
          _readString(json['video_url']) ??
          _readString(trainingVideoMap?['url']),
      videoThumbnailLink:
          _readString(json['video_thumbnail_link']) ??
          _readString(trainingVideoMap?['thumbnail_link']),
      completionPercentage:
          _readInt(json['completion_percentage']) ??
          _readInt(trainingModuleMap?['completion_percentage']),
      passingPercentage:
          _readInt(json['passing_percentage']) ??
          _readInt(trainingModuleMap?['passing_percentage']),
      breakPointTitle: _readString(_readMap(json['break_point'])?['title']),
      breakPointSubtitle: _readString(
        _readMap(json['break_point'])?['subtitle'],
      ),
    );
  }

  double get progressValue {
    final value = completionPercentage ?? 0;
    final safeValue = value.clamp(0, 100);
    return safeValue / 100;
  }

  double get passingPercentageValue {
    final value = passingPercentage ?? 0.0;
    final safeValue = value.clamp(0, 100);
    return (safeValue / 100);
  }

  String get displayName => _resolvedOrFallback(name, 'Untitled Track');

  String get displayJob => _resolvedOrFallback(job, 'No Job');

  String get displayStatus {
    final rawStatus = _resolvedOrFallback(status, 'Pending');
    return CustomFunctions.displayStatus(rawStatus) ?? 'Pending';
  }

  String get displayDeadline => _resolvedOrFallback(deadline, 'No deadline');

  String get displaySchedule => _resolvedOrFallback(schedule, 'No schedule');

  String get displayTrackName => _resolvedOrFallback(schedule, displayName);

  String get displayCreatedAt => _resolvedOrFallback(createdAt, 'Unknown date');

  bool get isBreakPoint =>
      (breakPointTitle?.trim().isNotEmpty ?? false) ||
      (breakPointSubtitle?.trim().isNotEmpty ?? false);

  String get displayBreakPointTitle =>
      _resolvedOrFallback(breakPointTitle, 'Congratulations!');

  String get displayBreakPointSubtitle => _resolvedOrFallback(
    breakPointSubtitle,
    'You can now move forward to the next module.',
  );

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

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  static String _resolvedOrFallback(String? value, String fallback) {
    final resolved = value?.trim();
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }

    return resolved;
  }
}
