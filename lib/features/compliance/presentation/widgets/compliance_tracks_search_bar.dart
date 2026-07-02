import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class ComplianceTracksSearchBar extends StatelessWidget {
  const ComplianceTracksSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(color: AppColors.textPrimary),
                    cursorHeight: 16,
                    cursorColor: AppColors.textPrimary,
                    decoration: const InputDecoration(
                      hintText: AppStrings.complianceSearchHint,
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                //const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
