import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/audit_member_status.dart';

class AuditStatusSwitcher extends StatelessWidget {
  const AuditStatusSwitcher({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
    this.activeTitle = AppStrings.auditActive,
    this.deactivatedTitle = AppStrings.auditDeactivated,
    this.showDeactivated = true,
  });

  final AuditMemberStatus selectedStatus;
  final ValueChanged<AuditMemberStatus> onStatusSelected;
  final String activeTitle;
  final String deactivatedTitle;
  final bool showDeactivated;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatusChip(
              title: activeTitle,
              isSelected: selectedStatus == AuditMemberStatus.active,
              onTap: () => onStatusSelected(AuditMemberStatus.active),
            ),
          ),
          if (showDeactivated) ...[
            const SizedBox(width: 6),
            Expanded(
              child: _StatusChip(
                title: deactivatedTitle,
                isSelected: selectedStatus == AuditMemberStatus.deactivated,
                onTap: () => onStatusSelected(AuditMemberStatus.deactivated),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AppTextView.body3(
          title,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
