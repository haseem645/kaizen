import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../providers/seat_profile_controller.dart';

class SeatProfileFilterSheet extends StatefulWidget {
  const SeatProfileFilterSheet({super.key, required this.selectedFilter});

  final SeatProfileFilter selectedFilter;

  @override
  State<SeatProfileFilterSheet> createState() => _SeatProfileFilterSheetState();
}

class _SeatProfileFilterSheetState extends State<SeatProfileFilterSheet> {
  late SeatProfileFilter _selectedFilter = widget.selectedFilter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.mainBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextView.body1(
              AppStrings.seatProfileFilterTitle,
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ...SeatProfileFilter.values.map(_buildOption),
            const SizedBox(height: 20),
            AppButton(
              text: AppStrings.done,
              onPressed: () => Navigator.of(context).pop(_selectedFilter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(SeatProfileFilter filter) {
    final isSelected = _selectedFilter == filter;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: AppTextView.body(
        _labelFor(filter),
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      trailing: Icon(
        isSelected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isSelected ? AppColors.secondaryColor : AppColors.textSecondary,
      ),
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
    );
  }

  String _labelFor(SeatProfileFilter filter) {
    return switch (filter) {
      SeatProfileFilter.all => AppStrings.seatProfileFilterAll,
      SeatProfileFilter.primaryPaygrade =>
        AppStrings.seatProfileFilterPrimaryPaygrade,
      SeatProfileFilter.ancillaryPaygrade =>
        AppStrings.seatProfileFilterAncillaryPaygrade,
    };
  }
}
