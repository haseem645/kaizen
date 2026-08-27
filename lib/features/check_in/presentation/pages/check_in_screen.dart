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
import '../../domain/entities/audit_member_status.dart';
import '../../domain/entities/audit_profile.dart';
import '../../domain/usecases/get_audit_overview_usecase.dart';
import '../providers/check_in_controller.dart';
import '../providers/check_in_state.dart';
import '../widgets/check_in_member_card.dart';
import '../widgets/check_in_search_bar.dart';
import '../widgets/check_in_status_switcher.dart';
import 'check_in_filter_sheet.dart';

class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

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
        ChangeNotifierProvider<CheckInController>(
          create: (context) => CheckInController(
            context.read<GetAuditOverviewUseCase>(),
            null,
            null,
            null,
            null,
            null,
            null,
            context.read<AuditRepositoryImpl>(),
          )..initialize(),
        ),
      ],
      child: _CheckInScreenView(),
    );
  }
}

class _CheckInScreenView extends StatefulWidget {
  const _CheckInScreenView();

  @override
  State<_CheckInScreenView> createState() => _CheckInScreenViewState();
}

class _CheckInScreenViewState extends State<_CheckInScreenView> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 360) {
      return;
    }

    context.read<CheckInController>().loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CheckInController>();
    final state = controller.state;

    _syncSearchController(state.searchQuery);

    return DrawerMainScreen(
      title: state.isOwner
          ? AppStrings.checkInTitle
          : AppStrings.auditMyCheckInTitle,
      selectedMenu: AppMenuType.audits,
      centerTitle: true,
      appBarActions: const [
        // Padding(
        //   padding: EdgeInsets.only(right: 12),
        //   child: Icon(
        //     Icons.notifications_none_rounded,
        //     color: AppColors.textPrimary,
        //     size: 30,
        //   ),
        // ),
      ],
      child: SafeArea(
        top: false,
        bottom: false,
        child: state.isLoading && state.mainList == null
            ? FastCircularProgressIndicator()
            : _buildContent(controller, state),
      ),
    );
  }

  void _syncSearchController(String value) {
    if (_searchController.text == value) {
      return;
    }

    _searchController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Widget _buildContent(CheckInController controller, CheckInState state) {
    final members = controller.visibleMembers;
    final showSearchAndFilter = state.isOwner;
    final showSelectionTabs = state.isOwner && !state.isActualOwner;
    final isSearchLoading =
        state.isLoading &&
        state.mainList != null &&
        state.searchQuery.trim().isNotEmpty;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (showSearchAndFilter) ...[
          if (showSelectionTabs) ...[
            CheckInStatusSwitcher(
              selectedStatus: state.selectedStatus,
              activeTitle: AppStrings.auditTeamMembersTab,
              deactivatedTitle: AppStrings.auditMyCheckInsTab,
              onStatusSelected: controller.selectStatus,
            ),
            const SizedBox(height: 22),
          ],
          CheckInSearchBar(
            controller: _searchController,
            onChanged: controller.updateSearchQuery,
            onClearTap: () {
              _searchController.clear();
              controller.resetSearch();
            },
            isSearchLoading: isSearchLoading,
            onFilterTap: () => _openFilterSheet(context, controller, state),
          ),
          if (controller.isSeatProfileFilterLoading) ...[
            const SizedBox(height: 14),
            const Center(
              child: AppTextView.body2(
                AppStrings.performanceSnapshotFilterLoading,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (state.selectedYearQuarter != null ||
              state.selectedSeatProfile != null) ...[
            const SizedBox(height: 14),
            _buildAppliedFilterTags(controller, state),
          ],
        ],
        const SizedBox(height: 18),
        if (members.isEmpty)
          _buildEmptyCheckInState(state.selectedStatus)
        else ...[
          for (var index = 0; index < members.length; index++) ...[
            CheckInMemberCard(
              member: members[index],
              onCheckInTap: () {
                final member = members[index];
                AppRouter.pushNamed(
                  context,
                  AppRouter.checkInDetails,
                  arguments: CheckInDetailsRouteArgs(
                    profileJobId: member is AuditProfile
                        ? member.profileJob
                        : '',
                    year: controller.selectedAuditYear,
                    quarter: controller.selectedAuditQuarter,
                    selectedProfileUuid: member is AuditProfile
                        ? member.profileUuid
                        : null,
                  ),
                );
              },
            ),
            if (index != members.length - 1) const SizedBox(height: 18),
          ],
          if (state.isLoadingMore) ...[
            const SizedBox(height: 18),
            Center(child: FastCircularProgressIndicator()),
          ],
        ],
      ],
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    CheckInController controller,
    CheckInState state,
  ) async {
    await controller.ensureSeatProfileOptionsLoaded();
    if (!context.mounted) {
      return;
    }

    final result = await showModalBottomSheet<CheckInFilterResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CheckInFilterSheet(
          yearQuarterOptions: controller.yearQuarterOptions,
          seatProfileOptions: controller.seatProfileOptions,
          initialYearQuarter: controller.selectedAuditYearQuarterLabel,
          initialSeatProfile: state.selectedSeatProfile,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    await controller.applyFilters(
      yearQuarter: result.yearQuarter,
      seatProfile: result.seatProfile,
    );
  }

  Widget _buildAppliedFilterTags(
    CheckInController controller,
    CheckInState state,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (state.selectedYearQuarter != null)
          _buildFilterTag(
            label: state.selectedYearQuarter!,
            onRemove: () {
              controller.clearYearQuarterFilter();
            },
          ),
        if (state.selectedSeatProfile != null)
          _buildFilterTag(
            label: state.selectedSeatProfile!,
            onRemove: controller.clearSeatProfileFilter,
          ),
      ],
    );
  }

  Widget _buildFilterTag({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.lightPurple2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Icon(
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
    );
  }

  Widget _buildEmptyCheckInState(AuditMemberStatus status) {
    final state = context.read<CheckInController>().state;
    final statusLabel = switch ((state.isActualOwner, state.isOwner, status)) {
      (true, _, AuditMemberStatus.active) =>
        AppStrings.auditActive.toLowerCase(),
      (true, _, AuditMemberStatus.deactivated) =>
        AppStrings.auditDeactivated.toLowerCase(),
      (false, true, AuditMemberStatus.active) =>
        AppStrings.auditTeamMembersTab.toLowerCase(),
      (false, true, AuditMemberStatus.deactivated) =>
        AppStrings.auditMyCheckInsTab.toLowerCase(),
      (false, false, _) => AppStrings.auditMyCheckInsTab.toLowerCase(),
    };
    final message = state.isActualOwner
        ? '${AppStrings.nothingFound}\nTry a different search for $statusLabel members.'
        : AppStrings.auditNoStatusAvailable(statusLabel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AppTextView.body(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
        height: 1.5,
      ),
    );
  }
}
