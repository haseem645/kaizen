class SeatDescriptionAuditReportComments {
  const SeatDescriptionAuditReportComments({required this.items});

  final List<SeatDescriptionAuditReportComment> items;
}

class SeatDescriptionAuditReportComment {
  const SeatDescriptionAuditReportComment({
    required this.uuid,
    required this.comment,
    required this.media,
    required this.thumbnailUrl,
    required this.type,
    required this.authorName,
    required this.createdAt,
  });

  final String uuid;
  final String comment;
  final String? media;
  final String? thumbnailUrl;
  final String? type;
  final String? authorName;
  final String? createdAt;
}
