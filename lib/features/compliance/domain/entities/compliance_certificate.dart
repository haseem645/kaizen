class ComplianceCertificate {
  const ComplianceCertificate({
    required this.percentage,
    required this.certificate,
    required this.trackName,
  });

  final int percentage;
  final String certificate;
  final String trackName;

  String get displayPercentage => '$percentage%';
}
