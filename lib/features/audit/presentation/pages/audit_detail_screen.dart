import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';
import 'package:sparrowkaizen/features/audit/presentation/pages/audit_select_team_member_filter_sheet.dart';
import 'package:sparrowkaizen/features/audit/presentation/widgets/evaluation_chat_widget.dart';
import 'package:sparrowkaizen/routes/app_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../data/datasources/audit_remote_data_source.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../domain/entities/audit_details.dart';
import '../../domain/usecases/get_audit_details_usecase.dart';
import '../../domain/usecases/get_audit_evaluation_chart_usecase.dart';
import '../../domain/usecases/get_audit_overview_usecase.dart';
import '../../domain/usecases/get_quarterly_audit_usecase.dart';
import '../providers/audit_controller.dart';
import '../widgets/upgrade_plan_dialog.dart';
import 'audit_single_description.dart';

class AuditDetailsScreen extends StatelessWidget {
  const AuditDetailsScreen({
    super.key,
    required this.profileJobId,
    this.year,
    this.quarter,
  });

  final String profileJobId;
  final int? year;
  final int? quarter;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuditRemoteDataSource>(
          create: (_) => createAuditRemoteDataSource(),
        ),
        ProxyProvider<AuditRemoteDataSource, AuditRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createAuditRepository(remoteDataSource),
        ),
        ProxyProvider<AuditRepositoryImpl, GetAuditOverviewUseCase>(
          update: (_, repository, __) =>
              createGetAuditOverviewUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, GetAuditDetailsUseCase>(
          update: (_, repository, __) =>
              createGetAuditDetailsUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, GetAuditEvaluationChartUseCase>(
          update: (_, repository, __) =>
              createGetAuditEvaluationChartUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, GetQuarterlyAuditUseCase>(
          update: (_, repository, __) =>
              createGetQuarterlyAuditUseCase(repository),
        ),
        ChangeNotifierProvider<AuditController>(
          create: (context) => AuditController(
            context.read<GetAuditOverviewUseCase>(),
            context.read<GetAuditDetailsUseCase>(),
            context.read<GetAuditEvaluationChartUseCase>(),
            context.read<GetQuarterlyAuditUseCase>(),
            null,
            null,
            null,
            context.read<AuditRepositoryImpl>(),
          )..initializeDetails(profileJobId, year: year, quarter: quarter),
        ),
      ],
      child: _AuditDetailsScreenView(
        profileJobId: profileJobId,
        year: year,
        quarter: quarter,
      ),
    );
  }
}

