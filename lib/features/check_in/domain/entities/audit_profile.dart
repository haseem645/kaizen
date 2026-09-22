import 'audit_member.dart';

class AuditProfile extends AuditMember {
  const AuditProfile({
    required this.uuid,
    required this.profileJob,
    required this.profileUuid,
    required this.email,
    required this.imageUrl,
    required this.isFavorite,
    required this.lastAuditDates,
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
    super.profiles,
    super.avatarImageUrl,
  });

  final String uuid;
  final String profileJob;
  final String profileUuid;
  final String email;
  final String? imageUrl;
  final bool isFavorite;
  final List<String?> lastAuditDates;
}
