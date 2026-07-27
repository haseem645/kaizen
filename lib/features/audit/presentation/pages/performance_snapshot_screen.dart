import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparrowkaizen/core/widgets/fast_circular_progress.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../routes/app_router.dart';
import '../../data/datasources/audit_remote_data_source.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../domain/entities/audit_profile.dart';
import '../../domain/usecases/get_audit_overview_usecase.dart';
import '../providers/audit_controller.dart';
import '../providers/performance_snapshot_controller.dart';
import '../widgets/audit_search_bar.dart';
import '../widgets/performance_card.dart';
import 'audit_seat_profile_filter_sheet.dart';

class PerformanceSnapshotScreen extends StatelessWidget {
  const PerformanceSnapshotScreen({super.key});

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
        ChangeNotifierProvider<PerformanceSnapshotController>(
          create: (context) =>
              PerformanceSnapshotController(context.read<AuditRepositoryImpl>())
                ..initialize(),
        ),
      ],
      child: const _PerformanceSnapshotView(),
    );
  }
}

class _PerformanceSnapshotView extends StatelessWidget {
  const _PerformanceSnapshotView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PerformanceSnapshotController>();
    final data = controller.currentData;
    final visibleReports = controller.visibleReports;
    final showTeamReportsControls = controller.canAccessTeamReports;

    return DrawerMainScreen(
      title: AppStrings.performanceSnapshot,
      selectedMenu: AppMenuType.performanceSnapshot,
      centerTitle: true,
      child: SafeArea(
        top: false,
        bottom: false,
        child: controller.isInitialLoading
            ? FastCircularProgressIndicator()
            : ListView(
                controller: controller.scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (showTeamReportsControls) ...[
                    AuditSearchBar(
                      controller: controller.searchController,
                      onChanged: (_) {},
                      onFilterTap: () =>
                          _openSeatProfileFilter(context, controller),
                    ),
                    if (controller.selectedJobTitle != null) ...[
                      const SizedBox(height: 14),
                      _FilterTag(
                        label: controller.selectedJobTitle!,
                        onClear: controller.clearSelectedJobTitle,
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (controller.isFilterLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 18),
                        child: Center(
                          child: AppTextView.body2(
                            AppStrings.performanceSnapshotFilterLoading,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                  if (visibleReports.isEmpty)
                    _EmptyState(message: controller.emptyStateMessage)
                  else ...[
                    for (
                      var index = 0;
                      index < visibleReports.length;
                      index++
                    ) ...[
                      PerformanceSnapshotCard(
                        member: visibleReports[index],
                        actionLabel: 'View',
                        onAuditTap: () => _openReport(
                          context,
                          visibleReports[index],
                          controller.selectedTab ==
                              PerformanceSnapshotTab.myReports,
                        ),
                      ),
                      if (index != visibleReports.length - 1)
                        const SizedBox(height: 18),
                    ],
                    if (data.isLoadingMore) ...[
                      const SizedBox(height: 18),
                      Center(child: FastCircularProgressIndicator()),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _openSeatProfileFilter(
    BuildContext context,
    PerformanceSnapshotController controller,
  ) async {
    await controller.ensureJobOptionsLoaded();
    if (!context.mounted) {
      return;
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AuditSeatProfileFilterSheet(
          options: controller.jobOptions,
          initialValue: controller.selectedJobTitle,
          showAllOption: true,
          title: AppStrings.performanceSnapshotJob,
          allOptionLabel: AppStrings.performanceSnapshotAllJobs,
          searchHint: AppStrings.performanceSnapshotSearchJob,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    controller.setSelectedJobTitle(result);
  }

  Future<void> _openReport(
    BuildContext context,
    AuditProfile profile,
    bool isMyReport,
  ) {
    return AppRouter.pushNamed(
      context,
      AppRouter.reports,
      arguments: PerformanceReportRouteArgs(
        profile: profile,
        isMyReport: isMyReport,
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.lightPurple2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(999),
                child: const Icon(
                  Icons.close_outlined,
                  size: 14,
                  color: AppColors.purple2,
                ),
              ),
              const SizedBox(width: 8),
              AppTextView.body3(
                label,
                color: AppColors.purple2,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: AppTextView.body(
          message,
          color: AppColors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
