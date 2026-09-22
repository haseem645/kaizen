import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../controllers/training_library_controller.dart';
import '../models/training_library_filter_tag.dart';

class TrainingLibraryFilterTags extends StatelessWidget {
  const TrainingLibraryFilterTags({super.key, required this.controller});

  final TrainingLibraryController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 8.0;
      final tagWidth = (constraints.maxWidth - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: controller.appliedFilterTags
            .map(
              (tag) => SizedBox(
                width: tagWidth,
                child: _FilterTag(
                  key: ValueKey(tag.type),
                  prefix: tag.type.prefix,
                  label: tag.label,
                  accentColor: tag.type == TrainingLibraryFilter.seat
                      ? AppColors.secondaryColor
                      : null,
                  onRemove: controller.canApplySelection
                      ? () => _removeFilter(context, tag.type)
                      : null,
                ),
              ),
            )
            .toList(),
      );
    },
  );

  Future<void> _removeFilter(BuildContext context, TrainingLibraryFilter filter) async {
    final messenger = ScaffoldMessenger.of(context);
    final succeeded = await controller.removeFilter(filter);
    if (!succeeded && messenger.mounted && controller.selectionErrorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(controller.selectionErrorMessage!)));
    }
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({
    super.key,
    required this.prefix,
    required this.label,
    required this.onRemove,
    this.accentColor,
  });

  final String prefix;
  final String label;
  final VoidCallback? onRemove;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 30),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.trainingLessonActionSurface,
      border: Border.all(color: accentColor ?? AppColors.lightGrey1, width: 0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: AppTextView.body3(
            AppStrings.trainingLibraryFilterTagLabel(prefix, label),
            color: accentColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            height: 1.2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: AppStrings.trainingLibraryRemoveFilter(label),
          onPressed: onRemove,
          icon: Icon(Icons.close_outlined, size: 16, color: accentColor ?? AppColors.lightGrey1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
          visualDensity: VisualDensity.compact,
          style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
      ],
    ),
  );
}
