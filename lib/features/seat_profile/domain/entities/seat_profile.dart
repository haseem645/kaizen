class SeatProfile {
  const SeatProfile({
    required this.id,
    required this.actualId,
    required this.name,
    required this.categoriesCount,
    required this.descriptionsCount,
    required this.hasPrimaryPaygrade,
    required this.hasAncillaryPaygrade,
  });

  final String id;
  final String actualId;
  final String name;
  final int categoriesCount;
  final int descriptionsCount;
  final bool hasPrimaryPaygrade;
  final bool hasAncillaryPaygrade;

  String get resolvedDetailId {
    final resolvedActualId = actualId.trim();
    if (resolvedActualId.isNotEmpty) {
      return resolvedActualId;
    }

    return id.trim();
  }
}
