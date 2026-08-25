class SingleAuditReportCategoryDetails {
  const SingleAuditReportCategoryDetails({
    required this.uuid,
    required this.description,
    required this.confidenceLevel,
    required this.jobDescriptionUuid,
    required this.stats,
  });

  final String uuid;
  final String description;
  final int confidenceLevel;
  final String jobDescriptionUuid;
  final SingleAuditReportCategoryStats stats;
}

class SingleAuditReportCategoryStats {
  const SingleAuditReportCategoryStats({
    required this.totalGreat,
    required this.totalNeedsImprovement,
    required this.totalAlmostThere,
    required this.totalPercentage,
  });

  final int totalGreat;
  final int totalNeedsImprovement;
  final int totalAlmostThere;
  final int totalPercentage;
}
