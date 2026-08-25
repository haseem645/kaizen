import 'package:flutter/material.dart';

import '../../domain/entities/audit_member.dart';
import 'check_in_member_card.dart';

class PerformanceSnapshotCard extends StatelessWidget {
  const PerformanceSnapshotCard({
    super.key,
    required this.member,
    this.onCheckInTap,
    this.actionLabel = 'View',
  });

  final AuditMember member;
  final VoidCallback? onCheckInTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return CheckInMemberCard(
      member: member,
      onCheckInTap: onCheckInTap,
      actionLabel: actionLabel,
      showLastCheckIn: false,
    );
  }
}
