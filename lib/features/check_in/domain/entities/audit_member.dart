import 'audit_member_status.dart';

class AuditMember {
  const AuditMember({
    required this.roleTitle,
    required this.name,
    required this.lastAuditLabel,
    required this.yearQuarter,
    required this.seatProfile,
    required this.overallScore,
    required this.confidenceLevel,
    required this.status,
    required this.reviewerInitials,
    required this.avatarLabel,
    this.profiles = const <AuditMemberProfile>[],
    this.avatarImageUrl,
  });

  final String roleTitle;
  final String name;
  final String lastAuditLabel;
  final String yearQuarter;
  final String seatProfile;
  final double overallScore;
  final int confidenceLevel;
  final AuditMemberStatus status;
  final List<String> reviewerInitials;
  final String avatarLabel;
  final List<AuditMemberProfile> profiles;
  final String? avatarImageUrl;
}

class AuditMemberProfile {
  const AuditMemberProfile({
    required this.uuid,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.onboarded,
  });

  final String uuid;
  final String name;
  final String email;
  final String? imageUrl;
  final bool onboarded;
}
