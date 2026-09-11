import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'app_text_view.dart';

class AppDepartmentFilterItem {
  const AppDepartmentFilterItem({required this.id, required this.name});

  final String id;
  final String name;
}

class AppDepartmentFilterStrip extends StatelessWidget {
  const AppDepartmentFilterStrip({
    super.key,
    required this.items,
    required this.selectedDepartmentId,
    required this.onSelected,
    required this.onSeeAll,
  });

  final List<AppDepartmentFilterItem> items;
  final String selectedDepartmentId;
  final ValueChanged<String> onSelected;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final visibleItems = <AppDepartmentFilterItem>[
      ...items.where((item) => item.id == 'all'),
      ...items.where((item) => item.id != 'all').take(3),
    ];

    return SizedBox(
      height: (MediaQuery.textScalerOf(context).scale(12) * 1.2 + 22).clamp(38.0, double.infinity),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleItems.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == visibleItems.length) {
            return _DepartmentFilterTab(
              title: AppStrings.seeAllAction,
              isHighlighted: true,
              fontSize: 10,
              trailingIcon: Icons.north_east,
              onTap: onSeeAll,
            );
          }

          final item = visibleItems[index];
          return _DepartmentFilterTab(
            title: item.name,
            isHighlighted: selectedDepartmentId == item.id,
            onTap: () => onSelected(item.id),
          );
        },
      ),
    );
  }
}

class _DepartmentFilterTab extends StatelessWidget {
  const _DepartmentFilterTab({
    required this.title,
    required this.isHighlighted,
    required this.onTap,
    this.fontSize = 12,
    this.trailingIcon,
  });

  final String title;
  final bool isHighlighted;
  final VoidCallback onTap;
  final double fontSize;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 54, maxWidth: 198),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHighlighted ? AppColors.secondaryColor : AppColors.grey1),
        ),
        child: Center(
          widthFactor: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AppTextView.body(
                  title,
                  color: isHighlighted ? AppColors.textPrimary : AppColors.grey1,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  trailingIcon,
                  size: 14,
                  color: isHighlighted ? AppColors.textPrimary : AppColors.grey1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
