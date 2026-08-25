import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../domain/entities/seat_profile_detail.dart';
import 'seat_profile_description_sheet.dart';

class SeatProfileDescriptionsScreen extends StatelessWidget {
  const SeatProfileDescriptionsScreen({
    super.key,
    required this.category,
    this.onUpdateDescription,
  });

  final SeatProfileCategory category;
  final Future<void> Function(
    SeatProfileDescription description,
    SeatProfileDescriptionFormData formData,
  )?
  onUpdateDescription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              Expanded(
                child: category.descriptions.isEmpty
                    ? Center(
                        child: AppTextView.body(
                          AppStrings.seatProfileNoDescriptionsFound,
                          color: AppColors.textSecondary,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextView.body1(
                                  category.title,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                const SizedBox(height: 8),
                                AppTextView.body2(
                                  '${_formatWeight(category.weightPercent)} ${AppStrings.seatProfilePercentageHold}',
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          ...category.descriptions.map(
                            (description) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _DescriptionCard(
                                description: description,
                                onUpdateDescription: onUpdateDescription,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: SvgPicture.asset(
              '${AppStrings.imagePath}back.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
        AppTextView.body(
          AppStrings.seatProfileDescriptionsTitle,
          color: AppColors.secondaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description, required this.onUpdateDescription});

  final SeatProfileDescription description;
  final Future<void> Function(
    SeatProfileDescription description,
    SeatProfileDescriptionFormData formData,
  )?
  onUpdateDescription;

  Future<void> _openDescriptionSheet(BuildContext context) async {
    await showSeatProfileDescriptionBottomSheet(
      context,
      description: description,
      onSave: onUpdateDescription == null
          ? null
          : (formData) => onUpdateDescription!(description, formData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDescriptionSheet(context),
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextView.body1(
                description.name,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  AppTextView.body2(
                    "${AppStrings.seatProfileMilestoneDays}: ",
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  AppTextView.body2(
                    seatProfileDescriptionMilestoneLabel(description.milestoneDays),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AppTextView.body2(
                    "${AppStrings.seatProfileCheckInType}: ",
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  AppTextView.body2(
                    seatProfileDescriptionCheckInTypeLabel(description.auditFactorType),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextView.body2(
                AppStrings.seatProfileAuditSpecifics,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              _ExpandableDescriptionText(description: description.auditSpecifics),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextView.body2(
                    AppStrings.seatProfileTrainings,
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.secondaryColor,
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableDescriptionText extends StatelessWidget {
  const _ExpandableDescriptionText({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: description, style: textStyle),
          maxLines: 7,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final hasOverflow = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: textStyle, maxLines: 7, overflow: TextOverflow.ellipsis),
            if (hasOverflow) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.seeAllAction,
                style: TextStyle(
                  color: AppColors.secondaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.secondaryColor,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
