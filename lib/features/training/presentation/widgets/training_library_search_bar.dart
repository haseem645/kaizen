import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../controllers/training_library_controller.dart';

class TrainingLibrarySearchBar extends StatefulWidget {
  const TrainingLibrarySearchBar({super.key, required this.controller, required this.onSelectSeat});

  final TrainingLibraryController controller;
  final VoidCallback onSelectSeat;

  @override
  State<TrainingLibrarySearchBar> createState() => _TrainingLibrarySearchBarState();
}

class _TrainingLibrarySearchBarState extends State<TrainingLibrarySearchBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.searchQuery);
  }

  @override
  void didUpdateWidget(covariant TrainingLibrarySearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextQuery = widget.controller.searchQuery;
    if (_textController.text == nextQuery) {
      return;
    }

    _textController.value = TextEditingValue(
      text: nextQuery,
      selection: TextSelection.collapsed(offset: nextQuery.length),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: (MediaQuery.textScalerOf(context).scale(14) * 1.2 + 18).clamp(
              40.0,
              double.infinity,
            ),
            padding: const EdgeInsets.only(left: 12, right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey1),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.grey1, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onChanged: controller.updateSearchQuery,
                    textInputAction: TextInputAction.search,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: AppColors.textPrimary,
                    cursorHeight: 15,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.2),
                    decoration: InputDecoration(
                      hintText: AppStrings.trainingLibraryFilterHint(
                        AppStrings.trainingLibrarySeat,
                      ),
                      hintMaxLines: 1,
                      hintStyle: const TextStyle(color: AppColors.grey1),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (controller.hasSearchQuery)
                  IconButton(
                    tooltip: AppStrings.clearSearch,
                    onPressed: controller.clearSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 32, height: 38),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                  ),
                _TrainingLibrarySeatFilterButton(onTap: widget.onSelectSeat),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _TrainingLibrarySeatFilterButton(onTap: widget.onSelectSeat, isPrimary: true),
      ],
    );
  }
}

class _TrainingLibrarySeatFilterButton extends StatelessWidget {
  const _TrainingLibrarySeatFilterButton({required this.onTap, this.isPrimary = false});

  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.trainingSetupSelectSeat,
      child: Material(
        color: isPrimary ? AppColors.secondaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: isPrimary ? 40 : 36,
            height: isPrimary ? 40 : 38,
            child: Icon(
              isPrimary ? Icons.tune_rounded : Icons.arrow_drop_down_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
