import '../../domain/entities/seat_profile_detail.dart';

class SeatProfileDetailModel extends SeatProfileDetail {
  const SeatProfileDetailModel({
    required super.id,
    required super.title,
    required super.departmentName,
    required super.categories,
  });

  factory SeatProfileDetailModel.fromApiJson(Map<String, dynamic> json) {
    final department = json['department'] as Map<String, dynamic>?;
    final categories =
        (json['categories'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(SeatProfileCategoryModel.fromApiJson)
            .toList(growable: false) ??
        const <SeatProfileCategory>[];

    return SeatProfileDetailModel(
      id: json['uuid']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      departmentName: department?['name']?.toString().trim() ?? '',
      categories: categories,
    );
  }
}

class SeatProfileCategoryModel extends SeatProfileCategory {
  const SeatProfileCategoryModel({
    required super.id,
    required super.title,
    required super.weightPercent,
    required super.descriptions,
  });

  factory SeatProfileCategoryModel.fromApiJson(Map<String, dynamic> json) {
    final descriptions =
        (json['descriptions'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(SeatProfileDescriptionModel.fromApiJson)
            .toList(growable: false) ??
        const <SeatProfileDescription>[];

    return SeatProfileCategoryModel(
      id: json['uuid']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      weightPercent: _readDouble(json['weight_percent']) ?? 0,
      descriptions: descriptions,
    );
  }
}

class SeatProfileDescriptionModel extends SeatProfileDescription {
  const SeatProfileDescriptionModel({
    required super.id,
    required super.name,
    required super.auditSpecifics,
    required super.milestoneDays,
  });

  factory SeatProfileDescriptionModel.fromApiJson(Map<String, dynamic> json) {
    return SeatProfileDescriptionModel(
      id: json['uuid']?.toString().trim() ?? '',
      name: json['description']?.toString().trim() ?? '',
      auditSpecifics: json['job_specifics']?.toString().trim() ?? '',
      milestoneDays: json['milestone_day']?.toString().trim() ?? '',
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}
