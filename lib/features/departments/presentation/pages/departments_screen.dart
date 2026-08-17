import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../seat_profile/domain/entities/department.dart';
import '../../../seat_profile/widgets/seat_profile_search_bar.dart';
import '../../data/datasources/departments_remote_data_source.dart';
import '../../data/repositories/departments_repository_impl.dart';
import '../../domain/usecases/manage_departments_use_case.dart';
import '../models/department_color_option.dart';
import '../providers/departments_controller.dart';
import 'department_edit_dialog.dart';

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DepartmentsRemoteDataSource>(
          create: (_) => createDepartmentsRemoteDataSource(),
        ),
        ProxyProvider<DepartmentsRemoteDataSource, DepartmentsRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createDepartmentsRepository(remoteDataSource),
        ),
        ProxyProvider<DepartmentsRepositoryImpl, ManageDepartmentsUseCase>(
          update: (_, repository, __) =>
              createManageDepartmentsUseCase(repository),
        ),
        ChangeNotifierProvider<DepartmentsController>(
          create: (context) =>
              DepartmentsController(context.read<ManageDepartmentsUseCase>()),
        ),
      ],
      child: const _DepartmentsScreenView(),
    );
  }
}

class _DepartmentsScreenView extends StatefulWidget {
  const _DepartmentsScreenView();

  @override
  State<_DepartmentsScreenView> createState() => _DepartmentsScreenViewState();
}

class _DepartmentsScreenViewState extends State<_DepartmentsScreenView> {
  late final DepartmentsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = context.read<DepartmentsController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _controller.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DepartmentsController>();

    return DrawerMainScreen(
      title: AppStrings.departmentsTitle,
      selectedMenu: AppMenuType.departments,
      centerTitle: true,
      child: SafeArea(
        top: false,
        bottom: false,
        child: controller.isInitialLoading
            ? Center(child: FastCircularProgressIndicator())
            : _buildContent(controller),
      ),
    );
  }

  Widget _buildContent(DepartmentsController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          SeatProfileSearchBar(
            controller: controller.searchController,
            onChanged: controller.updateSearchQuery,
            hintText: AppStrings.departmentsSearchHint,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: _buildListArea(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListArea(DepartmentsController controller) {
    final items = controller.departments;

    if (controller.errorMessage != null && items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [_ErrorStateCard(controller: controller)],
      );
    }

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _EmptyStateCard(
            message: controller.hasSearchQuery
                ? AppStrings.departmentsNoSearchResults
                : AppStrings.departmentsNoItemsFound,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final department = items[index];
        return _DepartmentCard(
          department: department,
          onEditTap: () => _openEditDialog(department),
        );
      },
    );
  }

  Future<void> _openEditDialog(Department department) async {
    final didSave = await showEditDepartmentDialog(
      context,
      department: department,
      onSave: (name, colorHex) {
        return _controller.updateDepartment(
          department: department,
          name: name,
          colorHex: colorHex,
        );
      },
    );

    if (!mounted || !didSave) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: AppTextView.body2(AppStrings.departmentsUpdateSuccess),
        ),
      );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department, required this.onEditTap});

  final Department department;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final color = DepartmentColorPalette.resolveColor(department.colorHex);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.16),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AppTextView.body2(
              department.name,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onEditTap,
            icon: const Icon(
              Icons.edit_rounded,
              color: AppColors.secondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }
}

class _ErrorStateCard extends StatelessWidget {
  const _ErrorStateCard({required this.controller});

  final DepartmentsController controller;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            child: AppButton(
              text: AppStrings.departmentsRetryAction,
              onPressed: controller.initialize,
              borderRadius: 14,
              minimumHeight: 46,
            ),
          ),
        ],
      ),
    );
  }
}
