import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/compliance_tab_type.dart';

class ComplianceTabSwitcher extends StatelessWidget {
  const ComplianceTabSwitcher({super.key, required this.selectedTab, required this.onTabSelected});

  final ComplianceTabType selectedTab;
  final ValueChanged<ComplianceTabType> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: AppStrings.complianceLearningTrack,
              isSelected: selectedTab == ComplianceTabType.learningTrack,
              onTap: () => onTabSelected(ComplianceTabType.learningTrack),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: AppStrings.complianceDocument,
              isSelected: selectedTab == ComplianceTabType.document,
              onTap: () => onTabSelected(ComplianceTabType.document),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.title, required this.isSelected, required this.onTap});

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AppTextView.body2(
          title,
          textAlign: TextAlign.center,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
