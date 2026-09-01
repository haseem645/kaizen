import '../models/audit_member_model.dart';
import '../models/audit_overview_model.dart';

class AuditLocalDataSource {
  Future<AuditOverviewModel> getAuditOverview() async {
    return const AuditOverviewModel(
      members: [
        AuditMemberModel.active(
          roleTitle: 'Cosmetic Dentist',
          name: 'Clara Bell',
          lastAuditLabel: 'Mar 27, 25',
          yearQuarter: '2025 - Q1',
          seatProfile: 'Cosmetic Dentist',
          overallScore: 2.7,
          confidenceLevel: 18,
          reviewerInitials: ['AB', 'JR', 'CL'],
          avatarLabel: 'CB',
        ),
        AuditMemberModel.active(
          roleTitle: 'Dental Surgeon',
          name: 'Mathew Walker',
          lastAuditLabel: 'Mar 27, 25',
          yearQuarter: '2024 - Q4',
          seatProfile: 'Dental Surgeon',
          overallScore: 2.7,
          confidenceLevel: 18,
          reviewerInitials: ['AS', 'RG', 'MW'],
          avatarLabel: 'MW',
        ),
        AuditMemberModel.active(
          roleTitle: 'Orthodontist',
          name: 'Chloe Adams',
          lastAuditLabel: 'Mar 27, 25',
          yearQuarter: '2023 - Q2',
          seatProfile: 'Orthodontist',
          overallScore: 2.7,
          confidenceLevel: 18,
          reviewerInitials: ['BM', 'RA', 'CA'],
          avatarLabel: 'CA',
        ),
        AuditMemberModel.deactivated(
          roleTitle: 'Periodontist',
          name: 'Ethan Brooks',
          lastAuditLabel: 'Feb 14, 25',
          yearQuarter: '2022 - Q3',
          seatProfile: 'Periodontist',
          overallScore: 2.2,
          confidenceLevel: 12,
          reviewerInitials: ['SK', 'ED', 'HB'],
          avatarLabel: 'EB',
        ),
        AuditMemberModel.deactivated(
          roleTitle: 'Dental Hygienist',
          name: 'Sophia Turner',
          lastAuditLabel: 'Jan 09, 25',
          yearQuarter: '2021 - Q4',
          seatProfile: 'Dental Hygienist',
          overallScore: 2.4,
          confidenceLevel: 15,
          reviewerInitials: ['AL', 'TR', 'ST'],
          avatarLabel: 'ST',
        ),
      ],
    );
  }
}
