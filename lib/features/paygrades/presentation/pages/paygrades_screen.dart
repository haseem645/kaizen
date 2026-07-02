import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../../routes/app_router.dart';
import '../../../seat_profile/data/models/department_option.dart';
import '../../../seat_profile/widgets/seat_profile_search_bar.dart';
import '../../data/datasources/paygrade_remote_data_source.dart';
import '../../data/repositories/paygrade_repository_impl.dart';
import '../../domain/entities/paygrade.dart';
import '../../domain/usecases/get_paygrades_usecase.dart';
import '../providers/paygrades_controller.dart';

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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          SeatProfileSearchBar(
            controller: controller.searchController,
            onChanged: controller.updateSearchQuery,
            hintText: AppStrings.paygradesSearchHint,
          ),
          if (controller.departments.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildDepartmentStrip(controller),
          ],
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
        for (var index = 0; index < items.length; index++) ...[
          _PaygradeCard(paygrade: items[index]),
          if (index != items.length - 1) const SizedBox(height: 16),
        ],
        if (controller.isLoadingMore) ...[
          const SizedBox(height: 18),
          Center(child: FastCircularProgressIndicator()),
        ],
      ],
    );
  }

  Widget _buildDepartmentStrip(PaygradesController controller) {
    final items = controller.isOwner
        ? <DepartmentOption>[
            const DepartmentOption(id: 'all', name: 'ALL'),
            ...controller.departments.map(
              (department) =>
                  DepartmentOption(id: department.id, name: department.name),
            ),
          ]
        : controller.departments
              .map(
                (department) =>
                    DepartmentOption(id: department.id, name: department.name),
              )
              .toList(growable: false);
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, index) => controller.isOwner && index == 0
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
            : const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = controller.selectedDepartmentId == item.id;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => controller.selectDepartment(item.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

class _PaygradeCard extends StatefulWidget {
  const _PaygradeCard({required this.paygrade});

  final Paygrade paygrade;

  @override
  State<_PaygradeCard> createState() => _PaygradeCardState();
}

class _PaygradeCardState extends State<_PaygradeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final paygrade = widget.paygrade;

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
                      paygrade.seatName,
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
                _buildDepartmentRow(
                  AppStrings.paygradesDepartment,
                  paygrade.department,
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  AppStrings.paygradesPrimaryPaygrade,
                  paygrade.hasPrimaryPaygrade ? 'Yes' : 'No',
                  isStatus: true,
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  AppStrings.paygradesAncillaryPaygrade,
                  paygrade.hasAncillaryPaygrade ? 'Yes' : 'No',
                  isStatus: true,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () {
                    AppRouter.pushNamed(
                      context,
                      AppRouter.paygradeDetail,
                      arguments: PaygradeDetailRouteArgs(
                        paygradeId: paygrade.id,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTextView.body2(
                        AppStrings.paygradesDetailsTitle,
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

  Widget _buildDepartmentRow(String label, String value) {
    return Row(
      children: [
        AppTextView.body2(label, color: AppColors.textSecondary),
        Spacer(),
        AppTextView.body2(
          value,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ],
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
            padding: const EdgeInsets.only(right: 17),
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
