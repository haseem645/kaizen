import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import 'app_department_filter_strip.dart';
import 'app_radio_selection_tile.dart';
import 'app_selection_sheet.dart';
import 'app_text_view.dart';

Future<String?> showAppDepartmentSelectionSheet(
  BuildContext context, {
  required List<AppDepartmentFilterItem> items,
  required String selectedDepartmentId,
  bool safeAreaBottom = true,
}) {
  FocusScope.of(context).unfocus();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _DepartmentSelectionContent(
      items: items,
      selectedDepartmentId: selectedDepartmentId,
      safeAreaBottom: safeAreaBottom,
    ),
  );
}

class _DepartmentSelectionContent extends StatefulWidget {
  const _DepartmentSelectionContent({
    required this.items,
    required this.selectedDepartmentId,
    required this.safeAreaBottom,
  });

  final List<AppDepartmentFilterItem> items;
  final String selectedDepartmentId;
  final bool safeAreaBottom;

  @override
  State<_DepartmentSelectionContent> createState() => _DepartmentSelectionContentState();
}

class _DepartmentSelectionContentState extends State<_DepartmentSelectionContent> {
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchQuery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQuery,
      builder: (context, query, _) {
        final items = widget.items
            .where((item) => item.id == 'all' || item.name.toLowerCase().contains(query))
            .toList(growable: false);
        return AppSelectionSheet(
          safeAreaBottom: widget.safeAreaBottom,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: AppSelectionHeader(
                  title: AppStrings.departmentsTitle,
                  searchHint: AppStrings.departmentsSearchHint,
                  onSearchChanged: (value) => _searchQuery.value = value.trim().toLowerCase(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return AppRadioSelectionTile(
                      title: item.name,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                      isSelected: widget.selectedDepartmentId == item.id,
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop(item.id);
                      },
                    );
                  },
                ),
              ),
              if (!items.any((item) => item.id != 'all'))
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AppTextView.body2(
                      AppStrings.departmentsNoSearchResults,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
