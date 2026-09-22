import '../../domain/entities/audit_evaluation_chart.dart';

class AuditEvaluationChartModel extends AuditEvaluationChart {
  const AuditEvaluationChartModel({
    required super.uuid,
    required super.quarter,
    required super.year,
    required super.label,
    required super.overallScore,
    required super.confidenceLevel,
    required super.weeklyTrends,
  });

  factory AuditEvaluationChartModel.fromApiJson(Map<String, dynamic> json) {
    final weeklyTrendsJson = json['weekly_trends'];

    return AuditEvaluationChartModel(
      uuid: _readString(json['uuid']) ?? '',
      quarter: _readString(json['quarter']) ?? '',
      year: _readInt(json['year']) ?? 0,
      label: _readString(json['label']) ?? '',
      overallScore: _readDouble(json['overall_score']) ?? 0,
      confidenceLevel: _readDouble(json['confidence_level']) ?? 0,
      weeklyTrends: weeklyTrendsJson is List
          ? weeklyTrendsJson
                .whereType<Map<String, dynamic>>()
                .map(AuditWeeklyTrendModel.fromApiJson)
                .toList(growable: false)
          : const <AuditWeeklyTrend>[],
    );
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

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}

class AuditWeeklyTrendModel extends AuditWeeklyTrend {
  const AuditWeeklyTrendModel({
    required super.week,
    required super.great,
    required super.almostThere,
    required super.needsImprovement,
  });

  factory AuditWeeklyTrendModel.fromApiJson(Map<String, dynamic> json) {
    return AuditWeeklyTrendModel(
      week: _readInt(json['week']) ?? 0,
      great: _readInt(json['great']) ?? 0,
      almostThere: _readInt(json['almost_there']) ?? 0,
      needsImprovement: _readInt(json['needs_improvement']) ?? 0,
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
