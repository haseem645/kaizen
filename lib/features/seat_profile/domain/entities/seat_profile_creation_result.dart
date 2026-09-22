import 'seat_profile_category_draft.dart';

class SeatProfileCreationResult {
  const SeatProfileCreationResult({
    required this.id,
    required this.actualId,
    required this.descriptionsCount,
    required this.categoriesCount,
    this.categories = const <SeatProfileCategoryDraft>[],
  });

  final String id;
  final String actualId;
  final int descriptionsCount;
  final int categoriesCount;
  final List<SeatProfileCategoryDraft> categories;

  String get jobContentId {
    final resolvedActualId = actualId.trim();
    if (resolvedActualId.isNotEmpty) {
      return resolvedActualId;
    }

    return id.trim();
  }
}
