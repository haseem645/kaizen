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
  });

  final AuditMemberStatus selectedStatus;
  final ValueChanged<AuditMemberStatus> onStatusSelected;
  final String activeTitle;
  final String deactivatedTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatusChip(
          title: activeTitle,
          isSelected: selectedStatus == AuditMemberStatus.active,
          onTap: () => onStatusSelected(AuditMemberStatus.active),
        ),
        const SizedBox(width: 20),
        _StatusChip(
          title: deactivatedTitle,
          isSelected: selectedStatus == AuditMemberStatus.deactivated,
          onTap: () => onStatusSelected(AuditMemberStatus.deactivated),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.title, required this.isSelected, required this.onTap});

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryColor
                : AppColors.fieldBorder.withValues(alpha: 0.7),
          ),
        ),
        child: AppTextView.body2(title, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }
}
