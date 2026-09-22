import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_listing_search_bar.dart';

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
    return AppListingSearchBar(
      controller: controller,
      onChanged: onChanged,
      hintText: AppStrings.auditSearchHint,
      onFilterTap: onFilterTap,
      onClearTap: onClearTap,
      isSearchLoading: isSearchLoading,
    );
  }
}
