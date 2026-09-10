import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../check_in/data/datasources/audit_remote_data_source.dart';
import '../../../check_in/data/repositories/audit_repository_impl.dart';
import '../../domain/entities/seat_description_training.dart';
import '../../domain/entities/seat_description_training_route.dart';
import '../controllers/training_module_controller.dart';
import '../controllers/training_tab_navigation_controller.dart';
import '../models/view_training_tab_access.dart';
import '../widgets/training_tab_view.dart';
import 'edit_training_screen.dart';

part '../widgets/view_training/view_training_content.dart';

class ViewTrainingScreen extends StatelessWidget {
  const ViewTrainingScreen({super.key, required this.trainingRoute});

  final SeatDescriptionTrainingRoute trainingRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuditRemoteDataSource>(create: (_) => AuditRemoteDataSource()),
        ProxyProvider<AuditRemoteDataSource, AuditRepositoryImpl>(
          update: (_, remoteDataSource, __) => AuditRepositoryImpl(remoteDataSource),
        ),
        ChangeNotifierProvider<TrainingModuleController>(
          create: (context) =>
              TrainingModuleController(
                context.read<AuditRepositoryImpl>(),
                canManageTraining: false,
              )..initialize(
                jobId: trainingRoute.job,
                descriptionId: trainingRoute.description,
                initialModuleId: trainingRoute.initialModuleId,
              ),
        ),
      ],
      child: const _ViewTrainingScreenView(),
    );
  }
}

class _ViewTrainingScreenView extends StatefulWidget {
  const _ViewTrainingScreenView();

  @override
  State<_ViewTrainingScreenView> createState() => _ViewTrainingScreenViewState();
}

class _ViewTrainingScreenViewState extends State<_ViewTrainingScreenView> {
  late final TrainingModuleController _trainingController;
  final TrainingTabNavigationController _navigation = TrainingTabNavigationController();
  int _lastHandledTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _trainingController = context.read<TrainingModuleController>();
    _trainingController.addListener(_handleTrainingModuleChanged);
    _navigation.addListener(_handleTabChanged);
    AppManager.instance.addListener(_handleTrainingModuleChanged);
  }

  @override
  void dispose() {
    AppManager.instance.removeListener(_handleTrainingModuleChanged);
    _trainingController.removeListener(_handleTrainingModuleChanged);
    _navigation.removeListener(_handleTabChanged);
    _navigation.dispose();
    super.dispose();
  }

  int get _maxTabIndex =>
      _trainingController.canAccessSelectedModuleExtras ? trainingViewerTabCount - 1 : 0;

  int _coerceSelectedTab() {
    final index = _trainingController.canAccessSelectedModuleExtras
        ? normalizeTrainingViewerTabIndex(
            isPubliclyAvailable: _trainingController.isSelectedModulePubliclyAvailable,
            tabIndex: _navigation.selectedIndex,
            isChildOrganization: AppManager.instance.isCurrentOrganizationChild,
          )
        : 0;
    if (_navigation.selectedIndex != index) _navigation.selectTab(index);
    return index;
  }

  void _handleTrainingModuleChanged() {
    if (mounted) _coerceSelectedTab();
  }

  void _handleTabChanged() {
    final index = _coerceSelectedTab();
    if (_lastHandledTabIndex == index) return;
    _lastHandledTabIndex = index;
    unawaited(_syncSelectedTabData(index));
  }

  Future<void> _selectModule(String moduleId) async {
    if (moduleId != _trainingController.selectedModuleId) {
      await _trainingController.selectModule(moduleId);
      if (!mounted) return;
    }
    await _syncSelectedTabData(_coerceSelectedTab());
  }

  Future<void> _syncSelectedTabData(int index) async {
    switch (index) {
      case 1:
        await _trainingController.loadDocumentForSelectedModule();
      case 2:
        await _trainingController.loadQuestionsForSelectedModule();
      case 3:
        await _trainingController.loadAssignmentForSelectedModule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();
    return AnimatedBuilder(
      animation: AppManager.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.mainBg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                child: _buildHeader(context),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildBody(controller),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: controller.modules.isEmpty
            ? null
            : SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: TrainingTabs(navigation: _navigation, maxTabIndex: _maxTabIndex),
              ),
      ),
    );
  }

  Widget _buildBody(TrainingModuleController controller) {
    if (controller.isLoading && controller.modules.isEmpty) {
      return const Center(child: FastCircularProgressIndicator());
    }
    if (controller.modules.isEmpty) {
      return _CenteredMessage(
        message: controller.errorMessage ?? AppStrings.trainingNoModulesAvailable,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrainingLessonSelector(controller: controller, onModuleSelected: _selectModule),
        Expanded(
          child: TrainingTabView(
            navigation: _navigation,
            maxTabIndex: _maxTabIndex,
            pagePaddingBuilder: (index) =>
                index == 2 ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8),
            pageBuilder: (context, index) => _buildTabPage(controller, index),
          ),
        ),
      ],
    );
  }

  Widget _buildTabPage(TrainingModuleController controller, int index) {
    final content = _buildTabContent(controller, index);
    if (index == 1 || index == 3) return content;
    return SingleChildScrollView(
      key: PageStorageKey<String>('${controller.selectedModuleId}:$index'),
      primary: false,
      padding: const EdgeInsets.only(bottom: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (index == 0 && controller.selectedModuleTitle.isNotEmpty) ...[
            AppTextView.body1(
              controller.selectedModuleTitle,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 14),
          ],
          content,
        ],
      ),
    );
  }

  Widget _buildTabContent(TrainingModuleController controller, int index) {
    if (index == 1) {
      final detailError = controller.selectedModuleDetail == null ? controller.errorMessage : null;
      return TrainingReadOnlySopTab(
        isLoading:
            controller.isLoading ||
            controller.isDocumentLoading ||
            (!controller.hasResolvedSelectedModuleDocument && detailError == null),
        errorMessage: controller.documentErrorMessage ?? detailError,
        document: controller.selectedModuleDocument,
      );
    }

    if (controller.isLoading && controller.selectedModuleDetail == null) {
      return const Center(child: FastCircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.selectedModuleDetail == null) {
      return _ContentMessage(message: controller.errorMessage!);
    }

    switch (index) {
      case 0:
        return TrainingReadOnlyVideoTab(controller: controller);
      case 2:
        if (controller.questionsErrorMessage != null) {
          return _ContentMessage(message: controller.questionsErrorMessage!);
        }
        return TrainingReadOnlyQuizTab(controller: controller);
      default:
        return _AssignmentTabContent(
          isLoading: controller.isAssignmentLoading,
          errorMessage: controller.assignmentErrorMessage,
          assignment: controller.selectedModuleAssignment,
        );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  '${AppStrings.imagePath}back.svg',
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          const AppTextView.body(
            AppStrings.seatProfileTrainings,
            color: AppColors.secondaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
