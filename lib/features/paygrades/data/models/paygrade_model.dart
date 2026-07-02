import '../../domain/entities/paygrade.dart';

class PaygradeModel extends Paygrade {
  const PaygradeModel({
    required super.id,
    required super.seatName,
    required super.department,
    required super.hasPrimaryPaygrade,
    required super.hasAncillaryPaygrade,
  });

  factory PaygradeModel.fromApiJson(Map<String, dynamic> json) {
    return PaygradeModel(
      id: _readString(json['uuid']) ?? '',
      seatName: _readString(json['title']) ?? 'Unknown Seat',
      department: _readString(json['department']) ?? 'Unknown Department',
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
