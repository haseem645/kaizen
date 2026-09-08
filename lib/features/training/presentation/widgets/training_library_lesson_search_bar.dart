import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../controllers/training_library_detail_controller.dart';

class TrainingLibraryLessonSearchBar extends StatefulWidget {
  const TrainingLibraryLessonSearchBar({
    super.key,
    required this.controller,
    required this.onSelectLesson,
  });

  final TrainingLibraryDetailController controller;
  final VoidCallback onSelectLesson;

  @override
  State<TrainingLibraryLessonSearchBar> createState() => _TrainingLibraryLessonSearchBarState();
}

class _TrainingLibraryLessonSearchBarState extends State<TrainingLibraryLessonSearchBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.searchQuery);
  }

  @override
  void didUpdateWidget(covariant TrainingLibraryLessonSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.controller.searchQuery;
    if (_textController.text != query) {
      _textController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (MediaQuery.textScalerOf(context).scale(16) * 1.2 + 24).clamp(46.0, double.infinity),
      child: TextField(
        controller: _textController,
        onChanged: widget.controller.updateSearchQuery,
        cursorHeight: 15,
        cursorColor: AppColors.textPrimary,
        textInputAction: TextInputAction.search,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.2),
        decoration: InputDecoration(
          hintText: AppStrings.trainingLibrarySearchLesson,
          hintStyle: const TextStyle(color: AppColors.grey1),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey1, size: 21),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: IconButton(
            tooltip: AppStrings.trainingLibrarySelectLesson,
            onPressed: widget.onSelectLesson,
            icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textPrimary, size: 20),
          ),
          suffixIconConstraints: const BoxConstraints.tightFor(width: 44, height: 44),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.grey1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.secondaryColor),
          ),
        ),
      ),
    );
  }
}
