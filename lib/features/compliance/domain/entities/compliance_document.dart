class ComplianceDocument {
  const ComplianceDocument({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.updatedAt,
    this.rawStatus,
    this.hasExpiry = false,
    this.hasLatestDocument = false,
    this.latestDocumentUuid,
    this.latestDocumentName,
    this.latestDocumentExpiryDate,
    this.latestDocumentCreatedAt,
    this.latestDocumentUrl,
    this.latestDocumentThumbnailUrl,
    this.latestDocumentStatus,
    this.latestDocumentReason,
    this.seatProfiles = const <String>[],
  });

  final String id;
  final String title;
  final String category;
  final String status;
  final String updatedAt;
  final String? rawStatus;
  final bool hasExpiry;
  final bool hasLatestDocument;
  final String? latestDocumentUuid;
  final String? latestDocumentName;
  final String? latestDocumentExpiryDate;
  final String? latestDocumentCreatedAt;
  final String? latestDocumentUrl;
  final String? latestDocumentThumbnailUrl;
  final String? latestDocumentStatus;
  final String? latestDocumentReason;
  final List<String> seatProfiles;
}
