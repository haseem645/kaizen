import 'dart:convert';

class OrganizationConflictPayload {
  const OrganizationConflictPayload({required this.organizationId, required this.organizationType});

  final String organizationId;
  final String organizationType;

  static OrganizationConflictPayload? fromResponseBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      return _fromDecodedJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static OrganizationConflictPayload? _fromDecodedJson(dynamic decoded) {
    if (decoded is List) {
      for (final item in decoded) {
        final payload = _fromDecodedJson(item);
        if (payload != null) {
          return payload;
        }
      }

      return null;
    }

    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final directPayload = _fromMap(decoded);
    if (directPayload != null) {
      return directPayload;
    }

    final dataMap = _readMap(decoded['data']);
    final nestedCandidates = <Map<String, dynamic>>[];

    void addCandidate(Map<String, dynamic>? candidate) {
      if (candidate != null) {
        nestedCandidates.add(candidate);
      }
    }

    addCandidate(dataMap);
    addCandidate(_readMap(decoded['active_organization']));
    addCandidate(_readMap(decoded['activeOrganization']));
    addCandidate(_readMap(decoded['organization']));
    addCandidate(_readMap(decoded['organizationData']));
    addCandidate(_readMap(decoded['company']));

    if (dataMap != null) {
      addCandidate(_readMap(dataMap['active_organization']));
      addCandidate(_readMap(dataMap['activeOrganization']));
      addCandidate(_readMap(dataMap['organization']));
      addCandidate(_readMap(dataMap['organizationData']));
      addCandidate(_readMap(dataMap['company']));
    }

    for (final candidate in nestedCandidates) {
      final payload = _fromMap(candidate);
      if (payload != null) {
        return payload;
      }
    }

    return null;
  }

  static OrganizationConflictPayload? _fromMap(Map<String, dynamic> json) {
    final code = _readFirstString(json, <String>['code']);
    if (code != null && code != 'ORG_CONTEXT_MISMATCH') {
      return null;
    }

    final organizationId = _readFirstString(json, <String>['current_org_uuid', 'currentOrgUuid']);
    final organizationType = _readFirstString(json, <String>['current_org_type', 'currentOrgType']);

    if (organizationId == null || organizationType == null) {
      return null;
    }

    return OrganizationConflictPayload(
      organizationId: organizationId,
      organizationType: organizationType,
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return null;
  }

  static String? _readFirstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }

    return null;
  }
}
