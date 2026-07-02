import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../data/datasources/paygrade_remote_data_source.dart';
import '../../data/repositories/paygrade_repository_impl.dart';
import '../../domain/entities/paygrade_detail.dart';
import '../../domain/usecases/get_paygrades_usecase.dart';
import '../providers/paygrade_detail_controller.dart';

class PaygradeDetailScreen extends StatelessWidget {
  const PaygradeDetailScreen({super.key, required this.paygradeId});

  final String paygradeId;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PaygradeRemoteDataSource>(
          create: (_) => createPaygradeRemoteDataSource(),
        ),
        ProxyProvider<PaygradeRemoteDataSource, PaygradeRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createPaygradeDetailRepository(remoteDataSource),
        ),
        ProxyProvider<PaygradeRepositoryImpl, GetPaygradesUseCase>(
          update: (_, repository, __) =>
              createGetPaygradeDetailUseCase(repository),
        ),
        ChangeNotifierProvider<PaygradeDetailController>(
          create: (context) =>
              PaygradeDetailController(context.read<GetPaygradesUseCase>())
                ..initialize(paygradeId),
        ),
      ],
      child: const _PaygradeDetailScreenView(),
    );
  }
}

class _PaygradeDetailScreenView extends StatelessWidget {
  const _PaygradeDetailScreenView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaygradeDetailController>();
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
              _PaygradeTabSwitcher(
                selectedTab: controller.selectedTab,
                onTabSelected: controller.selectTab,
              ),
              const SizedBox(height: 18),
              if (controller.isLoading)
                Expanded(child: Center(child: FastCircularProgressIndicator()))
              else if (controller.errorMessage != null)
                Expanded(child: _buildErrorMessage(controller))
              else if (detail == null)
                Expanded(
                  child: _buildMessage(AppStrings.loginSomethingWentWrong),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      _buildSummary(detail),
                      const SizedBox(height: 18),
                      if (detail.payGrades.isEmpty)
                        _buildMessage(AppStrings.paygradesNoDetailItemsFound)
                      else
                        for (
                          var index = 0;
                          index < detail.payGrades.length;
                          index++
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _PaygradeEntryCard(
                              entry: detail.payGrades[index],
                              rowNumber: index + 1,
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
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        AppTextView.body(
          AppStrings.paygradesDetailsTitle,
          color: AppColors.secondaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  Widget _buildSummary(PaygradeDetail detail) {
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
          if (detail.department.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppTextView.body2(
              detail.department,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ],
          // if (detail.paygradeUnit.isNotEmpty) ...[
          //   const SizedBox(height: 12),
          //   _buildSummaryRow(AppStrings.paygradesUnit, detail.paygradeUnit),
          // ],
        ],
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: AppTextView.body(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorMessage(PaygradeDetailController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextView.body(
            controller.errorMessage ?? AppStrings.loginSomethingWentWrong,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: controller.retry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PaygradeTabSwitcher extends StatelessWidget {
  const _PaygradeTabSwitcher({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final PaygradeDetailTab selectedTab;
  final ValueChanged<PaygradeDetailTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: AppStrings.paygradesPrimaryTab,
              isSelected: selectedTab == PaygradeDetailTab.primary,
              onTap: () => onTabSelected(PaygradeDetailTab.primary),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: AppStrings.paygradesAncillaryTab,
              isSelected: selectedTab == PaygradeDetailTab.ancillary,
              onTap: () => onTabSelected(PaygradeDetailTab.ancillary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: AppTextView.body2(
          title,
          textAlign: TextAlign.center,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaygradeEntryCard extends StatefulWidget {
  const _PaygradeEntryCard({required this.entry, required this.rowNumber});

  final PaygradeEntry entry;
  final int rowNumber;

  @override
  State<_PaygradeEntryCard> createState() => _PaygradeEntryCardState();
}

class _PaygradeEntryCardState extends State<_PaygradeEntryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final cleanedTitle = _cleanPaygradeTitle(entry.title);
    final paygradePrefix = _buildPaygradePrefix(cleanedTitle, widget.rowNumber);

    return InkWell(
      borderRadius: BorderRadius.circular(6),
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
                    child: AppTextView.body1(
                      '$paygradePrefix: $cleanedTitle',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ForwardArrowBadge(isExpanded: _isExpanded),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 14),
                _buildRow(AppStrings.paygradesRate, entry.payRate),
                const SizedBox(height: 10),
                _buildMultilineRow(
                  context,
                  AppStrings.paygradesDescription,
                  entry.description,
                  emptyValue: AppStrings.paygradesEmptyDescription,
                ),
                const SizedBox(height: 10),
                _buildMultilineRow(
                  context,
                  AppStrings.paygradesPromotionRequirement,
                  entry.promotionRequirement,
                  emptyValue: AppStrings.paygradesEmptyPromotionRequirement,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _cleanPaygradeTitle(String title) {
    return title
        .replaceFirst(RegExp(r'^\s*paygrade\s*:\s*', caseSensitive: false), '')
        .trim();
  }

  String _buildPaygradePrefix(String cleanedTitle, int rowNumber) {
    if (cleanedTitle.isEmpty) {
      return rowNumber.toString();
    }

    final prefix = cleanedTitle
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .join();

    return '$prefix$rowNumber';
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextView.body2(label, color: AppColors.textSecondary),
        ),
        AppTextView.body2(
          value,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }

  Widget _buildMultilineRow(
    BuildContext context,
    String label,
    String value, {
    required String emptyValue,
  }) {
    final resolvedValue = value.trim().isEmpty ? emptyValue : value.trim();
    final isEmpty = value.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextView.body2(label, color: AppColors.textSecondary),
        const SizedBox(height: 4),
        AppTextView.body2(
          resolvedValue,
          color: isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          height: 1.4,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (!isEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                CustomFunctions.showCustomAlert(context, label, resolvedValue),
            child: AppTextView.body2(
              AppStrings.seeAll,
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
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
          border: Border.all(
            color: AppColors.fieldBorder.withValues(alpha: 0.28),
          ),
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
