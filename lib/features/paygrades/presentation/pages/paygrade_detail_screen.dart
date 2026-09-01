import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_gradient_action_button.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_swipe_reveal_action.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../data/datasources/paygrade_remote_data_source.dart';
import '../../data/repositories/paygrade_repository_impl.dart';
import '../../domain/entities/paygrade_detail.dart';
import '../../domain/usecases/get_paygrades_usecase.dart';
import '../providers/paygrade_detail_controller.dart';
import 'paygrade_entry_sheet.dart';
import 'paygrade_generate_sheet.dart';

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
          child: ListenableBuilder(
            listenable: AppManager.instance,
            builder: (context, _) {
              final canManageContent =
                  AppManager.instance.currentUserCanManagePaygrades;

              return Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _PaygradeTabSwitcher(
                    selectedTab: controller.selectedTab,
                    onTabSelected: controller.selectTab,
                  ),
                  const SizedBox(height: 18),
                  if (controller.isLoading)
                    Expanded(
                      child: Center(child: FastCircularProgressIndicator()),
                    )
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
                          if (canManageContent) ...[
                            const SizedBox(height: 18),
                            _RegenerateWithAiButton(
                              isLoading: controller.isGeneratingPaygrades,
                              onTap: controller.isGeneratingPaygrades
                                  ? null
                                  : () => _openGeneratePaygradesSheet(
                                      context,
                                      controller,
                                    ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          if (detail.payGrades.isNotEmpty)
                            for (
                              var index = 0;
                              index < detail.payGrades.length;
                              index++
                            )
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _PaygradeEntryCard(
                                  isEditable: canManageContent,
                                  isDeleting: controller.isDeletingPaygrade(
                                    detail.payGrades[index].id,
                                  ),
                                  entry: detail.payGrades[index],
                                  rowNumber: index + 1,
                                  onEditTap: canManageContent
                                      ? () => _openPaygradeSheet(
                                          context,
                                          controller,
                                          detail.payGrades[index],
                                        )
                                      : null,
                                  onDeleteTap: canManageContent
                                      ? () => _showDeleteDialog(
                                          context,
                                          controller,
                                          detail.payGrades[index],
                                        )
                                      : null,
                                ),
                              ),
                          if (canManageContent) ...[
                            SizedBox(height: detail.payGrades.isEmpty ? 18 : 2),
                            _AddPaygradeLevelButton(
                              onTap: () =>
                                  _openCreatePaygradeSheet(context, controller),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
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

  Future<void> _openPaygradeSheet(
    BuildContext context,
    PaygradeDetailController controller,
    PaygradeEntry entry,
  ) async {
    if (!AppManager.instance.currentUserCanManagePaygrades) {
      return;
    }

    final didSave = await showPaygradeEntryBottomSheet(
      context,
      entry: entry,
      mode: PaygradeEntrySheetMode.update,
      onSave:
          ({
            required String title,
            required String description,
            required String promotionRequirement,
          }) {
            return controller.updatePaygrade(
              entry: entry,
              title: title,
              description: description,
              promotionRequirement: promotionRequirement,
            );
          },
    );

    if (!didSave || !context.mounted) {
      return;
    }
  }

  Future<void> _openCreatePaygradeSheet(
    BuildContext context,
    PaygradeDetailController controller,
  ) async {
    if (!AppManager.instance.currentUserCanManagePaygrades) {
      return;
    }

    final didSave = await showPaygradeEntryBottomSheet(
      context,
      mode: PaygradeEntrySheetMode.create,
      onSave:
          ({
            required String title,
            required String description,
            required String promotionRequirement,
          }) {
            return controller.createPaygrade(
              title: title,
              description: description,
              promotionRequirement: promotionRequirement,
            );
          },
    );

    if (!didSave || !context.mounted) {
      return;
    }
  }

  Future<void> _openGeneratePaygradesSheet(
    BuildContext context,
    PaygradeDetailController controller,
  ) async {
    if (!AppManager.instance.currentUserCanManagePaygrades) {
      return;
    }

    final didGenerate = await showPaygradeGenerateSheet(
      context,
      controller: controller,
      hasExistingPaygrades: (controller.detail?.payGrades.length ?? 0) > 0,
    );

    if (!didGenerate || !context.mounted) {
      return;
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    PaygradeDetailController controller,
    PaygradeEntry entry,
  ) async {
    if (!AppManager.instance.currentUserCanManagePaygrades) {
      return;
    }

    final didDelete = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _DeletePaygradeDialog(controller: controller, entry: entry),
    );

    if (!context.mounted) {
      return;
    }

    if (didDelete == false && (controller.errorMessage ?? '').isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: AppTextView.body2(controller.errorMessage!)),
        );
    }
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

class _RegenerateWithAiButton extends StatelessWidget {
  const _RegenerateWithAiButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          SizedBox(
            width: double.infinity,
            child: AppGradientActionButton(
              label: AppStrings.paygradesGenerateWithAiAction,
              icon: Icons.auto_awesome_rounded,
              onTap: onTap,
            ),
          ),
          if (isLoading)
            Positioned(
              right: 16,
              child: FastCircularProgressIndicator(width: 18, height: 18),
            ),
        ],
      ),
    );
  }
}

class _PaygradeEntryCard extends StatefulWidget {
  const _PaygradeEntryCard({
    required this.entry,
    required this.rowNumber,
    required this.isEditable,
    required this.isDeleting,
    this.onEditTap,
    this.onDeleteTap,
  });

  final PaygradeEntry entry;
  final int rowNumber;
  final bool isEditable;
  final bool isDeleting;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  @override
  State<_PaygradeEntryCard> createState() => _PaygradeEntryCardState();
}

class _PaygradeEntryCardState extends State<_PaygradeEntryCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final cleanedTitle = _cleanPaygradeTitle(entry.title);
    final paygradePrefix = _buildPaygradePrefix(cleanedTitle, widget.rowNumber);
    final shouldShowExpandedDetails = _isExpanded;
    final card = InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: _toggleExpanded,
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
              const SizedBox(height: 14),
              _buildRow(AppStrings.paygradesRate, entry.payRate),
              if (shouldShowExpandedDetails) ...[
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
                if (widget.isEditable && widget.onEditTap != null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: widget.onEditTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondaryColor,
                        side: BorderSide(
                          color: AppColors.secondaryColor.withValues(
                            alpha: 0.72,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.secondaryColor,
                      ),
                      label: const AppTextView.body3(
                        AppStrings.paygradesEditAction,
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );

    if (!widget.isEditable) {
      return card;
    }

    return AppSwipeRevealAction(
      isEnabled: widget.onDeleteTap != null && !widget.isDeleting,
      onActionTap: widget.onDeleteTap,
      borderRadius: 6,
      actionWidth: 64,
      actionGap: 10,
      actionChild: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.red1,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: widget.isDeleting
                ? FastCircularProgressIndicator(width: 14, height: 14)
                : const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
          ),
        ),
      ),
      child: card,
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
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    if (prefix.isEmpty) {
      return rowNumber.toString();
    }

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
    const detailFontSize = 13.0;
    const detailFontWeight = FontWeight.w400;
    const detailLineHeight = 1.45;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textStyle = TextStyle(
          color: isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
          fontSize: detailFontSize,
          fontWeight: detailFontWeight,
          height: detailLineHeight,
        );
        final textPainter = TextPainter(
          text: TextSpan(text: resolvedValue, style: textStyle),
          maxLines: 3,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final shouldShowSeeAll = !isEmpty && textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextView.body3(label, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            AppTextView.body(
              resolvedValue,
              color: isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: detailFontSize,
              fontWeight: detailFontWeight,
              height: detailLineHeight,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (shouldShowSeeAll) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showExpandedTextDialog(
                  context,
                  title: label,
                  description: resolvedValue,
                ),
                child: AppTextView.body2(
                  AppStrings.seeAllAction,
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showExpandedTextDialog(
    BuildContext context, {
    required String title,
    required String description,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _PaygradeExpandedTextDialog(title: title, description: description),
    );
  }
}

class _PaygradeExpandedTextDialog extends StatelessWidget {
  const _PaygradeExpandedTextDialog({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppTextView.body1(
                      title,
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _PaygradeExpandedTextDialogCloseButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const AppDotDivider(),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: AppTextView.body(
                    description,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 140,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(AppStrings.done),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaygradeExpandedTextDialogCloseButton extends StatelessWidget {
  const _PaygradeExpandedTextDialogCloseButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppOverlayCloseButton(onTap: onTap);
  }
}

class _AddPaygradeLevelButton extends StatelessWidget {
  const _AddPaygradeLevelButton({required this.onTap});

  final VoidCallback onTap;
  static const double _borderRadius = 10;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedPaygradeButtonPainter(
          color: AppColors.secondaryColor.withValues(alpha: 0.78),
          radius: _borderRadius,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_borderRadius),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: AppColors.secondaryColor,
                  ),
                  const SizedBox(width: 8),
                  AppTextView.body3(
                    AppStrings.paygradesAddLevelAction,
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPaygradeButtonPainter extends CustomPainter {
  const _DashedPaygradeButtonPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;
  static const double _strokeWidth = 1.2;
  static const double _dashWidth = 7;
  static const double _dashSpace = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + _dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, nextDistance.clamp(0, metric.length)),
          Offset.zero,
        );
        distance += _dashWidth + _dashSpace;
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedPaygradeButtonPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _DeletePaygradeDialog extends StatelessWidget {
  const _DeletePaygradeDialog({required this.controller, required this.entry});

  final PaygradeDetailController controller;
  final PaygradeEntry entry;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AppConfirmationDialog(
          title: AppStrings.paygradesDeleteTitle,
          description: AppStrings.paygradesDeleteDescription(entry.title),
          confirmText: AppStrings.paygradesDeleteAction,
          cancelText: AppStrings.trainingCancel,
          isConfirmLoading: controller.isDeletingPaygrade(entry.id),
          onCancelCallback: () async {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          onConfirmCallback: () async {
            final didDelete = await controller.deletePaygrade(entry);
            if (!context.mounted) {
              return;
            }

            Navigator.of(context).pop(didDelete);
          },
        );
      },
    );
  }
}

class _ForwardArrowBadge extends StatelessWidget {
  const _ForwardArrowBadge({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: isExpanded ? 0.5 : 0,
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
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
