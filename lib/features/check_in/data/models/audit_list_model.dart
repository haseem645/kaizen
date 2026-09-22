import '../../domain/entities/audit_list.dart';

class AuditListModel extends AuditList {
  const AuditListModel({
    required super.uuid,
    required super.categoryTitle,
    required super.weightPercent,
    required super.averageWeightedScore,
  });

  factory AuditListModel.fromApiJson(Map<String, dynamic> json) {
    return AuditListModel(
      uuid: _readString(json['uuid']) ?? '',
      categoryTitle: _readString(json['category_title']) ?? '',
      weightPercent: _readDouble(json['weight_percent']) ?? 0,
      averageWeightedScore: _readDouble(json['average_weighted_score']) ?? 0,
    );
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}
