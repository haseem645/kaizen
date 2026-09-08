import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../domain/entities/training_library_module.dart';
import '../controllers/training_library_controller.dart';
import 'training_library_selection_sheet.dart';
import 'training_library_status_state.dart';

Future<void> showTrainingLibrarySeatSelectionSheet(
  BuildContext context, {
  required TrainingLibraryController controller,
}) async {
  FocusScope.of(context).unfocus();
  controller.clearSelectionError();
  unawaited(controller.openSeatSelection());
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SeatSelectionContent(
        controller: controller,
        onSelected: (seat) async {
          FocusScope.of(sheetContext).unfocus();
          final succeeded = await controller.applySeatSelection(seat);
          if (succeeded && sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
  } finally {
    controller.closeSeatSelection();
  }
}

class _SeatSelectionContent extends StatelessWidget {
  const _SeatSelectionContent({required this.controller, required this.onSelected});

  final TrainingLibraryController controller;
  final ValueChanged<TrainingLibrarySeat?> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final seats = controller.seatOptions;
        return TrainingLibrarySelectionSheet(
          isBusy: controller.isApplyingSelection,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: TrainingLibrarySelectionHeader(
                  title: AppStrings.trainingSetupSelectSeat,
                  searchHint: AppStrings.trainingSetupSearchSeat,
                  onSearchChanged: controller.updateSeatSearchQuery,
                  enabled: !controller.isApplyingSelection,
                ),
              ),
              SliverToBoxAdapter(
                child: TrainingLibrarySelectionError(message: controller.selectionErrorMessage),
              ),
              SliverToBoxAdapter(
                child: TrainingLibrarySelectionTile(
                  title: AppStrings.trainingLibraryAllSeats,
                  isSelected: controller.selectedSeatId == null,
                  isLoading: controller.isApplyingSeatSelection(null),
                  onTap: controller.canApplySelection ? () => onSelected(null) : null,
                ),
              ),
              if (controller.isLoadingSeatOptions)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: FastCircularProgressIndicator(width: 24, height: 24)),
                )
              else if (controller.seatOptionsError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: TrainingLibraryStatusState(
                      message: controller.seatOptionsError!,
                      actionLabel: AppStrings.trainingLibraryRetry,
                      onActionTap: controller.loadSeatOptions,
                    ),
                  ),
                )
              else if (seats.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AppTextView.body2(
                      AppStrings.trainingSetupNoMatches,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 16),
                  sliver: SliverList.builder(
                    itemCount: seats.length,
                    itemBuilder: (context, index) {
                      final seat = seats[index];
                      return TrainingLibrarySelectionTile(
                        title: seat.title,
                        isSelected: controller.selectedSeatId == seat.id,
                        isLoading: controller.isApplyingSeatSelection(seat.id),
                        onTap: controller.canApplySelection ? () => onSelected(seat) : null,
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
