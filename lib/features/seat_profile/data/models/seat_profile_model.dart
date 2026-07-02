import '../../domain/entities/seat_profile.dart';

class SeatProfileModel extends SeatProfile {
  const SeatProfileModel({
    required super.id,
    required super.name,
    required super.categoriesCount,
    required super.descriptionsCount,
    required super.hasPrimaryPaygrade,
    required super.hasAncillaryPaygrade,
  });

  factory SeatProfileModel.fromApiJson(Map<String, dynamic> json) {
    return SeatProfileModel(
      id: _readString(json['uuid']) ?? '',
      name: _readString(json['title']) ?? 'Unknown Seat Profile',
      categoriesCount: _readInt(json['total_categories']) ?? 0,
      descriptionsCount: _readInt(json['total_descriptions']) ?? 0,
      hasPrimaryPaygrade: _readBool(json['has_primary_pay_grades']) ?? false,
      hasAncillaryPaygrade:
          _readBool(json['has_ancillary_pay_grades']) ?? false,
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

  static bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
        return true;
      }

      if (normalized == 'false' || normalized == 'no' || normalized == '0') {
        return false;
      }
    }

    if (value is num) {
      return value != 0;
    }

    return null;
  }
}
