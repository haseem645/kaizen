class AuditList {
  const AuditList({
    required this.uuid,
    required this.categoryTitle,
    required this.weightPercent,
    required this.averageWeightedScore,
  });

  final String uuid;
  final String categoryTitle;
  final double weightPercent;
  final double averageWeightedScore;
}
