part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _DraftQuizOptionTile extends StatelessWidget {
  const _DraftQuizOptionTile({
    required this.controller,
    required this.hintText,
    required this.isSelected,
    this.onSelect,
    this.onDeleteTap,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final isTextEditable = onDeleteTap != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? AppColors.secondaryColor
                    : AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isTextEditable,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: Colors.white,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onDeleteTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fieldBorder.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.red,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCorrectOptionChoice {
  const _QuizCorrectOptionChoice({required this.uuid, required this.label});

  final String uuid;
  final String label;
}

class _QuizCorrectOptionDropdown extends StatelessWidget {
  const _QuizCorrectOptionDropdown({
    required this.value,
    required this.options,
    this.onChanged,
    this.showLabel = true,
  });

  final String value;
  final List<_QuizCorrectOptionChoice> options;
  final ValueChanged<String?>? onChanged;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final hasValue = options.any((option) => option.uuid == value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          const AppTextView.body3(
            AppStrings.trainingQuestionCorrectAnswerLabel,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        if (showLabel) const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(value),
          initialValue: hasValue ? value : null,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: AppColors.surfaceDark,
          iconEnabledColor: AppColors.textPrimary,
          iconSize: 18,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceDark2.withValues(alpha: 0.42),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.22),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.22),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.uuid,
                  child: Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.controller,
    required this.hintText,
    required this.isSelected,
    required this.isEditable,
    this.onTap,
    this.canDelete = false,
    this.onDeleteTap,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isSelected;
  final bool isEditable;
  final VoidCallback? onTap;
  final bool canDelete;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.secondaryColor.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.secondaryColor.withValues(alpha: 0.58)
              : AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 10, bottom: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? AppColors.secondaryColor
                    : AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEditable,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: Colors.white,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                height: 1.45,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: onDeleteTap,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.fieldBorder.withValues(alpha: 0.22),
                  ),
                ),
                child: Tooltip(
                  message: AppStrings.trainingDeleteOption,
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.red,
                    size: 15,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrainingReadOnlyBanner extends StatelessWidget {
  const _TrainingReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark2.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: const AppTextView.body3(
        AppStrings.trainingReadOnlyAccessMessage,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    );
  }
}

class _QuizEmptyStateCard extends StatelessWidget {
  const _QuizEmptyStateCard();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.48;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark2.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.16),
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: AppTextView.body3(
            AppStrings.trainingNoQuizQuestionsAvailable,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _ContentMessage extends StatelessWidget {
  const _ContentMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark2.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.16),
        ),
      ),
      child: AppTextView.body3(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DottedRoundedBorderPainter extends CustomPainter {
  const _DottedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + 6;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
