part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _AiGenerateButton extends StatelessWidget {
  const _AiGenerateButton({
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.verticalPadding = 11,
  });

  final String label;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onTap;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return _GradientTrainingActionButton(
      label: label,
      icon: Icons.auto_awesome_rounded,
      isEnabled: isEnabled,
      isLoading: isLoading,
      verticalPadding: verticalPadding,
      onTap: onTap,
    );
  }
}

class _GradientTrainingActionButton extends StatelessWidget {
  const _GradientTrainingActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.showLoaderInIconSlot = false,
    this.verticalPadding = 11,
  });

  final String label;
  final IconData icon;
  final bool isEnabled;
  final bool isLoading;
  final bool showLoaderInIconSlot;
  final VoidCallback? onTap;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final isEnabledAppearance = isEnabled && onTap != null;
    final isInteractive = isEnabledAppearance && !isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: isEnabledAppearance
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.purple1, AppColors.secondaryColor],
                  )
                : null,
            color: isEnabledAppearance ? null : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabledAppearance
                  ? AppColors.lightPurple1.withValues(alpha: 0.35)
                  : AppColors.fieldBorder.withValues(alpha: 0.22),
            ),
            boxShadow: isEnabledAppearance
                ? [
                    BoxShadow(
                      color: AppColors.purple1.withValues(alpha: 0.36),
                      blurRadius: 10,
                      offset: const Offset(-6, 0),
                      spreadRadius: -1,
                    ),
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.42),
                      blurRadius: 16,
                      offset: const Offset(12, 0),
                      spreadRadius: -2,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLoaderInIconSlot && isLoading)
                FastCircularProgressIndicator(width: 16, height: 16)
              else
                Icon(
                  icon,
                  size: 16,
                  color: isEnabledAppearance
                      ? Colors.white.withValues(alpha: 0.96)
                      : AppColors.textSecondary,
                ),
              const SizedBox(width: 8),
              AppTextView.body2(
                label,
                color: isEnabledAppearance
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              if (isLoading && !showLoaderInIconSlot) ...[
                const SizedBox(width: 10),
                FastCircularProgressIndicator(width: 14, height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryTrainingActionButton extends StatelessWidget {
  const _SecondaryTrainingActionButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.isDottedBorder = false,
    this.horizontalPadding = 14,
    this.verticalPadding = 10,
    this.borderRadius = 999,
    this.backgroundColor,
    this.activeBorderColor,
    this.activeTextColor,
    this.activeIconColor,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLoading;
  final bool isDottedBorder;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? activeBorderColor;
  final Color? activeTextColor;
  final Color? activeIconColor;

  @override
  Widget build(BuildContext context) {
    final isInteractive = isEnabled && !isLoading && onTap != null;
    final borderColor = isInteractive
        ? activeBorderColor ?? AppColors.fieldBorder.withValues(alpha: 0.22)
        : AppColors.fieldBorder.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          foregroundPainter: isDottedBorder
              ? _DottedRoundedBorderPainter(
                  color: borderColor,
                  radius: borderRadius,
                )
              : null,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(borderRadius),
              border: isDottedBorder ? null : Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isInteractive
                        ? activeIconColor ?? AppColors.secondaryColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                AppTextView.body2(
                  label,
                  color: isInteractive
                      ? activeTextColor ?? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                if (isLoading) ...[
                  const SizedBox(width: 10),
                  FastCircularProgressIndicator(width: 14, height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingSectionHeader extends StatelessWidget {
  const _TrainingSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppTextView.body3(
      title,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
    );
  }
}

class _TrainingDisplayCard extends StatelessWidget {
  const _TrainingDisplayCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark2.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.16),
        ),
      ),
      child: child,
    );
  }
}

class _TrainingEditableTextCard extends StatelessWidget {
  const _TrainingEditableTextCard({
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
    this.readOnly = false,
    this.wrapWithCard = true,
    this.padding = const EdgeInsets.all(16),
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final bool wrapWithCard;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textField = Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        cursorColor: Colors.white,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.65,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.74),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.65,
          ),
        ),
      ),
    );

    if (!wrapWithCard) {
      return textField;
    }

    return _TrainingDisplayCard(child: textField);
  }
}

class _TrainingSingleLineInputCard extends StatelessWidget {
  const _TrainingSingleLineInputCard({
    required this.controller,
    required this.hintText,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return _TrainingDisplayCard(
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        cursorColor: Colors.white,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.74),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TrainingTapEditField extends StatelessWidget {
  const _TrainingTapEditField({
    required this.valueText,
    required this.hintText,
    this.onTap,
    this.isLoading = false,
  });

  final String valueText;
  final String hintText;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasValue = valueText.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark2.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? valueText.trim() : hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasValue
                        ? AppColors.textPrimary
                        : AppColors.textSecondary.withValues(alpha: 0.74),
                    fontSize: 16,
                    fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: FastCircularProgressIndicator(width: 12, height: 12),
                )
              else
                Icon(
                  Icons.edit_outlined,
                  color: onTap != null
                      ? AppColors.secondaryColor
                      : AppColors.textSecondary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingOutlinedTextField extends StatelessWidget {
  const _TrainingOutlinedTextField({
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
    this.textInputAction,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
    this.textHeight = 1.4,
    this.hintFontWeight = FontWeight.w500,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;
  final TextInputAction? textInputAction;
  final double fontSize;
  final FontWeight fontWeight;
  final double textHeight;
  final FontWeight hintFontWeight;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: Colors.white,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: textHeight,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.74),
          fontSize: fontSize,
          fontWeight: hintFontWeight,
          height: textHeight,
        ),
        filled: true,
        fillColor: AppColors.surfaceDark2.withValues(alpha: 0.42),
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.fieldBorder.withValues(alpha: 0.16),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppColors.fieldBorder.withValues(alpha: 0.16),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.secondaryColor),
        ),
      ),
    );
  }
}
