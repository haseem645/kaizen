class SeatProfileDetail {
  const SeatProfileDetail({
    required this.id,
    required this.title,
    required this.departmentName,
    required this.categories,
  });

  final String id;
  final String title;
  final String departmentName;
  final List<SeatProfileCategory> categories;
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
    required this.name,
    required this.auditSpecifics,
    required this.milestoneDays,
  });

  final String id;
  final String name;
  final String auditSpecifics;
  final String milestoneDays;
}
