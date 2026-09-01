class TrainingLibraryDepartment {
  const TrainingLibraryDepartment({
    required this.id,
    required this.name,
    this.colorHex,
  });

  final String id;
  final String name;
  final String? colorHex;
}

class TrainingLibraryCategory {
  const TrainingLibraryCategory({required this.id, required this.title});

  final String id;
  final String title;
}

class TrainingLibrarySeat {
  const TrainingLibrarySeat({required this.id, required this.title});

  final String id;
  final String title;
}

class TrainingLibraryLesson {
  const TrainingLibraryLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailLink,
    required this.isPubliclyAvailable,
  });

  final String id;
  final String title;
  final String description;
  final String? thumbnailLink;
  final bool isPubliclyAvailable;

  bool get hasDescription => description.trim().isNotEmpty;
}

class TrainingLibraryModule {
  const TrainingLibraryModule({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.totalDuration,
    required this.seat,
    required this.lessons,
    required this.thumbnailLink,
    required this.category,
  });

  final String id;
  final String title;
  final String description;
  final TrainingLibraryDepartment department;
  final int totalDuration;
  final TrainingLibrarySeat seat;
  final List<TrainingLibraryLesson> lessons;
  final String? thumbnailLink;
  final TrainingLibraryCategory category;

  int get lessonsCount => lessons.length;
}
