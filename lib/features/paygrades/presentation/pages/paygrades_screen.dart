import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/widgets/app_department_filter_strip.dart';
import '../../../../core/widgets/app_department_selection_sheet.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../../routes/app_router.dart';
import '../../../seat_profile/widgets/seat_profile_search_bar.dart';
import '../../data/datasources/paygrade_remote_data_source.dart';
import '../../data/repositories/paygrade_repository_impl.dart';
import '../../domain/entities/paygrade.dart';
import '../../domain/usecases/get_paygrades_usecase.dart';
import '../providers/paygrades_controller.dart';
import '../widgets/paygrade_listing_card.dart';

class PaygradesScreen extends StatelessWidget {
  const PaygradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PaygradeRemoteDataSource>(
          create: (_) => createPaygradeRemoteDataSource(),
        ),
        ProxyProvider<PaygradeRemoteDataSource, PaygradeRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createPaygradeRepository(remoteDataSource),
        ),
        ProxyProvider<PaygradeRepositoryImpl, GetPaygradesUseCase>(
          update: (_, repository, __) => createGetPaygradesUseCase(repository),
        ),
        ChangeNotifierProvider<PaygradesController>(
          create: (context) =>
              PaygradesController(context.read<GetPaygradesUseCase>()),
        ),
      ],
      child: const _PaygradesScreenView(),
    );
  }
}

class _PaygradesScreenView extends StatefulWidget {
  const _PaygradesScreenView();

  @override
  State<_PaygradesScreenView> createState() => _PaygradesScreenViewState();
}

class _PaygradesScreenViewState extends State<_PaygradesScreenView> {
  late final ScrollController _scrollController;
  late final PaygradesController _controller;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
    _controller = context.read<PaygradesController>();

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
    final controller = context.watch<PaygradesController>();

    return DrawerMainScreen(
      title: AppStrings.paygradesTitle,
      selectedMenu: AppMenuType.paygrades,
      centerTitle: true,
      child: SafeArea(
        top: false,
        bottom: false,
        child: controller.isInitialLoading
            ? FastCircularProgressIndicator()
            : _buildContent(controller),
      ),
    );
  }

  Widget _buildContent(PaygradesController controller) {
    final items = controller.items;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          SeatProfileSearchBar(
            controller: controller.searchController,
            onChanged: controller.updateSearchQuery,
            hintText: AppStrings.paygradesSearchHint,
            onFilterTap: controller.departments.isEmpty
                ? null
                : () => _openDepartmentSheet(controller),
          ),
          const SizedBox(height: 24),
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

  Widget _buildListArea(PaygradesController controller, List<Paygrade> items) {
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
        ...items.asMap().entries.map(
          (item) => Padding(
            padding: EdgeInsets.only(
              bottom: item.key == items.length - 1 ? 0 : 16,
            ),
            child: PaygradeListingCard(
              paygrade: item.value,
              onDetailsTap: () => AppRouter.pushNamed(
                context,
                AppRouter.paygradeDetail,
                arguments: PaygradeDetailRouteArgs(paygradeId: item.value.id),
              ),
            ),
          ),
        ),
        if (controller.isLoadingMore) ...[
          const SizedBox(height: 18),
          Center(child: FastCircularProgressIndicator()),
        ],
      ],
    );
  }

  List<AppDepartmentFilterItem> _departmentFilterItems(
    PaygradesController controller,
  ) {
    return <AppDepartmentFilterItem>[
      if (controller.hasGlobalDepartmentAccess)
        const AppDepartmentFilterItem(id: 'all', name: AppStrings.categoryAll),
      ...controller.departments.map(
        (department) =>
            AppDepartmentFilterItem(id: department.id, name: department.name),
      ),
    ];
  }

  Future<void> _openDepartmentSheet(PaygradesController controller) async {
    final departmentId = await showAppDepartmentSelectionSheet(
      context,
      items: _departmentFilterItems(controller),
      selectedDepartmentId: controller.selectedDepartmentId,
    );
    if (departmentId == null || !mounted) {
      return;
    }

    await controller.selectDepartment(departmentId);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AppTextView.body(
        AppStrings.paygradesNoItemsFound,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState(PaygradesController controller) {
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
}
