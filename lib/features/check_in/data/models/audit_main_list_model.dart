import '../../domain/entities/audit_main_list.dart';
import '../../domain/entities/audit_profile.dart';
import 'audit_profile_model.dart';

class AuditMainListModel extends AuditMainList {
  const AuditMainListModel({
    required super.count,
    required super.next,
    required super.previous,
    required super.current,
    required super.results,
  });

  factory AuditMainListModel.empty() {
    return const AuditMainListModel(
      count: 0,
      next: null,
      previous: null,
      current: 1,
      results: <AuditProfile>[],
    );
  }

  factory AuditMainListModel.fromApiJson({
    required Map<String, dynamic> json,
    required int year,
    required int quarter,
  }) {
    final resultsJson = json['results'];

    return AuditMainListModel(
      count: _readInt(json['count']) ?? 0,
      next: _readString(json['next']),
      previous: _readString(json['previous']),
      current: _readInt(json['current']) ?? 1,
      results: resultsJson is List
          ? resultsJson
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => AuditProfileModel.fromApiJson(
                    json: item,
                    year: year,
                    quarter: quarter,
                  ),
                )
                .toList(growable: false)
          : const <AuditProfile>[],
    );
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
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