class _AuditDetailsScreenView extends StatelessWidget {
  const _AuditDetailsScreenView({
    required this.profileJobId,
    this.year,
    this.quarter,
  });
  final String profileJobId;
  final int? year;
  final int? quarter;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AuditController>();
    final state = controller.state;
    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 14, right: 14),
                child: Column(
                  children: [
                    _buildTitle(context),
                    const SizedBox(height: 18),
                    if (state.isLoading)
                      Expanded(
                        child: Center(child: FastCircularProgressIndicator()),
                      )
                    else if (state.details == null)
                      const Expanded(
                        child: Center(
                          child: AppTextView.body(
                            'No audit details found.',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else ...[
                      _buildHeaderSection(state.details!),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark3,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.only(
                            left: 14,
                            right: 14,
                            top: 12,
                          ),
                          child: Column(
                            children: [
                              _buildAuditListHeader(
                                context,
                                controller,
                                state.details!,
                              ),
                              const SizedBox(height: 6),

                              controller.showGraph
                                  ? Expanded(
                                      child: AuditEvaluationChartWidget(
                                        charts: state.evaluationCharts,
                                        isLoading:
                                            state.isEvaluationChartLoading,
                                      ),
                                    )
                                  : Expanded(
                                      child: _buildAuditListView(
                                        state.details!,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!state.isLoading && state.isOwner)
              _buildNewAuditButton(
                context,
                state.details,
                isAuditActionLoading: state.isAuditActionLoading,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: SvgPicture.asset(
                '${AppStrings.imagePath}back.svg',
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          AppTextView.body(
            AppStrings.checkInTitle,
            color: AppColors.secondaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(AuditDetails details) {
    final profileImage = CustomFunctions.resolveImageUrl(details.profileImage);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Card
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: profileImage == null
                            ? const AssetImage('lib/assets/images/dumy_pic.png')
                            : NetworkImage(profileImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppTextView.body1(
                    details.jobTitle,
                    color: AppColors.secondaryColor,
                    fontSize: 14,
                  ),
                  if (details.profileName.isNotEmpty)
                    AppTextView.body1(
                      details.profileName,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: '${AppStrings.lastAudit}: ',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.75,
                            ),
                            fontSize: 11,
                          ),
                        ),
                        TextSpan(
                          text: details.lastAuditDate,
                          style: const TextStyle(
                            color: AppColors.secondaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (details.profiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildProfilesList(details.profiles),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Stats Column
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildStatBox(
                  details.overallScore.toStringAsFixed(1),
                  AppStrings.runningOverallPerformance,
                  AppColors.green1,
                ),
                const SizedBox(height: 12),
                _buildStatBox(
                  '${details.confidenceLevel.round()}%',
                  AppStrings.confidenceLevel,
                  AppColors.orange1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark3,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.grey2.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppTextView.body1(
              value,
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            AppTextView.body2(
              label,
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditListHeader(
    BuildContext context,
    AuditController controller,
    AuditDetails details,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            AppTextView.body1(
              AppStrings.auditEvaluationChart,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),

            // const SizedBox(height: 4),
            // GestureDetector(
            //   onTap: () => _openAuditReport(context, details),
            //   child: const Text(
            //     'Check-in Report',
            //     style: TextStyle(
            //       color: AppColors.textPrimary,
            //       fontSize: 12,
            //       fontWeight: FontWeight.w500,
            //       decoration: TextDecoration.underline,
            //       decorationColor: AppColors.textPrimary,
            //     ),
            //   ),
            // ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (controller.showGraph) {
                  controller.setShowGraph(false);
                } else {
                  controller.showEvaluationChart(profileJobId);
                }
              },
              child: _buildGraphIcon(
                controller.showGraph ? 'chart.svg' : 'list.svg',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                openAuditTeamMemberFilterSheet(context, controller);
              },
              child: _buildFilterIcon(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraphIcon(String iconName) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      width: 34,
      height: 34,
      child: SvgPicture.asset('${AppStrings.imagePath}$iconName'),
    );
  }

  Widget _buildFilterIcon() {
    return Container(
      width: 34,
      height: 34,
      padding: EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: SvgPicture.asset('${AppStrings.imagePath}filter.svg'),
    );
  }

  Widget _buildAuditListView(AuditDetails details) {
    final isPastLastAuditDate = CustomFunctions.isDateBeforeToday(
      details.lastAuditDate,
    );
    final visibleAudits = isPastLastAuditDate
        ? details.audits
              .where((audit) => audit.totalRatings > 0)
              .toList(growable: false)
        : details.audits;

    if (visibleAudits.isEmpty) {
      return const Center(
        child: AppTextView.body(
          'No audits found.',
          color: AppColors.textSecondary,
        ),
      );
    }

    return ListView.separated(
      itemCount: visibleAudits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final audit = visibleAudits[index];

        return Material(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openSingleAuditDetails(context, details, audit.date),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.grey2.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextView.body1(
                        CustomFunctions.formatDate(audit.date),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppTextView.body2('Ratings: ', color: Colors.grey),
                          _buildRatingBadge(
                            value: audit.great,
                            color: AppColors.green1,
                          ),
                          _buildRatingBadge(
                            value: audit.almostThere,
                            color: AppColors.orange1,
                          ),
                          _buildRatingBadge(
                            value: audit.needsImprovement,
                            color: AppColors.red1,
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      _openSingleAuditDetails(context, details, audit.date);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 7,
                        bottom: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppTextView.body2(
                            AppStrings.view,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.north_east,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingBadge({required int value, required Color color}) {
    return Container(
      alignment: Alignment.center,
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: AppTextView.body2(
        '$value',
        color: AppColors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Future<void> _openSingleAuditDetails(
    BuildContext context,
    AuditDetails details,
    String date,
  ) async {
    await AppRouter.pushNamed(
      context,
      AppRouter.singleAuditDetails,
      arguments: SingleAuditDetailsRouteArgs(
        quarterlyAuditId: details.uuid,
        date: date,
        lastAuditDate: details.lastAuditDate,
        year: year,
        quarter: quarter,
      ),
    );

    if (!context.mounted) {
      return;
    }

    await _refreshDetailsAfterAuditReturn(context, details.profileJob);
  }

  Widget _buildNewAuditButton(
    BuildContext context,
    AuditDetails? details, {
    required bool isAuditActionLoading,
  }) {
    final hasDetails = details != null;
    final shouldStartNewAudit =
        hasDetails && CustomFunctions.shouldStartNewAudit(details);

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 20,
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14, right: 14, top: 12),
            child: hasDetails
                ? AppButton(
                    text: shouldStartNewAudit
                        ? AppStrings.newCheckIn
                        : 'Continue Check-in',
                    onPressed: isAuditActionLoading
                        ? null
                        : () => _handleAuditAction(
                            context,
                            details,
                            shouldStartNewAudit,
                          ),
                    isLoading: isAuditActionLoading,
                    minimumHeight: 40,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuditAction(
    BuildContext context,
    AuditDetails details,
    bool shouldStartNewAudit,
  ) async {
    if (!context.read<AuditController>().state.isOwner) {
      return;
    }

    if (context.read<AppManager>().showBillingBanner) {
      await showDialog<void>(
        context: context,
        builder: (_) => const UpgradePlanDialog(),
        barrierDismissible: false,
      );
      return;
    }

    final todayDate = CustomFunctions.apiDateString();
    final controller = context.read<AuditController>();
    if (controller.state.isAuditActionLoading) {
      return;
    }

    controller.setAuditActionLoading(true);

    try {
      if (shouldStartNewAudit) {
        controller.setAuditActionLoading(false);

        await AppRouter.pushNamed<void>(
          context,
          AppRouter.singleAuditDetails,
          arguments: SingleAuditDetailsRouteArgs(
            quarterlyAuditId: details.uuid,
            date: todayDate,
            lastAuditDate: details.lastAuditDate,
            year: year,
            quarter: quarter,
            requireDescriptionSelection: true,
          ),
        );

        if (!context.mounted) {
          return;
        }

        await _refreshDetailsAfterAuditReturn(context, details.profileJob);
        return;
      }

      final quarterlyAudit = await controller.loadQuarterlyAuditForDate(
        quarterlyAuditId: details.uuid,
        date: todayDate,
      );

      if (!context.mounted || quarterlyAudit == null) {
        return;
      }

      final description = CustomFunctions.resolveTargetAuditDescription(
        quarterlyAudit: quarterlyAudit,
        shouldStartNewAudit: shouldStartNewAudit,
      );
      if (description == null) {
        return;
      }

      controller.setAuditActionLoading(false);

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChangeNotifierProvider<AuditController>.value(
            value: controller,
            child: SingleDescriptionDetails(
              audit: quarterlyAudit,
              description: description,
              date: todayDate,
              isOwner: controller.state.isOwner,
              onAuditUpdated: () async {
                await _refreshControllerDetailsAfterAuditReturn(
                  controller,
                  details.profileJob,
                );
              },
            ),
          ),
        ),
      );

      if (!context.mounted) {
        return;
      }

      await _refreshDetailsAfterAuditReturn(context, details.profileJob);
    } finally {
      controller.setAuditActionLoading(false);
    }
  }

  Future<void> _refreshDetailsAfterAuditReturn(
    BuildContext context,
    String profileJobId,
  ) async {
    await _refreshControllerDetailsAfterAuditReturn(
      context.read<AuditController>(),
      profileJobId,
    );
  }

  Future<void> _refreshControllerDetailsAfterAuditReturn(
    AuditController controller,
    String profileJobId,
  ) async {
    await controller.initializeDetails(
      profileJobId,
      year: year,
      quarter: quarter,
      clearEvaluationCharts: !controller.showGraph,
    );

    if (controller.showGraph) {
      await controller.refreshEvaluationChart(profileJobId);
    }
  }

  Widget _buildProfilesList(List<AuditDetailsProfile> profiles) {
    const avatarSize = 26.0;
    const overlapOffset = 18.0;
    final visibleProfiles = profiles.take(5).toList(growable: false);
    final stackWidth = visibleProfiles.isEmpty
        ? 0.0
        : avatarSize + ((visibleProfiles.length - 1) * overlapOffset);

    return SizedBox(
      height: 34,
      width: stackWidth,
      child: Stack(
        children: [
          for (var index = 0; index < visibleProfiles.length; index++)
            Positioned(
              left: index * overlapOffset,
              child: _DetailProfileAvatar(
                imageUrl: visibleProfiles[index].image,
              ),
            ),
        ],
      ),
    );
  }

  openAuditTeamMemberFilterSheet(
    BuildContext context,
    AuditController controller,
  ) async {
    await showModalBottomSheet<AuditTeamMemberFilterSheet>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AuditTeamMemberFilterSheet(
          options: controller.teamMemberOptions,
        ),
      ),
    );
  }
}

class _DetailProfileAvatar extends StatelessWidget {
  const _DetailProfileAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(imageUrl);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textPrimary, width: 1.4),
        image: DecorationImage(
          image: resolvedImageUrl == null
              ? const AssetImage('lib/assets/images/dumy_pic.png')
              : NetworkImage(resolvedImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
