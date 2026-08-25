import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_confirmation_dialog.dart';
import '../../../../core/widgets/app_gradient_action_button.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../audit/data/datasources/audit_remote_data_source.dart';
import '../../../audit/data/repositories/audit_repository_impl.dart';
import '../../../compliance/presentation/widgets/compliance_video_player.dart';
import '../../domain/entities/seat_description_training.dart';
import '../../domain/entities/seat_description_training_route.dart';
import '../controllers/training_module_controller.dart';
import '../controllers/training_video_capture_bridge.dart';
import '../controllers/training_video_upload_controller.dart';

part '../widgets/edit_training/edit_training_section_state_handlers.dart';
part '../widgets/edit_training/edit_training_section_state_view.dart';
part '../widgets/edit_training/edit_training_section_state_media.dart';
part '../widgets/edit_training/edit_training_section_state_dialogs.dart';
part '../widgets/edit_training/edit_training_tabs.dart';
part '../widgets/edit_training/edit_training_module_selector.dart';
part '../widgets/edit_training/edit_training_module_dialogs.dart';
part '../widgets/edit_training/edit_training_video_tab.dart';
part '../widgets/edit_training/edit_training_video_picker.dart';
part '../widgets/edit_training/edit_training_video_picker_tiles.dart';
part '../widgets/edit_training/edit_training_sop_tab.dart';
part '../widgets/edit_training/edit_training_assignment_tab.dart';
part '../widgets/edit_training/edit_training_quiz_tab.dart';
part '../widgets/edit_training/edit_training_shared_actions.dart';
part '../widgets/edit_training/edit_training_text_edit.dart';
part '../widgets/edit_training/edit_training_generate_quiz_dialog.dart';
part '../widgets/edit_training/edit_training_add_question_dialog.dart';
part '../widgets/edit_training/edit_training_add_question_dialog_widgets.dart';
part '../widgets/edit_training/edit_training_generate_sop_dialog.dart';
part '../widgets/edit_training/edit_training_dialog_support.dart';
part '../widgets/edit_training/edit_training_quiz_question_card.dart';
part '../widgets/edit_training/edit_training_quiz_editor_controller.dart';
part '../widgets/edit_training/edit_training_quiz_option_widgets.dart';

class EditTrainingScreen extends StatelessWidget {
  const EditTrainingScreen({
    super.key,
    required this.trainingRoute,
    this.initialModuleId,
    this.canManageTraining,
    this.useNonBlockingVideoUpload = false,
  });

  final SeatDescriptionTrainingRoute trainingRoute;
  final String? initialModuleId;
  final bool? canManageTraining;
  final bool useNonBlockingVideoUpload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: EditTrainingSection(
                  trainingRoute: trainingRoute,
                  initialModuleId: initialModuleId,
                  canManageTraining: canManageTraining,
                  useNonBlockingVideoUpload: useNonBlockingVideoUpload,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
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

class EditTrainingSection extends StatelessWidget {
  const EditTrainingSection({
    super.key,
    required this.trainingRoute,
    this.initialModuleId,
    this.canManageTraining,
    this.isEmbedded = false,
    this.skipResumeSessionRefreshOnMediaPicker = false,
    this.showOnlyApiErrorSnackBars = false,
    this.useNonBlockingVideoUpload = false,
  });

  final SeatDescriptionTrainingRoute trainingRoute;
  final String? initialModuleId;
  final bool? canManageTraining;
  final bool isEmbedded;
  final bool skipResumeSessionRefreshOnMediaPicker;
  final bool showOnlyApiErrorSnackBars;
  final bool useNonBlockingVideoUpload;

  @override
  Widget build(BuildContext context) {
    final resolvedInitialModuleId =
        (initialModuleId?.trim().isNotEmpty ?? false)
        ? initialModuleId
        : trainingRoute.initialModuleId;

    final routeBasedTrainingAccess = AppManager.instance
        .canCurrentUserManageTrainingForSeatProfile(
          seatProfileId: trainingRoute.job,
        );
    final resolvedCanManageTraining =
        (canManageTraining ?? routeBasedTrainingAccess) &&
        routeBasedTrainingAccess;

    return MultiProvider(
      providers: [
        Provider<AuditRemoteDataSource>(create: (_) => AuditRemoteDataSource()),
        ProxyProvider<AuditRemoteDataSource, AuditRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              AuditRepositoryImpl(remoteDataSource),
        ),
        ChangeNotifierProvider<TrainingModuleController>(
          create: (context) =>
              TrainingModuleController(
                context.read<AuditRepositoryImpl>(),
                canManageTraining: resolvedCanManageTraining,
              )..initialize(
                jobId: trainingRoute.job,
                descriptionId: trainingRoute.description,
                initialModuleId: resolvedInitialModuleId,
              ),
        ),
      ],
      child: _EditTrainingSectionView(
        initialModuleId: resolvedInitialModuleId,
        trainingDescriptionId: trainingRoute.description,
        isEmbedded: isEmbedded,
        skipResumeSessionRefreshOnMediaPicker:
            skipResumeSessionRefreshOnMediaPicker,
        showOnlyApiErrorSnackBars: showOnlyApiErrorSnackBars,
        useNonBlockingVideoUpload: useNonBlockingVideoUpload,
      ),
    );
  }
}

class _EditTrainingSectionView extends StatefulWidget {
  const _EditTrainingSectionView({
    required this.initialModuleId,
    required this.trainingDescriptionId,
    required this.isEmbedded,
    required this.skipResumeSessionRefreshOnMediaPicker,
    required this.showOnlyApiErrorSnackBars,
    required this.useNonBlockingVideoUpload,
  });

