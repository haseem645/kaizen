class SeatProfile {
  const SeatProfile({
    required this.id,
    required this.name,
    required this.categoriesCount,
    required this.descriptionsCount,
    required this.hasPrimaryPaygrade,
    required this.hasAncillaryPaygrade,
  });

  final String id;
  final String name;
  final int categoriesCount;
  final int descriptionsCount;
  final bool hasPrimaryPaygrade;
  final bool hasAncillaryPaygrade;
}
