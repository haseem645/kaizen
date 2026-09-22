class SeatProfileCategoryDraft {
  const SeatProfileCategoryDraft({
    this.uuid,
    required this.title,
    required this.weightPercent,
  });

  final String? uuid;
  final String title;
  final double weightPercent;
}
