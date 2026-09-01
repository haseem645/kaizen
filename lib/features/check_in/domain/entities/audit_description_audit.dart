enum AuditRating { great, almostThere, needsImprovement }

extension AuditRatingApiValue on AuditRating {
  String get apiValue => switch (this) {
    AuditRating.great => 'great',
    AuditRating.almostThere => 'almost_there',
    AuditRating.needsImprovement => 'needs_improvement',
  };
}

class AuditDescriptionAudit {
  const AuditDescriptionAudit({
    required this.uuid,
    required this.audit,
    required this.isGeneral,
    required this.isMirror,
    required this.auditMedia,
    required this.weightedScore,
  });

  final String uuid;
  final List<AuditRating> audit;
  final bool isGeneral;
  final bool isMirror;
  final List<AuditDescriptionMedia> auditMedia;
  final double weightedScore;
}

class AuditDescriptionMedia {
  const AuditDescriptionMedia({
    required this.uuid,
    required this.media,
    required this.type,
    required this.comment,
    required this.unreadCount,
  });

  final String uuid;
  final String media;
  final String type;
  final String? comment;
  final int unreadCount;
}
