import '../../domain/entities/single_audit_report_category_details.dart';

class SingleAuditReportCategoryDetailsModel
    extends SingleAuditReportCategoryDetails {
  const SingleAuditReportCategoryDetailsModel({
    required super.uuid,
    required super.description,
    required super.confidenceLevel,
    required super.jobDescriptionUuid,
    required super.stats,
  });

  factory SingleAuditReportCategoryDetailsModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    final statsJson = _readMap(json['stats']);

    return SingleAuditReportCategoryDetailsModel(
      uuid: _readString(json['uuid']) ?? '',
      description: _readString(json['description']) ?? '',
      confidenceLevel: _readInt(json['confidence_level']) ?? 0,
      jobDescriptionUuid: _readString(json['job_description_uuid']) ?? '',
      stats: SingleAuditReportCategoryStatsModel.fromApiJson(
        statsJson ?? const <String, dynamic>{},
      ),
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
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
}

class SingleAuditReportCategoryStatsModel
    extends SingleAuditReportCategoryStats {
  const SingleAuditReportCategoryStatsModel({
    required super.totalGreat,
    required super.totalNeedsImprovement,
    required super.totalAlmostThere,
    required super.totalPercentage,
  });

  factory SingleAuditReportCategoryStatsModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return SingleAuditReportCategoryStatsModel(
      totalGreat: _readInt(json['total_great']) ?? 0,
      totalNeedsImprovement: _readInt(json['total_needs_improvement']) ?? 0,
      totalAlmostThere: _readInt(json['total_almost_there']) ?? 0,
      totalPercentage: _readInt(json['total_percentage']) ?? 0,
    );
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
}
