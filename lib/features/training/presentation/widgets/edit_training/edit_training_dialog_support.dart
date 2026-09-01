part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppOverlayCloseButton(onTap: onTap);
  }
}

class _DialogErrorMessageCard extends StatelessWidget {
  const _DialogErrorMessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.22)),
      ),
      child: AppTextView.body3(
        message,
        color: AppColors.textPrimary,
        height: 1.45,
      ),
    );
  }
}

class _QuizGenerationStepper extends StatelessWidget {
  const _QuizGenerationStepper({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    required this.canIncrement,
    required this.canDecrement,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool canIncrement;
  final bool canDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextView.body2(
              label,
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          _StepperActionButton(
            icon: Icons.remove_rounded,
            onTap: canDecrement ? onDecrement : null,
          ),
          SizedBox(
            width: 38,
            child: AppTextView.body1(
              '$value',
              fontSize: 16,
              textAlign: TextAlign.center,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          _StepperActionButton(
            icon: Icons.add_rounded,
            onTap: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepperActionButton extends StatelessWidget {
  const _StepperActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.surfaceDark.withValues(alpha: 0.45)
              : AppColors.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap == null
                ? AppColors.fieldBorder.withValues(alpha: 0.1)
                : AppColors.fieldBorder.withValues(alpha: 0.16),
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? AppColors.textSecondary.withValues(alpha: 0.45)
              : AppColors.textPrimary,
          size: 14,
        ),
      ),
    );
  }
}

class _QuizDifficultyChip extends StatelessWidget {
  const _QuizDifficultyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryColor.withValues(alpha: 0.16)
              : AppColors.mainBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryColor
                : AppColors.fieldBorder.withValues(alpha: 0.18),
          ),
        ),
        child: AppTextView.body2(
          label,
          fontSize: 13,
          color: isSelected
              ? AppColors.secondaryColor
              : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuizReplaceToggle extends StatelessWidget {
  const _QuizReplaceToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: AppTextView.body3(
              AppStrings.trainingQuizReplaceExistingQuestions,
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppTextView.body4(
            value
                ? AppStrings.trainingQuizEnabled
                : AppStrings.trainingQuizDisabled,
            color: value ? AppColors.secondaryColor : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.secondaryColor,
            activeTrackColor: AppColors.secondaryColor.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: AppColors.hex51597a,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SopAlertCard extends StatelessWidget {
  const _SopAlertCard({required this.confirmationController});

  final TextEditingController confirmationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: AppTextView.body1(
                  AppStrings.trainingGenerateSopAlertTitle,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const AppTextView.body(
            AppStrings.trainingGenerateSopAlertInstruction,
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmationController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.trainingGenerateSopConfirmation,
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
              filled: true,
              fillColor: AppColors.surfaceDark2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
