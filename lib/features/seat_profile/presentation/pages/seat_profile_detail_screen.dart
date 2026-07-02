import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../data/datasources/seat_profile_remote_data_source.dart';
import '../../data/repositories/seat_profile_repository_impl.dart';
import '../../domain/entities/seat_profile_detail.dart';
import '../../domain/usecases/get_seat_profiles_usecase.dart';
import '../providers/seat_profile_detail_controller.dart';
import 'seat_profile_description_dialog.dart';

class SeatProfileDetailScreen extends StatelessWidget {
  const SeatProfileDetailScreen({super.key, required this.seatId});

  final String seatId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SeatProfileRemoteDataSource>(create: (_) => createSeatProfileRemoteDataSource()),
        ProxyProvider<SeatProfileRemoteDataSource, SeatProfileRepositoryImpl>(
          update: (_, remoteDataSource, __) => createSeatProfileDetailRepository(remoteDataSource),
        ),
        ProxyProvider<SeatProfileRepositoryImpl, GetSeatProfilesUseCase>(
          update: (_, repository, __) => createGetSeatProfileDetailUseCase(repository),
        ),
        ChangeNotifierProvider<SeatProfileDetailController>(
          create: (context) =>
              SeatProfileDetailController(context.read<GetSeatProfilesUseCase>())
                ..initialize(seatId),
        ),
      ],
      child: const _SeatProfileDetailScreenView(),
    );
  }
}

class _SeatProfileDetailScreenView extends StatelessWidget {
  const _SeatProfileDetailScreenView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SeatProfileDetailController>();
    final detail = controller.detail;

    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              if (controller.isLoading)
                Expanded(child: Center(child: FastCircularProgressIndicator()))
              else if (controller.errorMessage != null)
                Expanded(child: _buildMessage(controller.errorMessage!))
              else if (detail == null)
                Expanded(child: _buildMessage(AppStrings.loginSomethingWentWrong))
              else
                Expanded(
                  child: ListView(
                    children: [
                      _buildSeatSummary(detail),
                      const SizedBox(height: 18),
                      if (detail.categories.isEmpty)
                        _buildMessage(AppStrings.seatProfileNoCategoriesFound)
                      else
                        ...detail.categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _CategoryCard(category: category),
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
          AppStrings.seatProfileDetailsTitle,
          color: AppColors.secondaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  Widget _buildSeatSummary(SeatProfileDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.body1(
            detail.title,
            color: AppColors.secondaryColor,
            fontWeight: FontWeight.w700,
          ),
          if (detail.departmentName.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppTextView.body2(
              detail.departmentName,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: AppTextView.body(message, color: AppColors.textSecondary, textAlign: TextAlign.center),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category});

  final SeatProfileCategory category;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(6),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextView.body1(
                          category.title,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 10),
                        AppTextView.body2(
                          AppStrings.seatProfilePercentageHold,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        AppTextView.body2(
                          _formatWeight(category.weightPercent),
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ForwardArrowBadge(isExpanded: _isExpanded),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 16),
                if (category.descriptions.isEmpty)
                  AppTextView.body2(
                    AppStrings.seatProfileNoDescriptionsFound,
                    color: AppColors.textSecondary,
                  )
                else
                  ...category.descriptions.map(
                    (description) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InlineDescriptionCard(description: description),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toInt()}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}

class _InlineDescriptionCard extends StatelessWidget {
  const _InlineDescriptionCard({required this.description});

  final SeatProfileDescription description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.body2(
            description.name,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AppTextView.body3(
                '${AppStrings.seatProfileMilestoneDays}:',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              AppTextView.body3(
                description.milestoneDays,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextView.body3(AppStrings.seatProfileAuditSpecifics, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          _ExpandableDescriptionText(
            title: description.name,
            description: description.auditSpecifics,
          ),
        ],
      ),
    );
  }
}

class _ForwardArrowBadge extends StatelessWidget {
  const _ForwardArrowBadge({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isExpanded ? 0.25 : 0,
      duration: const Duration(milliseconds: 220),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.mainBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.28)),
        ),
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.textSecondary,
          size: 14,
        ),
      ),
    );
  }
}

class _ExpandableDescriptionText extends StatelessWidget {
  const _ExpandableDescriptionText({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
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
              InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      SeatProfileDescriptionDialog(title: title, description: description),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: AppColors.secondaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.secondaryColor,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
