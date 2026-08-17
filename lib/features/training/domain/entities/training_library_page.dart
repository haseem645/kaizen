import 'training_library_module.dart';

class TrainingLibraryPage {
  const TrainingLibraryPage({required this.items, required this.hasNextPage});

  final List<TrainingLibraryModule> items;
  final bool hasNextPage;
}
