import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_seat_selection_tile.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
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
        onApply: () async {
          FocusScope.of(sheetContext).unfocus();
          final succeeded = await controller.applyPendingSeatSelection();
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
  const _SeatSelectionContent({required this.controller, required this.onApply});

  final TrainingLibraryController controller;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TrainingLibrarySelectionSheet(
        isBusy: controller.isApplyingSelection,
        child: Column(
          children: [
            Expanded(child: _SeatSelectionList(controller: controller)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: AppButton(
                text: AppStrings.trainingLibraryShowAction,
                textSize: 14,
                isLoading: controller.isApplyingSelection,
                onPressed: controller.canApplySelection ? onApply : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatSelectionList extends StatelessWidget {
  const _SeatSelectionList({required this.controller});

  final TrainingLibraryController controller;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
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
          child: AppSeatSelectionTile(
            title: AppStrings.trainingLibraryAllSeats,
            contentPadding: const EdgeInsets.symmetric(horizontal: 28),
            isSelected: controller.pendingSeatSelectionId == null,
            onTap: controller.canApplySelection
                ? () => controller.updatePendingSeatSelection(null)
                : null,
          ),
        ),
        _SeatOptionsSliver(controller: controller),
      ],
    );
  }
}

class _SeatOptionsSliver extends StatelessWidget {
  const _SeatOptionsSliver({required this.controller});

  final TrainingLibraryController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoadingSeatOptions) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: FastCircularProgressIndicator(width: 24, height: 24)),
      );
    }
    if (controller.seatOptionsError != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: TrainingLibraryStatusState(
            message: controller.seatOptionsError!,
            actionLabel: AppStrings.trainingLibraryRetry,
            onActionTap: controller.loadSeatOptions,
          ),
        ),
      );
    }

    final seats = controller.seatOptions;
    if (seats.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: AppTextView.body2(
            AppStrings.trainingSetupNoMatches,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 16),
      sliver: SliverList.builder(
        itemCount: seats.length,
        itemBuilder: (context, index) {
          final seat = seats[index];
          return AppSeatSelectionTile(
            title: seat.title,
            contentPadding: const EdgeInsets.symmetric(horizontal: 28),
            isSelected: controller.pendingSeatSelectionId == seat.id,
            onTap: controller.canApplySelection
                ? () => controller.updatePendingSeatSelection(seat)
                : null,
          );
        },
      ),
    );
  }
}
