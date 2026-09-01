import '../../domain/entities/training_library_page.dart';
import 'training_library_module_model.dart';

class TrainingLibraryPageModel extends TrainingLibraryPage {
  const TrainingLibraryPageModel({
    required super.items,
    required super.hasNextPage,
  });

  factory TrainingLibraryPageModel.fromApiJson(
    Map<String, dynamic> json, {
    required int pageSize,
  }) {
    final items = _extractItems(
      json,
    ).map(TrainingLibraryModuleModel.fromApiJson).toList(growable: false);

    final next = json['next'];
    final count = _readInt(json['count']);
    final currentPage = _readInt(json['current']) ?? _readInt(json['page']);
    final totalPages = _readInt(json['total_pages']);

    final hasNextPage =
        next != null ||
        (currentPage != null &&
            totalPages != null &&
            currentPage < totalPages) ||
        (count != null &&
            currentPage != null &&
            currentPage * pageSize < count);

    return TrainingLibraryPageModel(items: items, hasNextPage: hasNextPage);
  }

  factory TrainingLibraryPageModel.fromLegacyList(
    List<Map<String, dynamic>> items, {
    required int pageSize,
  }) {
    final parsedItems = items
        .map(TrainingLibraryModuleModel.fromApiJson)
        .toList(growable: false);
    return TrainingLibraryPageModel(items: parsedItems, hasNextPage: false);
  }

  static List<Map<String, dynamic>> _extractItems(Map<String, dynamic> json) {
    final candidates = <dynamic>[
      json['results'],
      json['data'],
      json['items'],
      json['list'],
    ];

    for (final candidate in candidates) {
      if (candidate is List) {
        return candidate.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }
    }

    return const <Map<String, dynamic>>[];
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }
}
