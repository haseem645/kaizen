import '../../domain/entities/seat_description_final_audit_report.dart';
import '../../../training/domain/entities/seat_description_training_route.dart';

class SeatDescriptionFinalAuditReportModel
    extends SeatDescriptionFinalAuditReport {
  const SeatDescriptionFinalAuditReportModel({
    required super.uuid,
    required super.trainingRoute,
    required super.auditFactorType,
    required super.description,
    required super.jobSpecifics,
    required super.job,
    required super.isOpenSeat,
    required super.summaryData,
    required super.checkInComments,
  });

  factory SeatDescriptionFinalAuditReportModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionFinalAuditReportModel(
      uuid: _readString(json['uuid']) ?? '',
      trainingRoute: SeatDescriptionTrainingRouteModel.fromApiJson(
        _readMap(json['training_route']) ?? const <String, dynamic>{},
      ),
      auditFactorType: _readString(json['audit_factor_type']) ?? '',
      description: _readString(json['description']) ?? '',
      jobSpecifics: _readString(json['job_specifics']) ?? '',
      job: SeatDescriptionFinalAuditJobModel.fromApiJson(
        _readMap(json['job']) ?? const <String, dynamic>{},
      ),
      isOpenSeat: _readBool(json['is_open_seat']) ?? false,
      summaryData: SeatDescriptionFinalAuditSummaryModel.fromApiJson(
        _readMap(json['summary_data']) ?? const <String, dynamic>{},
      ),
      checkInComments: _readComments(
        json['check_in_comments'] ?? json['comments'] ?? json['audit_comments'],
      ),
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

  static List<String> _readComments(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((item) {
          if (item is String) {
            return item.trim();
          }
          if (item is Map) {
            return _readString(item['comment']) ??
                _readString(item['text']) ??
                '';
          }
          return item.toString().trim();
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class SeatDescriptionTrainingRouteModel extends SeatDescriptionTrainingRoute {
  const SeatDescriptionTrainingRouteModel({
    required super.job,
    required super.category,
    required super.description,
    super.initialModuleId,
  });

  factory SeatDescriptionTrainingRouteModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionTrainingRouteModel(
      job: SeatDescriptionFinalAuditReportModel._readString(json['job']) ?? '',
      category:
          SeatDescriptionFinalAuditReportModel._readString(json['category']) ??
          '',
      description:
          SeatDescriptionFinalAuditReportModel._readString(
            json['description'],
          ) ??
          '',
      initialModuleId: SeatDescriptionFinalAuditReportModel._readString(
        json['initial_module_id'] ?? json['initialModuleId'],
      ),
    );
  }
}

class SeatDescriptionFinalAuditJobModel extends SeatDescriptionFinalAuditJob {
  const SeatDescriptionFinalAuditJobModel({
    required super.uuid,
    required super.title,
  });

  factory SeatDescriptionFinalAuditJobModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionFinalAuditJobModel(
      uuid:
          SeatDescriptionFinalAuditReportModel._readString(json['uuid']) ?? '',
      title:
          SeatDescriptionFinalAuditReportModel._readString(json['title']) ?? '',
    );
  }
}

class SeatDescriptionFinalAuditSummaryModel
    extends SeatDescriptionFinalAuditSummary {
  const SeatDescriptionFinalAuditSummaryModel({
    required super.stats,
    required super.trends,
  });

  factory SeatDescriptionFinalAuditSummaryModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    final trendsJson = json['trends'];
    return SeatDescriptionFinalAuditSummaryModel(
      stats: SeatDescriptionFinalAuditStatsModel.fromApiJson(
        SeatDescriptionFinalAuditReportModel._readMap(json['stats']) ??
            const <String, dynamic>{},
      ),
      trends: trendsJson is List
          ? trendsJson
                .whereType<Map>()
                .map(
                  (item) => SeatDescriptionFinalAuditTrendModel.fromApiJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <SeatDescriptionFinalAuditTrend>[],
    );
  }
}

class SeatDescriptionFinalAuditStatsModel
    extends SeatDescriptionFinalAuditStats {
  const SeatDescriptionFinalAuditStatsModel({
    required super.totalGreat,
    required super.totalNeedsImprovement,
    required super.totalAlmostThere,
    required super.totalPercentage,
    required super.confidenceLevel,
  });

  factory SeatDescriptionFinalAuditStatsModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionFinalAuditStatsModel(
      totalGreat:
          SeatDescriptionFinalAuditReportModel._readInt(json['total_great']) ??
          0,
      totalNeedsImprovement:
          SeatDescriptionFinalAuditReportModel._readInt(
            json['total_needs_improvement'],
          ) ??
          0,
      totalAlmostThere:
          SeatDescriptionFinalAuditReportModel._readInt(
            json['total_almost_there'],
          ) ??
          0,
      totalPercentage:
          SeatDescriptionFinalAuditReportModel._readInt(
            json['total_percentage'],
          ) ??
          0,
      confidenceLevel:
          SeatDescriptionFinalAuditReportModel._readInt(
            json['confidence_level'],
          ) ??
          0,
    );
  }
}

class SeatDescriptionFinalAuditTrendModel
    extends SeatDescriptionFinalAuditTrend {
  const SeatDescriptionFinalAuditTrendModel({
    required super.week,
    required super.year,
    required super.quarter,
    required super.great,
    required super.needsImprovement,
    required super.almostThere,
    required super.confidenceLevel,
    required super.profiles,
  });

  factory SeatDescriptionFinalAuditTrendModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    final profilesJson = json['profiles'];
    return SeatDescriptionFinalAuditTrendModel(
      week: SeatDescriptionFinalAuditReportModel._readInt(json['week']) ?? 0,
      year: SeatDescriptionFinalAuditReportModel._readInt(json['year']),
      quarter: SeatDescriptionFinalAuditReportModel._readString(
        json['quarter'],
      ),
      great: SeatDescriptionFinalAuditReportModel._readInt(json['great']) ?? 0,
      needsImprovement:
          SeatDescriptionFinalAuditReportModel._readInt(
            json['needs_improvement'],
          ) ??
          0,
      almostThere:
          SeatDescriptionFinalAuditReportModel._readInt(json['almost_there']) ??
          0,
      confidenceLevel:
          SeatDescriptionFinalAuditReportModel._readInt(
            json['confidence_level'],
          ) ??
          0,
      profiles: profilesJson is List
          ? profilesJson
                .whereType<Map>()
                .map(
                  (item) => SeatDescriptionFinalAuditProfileModel.fromApiJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <SeatDescriptionFinalAuditProfile>[],
    );
  }
}

class SeatDescriptionFinalAuditProfileModel
    extends SeatDescriptionFinalAuditProfile {
  const SeatDescriptionFinalAuditProfileModel({
    required super.uuid,
    required super.name,
    required super.userUuid,
    required super.email,
    required super.image,
    required super.onboarded,
  });

  factory SeatDescriptionFinalAuditProfileModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SeatDescriptionFinalAuditProfileModel(
      uuid:
          SeatDescriptionFinalAuditReportModel._readString(json['uuid']) ?? '',
      name:
          SeatDescriptionFinalAuditReportModel._readString(json['name']) ?? '',
      userUuid:
          SeatDescriptionFinalAuditReportModel._readString(json['user_uuid']) ??
          '',
      email:
          SeatDescriptionFinalAuditReportModel._readString(json['email']) ?? '',
      image: SeatDescriptionFinalAuditReportModel._readString(json['image']),
      onboarded:
          SeatDescriptionFinalAuditReportModel._readBool(json['onboarded']) ??
          false,
    );
  }
}
