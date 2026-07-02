import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class AuditSearchBar extends StatelessWidget {
  const AuditSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.75)),
            ),
            child: Row(
              children: [
                SvgPicture.asset("${AppStrings.imagePath}search.svg", width: 20, height: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    cursorHeight: 16,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    cursorColor: AppColors.textPrimary,
                    decoration: InputDecoration(
                      hintText: AppStrings.auditSearchHint,
                      hintStyle: TextStyle(
                        color: AppColors.grey1,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                //const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textPrimary, size: 26),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onFilterTap,
            child: const SizedBox(
              width: 47,
              height: 47,
              child: Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}
