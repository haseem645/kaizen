import '../../domain/entities/audit_member.dart';
import '../../domain/entities/audit_member_status.dart';

class AuditMemberModel extends AuditMember {
  const AuditMemberModel({
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

  const AuditMemberModel.active({
    required String roleTitle,
    required String name,
    required String lastAuditLabel,
    required String yearQuarter,
    required String seatProfile,
    required double overallScore,
    required int confidenceLevel,
    required List<String> reviewerInitials,
    required String avatarLabel,
  }) : this(
         roleTitle: roleTitle,
         name: name,
         lastAuditLabel: lastAuditLabel,
         yearQuarter: yearQuarter,
         seatProfile: seatProfile,
         overallScore: overallScore,
         confidenceLevel: confidenceLevel,
         status: AuditMemberStatus.active,
         reviewerInitials: reviewerInitials,
         avatarLabel: avatarLabel,
       );

  const AuditMemberModel.deactivated({
    required String roleTitle,
    required String name,
    required String lastAuditLabel,
    required String yearQuarter,
    required String seatProfile,
    required double overallScore,
    required int confidenceLevel,
    required List<String> reviewerInitials,
    required String avatarLabel,
  }) : this(
         roleTitle: roleTitle,
         name: name,
         lastAuditLabel: lastAuditLabel,
         yearQuarter: yearQuarter,
         seatProfile: seatProfile,
         overallScore: overallScore,
         confidenceLevel: confidenceLevel,
         status: AuditMemberStatus.deactivated,
         reviewerInitials: reviewerInitials,
         avatarLabel: avatarLabel,
       );
}
