import '../../domain/entities/seat_profile_page.dart';
import 'seat_profile_model.dart';

class SeatProfilePageModel extends SeatProfilePage {
  const SeatProfilePageModel({
    required super.items,
    required super.hasNextPage,
  });

  factory SeatProfilePageModel.fromApiJson(
    Map<String, dynamic> json, {
    required int pageSize,
  }) {
    final items = _extractItems(
      json,
    ).map(SeatProfileModel.fromApiJson).toList(growable: false);

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
            currentPage * pageSize < count) ||
        items.length >= pageSize;

    return SeatProfilePageModel(items: items, hasNextPage: hasNextPage);
  }

  static List<Map<String, dynamic>> _extractItems(Map<String, dynamic> json) {
    final candidates = [
      json['results'],
      json['data'],
      json['items'],
      json['jobs'],
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