  final String? initialModuleId;
  final String trainingDescriptionId;
  final bool isEmbedded;
  final bool skipResumeSessionRefreshOnMediaPicker;
  final bool showOnlyApiErrorSnackBars;
  final bool useNonBlockingVideoUpload;

  @override
  State<_EditTrainingSectionView> createState() =>
      _EditTrainingSectionViewState();
}

class _EditTrainingSectionViewState extends State<_EditTrainingSectionView>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _tabSwipeResetController;
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _newLessonTitleFocusNode = FocusNode();
  final GlobalKey _newLessonTitleFieldKey = GlobalKey();
  final ValueNotifier<int> _selectedTabIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<double> _tabSwipeOffsetNotifier = ValueNotifier<double>(
    0,
  );
  final ValueNotifier<int?> _tabSwipeTargetIndexNotifier = ValueNotifier<int?>(
    null,
  );
  final ValueNotifier<bool> _isPickingVideoNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> _isFinalizingVideoSetupNotifier =
      ValueNotifier<bool>(false);
  int? _tabSwipePointerId;
  Offset? _tabSwipeStartPosition;
  bool _isTrackingTabSwipe = false;
  Animation<double>? _tabSwipeResetAnimation;
  TrainingModuleController? _trainingController;
  String? _lastDocumentErrorMessage;
  String? _lastAssignmentErrorMessage;
  String? _lastQuestionsErrorMessage;
  int _lastHandledSummarySnackBarSequence = 0;
  int _lastHandledGlobalVideoUploadEventSequence = 0;
  int _lastHandledGlobalVideoSummaryEventSequence = 0;
  int _activeTrainingModalSheetCount = 0;
  late final Listenable _viewStateListenable;

  int get _selectedTabIndex => _selectedTabIndexNotifier.value;

  bool get _isPickingVideo => _isPickingVideoNotifier.value;

  bool get _isFinalizingVideoSetup => _isFinalizingVideoSetupNotifier.value;

  bool get _isTrainingModalSheetOpen => _activeTrainingModalSheetCount > 0;

  void _beginTrainingModalSheetPresentation() {
    _activeTrainingModalSheetCount += 1;
  }

  void _endTrainingModalSheetPresentation() {
    if (_activeTrainingModalSheetCount == 0) {
      return;
    }

    _activeTrainingModalSheetCount -= 1;
  }

  @override
  void initState() {
    super.initState();
    _viewStateListenable = Listenable.merge([
      _selectedTabIndexNotifier,
      _tabSwipeOffsetNotifier,
      _tabSwipeTargetIndexNotifier,
      _isPickingVideoNotifier,
      _isFinalizingVideoSetupNotifier,
      if (widget.useNonBlockingVideoUpload)
        TrainingVideoUploadController.instance,
    ]);
    if (widget.useNonBlockingVideoUpload) {
      _lastHandledGlobalVideoUploadEventSequence =
          TrainingVideoUploadController.instance.latestTerminalEventSequence;
      _lastHandledGlobalVideoSummaryEventSequence =
          TrainingVideoUploadController.instance.latestSummaryEventSequence;
      TrainingVideoUploadController.instance.addListener(
        _handleGlobalVideoUploadChanged,
      );
    }
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _tabSwipeResetController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 180),
        )..addListener(() {
          final animation = _tabSwipeResetAnimation;
          if (animation == null) {
            return;
          }

          _tabSwipeOffsetNotifier.value = animation.value;
        });
    unawaited(_restoreLostTrainingVideoIfNeeded());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<TrainingModuleController>();
    if (identical(_trainingController, controller)) {
      return;
    }

    _trainingController?.removeListener(_handleTrainingControllerChanged);
    _trainingController = controller;
    _lastDocumentErrorMessage = _normalizeSnackBarMessage(
      controller.documentErrorMessage,
    );
    _lastAssignmentErrorMessage = _normalizeSnackBarMessage(
      controller.assignmentErrorMessage,
    );
    _lastQuestionsErrorMessage = _normalizeSnackBarMessage(
      controller.questionsErrorMessage,
    );
    _lastHandledSummarySnackBarSequence = controller.summarySnackBarSequence;
    _trainingController?.addListener(_handleTrainingControllerChanged);
  }

  @override
  void dispose() {
    _trainingController?.removeListener(_handleTrainingControllerChanged);
    if (widget.useNonBlockingVideoUpload) {
      TrainingVideoUploadController.instance.removeListener(
        _handleGlobalVideoUploadChanged,
      );
    }
    _tabSwipeResetController.dispose();
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _newLessonTitleFocusNode.dispose();
    _selectedTabIndexNotifier.dispose();
    _tabSwipeOffsetNotifier.dispose();
    _tabSwipeTargetIndexNotifier.dispose();
    _isPickingVideoNotifier.dispose();
    _isFinalizingVideoSetupNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();
    return AnimatedBuilder(
      animation: _viewStateListenable,
      builder: (context, _) => _buildBody(controller),
    );
  }
}
