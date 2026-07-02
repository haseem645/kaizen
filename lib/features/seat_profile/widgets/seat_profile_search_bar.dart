import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

class SeatProfileSearchBar extends StatelessWidget {
  const SeatProfileSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  "${AppStrings.imagePath}search.svg",
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    cursorHeight: 16,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    cursorColor: AppColors.textPrimary,
                    decoration: InputDecoration(
                      hintText: hintText ?? AppStrings.auditSearchHint,
                      hintStyle: TextStyle(
                        color: AppColors.grey1,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                //const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
              ],
            ),
          ),
        ),
        // const SizedBox(width: 12),
        // Container(
        //   width: 48,
        //   height: 48,
        //   decoration: BoxDecoration(
        //     color: AppColors.secondaryColor,
        //     borderRadius: BorderRadius.circular(6),
        //   ),
        //   child: Material(
        //     color: Colors.transparent,
        //     child: InkWell(
        //       borderRadius: BorderRadius.circular(6),
        //       onTap: onFilterTap,
        //       child: const Icon(
        //         Icons.tune_rounded,
        //         color: AppColors.textPrimary,
        //         size: 26,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}
