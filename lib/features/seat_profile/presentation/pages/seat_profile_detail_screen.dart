import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/preference/app_preference.dart';
import '../../../../core/widgets/app_ai_generate_button.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../core/widgets/app_dialog_style.dart';
import '../../../../core/widgets/app_dot_divider.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_share_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../../routes/app_router.dart';
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
import 'seat_profile_share_dialogue.dart';

class SeatProfileDetailScreen extends StatelessWidget {
  const SeatProfileDetailScreen({super.key, required this.seatId, this.getSeatProfilesUseCase});

  final String seatId;
  final GetSeatProfilesUseCase? getSeatProfilesUseCase;

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
          create: (context) => SeatProfileDetailController(
            getSeatProfilesUseCase ?? context.read<GetSeatProfilesUseCase>(),
          )..initialize(seatId),
        ),
      ],
      child: const SeatProfileDetailView(),
    );
  }
}

class SeatProfileDetailView extends StatelessWidget {
  const SeatProfileDetailView({super.key, this.isShared = false});

  final bool isShared;

  void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    final destination = AppPreference.getAuthToken().trim().isEmpty
        ? AppRouter.login
        : AppRouter.defaultAuthenticatedRouteName;
    navigator.pushReplacementNamed(destination);
  }

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
          onPressed: () => isShared ? _goBack(context) : Navigator.of(context).pop(),
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
              final canManageContent = !isShared && _canManageSeatProfile(detail);

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
                          _buildSeatSummary(
                            detail,
                            onShare: !isShared && (controller.shareController?.canManage ?? false)
                                ? () => showSeatProfileShareDialogue(
                                    context,
                                    controller.shareController!,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 18),
                          if (!isShared) ...[
                            _DetailActionRow(
                              controller: controller,
                              canManageContent: canManageContent,
                              onUpdateCategory: () =>
                                  _showManageSeatCategoriesDialog(context, controller),
                              onGenerate: () => _showGenerateSeatContentSheet(context, controller),
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (detail.categories.isEmpty)
                            _buildMessage(AppStrings.seatProfileNoCategoriesFound)
                          else
                            ...detail.categories.map(
                              (category) => Padding(
                                key: ValueKey(category.id),
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _CategoryCard(
                                  controller: controller,
                                  isExpanded: controller.isCategoryExpanded(category.id),
                                  canManageContent: canManageContent,
                                  isShared: isShared,
                                  seatProfileId: detail.id,
                                  seatProfileResolvedId: detail.resolvedSeatId,
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
    if (!_canManageSeatProfile(controller.detail)) {
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
    if (!_canManageSeatProfile(controller.detail)) {
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
    if (!_canManageSeatProfile(controller.detail)) {
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
    if (!_canManageSeatProfile(controller.detail)) {
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
    if (!_canManageSeatProfile(controller.detail)) {
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (_) =>
          _DeleteSeatDescriptionDialog(controller: controller, description: description),
    );
  }

  Widget _buildSeatSummary(SeatProfileDetail detail, {VoidCallback? onShare}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextView.body1(
                  detail.title,
                  color: AppColors.secondaryColor,
                  fontWeight: FontWeight.w700,
                ),
                if ((detail.department?.name ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppTextView.body2(
                    detail.department!.name,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ],
            ),
          ),
          if (onShare != null) ...[const SizedBox(width: 12), AppShareButton(onTap: onShare)],
        ],
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: AppTextView.body(message, color: AppColors.textSecondary, textAlign: TextAlign.center),
    );
  }

  bool _canManageSeatProfile(SeatProfileDetail? detail) {
    final departmentId = detail?.department?.id.trim() ?? '';
    return AppManager.instance.canCurrentUserManageSeatProfileDepartment(
      departmentId: departmentId,
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
          child: AppAiGenerateButton(
            label: AppStrings.seatProfileGenerateAction,
            expand: true,
            minHeight: 40,
            showOutline: true,
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

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.controller,
    required this.isExpanded,
    required this.canManageContent,
    required this.isShared,
    required this.seatProfileId,
    required this.seatProfileResolvedId,
    required this.category,
    required this.onOpenDescription,
    required this.onDeleteDescription,
    required this.onAddDescription,
  });

  final SeatProfileDetailController controller;
  final bool isExpanded;
  final bool canManageContent;
  final bool isShared;
  final String seatProfileId;
  final String seatProfileResolvedId;
  final SeatProfileCategory category;
  final ValueChanged<SeatProfileDescription> onOpenDescription;
  final ValueChanged<SeatProfileDescription> onDeleteDescription;
  final VoidCallback onAddDescription;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  static const _expandDuration = Duration(milliseconds: 320);
  static const _collapseDuration = Duration(milliseconds: 280);

  late final AnimationController _expansionController;
  late final CurvedAnimation _expansion;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      vsync: this,
      duration: _expandDuration,
      reverseDuration: _collapseDuration,
      value: widget.isExpanded ? 1 : 0,
    );
    _expansion = CurvedAnimation(parent: _expansionController, curve: Curves.easeInOutCubic);
    _chevronTurns = Tween<double>(begin: -0.25, end: 0).animate(_expansion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    _expansionController
      ..duration = disableAnimations ? Duration.zero : _expandDuration
      ..reverseDuration = disableAnimations ? Duration.zero : _collapseDuration;
  }

  @override
  void didUpdateWidget(covariant _CategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expansion.dispose();
    _expansionController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    final controller = widget.controller;
    final categoryId = widget.category.id;
    controller.setCategoryExpanded(categoryId, !controller.isCategoryExpanded(categoryId));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryCardHeader(
            category: widget.category,
            chevronTurns: _chevronTurns,
            onToggle: _toggleExpansion,
          ),
          // Keep the header fixed and retain the body during interrupted transitions.
          SizeTransition(
            sizeFactor: _expansion,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _expansion,
              child: AnimatedBuilder(
                animation: _expansionController,
                builder: (context, child) {
                  final canInteract = widget.isExpanded && _expansionController.isCompleted;
                  return IgnorePointer(
                    ignoring: !canInteract,
                    child: ExcludeSemantics(
                      excluding: !canInteract,
                      child: ExcludeFocus(excluding: !canInteract, child: child!),
                    ),
                  );
                },
                child: _CategoryCardDescriptions(
                  controller: widget.controller,
                  canManageContent: widget.canManageContent,
                  isShared: widget.isShared,
                  seatProfileId: widget.seatProfileId,
                  seatProfileResolvedId: widget.seatProfileResolvedId,
                  category: widget.category,
                  onOpenDescription: widget.onOpenDescription,
                  onDeleteDescription: widget.onDeleteDescription,
                  onAddDescription: widget.onAddDescription,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCardHeader extends StatelessWidget {
  const _CategoryCardHeader({
    required this.category,
    required this.chevronTurns,
    required this.onToggle,
  });

  final SeatProfileCategory category;
  final Animation<double> chevronTurns;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
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
        _CategoryToggleBadge(turns: chevronTurns, onTap: onToggle),
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

class _CategoryCardDescriptions extends StatelessWidget {
  const _CategoryCardDescriptions({
    required this.controller,
    required this.canManageContent,
    required this.isShared,
    required this.seatProfileId,
    required this.seatProfileResolvedId,
    required this.category,
    required this.onOpenDescription,
    required this.onDeleteDescription,
    required this.onAddDescription,
  });

  final SeatProfileDetailController controller;
  final bool canManageContent;
  final bool isShared;
  final String seatProfileId;
  final String seatProfileResolvedId;
  final SeatProfileCategory category;
  final ValueChanged<SeatProfileDescription> onOpenDescription;
  final ValueChanged<SeatProfileDescription> onDeleteDescription;
  final VoidCallback onAddDescription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (category.descriptions.isEmpty)
          AppTextView.body2(
            AppStrings.seatProfileNoDescriptionsFound,
            color: AppColors.textSecondary,
          )
        else
          ...category.descriptions.map(
            (description) => Padding(
              key: ValueKey(description.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: _InlineDescriptionCard(
                controller: controller,
                canManageContent: canManageContent,
                isShared: isShared,
                seatProfileId: seatProfileId,
                seatProfileResolvedId: seatProfileResolvedId,
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
    );
  }
}

class _InlineDescriptionCard extends StatelessWidget {
  const _InlineDescriptionCard({
    required this.controller,
    required this.canManageContent,
    required this.isShared,
    required this.seatProfileId,
    required this.seatProfileResolvedId,
    required this.categoryId,
    required this.description,
    required this.onOpenDescription,
    required this.onDeleteDescription,
  });

  final SeatProfileDetailController controller;
  final bool canManageContent;
  final bool isShared;
  final String seatProfileId;
  final String seatProfileResolvedId;
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
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.circular(12),
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
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  AppTextView.body3(
                    '${AppStrings.seatProfileMilestoneDays}:',
                    color: AppColors.textSecondary,
                  ),
                  AppTextView.body3(
                    seatProfileDescriptionMilestoneLabel(description.milestoneDays),
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  AppTextView.body3(
                    '${AppStrings.seatProfileCheckInType}:',
                    color: AppColors.textSecondary,
                  ),
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
              if (!isShared) ...[
                const SizedBox(height: 12),
                _DescriptionActionRow(
                  canEdit: canManageContent,
                  onEditTap: isDeleting ? null : onOpenDescription,
                  onTrainingTap: isDeleting ? null : () => _openTrainingModules(context),
                ),
              ],
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
          canManageTraining: AppManager.instance.canCurrentUserManageTrainingForSeatProfile(
            seatProfileId: seatProfileId,
            additionalSeatProfileIds: <String>[seatProfileResolvedId],
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
                : SvgPicture.asset(
                    '${AppStrings.imagePath}delete.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(AppColors.red1, BlendMode.srcIn),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CategoryToggleBadge extends StatelessWidget {
  const _CategoryToggleBadge({required this.turns, required this.onTap});

  final Animation<double> turns;
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
        child: RotationTransition(
          turns: turns,
          child: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _DescriptionActionRow extends StatelessWidget {
  const _DescriptionActionRow({
    required this.canEdit,
    required this.onEditTap,
    required this.onTrainingTap,
  });

  final bool canEdit;
  final VoidCallback? onEditTap;
  final VoidCallback? onTrainingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canEdit)
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _DescriptionActionTextButton(
                label: AppStrings.seatProfileEditAction,
                onTap: onEditTap,
              ),
            ),
          ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: _DescriptionActionTextButton(
              label: AppStrings.seatProfileViewTrainings,
              onTap: onTrainingTap,
            ),
          ),
        ),
      ],
    );
  }
}

class _DescriptionActionTextButton extends StatelessWidget {
  const _DescriptionActionTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: AppTextView.body4(
            label,
            fontSize: 12,
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

  static const _maxLines = 7;
  static const _linkPadding = 2.0;

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style.merge(
      const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: description, style: textStyle),
          maxLines: _maxLines,
          textScaler: textScaler,
          textDirection: textDirection,
        )..layout(maxWidth: constraints.maxWidth);

        try {
          if (!textPainter.didExceedMaxLines) {
            return Text(description, style: textStyle, maxLines: _maxLines);
          }
          return _buildEllipsizedText(
            textPainter: textPainter,
            textStyle: textStyle,
            textScaler: textScaler,
            textDirection: textDirection,
            maxWidth: constraints.maxWidth,
          );
        } finally {
          textPainter.dispose();
        }
      },
    );
  }

  Widget _buildEllipsizedText({
    required TextPainter textPainter,
    required TextStyle textStyle,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required double maxWidth,
  }) {
    final linkStyle = textStyle.copyWith(
      color: AppColors.secondaryColor,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.secondaryColor,
    );
    final linkScale = textScaler.scale(12) / 12;
    final scaledPadding = _linkPadding * linkScale;
    final linkPainter = TextPainter(
      text: TextSpan(text: AppStrings.seeAllAction, style: linkStyle),
      textScaler: textScaler,
      textDirection: textDirection,
    )..layout(maxWidth: (maxWidth - scaledPadding * 2).clamp(0, double.infinity));

    final link = WidgetSpan(
      style: linkStyle,
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: InkWell(
        onTap: onSeeAllTap,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.all(_linkPadding),
          child: Text(AppStrings.seeAllAction, style: linkStyle),
        ),
      ),
    );

    try {
      textPainter.text = TextSpan(style: textStyle, children: [link]);
      textPainter.setPlaceholderDimensions([
        PlaceholderDimensions(
          size: Size(linkPainter.width + scaledPadding * 2, linkPainter.height + scaledPadding * 2),
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          baselineOffset:
              linkPainter.computeDistanceToActualBaseline(TextBaseline.alphabetic) + scaledPadding,
        ),
      ]);

      final characters = description.characters.toList(growable: false);
      TextSpan preview(int length) => TextSpan(
        style: textStyle,
        children: [
          TextSpan(
            text:
                '${characters.take(length).join().trimRight()}${AppStrings.seatProfileDescriptionEllipsis}',
          ),
          link,
        ],
      );

      // Reserve room for the inline link without splitting an emoji or exceeding the preview.
      var lower = 0;
      var upper = characters.length;
      while (lower < upper) {
        final middle = (lower + upper + 1) ~/ 2;
        textPainter.text = preview(middle);
        textPainter.layout(maxWidth: maxWidth);
        if (textPainter.didExceedMaxLines) {
          upper = middle - 1;
        } else {
          lower = middle;
        }
      }
      return Text.rich(preview(lower), maxLines: _maxLines);
    } finally {
      linkPainter.dispose();
    }
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
      shape: AppDialogStyle.shape(radius: 24),
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
