class SharedLmsContent {
  const SharedLmsContent({
    required this.title,
    required this.categoryTitle,
    required this.description,
    required this.lessons,
  });

  final String title;
  final String categoryTitle;
  final String description;
  final List<SharedLmsLesson> lessons;
}

class SharedLmsLesson {
  const SharedLmsLesson({
    required this.publicId,
    required this.title,
    required this.thumbnailUrl,
  });

  final String publicId;
  final String title;
  final String? thumbnailUrl;
}
