import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/fast_circular_progress.dart';

class CheckInSearchBar extends StatelessWidget {
  const CheckInSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilterTap,
    this.onClearTap,
    this.isSearchLoading = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClearTap;
  final bool isSearchLoading;

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
              border: Border.all(
                color: AppColors.fieldBorder.withValues(alpha: 0.75),
              ),
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
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final hasQuery = value.text.trim().isNotEmpty;

                      return Row(
                        children: [
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
                          if (hasQuery)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: isSearchLoading
                                  ? Padding(
                                      padding: EdgeInsets.all(3),
                                      child: FastCircularProgressIndicator(
                                        width: 18,
                                        height: 18,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed:
                                          onClearTap ??
                                          () {
                                            controller.clear();
                                            onChanged('');
                                          },
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 24,
                                            height: 24,
                                          ),
                                      splashRadius: 16,
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                            ),
                        ],
                      );
                    },
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
              child: Icon(
                Icons.tune_rounded,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
