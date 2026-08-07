import 'department.dart';

class SeatProfileDetail {
  const SeatProfileDetail({
    required this.id,
    required this.actualId,
    required this.title,
    required this.department,
    required this.paygradeUnit,
    required this.categories,
  });

  final String id;
  final String actualId;
  final String title;
  final Department? department;
  final String paygradeUnit;
  final List<SeatProfileCategory> categories;

  String get resolvedSeatId {
    final resolvedActualId = actualId.trim();
    if (resolvedActualId.isNotEmpty) {
      return resolvedActualId;
    }

    return id.trim();
  }
}

class SeatProfileCategory {
  const SeatProfileCategory({
    required this.id,
    required this.title,
    required this.weightPercent,
    required this.descriptions,
  });

  final String id;
  final String title;
  final double weightPercent;
  final List<SeatProfileDescription> descriptions;
}

class SeatProfileDescription {
  const SeatProfileDescription({
    required this.id,
    required this.actualId,
    required this.name,
    required this.auditSpecifics,
    required this.auditFactorType,
    required this.milestoneDays,
  });

  final String id;
  final String actualId;
  final String name;
  final String auditSpecifics;
  final String auditFactorType;
  final String milestoneDays;

  String get resolvedDescriptionId {
    final resolvedActualId = actualId.trim();
    if (resolvedActualId.isNotEmpty) {
      return resolvedActualId;
    }

    return id.trim();
  }
}
