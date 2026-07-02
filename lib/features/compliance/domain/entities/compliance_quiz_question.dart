class ComplianceQuizQuestion {
  const ComplianceQuizQuestion({
    required this.uuid,
    required this.question,
    required this.options,
    required this.imageUrl,
  });

  final String uuid;
  final String question;
  final List<ComplianceQuizOption> options;
  final String? imageUrl;
}

class ComplianceQuizOption {
  const ComplianceQuizOption({required this.uuid, required this.text});

  final String uuid;
  final String text;
}
