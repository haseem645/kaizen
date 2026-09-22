class SeatDescriptionTrainingRoute {
  const SeatDescriptionTrainingRoute({
    required this.job,
    required this.category,
    required this.description,
    this.initialModuleId,
  });

  final String job;
  final String category;
  final String description;
  final String? initialModuleId;

  bool get hasDescription => description.trim().isNotEmpty;
}
