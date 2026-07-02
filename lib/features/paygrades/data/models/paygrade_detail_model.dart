import '../../domain/entities/paygrade_detail.dart';

class PaygradeDetailModel extends PaygradeDetail {
  const PaygradeDetailModel({
    required super.id,
    required super.title,
    required super.paygradeUnit,
    required super.department,
    required super.payGrades,
  });

  factory PaygradeDetailModel.fromApiJson(Map<String, dynamic> json) {
    final payGrades = (json['pay_grades'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PaygradeEntryModel.fromApiJson)
        .toList(growable: false);

    return PaygradeDetailModel(
      id: _readString(json['uuid']) ?? '',
      title: _readString(json['title']) ?? 'Unknown Seat',
      paygradeUnit: _readString(json['paygrade_unit']) ?? '',
      department: _readString(json['department']) ?? '',
      payGrades: payGrades,
    );
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }
}

class PaygradeEntryModel extends PaygradeEntry {
  const PaygradeEntryModel({
    required super.id,
    required super.type,
    required super.title,
    required super.payRate,
    required super.level,
    required super.description,
    required super.promotionRequirement,
  });

  factory PaygradeEntryModel.fromApiJson(Map<String, dynamic> json) {
    return PaygradeEntryModel(
      id: _readString(json['uuid']) ?? '',
      type: _readString(json['type']) ?? '',
      title: _readString(json['title']) ?? '',
      payRate: _readString(json['pay_rate']) ?? '',
      level: _readInt(json['level']) ?? 0,
      description: _readString(json['description']) ?? '',
      promotionRequirement: _readString(json['promotion_requirement']) ?? '',
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
}
