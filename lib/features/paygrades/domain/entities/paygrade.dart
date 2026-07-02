class Paygrade {
  const Paygrade({
    required this.id,
    required this.seatName,
    required this.department,
    required this.hasPrimaryPaygrade,
    required this.hasAncillaryPaygrade,
  });

  final String id;
  final String seatName;
  final String department;
  final bool hasPrimaryPaygrade;
  final bool hasAncillaryPaygrade;
}
