import 'audit_profile.dart';

class AuditMainList {
  const AuditMainList({
    required this.count,
    required this.next,
    required this.previous,
    required this.current,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final int current;
  final List<AuditProfile> results;
}
