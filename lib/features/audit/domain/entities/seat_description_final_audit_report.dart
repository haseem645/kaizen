import 'seat_description_training_route.dart';

class SeatDescriptionFinalAuditReport {
  const SeatDescriptionFinalAuditReport({
    required this.uuid,
    required this.trainingRoute,
    required this.auditFactorType,
    required this.description,
    required this.jobSpecifics,
    required this.job,
    required this.isOpenSeat,
    required this.summaryData,
    required this.checkInComments,
  });

  final String uuid;
  final SeatDescriptionTrainingRoute trainingRoute;
  final String auditFactorType;
  final String description;
  final String jobSpecifics;
  final SeatDescriptionFinalAuditJob job;
  final bool isOpenSeat;
  final SeatDescriptionFinalAuditSummary summaryData;
  final List<String> checkInComments;
}

class SeatDescriptionFinalAuditJob {
  const SeatDescriptionFinalAuditJob({required this.uuid, required this.title});

  final String uuid;
  final String title;
}

class SeatDescriptionFinalAuditSummary {
  const SeatDescriptionFinalAuditSummary({
    required this.stats,
    required this.trends,
  });

  final SeatDescriptionFinalAuditStats stats;
  final List<SeatDescriptionFinalAuditTrend> trends;
}

class SeatDescriptionFinalAuditStats {
  const SeatDescriptionFinalAuditStats({
    required this.totalGreat,
    required this.totalNeedsImprovement,
    required this.totalAlmostThere,
    required this.totalPercentage,
    required this.confidenceLevel,
  });

  final int totalGreat;
  final int totalNeedsImprovement;
  final int totalAlmostThere;
  final int totalPercentage;
  final int confidenceLevel;
}

class SeatDescriptionFinalAuditTrend {
  const SeatDescriptionFinalAuditTrend({
    required this.week,
    required this.year,
    required this.quarter,
    required this.great,
    required this.needsImprovement,
    required this.almostThere,
    required this.confidenceLevel,
    required this.profiles,
  });

  final int week;
  final int? year;
  final String? quarter;
  final int great;
  final int needsImprovement;
  final int almostThere;
  final int confidenceLevel;
  final List<SeatDescriptionFinalAuditProfile> profiles;
}

class SeatDescriptionFinalAuditProfile {
  const SeatDescriptionFinalAuditProfile({
    required this.uuid,
    required this.name,
    required this.userUuid,
    required this.email,
    required this.image,
    required this.onboarded,
  });

  final String uuid;
  final String name;
  final String userUuid;
  final String email;
  final String? image;
  final bool onboarded;
}
