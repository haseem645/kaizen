import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/performance_report.dart';

Future<void> showPaygradeDetailDialog(
  BuildContext context, {
  required PerformanceReportPaygradeStep step,
  PerformanceReportPaygradeStep? currentStep,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) =>
        _PaygradeDetailDialog(step: step, currentStep: currentStep),
  );
}

class _PaygradeDetailDialog extends StatelessWidget {
  const _PaygradeDetailDialog({required this.step, this.currentStep});

  final PerformanceReportPaygradeStep step;
  final PerformanceReportPaygradeStep? currentStep;

  @override
  Widget build(BuildContext context) {
    final requirements = _buildRequirements(step.promotionRequirement);
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.5;

    return Dialog(
      backgroundColor: AppColors.mainBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 760, maxHeight: maxDialogHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextView.title(
                    step.title,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: 1.6,
                        ),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                height: 2,
                width: double.infinity,
                color: AppColors.textSecondary.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 48),
              if (step.isCurrent || currentStep == null) ...[
                _CurrentPaygrade(step: step),
              ] else ...[
                _TargetPaygrade(currentStep: currentStep!, targetStep: step),
              ],
              const SizedBox(height: 52),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppTextView.title(
                        'Advancement Requirements',
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      const SizedBox(height: 18),
                      for (final requirement in requirements) ...[
                        _RequirementBullet(text: requirement),
                        const SizedBox(height: 12),
                      ],
                      if (!step.isCurrent && currentStep != null) ...[
                        const SizedBox(height: 24),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    'Estimated Target Payrate at ${step.label}: ',
                                style: const TextStyle(
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: step.payRateDisplay,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _buildRequirements(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      return const <String>['-'];
    }

    final items = trimmed
        .split(RegExp(r'[\r\n]+'))
        .map(
          (item) => item.replaceFirst(RegExp(r'^[\-\u2022\*]\s*'), '').trim(),
        )
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return items.isEmpty ? <String>[trimmed] : items;
  }
}

class _CurrentPaygrade extends StatelessWidget {
  const _CurrentPaygrade({required this.step});

  final PerformanceReportPaygradeStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(child: _PaygradeCircle(step: step, isCurrent: true)),
        const SizedBox(height: 16),
        Center(
          child: AppTextView.title1(
            step.payRateDisplay,
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TargetPaygrade extends StatelessWidget {
  const _TargetPaygrade({required this.currentStep, required this.targetStep});

  final PerformanceReportPaygradeStep currentStep;
  final PerformanceReportPaygradeStep targetStep;

  @override
  Widget build(BuildContext context) {
    final currentPayRate = _safePayRate(currentStep);
    final targetPayRate = _safePayRate(targetStep);
    final payDelta = targetPayRate - currentPayRate;
    final normalizedDelta = payDelta <= 0 ? 0.0 : payDelta;
    final payDeltaDisplay = _formatRate(normalizedDelta);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              _PaygradeCircle(step: currentStep, isCurrent: false),
              const SizedBox(height: 10),
              AppTextView.title1(
                currentStep.payRateDisplay,
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 2),
              const AppTextView.title1(
                'Current Grade',
                color: AppColors.secondaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: _TargetPaygradeConnector(value: payDeltaDisplay),
        ),
        Expanded(
          child: Column(
            children: [
              _PaygradeCircle(step: targetStep, isCurrent: true),
              const SizedBox(height: 10),
              AppTextView.title1(
                targetStep.payRateDisplay,
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        ),
      ],
    );
  }

  double _safePayRate(PerformanceReportPaygradeStep step) {
    try {
      final value = step.payRateAmount;
      if (value <= 0 || value.isNaN || value.isInfinite) {
        return _parsePayRateDisplay(step.payRateDisplay);
      }
      return value;
    } catch (_) {
      return _parsePayRateDisplay(step.payRateDisplay);
    }
  }

  double _parsePayRateDisplay(String value) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
    final parsed = match == null ? null : double.tryParse(match.group(1)!);
    if (parsed == null || parsed <= 0) {
      return 0.0;
    }
    return parsed;
  }

  String _formatRate(double value) {
    final safeValue = value <= 0 ? 0.0 : value;
    final normalized = safeValue.toStringAsFixed(2);
    return '\$$normalized/hr';
  }
}

class _TargetPaygradeConnector extends StatelessWidget {
  const _TargetPaygradeConnector({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.mainBg,
                    border: Border.all(color: AppColors.hex31d4ff, width: 2.2),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.hex3fd8ff.withValues(alpha: 0.28),
                          AppColors.secondaryColor.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 18,
                  height: 20,
                  child: CustomPaint(painter: _ArrowHeadPainter()),
                ),
              ],
            ),
          ),
          _PaygradeDeltaChip(value: value),
        ],
      ),
    );
  }
}

class _PaygradeCircle extends StatelessWidget {
  const _PaygradeCircle({required this.step, required this.isCurrent});

  final PerformanceReportPaygradeStep step;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceDark,
        border: Border.all(
          color: isCurrent
              ? AppColors.secondaryColor
              : AppColors.textSecondary.withValues(alpha: 0.45),
          width: 3,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.secondaryColor.withValues(alpha: 0.55),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: AppTextView.title1(
        step.label,
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PaygradeDeltaChip extends StatelessWidget {
  const _PaygradeDeltaChip({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppTextView.title1(
            '+',
            color: AppColors.hex31d4ff,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(width: 4),
          AppTextView.title1(
            value.replaceFirst('+ ', ''),
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ],
      ),
    );
  }
}

class _ArrowHeadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.18)
      ..lineTo(size.width * 0.48, size.height * 0.18)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width * 0.48, size.height * 0.82)
      ..lineTo(size.width * 0.12, size.height * 0.82)
      ..lineTo(size.width * 0.28, size.height / 2)
      ..lineTo(size.width * 0.12, size.height * 0.18)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.secondaryColor.withValues(alpha: 0.78),
          AppColors.secondaryColor,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RequirementBullet extends StatelessWidget {
  const _RequirementBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextView.body3(
            text,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
