import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/widgets/app_gradient_action_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../../routes/app_router.dart';
import '../../data/datasources/seat_profile_remote_data_source.dart';
import '../../data/models/department_option.dart';
import '../../data/repositories/seat_profile_repository_impl.dart';
import '../../domain/entities/seat_profile.dart';
import '../../domain/usecases/get_seat_profiles_usecase.dart';
import '../../widgets/seat_profile_search_bar.dart';
import '../providers/seat_profile_controller.dart';
import 'seat_profile_filter_sheet.dart';

class SeatProfileScreen extends StatelessWidget {
  const SeatProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SeatProfileRemoteDataSource>(
          create: (_) => createSeatProfileRemoteDataSource(),
        ),
        ProxyProvider<SeatProfileRemoteDataSource, SeatProfileRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createSeatProfileRepository(remoteDataSource),
        ),
        ProxyProvider<SeatProfileRepositoryImpl, GetSeatProfilesUseCase>(
          update: (_, repository, __) =>
              createGetSeatProfilesUseCase(repository),
        ),
        ChangeNotifierProvider<SeatProfileController>(
          create: (context) =>
              SeatProfileController(context.read<GetSeatProfilesUseCase>()),
        ),
      ],
      child: const _SeatProfileScreenView(),
    );
  }
}

class _SeatProfileScreenView extends StatefulWidget {
  const _SeatProfileScreenView();

  @override
  State<_SeatProfileScreenView> createState() => _SeatProfileScreenViewState();
}

class _SeatProfileScreenViewState extends State<_SeatProfileScreenView> {
  late final ScrollController _scrollController;
  late final SeatProfileController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _controller = context.read<SeatProfileController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _controller.initialize();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 360) {
      return;
    }

    _controller.loadNextPage();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SeatProfileController>();

    return DrawerMainScreen(
      title: AppStrings.seatProfileTitle,
      selectedMenu: AppMenuType.seatProfiles,
      centerTitle: true,
      appBarActions: <Widget>[
        _SeatProfileCreateAction(onTap: () => _openCreateSeatProfile(context)),
      ],
      child: SafeArea(
        top: false,
        bottom: false,
        child: controller.isInitialLoading
            ? FastCircularProgressIndicator()
            : _buildContent(context, controller),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SeatProfileController controller) {
    final items = controller.visibleItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          SeatProfileSearchBar(
            controller: controller.searchController,
            onChanged: controller.updateSearchQuery,
            onFilterTap: () => _openFilterSheet(context, controller),
            hintText: AppStrings.seatProfileSearchHint,
          ),
          const SizedBox(height: 14),
          _buildDepartmentStrip(controller),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: _buildListArea(controller, items),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListArea(
    SeatProfileController controller,
    List<SeatProfile> items,
  ) {
    if (controller.isListLoading) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 32),
          Center(child: FastCircularProgressIndicator()),
        ],
      );
    }

    if (controller.errorMessage != null && items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [_buildErrorState(controller)],
      );
    }

    if (items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [_buildEmptyState()],
      );
    }

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _SeatProfileCard(profile: items[index]),
          if (index != items.length - 1) const SizedBox(height: 16),
        ],
        if (controller.isLoadingMore) ...[
          const SizedBox(height: 18),
          Center(child: FastCircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildDepartmentStrip(SeatProfileController controller) {
    final items = <DepartmentOption>[
      const DepartmentOption(id: 'all', name: 'ALL'),
      ...controller.departments.map(
        (department) =>
            DepartmentOption(id: department.id, name: department.name),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AppTextView.body2(
        //   AppStrings.seatProfileDepartmentsTitle,
        //   color: AppColors.textSecondary,
        //   fontWeight: FontWeight.w600,
        // ),
        // const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, index) => index == 0
                ? Row(
                    children: [
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppColors.fieldBorder.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = controller.selectedDepartmentId == item.id;

              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => controller.selectDepartment(item.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondaryColor
                        : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.secondaryColor
                          : AppColors.fieldBorder.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Center(
                    child: AppTextView.body3(
                      item.name,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AppTextView.body(
        AppStrings.seatProfileNoItemsFound,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState(SeatProfileController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          AppTextView.body(
            controller.errorMessage ?? AppStrings.loginSomethingWentWrong,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: controller.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateSeatProfile(BuildContext context) async {
    if (!AppManager.instance.currentUserCanCreateSeatProfiles) {
      return;
    }

    final didCreate = await AppRouter.pushNamed(
      context,
      AppRouter.seatProfileCreate,
    );
    if (didCreate != true || !mounted) {
      return;
    }

    await _controller.refresh();
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    SeatProfileController controller,
  ) async {
    final selectedFilter = await showModalBottomSheet<SeatProfileFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          SeatProfileFilterSheet(selectedFilter: controller.selectedFilter),
    );

    if (selectedFilter == null) {
      return;
    }

    controller.selectFilter(selectedFilter);
  }
}

class _SeatProfileCreateAction extends StatelessWidget {
  const _SeatProfileCreateAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppManager.instance,
      builder: (context, _) {
        if (!AppManager.instance.currentUserCanCreateSeatProfiles) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AppGradientActionButton(
            label: AppStrings.seatProfileCreateAction,
            icon: Icons.add_rounded,
            iconSize: 14,
            textSize: 12,
            minHeight: 34,
            borderRadius: 10,
            iconSpacing: 6,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            onTap: onTap,
          ),
        );
      },
    );
  }
}

class _SeatProfileCard extends StatefulWidget {
  const _SeatProfileCard({required this.profile});

  final SeatProfile profile;

  @override
  State<_SeatProfileCard> createState() => _SeatProfileCardState();
}

class _SeatProfileCardState extends State<_SeatProfileCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(8),
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
                      profile.name,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CardForwardArrow(isExpanded: _isExpanded),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 14),
                _buildStatRow(
                  AppStrings.seatProfileCategoriesCount,
                  '${profile.categoriesCount}',
                  isStatus: false,
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  AppStrings.seatProfileDescriptionsCount,
                  '${profile.descriptionsCount}',
                  isStatus: false,
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  AppStrings.seatProfilePrimaryPaygrade,
                  profile.hasPrimaryPaygrade ? 'Yes' : 'No',
                  isStatus: true,
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  AppStrings.seatProfileAncillaryPaygrade,
                  profile.hasAncillaryPaygrade ? 'Yes' : 'No',
                  isStatus: true,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    AppRouter.pushNamed(
                      context,
                      AppRouter.seatProfileDetail,
                      arguments: SeatProfileDetailRouteArgs(
                        seatId: profile.resolvedDetailId,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextView.body2(
                        AppStrings.seatProfileDetailsTitle,
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {required bool isStatus}) {
    final isPositive = value == 'Yes';

    return Row(
      children: [
        Expanded(
          child: AppTextView.body2(label, color: AppColors.textSecondary),
        ),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.lightGreen1 : AppColors.red1)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isPositive ? AppColors.lightGreen1 : AppColors.red1,
              ),
            ),
            child: AppTextView.body3(
              value,
              color: isPositive ? AppColors.lightGreen1 : AppColors.red1,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          Padding(
            padding: EdgeInsets.only(right: 17),
            child: AppTextView.body2(
              value,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _CardForwardArrow extends StatelessWidget {
  const _CardForwardArrow({required this.isExpanded});

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
