class AuditEvaluationChart {
  const AuditEvaluationChart({
    required this.uuid,
    required this.quarter,
    required this.year,
    required this.label,
    required this.overallScore,
    required this.confidenceLevel,
    required this.weeklyTrends,
  });

  final String uuid;
  final String quarter;
  final int year;
  final String label;
  final double overallScore;
  final double confidenceLevel;
  final List<AuditWeeklyTrend> weeklyTrends;
}

class AuditWeeklyTrend {
  const AuditWeeklyTrend({
    required this.week,
    required this.great,
    required this.almostThere,
    required this.needsImprovement,
  });

  final int week;
  final int great;
  final int almostThere;
  final int needsImprovement;

  int get totalRatings => great + almostThere + needsImprovement;
}
