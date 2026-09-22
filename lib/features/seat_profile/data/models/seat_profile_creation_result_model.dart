import '../../domain/entities/seat_profile_category_draft.dart';
import '../../domain/entities/seat_profile_creation_result.dart';

class SeatProfileCreationResultModel extends SeatProfileCreationResult {
  const SeatProfileCreationResultModel({
    required super.id,
    required super.actualId,
    required super.descriptionsCount,
    required super.categoriesCount,
    required super.categories,
  });

  factory SeatProfileCreationResultModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    final id =
        _readString(json['uuid']) ?? _readString(json['actual_id']) ?? '';
    final actualId = _readString(json['actual_id']) ?? id;
    final categories =
        (json['categories'] as List?)?.whereType<Map<String, dynamic>>().toList(
          growable: false,
        ) ??
        const <Map<String, dynamic>>[];

    final categoriesCount =
        _readInt(json['total_categories']) ?? categories.length;
    final descriptionsCount =
        _readInt(json['total_descriptions']) ??
        categories.fold<int>(0, (count, category) {
          final descriptions = category['descriptions'];
          if (descriptions is! List) {
            return count;
          }

          return count + descriptions.length;
        });

    return SeatProfileCreationResultModel(
      id: id,
      actualId: actualId,
      descriptionsCount: descriptionsCount,
      categoriesCount: categoriesCount,
      categories: categories
          .map(_SeatProfileCategoryDraftModel.fromApiJson)
          .toList(growable: false),
    );
  }
}

class _SeatProfileCategoryDraftModel extends SeatProfileCategoryDraft {
  const _SeatProfileCategoryDraftModel({
    required super.uuid,
    required super.title,
    required super.weightPercent,
  });

  factory _SeatProfileCategoryDraftModel.fromApiJson(
    Map<String, dynamic> json,
  ) {
    return _SeatProfileCategoryDraftModel(
      uuid: _readString(json['uuid']),
      title: _readString(json['title']) ?? _readString(json['name']) ?? '',
      weightPercent: _readDouble(json['weight_percent']) ?? 0,
    );
  }
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

double? _readDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}
