import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../training/domain/entities/seat_description_training_route.dart';
import '../../../training/presentation/pages/edit_training_screen.dart';
import '../../data/datasources/seat_profile_remote_data_source.dart';
import '../../data/repositories/seat_profile_repository_impl.dart';
import '../../domain/entities/seat_profile_detail.dart';
import '../../domain/usecases/get_seat_profiles_usecase.dart';
import '../providers/seat_profile_detail_controller.dart';
import 'seat_profile_description_sheet.dart';
import 'seat_profile_generate_content_sheet.dart';
import 'seat_profile_manage_categories_sheet.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.mainBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: const AppTextView.title1(
          AppStrings.seatProfileDetailsTitle,
          color: AppColors.secondaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ListenableBuilder(
            listenable: AppManager.instance,
            builder: (context, _) {
              final canManageContent = AppManager.instance.canCurrentOrganizationModifyContent;

              return Column(
                children: [
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
                          _DetailActionRow(
                            controller: controller,
                            canManageContent: canManageContent,
                            onUpdateCategory: () =>
                                _showManageSeatCategoriesDialog(context, controller),
                            onGenerate: () => _showGenerateSeatContentSheet(context, controller),
                          ),
                          const SizedBox(height: 18),
                          if (detail.categories.isEmpty)
                            _buildMessage(AppStrings.seatProfileNoCategoriesFound)
                          else
                            ...detail.categories.map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _CategoryCard(
                                  controller: controller,
                                  canManageContent: canManageContent,
                                  seatProfileId: detail.id,
                                  category: category,
                                  onOpenDescription: (description) =>
                                      _showSeatDescriptionSheet(context, controller, description),
                                  onDeleteDescription: (description) =>
                                      _showDeleteDescriptionDialog(
                                        context,
                                        controller,
                                        description,
                                      ),
                                  onAddDescription: () =>
                                      _showSeatAdditionSheet(context, controller, category),
                                ),
                              ),
                            ),
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

  Future<void> _showManageSeatCategoriesDialog(
    BuildContext context,
    SeatProfileDetailController controller,
  ) async {
    if (!AppManager.instance.canCurrentOrganizationModifyContent) {
      return;
    }

    final didUpdate = await showSeatProfileManageCategoriesSheet(
      context,
      initialCategories: controller.categoryDrafts,
      onSaveCategories: controller.saveSeatCategoryDrafts,
    );
    if (didUpdate != true || !context.mounted) {
      return;
    }

    await controller.refresh();
  }

  Future<void> _showGenerateSeatContentSheet(
    BuildContext context,
    SeatProfileDetailController controller,
  ) async {
    if (!AppManager.instance.canCurrentOrganizationModifyContent) {
      return;
    }

    controller.clearSeatContentGenerationError();

    final hasExistingCategories =
        controller.detail?.categories.isNotEmpty == true || controller.categoryDrafts.isNotEmpty;

    await showSeatProfileGenerateContentSheet(
      context,
      controller: controller,
      hasExistingCategories: hasExistingCategories,
    );
  }

  Future<void> _showSeatAdditionSheet(
    BuildContext context,
    SeatProfileDetailController controller,
    SeatProfileCategory category,
  ) async {
    if (!AppManager.instance.canCurrentOrganizationModifyContent) {
      return;
    }

    await showSeatProfileDescriptionBottomSheet(
      context,
      description: const SeatProfileDescription(
        id: '',
        actualId: '',
        name: '',
        auditSpecifics: '',
        auditFactorType: 'observation',
        milestoneDays: '30',
      ),
      title: AppStrings.seatProfileSeatAdditionDialogTitle,
      descriptionText: AppStrings.seatProfileCreateDescriptionSheetDescription,
      submitLabel: AppStrings.seatProfileSaveAction,
      onSave: (formData) => controller.addSeatDescription(
        categoryId: category.id,
        descriptionName: formData.descriptionName,
        auditSpecifics: formData.auditSpecifics,
        auditFactorType: formData.auditFactorType,
        milestoneDays: formData.milestoneDays,
      ),
    );
  }

  Future<void> _showSeatDescriptionSheet(
    BuildContext context,
    SeatProfileDetailController controller,
    SeatProfileDescription description,
  ) async {
    if (!AppManager.instance.canCurrentOrganizationModifyContent) {
      return;
    }

    await showSeatProfileDescriptionBottomSheet(
      context,
      description: description,
      onSave: (formData) => controller.updateSeatDescription(
        description: description,
        descriptionName: formData.descriptionName,
        auditSpecifics: formData.auditSpecifics,
        auditFactorType: formData.auditFactorType,
        milestoneDays: formData.milestoneDays,
      ),
    );
  }

  Future<void> _showDeleteDescriptionDialog(
    BuildContext context,
    SeatProfileDetailController controller,
    SeatProfileDescription description,
  ) async {
    if (!AppManager.instance.canCurrentOrganizationModifyContent) {
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (_) =>
          _DeleteSeatDescriptionDialog(controller: controller, description: description),
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
          if ((detail.department?.name ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            AppTextView.body2(
              detail.department!.name,
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

class _DetailActionRow extends StatelessWidget {
  const _DetailActionRow({
    required this.controller,
    required this.canManageContent,
    required this.onUpdateCategory,
    required this.onGenerate,
  });

  final SeatProfileDetailController controller;
  final bool canManageContent;
  final VoidCallback onUpdateCategory;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    if (!canManageContent) {
      return const SizedBox.shrink();
    }

    final isBusy = controller.isGeneratingSeatContent;
    final isEnabled = controller.detail != null && !controller.isLoading;

    return Row(
      children: [
        Expanded(
          child: _SeatProfileDottedActionButton(
            label: AppStrings.seatProfileUpdateCategoryAction,
            onTap: isEnabled && !isBusy ? onUpdateCategory : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SeatProfileGradientActionButton(
            label: AppStrings.seatProfileGenerateAction,
            isLoading: controller.isGeneratingSeatContent,
            onTap: isEnabled && controller.canGenerateSeatContent ? onGenerate : null,
          ),
        ),
      ],
    );
  }
}

class _SeatProfileDottedActionButton extends StatelessWidget {
  const _SeatProfileDottedActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final borderColor = isEnabled
        ? AppColors.secondaryColor
        : AppColors.fieldBorder.withValues(alpha: 0.28);
    const minimumHeight = 48.0;

    return Opacity(
      opacity: isEnabled ? 1 : 0.58,
      child: CustomPaint(
        painter: _SeatProfileDottedRoundedBorderPainter(color: borderColor, radius: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: double.infinity,
              height: minimumHeight,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark3.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: AppTextView.body(
                  label,
                  color: isEnabled ? AppColors.secondaryColor : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatProfileGradientActionButton extends StatelessWidget {
  const _SeatProfileGradientActionButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isLoading;
    const minimumHeight = 48.0;

    return Opacity(
      opacity: isEnabled || isLoading ? 1 : 0.58,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            width: double.infinity,
            height: minimumHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.purple1, AppColors.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightPurple1.withValues(alpha: 0.35)),
              boxShadow: isEnabled
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
            child: Center(
              child: isLoading
                  ? FastCircularProgressIndicator(width: 18, height: 18)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: 10),
                        AppTextView.body(
                          label,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.controller,
    required this.canManageContent,
    required this.seatProfileId,
    required this.category,
    required this.onOpenDescription,
    required this.onDeleteDescription,
    required this.onAddDescription,
  });

  final SeatProfileDetailController controller;
  final bool canManageContent;
  final String seatProfileId;
  final SeatProfileCategory category;
  final ValueChanged<SeatProfileDescription> onOpenDescription;
  final ValueChanged<SeatProfileDescription> onDeleteDescription;
  final VoidCallback onAddDescription;

  @override
  Widget build(BuildContext context) {
    final isExpanded = controller.isCategoryExpanded(category.id);

    return Container(
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => controller.setCategoryExpanded(category.id, !isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
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
                  ),
                ),
                const SizedBox(width: 12),
                _CategoryToggleBadge(
                  isExpanded: isExpanded,
                  onTap: () => controller.setCategoryExpanded(category.id, !isExpanded),
                ),
              ],
            ),
            if (isExpanded) ...[
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
                    child: _InlineDescriptionCard(
                      controller: controller,
                      canManageContent: canManageContent,
                      seatProfileId: seatProfileId,
                      categoryId: category.id,
                      description: description,
                      onOpenDescription: () => onOpenDescription(description),
                      onDeleteDescription: () => onDeleteDescription(description),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              if (canManageContent)
                _SeatProfileDottedActionButton(
                  label: AppStrings.seatProfileAddSeatDescriptionAction,
                  onTap: onAddDescription,
                ),
            ],
          ],
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
  const _InlineDescriptionCard({
    required this.controller,
    required this.canManageContent,
    required this.seatProfileId,
    required this.categoryId,
    required this.description,
    required this.onOpenDescription,
    required this.onDeleteDescription,
  });

  final SeatProfileDetailController controller;
  final bool canManageContent;
  final String seatProfileId;
  final String categoryId;
  final SeatProfileDescription description;
  final VoidCallback onOpenDescription;
  final VoidCallback onDeleteDescription;

  @override
  Widget build(BuildContext context) {
    final isDeleting = controller.isDeletingDescription(description);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDeleting || !canManageContent ? null : onOpenDescription,
        borderRadius: BorderRadius.circular(6),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextView.body2(
                      description.name,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (canManageContent) ...[
                    const SizedBox(width: 10),
                    _DeleteDescriptionIconButton(
                      isDeleting: isDeleting,
                      onTap: isDeleting ? null : onDeleteDescription,
                    ),
                  ],
                ],
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
                    seatProfileDescriptionMilestoneLabel(description.milestoneDays),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AppTextView.body3(
                    '${AppStrings.seatProfileCheckInType}:',
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  AppTextView.body3(
                    seatProfileDescriptionCheckInTypeLabel(description.auditFactorType),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextView.body3(
                AppStrings.seatProfileAuditSpecifics,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              _ExpandableDescriptionText(
                description: description.auditSpecifics,
                onSeeAllTap: isDeleting ? null : () => _showAuditSpecificsDialog(context),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: _ViewTrainingTextButton(
                  onTap: isDeleting ? null : () => _openTrainingModules(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTrainingModules(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EditTrainingScreen(
          trainingRoute: SeatDescriptionTrainingRoute(
            job: seatProfileId,
            category: categoryId,
            description: description.id,
          ),
          useNonBlockingVideoUpload: true,
        ),
      ),
    );
  }

  Future<void> _showAuditSpecificsDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AuditSpecificsDialog(description: description.auditSpecifics),
    );
  }
}

class _DeleteSeatDescriptionDialog extends StatelessWidget {
  const _DeleteSeatDescriptionDialog({required this.controller, required this.description});

  final SeatProfileDetailController controller;
  final SeatProfileDescription description;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AppConfirmationDialog(
          title: AppStrings.seatProfileDeleteDescriptionTitle,
          description: AppStrings.seatProfileDeleteDescriptionDescription(description.name),
          confirmText: AppStrings.seatProfileDeleteDescriptionAction,
          cancelText: AppStrings.actionCancel,
          isConfirmLoading: controller.isDeletingDescription(description),
          onCancelCallback: () async {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          onConfirmCallback: () async {
            final didDelete = await controller.deleteSeatDescription(description);
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

class _DeleteDescriptionIconButton extends StatelessWidget {
  const _DeleteDescriptionIconButton({required this.isDeleting, required this.onTap});

  final bool isDeleting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.red1.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.red1.withValues(alpha: 0.24)),
          ),
          child: Center(
            child: isDeleting
                ? FastCircularProgressIndicator(width: 14, height: 14)
                : const Icon(Icons.delete_outline_rounded, color: AppColors.red1, size: 18),
          ),
        ),
      ),
    );
  }
}

class _CategoryToggleBadge extends StatelessWidget {
  const _CategoryToggleBadge({required this.isExpanded, required this.onTap});

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.mainBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.28)),
        ),
        child: Icon(
          isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.arrow_forward_ios_rounded,
          color: AppColors.textSecondary,
          size: isExpanded ? 20 : 14,
        ),
      ),
    );
  }
}

class _ViewTrainingTextButton extends StatelessWidget {
  const _ViewTrainingTextButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: AppTextView.body4(
            AppStrings.seatProfileViewTrainings,
            color: onTap == null ? AppColors.textSecondary : AppColors.secondaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SeatProfileDottedRoundedBorderPainter extends CustomPainter {
  const _SeatProfileDottedRoundedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final inset = paint.strokeWidth / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - (inset * 2), size.height - (inset * 2)),
      Radius.circular(radius > inset ? radius - inset : radius),
    );
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeatProfileDottedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _ExpandableDescriptionText extends StatelessWidget {
  const _ExpandableDescriptionText({required this.description, this.onSeeAllTap});

  final String description;
  final VoidCallback? onSeeAllTap;

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
              InkWell(
                onTap: onSeeAllTap,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  child: Text(
                    AppStrings.seeAllAction,
                    style: TextStyle(
                      color: AppColors.secondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.secondaryColor,
                    ),
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

class _AuditSpecificsDialog extends StatelessWidget {
  const _AuditSpecificsDialog({required this.description});

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
                  const Expanded(
                    child: AppTextView.body1(
                      AppStrings.seatProfileAuditSpecifics,
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _AuditSpecificsDialogCloseButton(onTap: () => Navigator.of(context).pop()),
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

class _AuditSpecificsDialogCloseButton extends StatelessWidget {
  const _AuditSpecificsDialogCloseButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppOverlayCloseButton(onTap: onTap);
  }
}
