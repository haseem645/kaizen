import '../../domain/entities/audit_member_status.dart';
import '../../domain/entities/audit_profile.dart';
import '../../domain/entities/audit_member.dart';

class AuditProfileModel extends AuditProfile {
  const AuditProfileModel({
    required super.uuid,
    required super.profileJob,
    required super.profileUuid,
    required super.email,
    required super.imageUrl,
    required super.isFavorite,
    required super.lastAuditDates,
    required super.roleTitle,
    required super.name,
    required super.lastAuditLabel,
    required super.yearQuarter,
    required super.seatProfile,
    required super.overallScore,
    required super.confidenceLevel,
    required super.status,
    required super.reviewerInitials,
    required super.avatarLabel,
    required super.profiles,
    super.avatarImageUrl,
  });

  factory AuditProfileModel.fromApiJson({
    required Map<String, dynamic> json,
    required int year,
    required int quarter,
  }) {
    final profile = _readMap(json['profile']);
    final profiles = _readProfiles(json['profiles']);
    final firstProfile = profiles.isEmpty ? null : profiles.first;
    final job = _readMap(json['job']);
    final name = _readString(profile?['name']) ?? firstProfile?.name ?? '';
    final email = _readString(profile?['email']) ?? firstProfile?.email ?? '';
    final imageUrl = _readString(profile?['image']) ?? firstProfile?.imageUrl;
    final jobTitle = _readString(job?['title']) ?? '';
    final onboarded =
        _readBool(profile?['onboarded']) ?? firstProfile?.onboarded ?? true;

    return AuditProfileModel(
      uuid: _readString(json['uuid']) ?? '',
      profileJob: _readString(json['profile_job']) ?? '',
      profileUuid: _readString(profile?['uuid']) ?? firstProfile?.uuid ?? '',
      email: email,
      imageUrl: imageUrl,
      isFavorite: _readBool(json['is_favorite']) ?? false,
      lastAuditDates: _readNullableStringList(json['last_audit_dates']),
      roleTitle: jobTitle,
      name: name,
      lastAuditLabel: _readString(json['last_audit_date']) ?? 'N/A',
      yearQuarter: '$year - Q$quarter',
      seatProfile: jobTitle,
      overallScore: _readDouble(json['overall_score']) ?? 0,
      confidenceLevel: (_readDouble(json['confidence_level']) ?? 0).round(),
      status: onboarded
          ? AuditMemberStatus.active
          : AuditMemberStatus.deactivated,
      reviewerInitials: _readReviewerInitials(json['profiles']),
      avatarLabel: _avatarLabel(name),
      profiles: profiles,
      avatarImageUrl: imageUrl,
    );
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }

    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }

  static List<String?> _readNullableStringList(dynamic value) {
    if (value is! List) {
      return const <String?>[];
    }

    return value.map((item) => _readString(item)).toList(growable: false);
  }

  static List<String> _readReviewerInitials(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map(_readMap)
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final name =
              _readString(item['name']) ?? _readString(item['email']) ?? '';
          return _avatarLabel(name);
        })
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<AuditMemberProfile> _readProfiles(dynamic value) {
    if (value is! List) {
      return const <AuditMemberProfile>[];
    }

    return value
        .map(_readMap)
        .whereType<Map<String, dynamic>>()
        .map(AuditMemberProfileModel.fromApiJson)
        .toList(growable: false);
  }

  static String _avatarLabel(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) {
      return '';
    }

    if (words.length == 1) {
      return String.fromCharCodes(words.first.runes.take(2)).toUpperCase();
    }

    return '${String.fromCharCode(words.first.runes.first)}'
            '${String.fromCharCode(words.last.runes.first)}'
        .toUpperCase();
  }
}

class AuditMemberProfileModel extends AuditMemberProfile {
  const AuditMemberProfileModel({
    required super.uuid,
    required super.name,
    required super.email,
    required super.imageUrl,
    required super.onboarded,
  });

  factory AuditMemberProfileModel.fromApiJson(Map<String, dynamic> json) {
    return AuditMemberProfileModel(
      uuid: _readString(json['uuid']) ?? '',
      name: _readString(json['name']) ?? '',
      email: _readString(json['email']) ?? '',
      imageUrl: _readString(json['image']),
      onboarded: _readBool(json['onboarded']) ?? true,
    );
  }

  static String? _readString(dynamic value) {
    final resolved = value?.toString().trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }

    return null;
  }
}
