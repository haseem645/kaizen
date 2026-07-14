class SeatDescriptionTrainingRoute {
  const SeatDescriptionTrainingRoute({
    required this.job,
    required this.category,
    required this.description,
  });

  final String job;
  final String category;
  final String description;

  bool get hasDescription => description.trim().isNotEmpty;
}
