import 'package:flutter/material.dart';

import '../../domain/entities/audit_member.dart';
import 'audit_member_card.dart';

class PerformanceSnapshotCard extends StatelessWidget {
  const PerformanceSnapshotCard({
    super.key,
    required this.member,
    this.onAuditTap,
    this.actionLabel = 'View',
  });

  final AuditMember member;
  final VoidCallback? onAuditTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return AuditMemberCard(
      member: member,
      onAuditTap: onAuditTap,
      actionLabel: actionLabel,
      showLastCheckIn: false,
    );
  }
}
