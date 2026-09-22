import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_radio_selection_tile.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../controllers/training_library_controller.dart';
import 'training_library_selection_sheet.dart';

Future<void> showTrainingLibraryDepartmentSelectionSheet(
  BuildContext context, {
  required TrainingLibraryController controller,
}) async {
  FocusScope.of(context).unfocus();
  controller.updateDepartmentSearchQuery('');
  controller.clearSelectionError();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _DepartmentSelectionContent(
      controller: controller,
      onSelected: (id) async {
        FocusScope.of(sheetContext).unfocus();
        final succeeded = await controller.applyDepartmentSelection(id);
        if (succeeded && sheetContext.mounted) {
          Navigator.of(sheetContext).pop();
        }
      },
    ),
  );
}

class _DepartmentSelectionContent extends StatelessWidget {
  const _DepartmentSelectionContent({required this.controller, required this.onSelected});

  final TrainingLibraryController controller;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final departments = controller.departmentOptions;
        return TrainingLibrarySelectionSheet(
          isBusy: controller.isApplyingSelection,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: TrainingLibrarySelectionHeader(
                  title: AppStrings.departmentsTitle,
                  searchHint: AppStrings.departmentsSearchHint,
                  onSearchChanged: controller.updateDepartmentSearchQuery,
                  enabled: !controller.isApplyingSelection,
                ),
              ),
              SliverToBoxAdapter(
                child: TrainingLibrarySelectionError(message: controller.selectionErrorMessage),
              ),
              SliverToBoxAdapter(
                child: AppRadioSelectionTile(
                  title: AppStrings.trainingLibraryAllFilter,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                  isSelected: controller.selectedDepartmentId == 'all',
                  isLoading: controller.isApplyingDepartmentSelection('all'),
                  onTap: controller.canApplySelection ? () => onSelected('all') : null,
                ),
              ),
              if (departments.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AppTextView.body2(
                      AppStrings.departmentsNoSearchResults,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverList.builder(
                    itemCount: departments.length,
                    itemBuilder: (context, index) {
                      final department = departments[index];
                      return AppRadioSelectionTile(
                        title: department.name,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                        isSelected: controller.selectedDepartmentId == department.id,
                        isLoading: controller.isApplyingDepartmentSelection(department.id),
                        onTap: controller.canApplySelection
                            ? () => onSelected(department.id)
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
