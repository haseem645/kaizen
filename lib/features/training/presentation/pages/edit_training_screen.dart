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
                initialModuleId: initialModuleId,
              ),
        ),
      ],
      child: _EditTrainingSectionView(
        initialModuleId: initialModuleId,
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
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ScrollController _moduleSelectorScrollController;
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _newLessonTitleFocusNode = FocusNode();
  final GlobalKey _newLessonTitleFieldKey = GlobalKey();
  final ValueNotifier<int> _selectedTabIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isPickingVideoNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<bool> _isFinalizingVideoSetupNotifier =
      ValueNotifier<bool>(false);
  String? _lastAutoScrolledModuleId;
  String? _pendingAutoScrolledModuleId;
  TrainingModuleController? _trainingController;
  String? _lastDocumentErrorMessage;
  String? _lastAssignmentErrorMessage;
  String? _lastQuestionsErrorMessage;
  int _lastHandledSummarySnackBarSequence = 0;
  int _lastHandledGlobalVideoUploadEventSequence = 0;
  int _lastHandledGlobalVideoSummaryEventSequence = 0;
  late final Listenable _viewStateListenable;

  int get _selectedTabIndex => _selectedTabIndexNotifier.value;

  bool get _isPickingVideo => _isPickingVideoNotifier.value;

  bool get _isFinalizingVideoSetup => _isFinalizingVideoSetupNotifier.value;

  @override
  void initState() {
    super.initState();
    _viewStateListenable = Listenable.merge([
      _selectedTabIndexNotifier,
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
    _moduleSelectorScrollController = ScrollController();
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
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _moduleSelectorScrollController.dispose();
    _newLessonTitleFocusNode.dispose();
    _selectedTabIndexNotifier.dispose();
    _isPickingVideoNotifier.dispose();
    _isFinalizingVideoSetupNotifier.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging ||
        _selectedTabIndex == _tabController.index) {
      return;
    }

    _selectedTabIndexNotifier.value = _tabController.index;

    final controller = context.read<TrainingModuleController>();
    if (!controller.canAccessSelectedModuleExtras) {
      return;
    }

    if (_selectedTabIndex == 1) {
      controller.loadDocumentForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 2) {
      controller.loadQuestionsForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 3) {
      controller.loadAssignmentForSelectedModule();
    }
  }

  void _handleTrainingControllerChanged() {
    if (!mounted) {
      return;
    }

    final controller = _trainingController;
    if (controller == null) {
      return;
    }

    final currentDocumentError = _normalizeSnackBarMessage(
      controller.documentErrorMessage,
    );
    final currentAssignmentError = _normalizeSnackBarMessage(
      controller.assignmentErrorMessage,
    );
    final currentQuestionsError = _normalizeSnackBarMessage(
      controller.questionsErrorMessage,
    );

    if (currentDocumentError != null &&
        currentDocumentError != _lastDocumentErrorMessage) {
      _showApiErrorSnackBar(currentDocumentError);
    }

    if (currentQuestionsError != null &&
        currentQuestionsError != _lastQuestionsErrorMessage) {
      _showApiErrorSnackBar(currentQuestionsError);
    }

    if (currentAssignmentError != null &&
        currentAssignmentError != _lastAssignmentErrorMessage) {
      _showApiErrorSnackBar(currentAssignmentError);
    }

    _lastDocumentErrorMessage = currentDocumentError;
    _lastAssignmentErrorMessage = currentAssignmentError;
    _lastQuestionsErrorMessage = currentQuestionsError;

    if (controller.summarySnackBarSequence >
        _lastHandledSummarySnackBarSequence) {
      _lastHandledSummarySnackBarSequence = controller.summarySnackBarSequence;
      final summaryMessage = _normalizeSnackBarMessage(
        controller.summarySnackBarMessage,
      );
      if (summaryMessage != null) {
        _showApiErrorSnackBar(summaryMessage);
      }
    }
  }

  void _handleGlobalVideoUploadChanged() {
    if (!mounted || !widget.useNonBlockingVideoUpload) {
      return;
    }

    final uploadController = TrainingVideoUploadController.instance;
    final terminalTasks = uploadController.terminalTasksSince(
      _lastHandledGlobalVideoUploadEventSequence,
    );
    final controller = _trainingController;
    if (controller == null) {
      return;
    }

    if (terminalTasks.isNotEmpty) {
      _lastHandledGlobalVideoUploadEventSequence =
          terminalTasks.last.terminalEventSequence;

      for (final task in terminalTasks) {
        if (task.descriptionId != widget.trainingDescriptionId) {
          continue;
        }

        if (task.isCompleted) {
          final uploadedVideo = task.uploadedVideo;
          if (uploadedVideo == null) {
            continue;
          }

          controller.applyBackgroundUploadedVideo(
            moduleId: task.moduleId,
            video: uploadedVideo,
            localVideoPath: task.localVideoPath,
          );
          if (controller.selectedModuleId == task.moduleId) {
            unawaited(_handleVideoUploadSuccess(controller));
          }
          continue;
        }

        if (!task.isFailed) {
          continue;
        }

        final message = task.errorMessage?.trim();
        if (message != null && message.isNotEmpty) {
          _showApiErrorSnackBar(message);
        }
      }
    }

    final summaryEvents = uploadController.summaryEventsSince(
      _lastHandledGlobalVideoSummaryEventSequence,
    );
    if (summaryEvents.isEmpty) {
      return;
    }

    _lastHandledGlobalVideoSummaryEventSequence =
        summaryEvents.last.eventSequence;

    for (final event in summaryEvents) {
      if (event.descriptionId != widget.trainingDescriptionId ||
          controller.selectedModuleId != event.moduleId) {
        continue;
      }

      controller.applyGeneratedSummaryForModule(
        moduleId: event.moduleId,
        description: event.summary,
      );

      final message = _normalizeSnackBarMessage(event.snackBarMessage);
      if (message != null) {
        _showApiErrorSnackBar(message);
      }
    }
  }

  Future<bool> _startNonBlockingVideoUpload(
    TrainingModuleController controller,
    File videoFile,
  ) {
    return TrainingVideoUploadController.instance.startUploadForTrainingModule(
      descriptionId: widget.trainingDescriptionId,
      moduleId: controller.selectedModuleId,
      moduleTitle: controller.selectedModuleTitle,
      sourceFile: videoFile,
    );
  }

  bool _ensureNoModuleVideoUploadInProgress(
    TrainingModuleController controller,
  ) {
    if (!widget.useNonBlockingVideoUpload ||
        !TrainingVideoUploadController.instance.isUploadActiveForModule(
          descriptionId: widget.trainingDescriptionId,
          moduleId: controller.selectedModuleId,
        )) {
      return true;
    }

    _showApiErrorSnackBar(
      AppStrings.trainingModuleVideoUploadAlreadyInProgress,
    );
    return false;
  }

  Future<void> _uploadSelectedGalleryVideo(
    TrainingModuleController controller,
    AssetEntity asset,
  ) async {
    if (!controller.canUploadSelectedModuleVideo ||
        _isPickingVideo ||
        !_ensureNoModuleVideoUploadInProgress(controller)) {
      return;
    }

    try {
      _setPickingVideo(true);
      if (!widget.useNonBlockingVideoUpload) {
        _setFinalizingVideoSetup(true);
      }

      final originalFile = await asset.originFile;
      final selectedFile = originalFile ?? await asset.file;
      if (!mounted || selectedFile == null) {
        _setFinalizingVideoSetup(false);
        _showNonApiSnackBar(AppStrings.pickVideoError);
        return;
      }

      if (widget.useNonBlockingVideoUpload) {
        final didStart = await _startNonBlockingVideoUpload(
          controller,
          selectedFile,
        );
        _setPickingVideo(false);
        _setFinalizingVideoSetup(false);

        if (!mounted) {
          return;
        }

        if (didStart != true) {
          final message = TrainingVideoUploadController
              .instance
              .startErrorMessage
              ?.trim();
          if (message != null && message.isNotEmpty) {
            _showApiErrorSnackBar(message);
          }
        }
        return;
      }

      final uploadFuture = controller.uploadVideoForSelectedModule(
        selectedFile,
      );
      _setPickingVideo(false);

      final didUpload = await uploadFuture;
      if (!mounted) {
        return;
      }

      if (didUpload != true) {
        _setFinalizingVideoSetup(false);
        final message = controller.errorMessage?.trim();
        if (message != null && message.isNotEmpty) {
          _showApiErrorSnackBar(message);
        }
        return;
      }

      await _handleVideoUploadSuccess(controller);
    } on PlatformException catch (error) {
      _setFinalizingVideoSetup(false);
      if (!mounted) {
        return;
      }
      _showNonApiSnackBar(_buildVideoErrorMessage(ImageSource.gallery, error));
    } catch (_) {
      _setFinalizingVideoSetup(false);
      if (!mounted) {
        return;
      }
      _showNonApiSnackBar(AppStrings.pickVideoError);
    } finally {
      if (mounted && _isPickingVideo) {
        _setPickingVideo(false);
      }
    }
  }

  String? _normalizeSnackBarMessage(String? value) {
    final resolved = value?.trim();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();
    return AnimatedBuilder(
      animation: _viewStateListenable,
      builder: (context, _) => _buildBody(controller),
    );
  }

  Widget _buildBody(TrainingModuleController controller) {
    if (controller.isLoading &&
        controller.modules.isEmpty &&
        !controller.isCreatingNewLessonDraft) {
      return Center(child: FastCircularProgressIndicator());
    }

    _scheduleSelectedModuleScroll(controller);

    final showModuleSelector =
        controller.canManageTraining ||
        controller.modules.isNotEmpty ||
        controller.isCreatingNewLessonDraft;
    final contentChildren = <Widget>[
      if (showModuleSelector) ...[
        _EditModuleSelector(
          scrollController: _moduleSelectorScrollController,
          modules: controller.modules,
          selectedModuleId: controller.selectedModuleId,
          isCreatingNewLessonDraft: controller.isCreatingNewLessonDraft,
          deletingModuleId: controller.deletingModuleId,
          canManageTraining: controller.canManageTraining,
          onAddNewLessonTap: () => _startNewLessonDraft(controller),
          onModuleSelected: (moduleId) async {
            if (moduleId == controller.selectedModuleId) {
              await _syncSelectedTabData(controller);
              return;
            }

            await controller.selectModule(moduleId);
            if (!mounted) {
              return;
            }
            await _syncSelectedTabData(controller);
          },
          onDeleteModuleTap: (module) =>
              _showDeleteModuleDialog(controller: controller, module: module),
        ),
        const SizedBox(height: 1),
      ],
      _buildContentCard(controller),
    ];

    if (widget.isEmbedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: contentChildren,
      );
    }

    return ListView(children: contentChildren);
  }

  Widget _buildContentCard(TrainingModuleController controller) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.isCreatingNewLessonDraft) ...[
            _NewLessonTitleField(
              key: _newLessonTitleFieldKey,
              controller: controller.newLessonTitleController,
              focusNode: _newLessonTitleFocusNode,
              isSubmitting: controller.isCreatingModule,
              canSubmit: controller.canSubmitNewLessonTitle,
              onSubmit: () => _createModuleFromDraft(controller),
            ),
            const SizedBox(height: 14),
          ] else if (controller.selectedModuleTitle.isNotEmpty) ...[
            AppTextView.body1(
              controller.selectedModuleTitle,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: 14),
          ],
          if (!controller.canManageTraining) ...[
            const _TrainingReadOnlyBanner(),
            const SizedBox(height: 14),
          ],
          _TrainingTabs(
            tabController: _tabController,
            areExtraTabsEnabled: controller.canAccessSelectedModuleExtras,
          ),
          const SizedBox(height: 8),
          _buildTabContent(controller),
        ],
      ),
    );
  }

  Widget _buildTabContent(TrainingModuleController controller) {
    final isBackgroundVideoUploadActive =
        widget.useNonBlockingVideoUpload &&
        TrainingVideoUploadController.instance.isUploadActiveForModule(
          descriptionId: widget.trainingDescriptionId,
          moduleId: controller.selectedModuleId,
        );

    if (controller.isCreatingNewLessonDraft) {
      return _VideoTabContent(
        detail: null,
        localVideoPath: null,
        isReadOnly: false,
        isUploadEnabled: false,
        isPickingVideo: _isPickingVideo,
        isFinalizingVideoSetup: _isFinalizingVideoSetup,
        isUploadingVideo: false,
        isDeletingVideo: false,
        isUploadingThumbnail: false,
        canEditSummary: false,
        isEditingSummary: false,
        isSavingSummary: false,
        summaryController: controller.summaryController,
      );
    }

    if (!controller.hasSelectedModule) {
      return _ContentMessage(
        message:
            controller.errorMessage ??
            (controller.canManageTraining
                ? AppStrings.trainingAddLessonPrompt
                : AppStrings.trainingNoModulesAvailable),
      );
    }

    if (controller.isLoading && controller.selectedModuleDetail == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: FastCircularProgressIndicator()),
      );
    }

    if (controller.errorMessage != null &&
        controller.selectedModuleDetail == null) {
      return _ContentMessage(message: controller.errorMessage!);
    }

    if (_selectedTabIndex == 0) {
      return _VideoTabContent(
        detail: controller.selectedModuleDetail,
        localVideoPath: controller.selectedModuleLocalVideoPath,
        isReadOnly: !controller.canManageTraining,
        isUploadEnabled:
            controller.canUploadSelectedModuleVideo &&
            !isBackgroundVideoUploadActive,
        isPickingVideo: _isPickingVideo,
        isFinalizingVideoSetup: _isFinalizingVideoSetup,
        isUploadingVideo:
            controller.isUploadingVideo || isBackgroundVideoUploadActive,
        isDeletingVideo: controller.isDeletingVideo,
        isUploadingThumbnail: controller.isUploadingThumbnail,
        canEditSummary: controller.canEditSelectedModuleSummary,
        isEditingSummary: controller.isEditingSummary,
        isSavingSummary: controller.isSavingSummary,
        summaryController: controller.summaryController,
        onUploadVideoTap: () => _selectVideoSourceAndUpload(controller),
        onDeleteVideoTap: () => _showDeleteVideoDialog(controller),
        onUpdateThumbnailTap: () => _pickAndUploadThumbnail(controller),
        onEditSummaryTap: controller.startEditingSummary,
        onCancelSummaryTap: controller.cancelEditingSummary,
        onSaveSummaryTap: () => controller.saveSummaryForSelectedModule(),
      );
    }

    if (_selectedTabIndex == 1) {
      return _SopTabContent(
        isLoading: controller.isDocumentLoading,
        canManageGeneration: controller.canManageTraining,
        canGenerate: controller.canGenerateSopForSelectedModule,
        isGeneratingSop: controller.isGeneratingSop,
        canEditDocument: controller.canEditSelectedModuleDocument,
        isSavingDocument: controller.isSavingDocument,
        documentController: controller.documentController,
        onGenerateSopTap: () => _handleGenerateSopTap(controller),
        onBoldTap: controller.applyDocumentBoldFormatting,
        onItalicTap: controller.applyDocumentItalicFormatting,
        onUnderlineTap: controller.applyDocumentUnderlineFormatting,
        onBulletListTap: controller.applyDocumentBulletListFormatting,
        onNumberedListTap: controller.applyDocumentNumberedListFormatting,
        onQuoteTap: controller.applyDocumentQuoteFormatting,
        onHeadingTap: controller.applyDocumentHeadingFormatting,
      );
    }

    if (_selectedTabIndex == 2) {
      return _QuizTabContent(
        isLoading: controller.isQuestionsLoading,
        questions: controller.selectedModuleQuestions,
        canManageQuestions: controller.canManageTraining,
        canAddQuestion: controller.canAddQuestionToSelectedModule,
        canGenerateQuiz: controller.canGenerateQuizForSelectedModule,
        isGeneratingQuiz: controller.isGeneratingQuiz,
        isAddingQuestion: controller.isAddingQuestion,
        savingQuestionId: controller.savingQuestionId,
        deletingQuestionId: controller.deletingQuestionId,
        onAddQuestionTap: () => _showAddQuestionDialog(controller),
        onGenerateQuizTap: () => _showGenerateQuizDialog(controller),
        onDeleteQuestionTap: (question) => _showDeleteQuestionDialog(
          controller: controller,
          question: question,
        ),
        onSaveQuestionTap: (questionId, options, correctOptionUuid) async {
          return controller.saveQuestion(
            questionId: questionId,
            options: options,
            correctOptionUuid: correctOptionUuid,
          );
        },
      );
    }

    if (_selectedTabIndex == 3) {
      return _AssignmentTabContent(
        isLoading: controller.isAssignmentLoading,
        canEditAssignment: controller.canEditSelectedModuleAssignment,
        isSavingAssignment: controller.isSavingAssignment,
        hasSavedAssignment: controller.hasPersistedSelectedModuleAssignment,
        titleController: controller.assignmentTitleController,
        descriptionController: controller.assignmentDescriptionController,
        onSaveTap: () => controller.saveAssignmentForSelectedModule(),
        onBoldTap: controller.applyAssignmentBoldFormatting,
        onItalicTap: controller.applyAssignmentItalicFormatting,
        onUnderlineTap: controller.applyAssignmentUnderlineFormatting,
        onBulletListTap: controller.applyAssignmentBulletListFormatting,
        onNumberedListTap: controller.applyAssignmentNumberedListFormatting,
        onQuoteTap: controller.applyAssignmentQuoteFormatting,
        onHeadingTap: controller.applyAssignmentHeadingFormatting,
      );
    }

    return const _ContentMessage(
      message: AppStrings.trainingNoAssignmentAvailable,
    );
  }

  Future<void> _syncSelectedTabData(TrainingModuleController controller) async {
    if (!controller.canAccessSelectedModuleExtras) {
      return;
    }

    if (_selectedTabIndex == 1) {
      await controller.loadDocumentForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 2) {
      await controller.loadQuestionsForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 3) {
      await controller.loadAssignmentForSelectedModule();
    }
  }

  void _startNewLessonDraft(TrainingModuleController controller) {
    if (!controller.canManageTraining) {
      return;
    }

    if (_tabController.index != 0) {
      _tabController.animateTo(0);
    }
    controller.startCreatingNewLessonDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _newLessonTitleFocusNode.requestFocus();
      final fieldContext = _newLessonTitleFieldKey.currentContext;
      if (fieldContext != null) {
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  Future<void> _createModuleFromDraft(
    TrainingModuleController controller,
  ) async {
    final didCreate = await controller.createModuleFromDraft();
    if (!mounted) {
      return;
    }

    if (didCreate != true) {
      final message = controller.errorMessage?.trim();
      if (message != null && message.isNotEmpty) {
        _showApiErrorSnackBar(message);
      }
      return;
    }

    _showNonApiSnackBar(AppStrings.trainingLessonCreatedSuccess);
  }

  void _scheduleSelectedModuleScroll(TrainingModuleController controller) {
    final scrollKey = controller.isCreatingNewLessonDraft
        ? '__draft__'
        : controller.selectedModuleId.trim();
    if (scrollKey.isEmpty || controller.modules.isEmpty) {
      return;
    }

    if (_lastAutoScrolledModuleId == scrollKey ||
        _pendingAutoScrolledModuleId == scrollKey) {
      return;
    }

    final selectedIndex = controller.isCreatingNewLessonDraft
        ? -1
        : controller.modules.indexWhere(
            (module) => module.uuid == controller.selectedModuleId,
          );
    if (!controller.isCreatingNewLessonDraft && selectedIndex < 0) {
      return;
    }

    _pendingAutoScrolledModuleId = scrollKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingAutoScrolledModuleId = null;
      if (!mounted || !_moduleSelectorScrollController.hasClients) {
        return;
      }

      final targetOffset = controller.isCreatingNewLessonDraft
          ? 0.0
          : _resolveSelectedModuleScrollOffset(
              selectedIndex: selectedIndex,
              canManageTraining: controller.canManageTraining,
              maxExtent:
                  _moduleSelectorScrollController.position.maxScrollExtent,
            );
      final currentOffset = _moduleSelectorScrollController.offset;
      _lastAutoScrolledModuleId = scrollKey;
      if ((currentOffset - targetOffset).abs() < 1) {
        return;
      }

      _moduleSelectorScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  double _resolveSelectedModuleScrollOffset({
    required int selectedIndex,
    required bool canManageTraining,
    required double maxExtent,
  }) {
    final leadingOffset = canManageTraining
        ? _trainingAddNewLessonCardWidth + _trainingModuleSelectorSpacing
        : 0.0;
    final rawOffset =
        leadingOffset +
        (selectedIndex *
            (_trainingModuleSelectorCardWidth +
                _trainingModuleSelectorSpacing));
    return rawOffset.clamp(0.0, maxExtent);
  }

  void _prepareForExternalMediaPicker() {
    if (!widget.skipResumeSessionRefreshOnMediaPicker) {
      return;
    }

    AppManager.instance.skipNextResumeSessionRefresh();
  }

  void _setFinalizingVideoSetup(bool value) {
    if (!mounted || _isFinalizingVideoSetup == value) {
      return;
    }

    _isFinalizingVideoSetupNotifier.value = value;
  }

  void _setPickingVideo(bool value) {
    if (!mounted || _isPickingVideo == value) {
      return;
    }

    _isPickingVideoNotifier.value = value;
  }

  Future<void> _selectVideoSourceAndUpload(
    TrainingModuleController controller,
  ) async {
    if (!controller.canUploadSelectedModuleVideo ||
        _isPickingVideo ||
        !_ensureNoModuleVideoUploadInProgress(controller)) {
      return;
    }

    final selection = await _showVideoSourcePicker();
    if (!mounted || selection == null) {
      return;
    }

    if (selection.usesCamera) {
      await _pickAndUploadVideo(controller, ImageSource.camera);
      return;
    }

    if (selection.usesSystemGalleryPicker) {
      await _pickAndUploadVideo(controller, ImageSource.gallery);
      return;
    }

    final asset = selection.asset;
    if (asset == null) {
      return;
    }

    await _uploadSelectedGalleryVideo(controller, asset);
  }

  Future<_TrainingVideoPickerSelection?> _showVideoSourcePicker() {
    return showModalBottomSheet<_TrainingVideoPickerSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Platform.isAndroid
          ? const _TrainingVideoSystemPickerSheet()
          : const _TrainingVideoGalleryPickerSheet(),
    );
  }

  Future<void> _pickAndUploadVideo(
    TrainingModuleController controller,
    ImageSource source,
  ) async {
    if (!controller.canUploadSelectedModuleVideo ||
        _isPickingVideo ||
        !_ensureNoModuleVideoUploadInProgress(controller)) {
      return;
    }

    try {
      _setPickingVideo(true);
      if (!widget.useNonBlockingVideoUpload) {
        _setFinalizingVideoSetup(true);
      }

      _prepareForExternalMediaPicker();
      final selectedVideo = await _pickVideoFile(source);
      if (!mounted || selectedVideo == null) {
        _setFinalizingVideoSetup(false);
        return;
      }

      if (source == ImageSource.camera &&
          !selectedVideo.isSavedDirectlyToGallery) {
        await _persistCapturedVideoToGallery(selectedVideo.file);
      }

      if (widget.useNonBlockingVideoUpload) {
        final didStart = await _startNonBlockingVideoUpload(
          controller,
          selectedVideo.file,
        );
        _setPickingVideo(false);
        _setFinalizingVideoSetup(false);

        if (!mounted) {
          return;
        }

        if (didStart != true) {
          final message = TrainingVideoUploadController
              .instance
              .startErrorMessage
              ?.trim();
          if (message != null && message.isNotEmpty) {
            _showApiErrorSnackBar(message);
          }
        }
        return;
      }

      final uploadFuture = controller.uploadVideoForSelectedModule(
        selectedVideo.file,
      );
      _setPickingVideo(false);

      final didUpload = await uploadFuture;
      if (!mounted) {
        return;
      }

      if (didUpload != true) {
        _setFinalizingVideoSetup(false);
        final message = controller.errorMessage?.trim();
        if (message != null && message.isNotEmpty) {
          _showApiErrorSnackBar(message);
        }
        return;
      }

      await _handleVideoUploadSuccess(controller);
    } on PlatformException catch (error) {
      _setFinalizingVideoSetup(false);
      if (!mounted) {
        return;
      }
      _showNonApiSnackBar(_buildVideoErrorMessage(source, error));
    } catch (_) {
      _setFinalizingVideoSetup(false);
      if (!mounted) {
        return;
      }
      _showNonApiSnackBar(
        source == ImageSource.camera
            ? AppStrings.auditRecordVideoError
            : AppStrings.pickVideoError,
      );
    } finally {
      if (mounted && _isPickingVideo) {
        _setPickingVideo(false);
      }
    }
  }

  Future<_PickedTrainingVideo?> _pickVideoFile(ImageSource source) async {
    if (source == ImageSource.camera && Platform.isAndroid) {
      try {
        final capturedFile = await TrainingVideoCaptureBridge.instance
            .captureVideoWithSystemCamera();
        if (capturedFile != null) {
          return _PickedTrainingVideo(
            file: capturedFile,
            isSavedDirectlyToGallery: true,
          );
        }
      } on PlatformException catch (error) {
        if (!_shouldFallbackToDefaultAndroidCamera(error)) {
          rethrow;
        }
      }
    }

    final pickedFile = await _imagePicker.pickVideo(source: source);
    if (pickedFile == null) {
      return null;
    }

    return _PickedTrainingVideo(
      file: File(pickedFile.path),
      isSavedDirectlyToGallery: false,
    );
  }

  bool _shouldFallbackToDefaultAndroidCamera(PlatformException error) {
    if (!Platform.isAndroid) {
      return false;
    }

    return switch (error.code) {
      'legacy_android_capture_fallback' ||
      'modern_android_capture_fallback' ||
      'capture_cleanup_failed' ||
      'capture_destination_unavailable' ||
      'camera_launch_failed' ||
      'no_available_camera' => true,
      _ => false,
    };
  }

  Future<void> _restoreLostTrainingVideoIfNeeded() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      await TrainingVideoCaptureBridge.instance.restorePendingCaptureIfNeeded();
      final response = await _imagePicker.retrieveLostData();
      if (!mounted || response.isEmpty) {
        return;
      }

      if (response.exception != null) {
        _showNonApiSnackBar(AppStrings.auditRestoreMediaError);
        return;
      }

      final restoredFile =
          response.file ??
          (response.files?.isNotEmpty == true ? response.files!.first : null);
      if (restoredFile == null || !_isRecoveredVideo(response, restoredFile)) {
        return;
      }

      final videoFile = File(restoredFile.path);
      await _persistCapturedVideoToGallery(videoFile);
    } catch (error) {
      debugPrint('Unable to restore lost training video: $error');
      if (mounted) {
        _showNonApiSnackBar(AppStrings.auditRestoreMediaError);
      }
    }
  }

  bool _isRecoveredVideo(LostDataResponse response, XFile restoredFile) {
    if (response.type == RetrieveType.video) {
      return true;
    }

    final contentType = CustomFunctions.contentTypeFromPath(
      restoredFile.path,
      fallback: 'application/octet-stream',
    );
    return contentType.startsWith('video/');
  }

  Future<void> _persistCapturedVideoToGallery(File mediaFile) async {
    if (Platform.isAndroid) {
      return;
    }

    if (!await mediaFile.exists()) {
      if (mounted) {
        _showNonApiSnackBar(AppStrings.auditRecordedVideoMissing);
      }
      return;
    }

    try {
      final permissionState = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          iosAccessLevel: IosAccessLevel.addOnly,
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: false,
          ),
        ),
      );
      if (!mounted) {
        return;
      }

      if (!permissionState.hasAccess) {
        _showNonApiSnackBar(AppStrings.auditSaveRecordedVideoPermission);
        return;
      }

      await PhotoManager.editor.saveVideo(
        mediaFile,
        title: CustomFunctions.fileNameFromPath(
          mediaFile.path,
          fallback: 'training-video.mp4',
        ),
      );
    } catch (error) {
      debugPrint('Unable to save training video to gallery: $error');
      if (mounted) {
        _showNonApiSnackBar(AppStrings.auditSaveRecordedVideoError);
      }
    }
  }

  Future<void> _showDeleteVideoDialog(
    TrainingModuleController controller,
  ) async {
    final didDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (_) => ChangeNotifierProvider<TrainingModuleController>.value(
        value: controller,
        child: _DeleteTrainingVideoDialog(
          moduleTitle: controller.selectedModuleTitle,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (didDelete == true) {
      return;
    }

    if (didDelete == false) {
      final message = controller.errorMessage?.trim();
      if (message != null && message.isNotEmpty) {
        _showApiErrorSnackBar(message);
      }
    }
  }

  Future<void> _handleVideoUploadSuccess(
    TrainingModuleController controller,
  ) async {
    try {
      final didUploadThumbnail = await _showThumbnailPickerDialog(controller);
      if (!mounted) {
        return;
      }

      _showNonApiSnackBar(
        didUploadThumbnail
            ? AppStrings.trainingThumbnailUpdatedSuccess
            : AppStrings.trainingVideoUploadedSuccess,
      );
    } finally {
      _setFinalizingVideoSetup(false);
    }
  }

  Future<bool> _showThumbnailPickerDialog(
    TrainingModuleController controller,
  ) async {
    final didUploadThumbnail = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (dialogContext) =>
          ChangeNotifierProvider<TrainingModuleController>.value(
            value: controller,
            child: _TrainingThumbnailPickerDialog(
              onSelectThumbnailTap: () async {
                final didUpload = await _pickAndUploadThumbnail(
                  controller,
                  showSuccessSnackBar: false,
                );
                if (didUpload == true && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              onSkipTap: () {
                if (!controller.isUploadingThumbnail && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(false);
                }
              },
            ),
          ),
    );

    return didUploadThumbnail == true;
  }

  Future<bool?> _pickAndUploadThumbnail(
    TrainingModuleController controller, {
    bool showSuccessSnackBar = true,
  }) async {
    if (controller.isUpdatingVideoActions) {
      return false;
    }

    try {
      _prepareForExternalMediaPicker();
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted || pickedFile == null) {
        return null;
      }

      final didUpload = await controller.uploadThumbnailForSelectedModule(
        File(pickedFile.path),
      );
      if (!mounted) {
        return false;
      }

      if (didUpload != true) {
        final message = controller.errorMessage?.trim();
        if (message != null && message.isNotEmpty) {
          _showApiErrorSnackBar(message);
        }
        return false;
      }

      if (showSuccessSnackBar) {
        _showNonApiSnackBar(AppStrings.trainingThumbnailUpdatedSuccess);
      }
      return true;
    } on PlatformException catch (error) {
      if (!mounted) {
        return false;
      }
      _showNonApiSnackBar(_buildImageErrorMessage(error));
    } catch (_) {
      if (!mounted) {
        return false;
      }
      _showNonApiSnackBar(AppStrings.pickImageError);
    }

    return false;
  }

  String _buildVideoErrorMessage(ImageSource source, PlatformException error) {
    final errorCode = error.code.toLowerCase();
    final errorMessage = (error.message ?? '').toLowerCase();
    final isCamera = source == ImageSource.camera;

    if (isCamera &&
        (errorCode.contains('camera_access_denied') ||
            errorCode.contains('camera_denied') ||
            errorMessage.contains('access to the camera'))) {
      return AppStrings.auditCameraPermissionVideo;
    }

    if (!isCamera &&
        (errorCode.contains('photo_access_denied') ||
            errorCode.contains('photo_access_restricted') ||
            errorMessage.contains('photo library'))) {
      return AppStrings.auditPhotoLibraryPermissionVideo;
    }

    return isCamera
        ? AppStrings.auditRecordVideoError
        : AppStrings.pickVideoError;
  }

  String _buildImageErrorMessage(PlatformException error) {
    final errorCode = error.code.toLowerCase();
    final errorMessage = (error.message ?? '').toLowerCase();
    if (errorCode.contains('photo_access_denied') ||
        errorCode.contains('photo_access_restricted') ||
        errorMessage.contains('photo library')) {
      return AppStrings.auditPhotoLibraryPermissionImage;
    }

    return AppStrings.pickImageError;
  }

  void _showApiErrorSnackBar(String message) {
    _showSnackBar(message);
  }

  void _showNonApiSnackBar(String message) {
    if (widget.showOnlyApiErrorSnackBars) {
      return;
    }

    _showSnackBar(message);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.surfaceDark3,
        ),
      );
  }

  Future<void> _showDeleteModuleDialog({
    required TrainingModuleController controller,
    required SeatDescriptionTrainingModule module,
  }) async {
    final didDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (_) => ChangeNotifierProvider<TrainingModuleController>.value(
        value: controller,
        child: _DeleteModuleDialog(module: module),
      ),
    );

    if (!mounted) {
      return;
    }

    if (didDelete == true) {
      await _syncSelectedTabData(controller);
      _showNonApiSnackBar(AppStrings.trainingModuleDeletedSuccess);
      return;
    }

    if (didDelete == false) {
      final message = controller.errorMessage?.trim();
      if (message != null && message.isNotEmpty) {
        _showApiErrorSnackBar(message);
      }
    }
  }

  Future<void> _showDeleteQuestionDialog({
    required TrainingModuleController controller,
    required SeatDescriptionTrainingQuestion question,
  }) async {
    final didDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (_) => ChangeNotifierProvider<TrainingModuleController>.value(
        value: controller,
        child: _DeleteQuestionDialog(question: question),
      ),
    );

    if (!mounted) {
      return;
    }

    if (didDelete == true) {
      _showNonApiSnackBar(AppStrings.trainingQuestionDeletedSuccess);
      return;
    }

    if (didDelete == false) {
      final message = controller.questionsErrorMessage?.trim();
      if (message != null && message.isNotEmpty) {
        _showApiErrorSnackBar(message);
      }
    }
  }

  Future<void> _showGenerateQuizDialog(
    TrainingModuleController controller,
  ) async {
    if (!controller.canGenerateQuizForSelectedModule) {
      return;
    }

    controller.resetQuizGenerationForm();

    final didGenerate = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (_) => ChangeNotifierProvider<TrainingModuleController>.value(
        value: controller,
        child: const _GenerateQuizDialog(),
      ),
    );

    if (!mounted || didGenerate != true) {
      return;
    }
  }

  Future<void> _showAddQuestionDialog(
    TrainingModuleController controller,
  ) async {
    if (!controller.canAddQuestionToSelectedModule) {
      return;
    }

    final didAdd = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.56),
      builder: (_) => ChangeNotifierProvider<TrainingModuleController>.value(
        value: controller,
        child: const _AddQuestionDialog(),
      ),
    );

    if (!mounted || didAdd != true) {
      return;
    }
  }

  Future<void> _handleGenerateSopTap(
    TrainingModuleController controller,
  ) async {
    if (!controller.canGenerateSopForSelectedModule ||
        controller.isDocumentLoading) {
      return;
    }

    await _showGenerateSopDialog(controller);
  }

  Future<void> _showGenerateSopDialog(
    TrainingModuleController controller,
  ) async {
    final didGenerate = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) => ChangeNotifierProvider<TrainingModuleController>.value(
        value: controller,
        child: const _GenerateSopDialog(),
      ),
    );

    if (!mounted || didGenerate != true) {
      return;
    }
  }
}

class _TrainingTabs extends StatelessWidget {
  const _TrainingTabs({
    required this.tabController,
    required this.areExtraTabsEnabled,
  });

  final TabController tabController;
  final bool areExtraTabsEnabled;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: EdgeInsets.zero,
      onTap: (index) {
        if (index == 0 || areExtraTabsEnabled) {
          return;
        }

        tabController.animateTo(0);
      },
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorColor: AppColors.secondaryColor,
      labelColor: AppColors.secondaryColor,
      unselectedLabelColor: AppColors.textSecondary,
      dividerColor: AppColors.fieldBorder.withValues(alpha: 0.22),
      tabs: <Widget>[
        const _TrainingTabLabel(label: AppStrings.trainingVideoTab),
        _TrainingTabLabel(
          label: AppStrings.trainingSopTab,
          isEnabled: areExtraTabsEnabled,
        ),
        _TrainingTabLabel(
          label: AppStrings.trainingQuizTab,
          isEnabled: areExtraTabsEnabled,
        ),
        _TrainingTabLabel(
          label: AppStrings.trainingAssignmentTab,
          isEnabled: areExtraTabsEnabled,
        ),
      ],
    );
  }
}

class _TrainingTabLabel extends StatelessWidget {
  const _TrainingTabLabel({required this.label, this.isEnabled = true});

  final String label;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Tab(
        child: Padding(
          padding: const EdgeInsets.only(left: 22, right: 14),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.42,
            child: AppTextView.body2(label, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

const double _trainingModuleSelectorCardWidth = 132;
const double _trainingAddNewLessonCardWidth = 180;
const double _trainingModuleSelectorCardHeight = 148;
const double _trainingModuleSelectorSpacing = 12;
const double _trainingModuleThumbnailHeight = 84;

class _EditModuleSelector extends StatelessWidget {
  const _EditModuleSelector({
    required this.scrollController,
    required this.modules,
    required this.selectedModuleId,
    required this.isCreatingNewLessonDraft,
    required this.deletingModuleId,
    required this.canManageTraining,
    required this.onAddNewLessonTap,
    required this.onModuleSelected,
    required this.onDeleteModuleTap,
  });

  final ScrollController scrollController;
  final List<SeatDescriptionTrainingModule> modules;
  final String selectedModuleId;
  final bool isCreatingNewLessonDraft;
  final String? deletingModuleId;
  final bool canManageTraining;
  final VoidCallback onAddNewLessonTap;
  final Future<void> Function(String moduleId) onModuleSelected;
  final Future<void> Function(SeatDescriptionTrainingModule module)
  onDeleteModuleTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _trainingModuleSelectorCardHeight,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canManageTraining) ...[
                _AddNewLessonCard(
                  isSelected: isCreatingNewLessonDraft,
                  onTap: onAddNewLessonTap,
                ),
                const SizedBox(width: _trainingModuleSelectorSpacing),
              ],
              // if (canManageTraining && modules.isNotEmpty) ...[
              //   Container(
              //     width: 1,
              //     height: _trainingModuleThumbnailHeight,
              //     color: Colors.white.withValues(alpha: 0.24),
              //   ),
              //   const SizedBox(width: _trainingModuleSelectorSpacing),
              // ],
              for (var index = 0; index < modules.length; index++) ...[
                _ModuleCard(
                  module: modules[index],
                  isSelected: modules[index].uuid == selectedModuleId,
                  onTap: () => onModuleSelected(modules[index].uuid),
                  isDeleting: deletingModuleId == modules[index].uuid,
                  showDeleteAction: canManageTraining,
                  onDeleteTap: () => onDeleteModuleTap(modules[index]),
                ),
                if (index != modules.length - 1)
                  const SizedBox(width: _trainingModuleSelectorSpacing),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddNewLessonCard extends StatelessWidget {
  const _AddNewLessonCard({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: _DottedRoundedBorderPainter(
            color: AppColors.secondaryColor,
            radius: 10,
          ),
          child: SizedBox(
            width: _trainingAddNewLessonCardWidth,
            height: _trainingModuleThumbnailHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.secondaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: AppTextView.body2(
                      AppStrings.trainingAddNewLesson,
                      maxLines: 1,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.isSelected,
    required this.onTap,
    required this.isDeleting,
    required this.showDeleteAction,
    required this.onDeleteTap,
  });

  final SeatDescriptionTrainingModule module;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDeleting;
  final bool showDeleteAction;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final resolvedThumbnail = CustomFunctions.resolveImageUrl(
      module.thumbnailLink,
    );

    return SizedBox(
      width: _trainingModuleSelectorCardWidth,
      height: _trainingModuleSelectorCardHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.all(isSelected ? 2 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          height: _trainingModuleThumbnailHeight,
                          child: resolvedThumbnail == null
                              ? const _ModuleThumbnailPlaceholder()
                              : CachedNetworkImage(
                                  imageUrl: resolvedThumbnail,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) =>
                                      const _ModuleThumbnailPlaceholder(),
                                  errorWidget: (_, _, _) =>
                                      const _ModuleThumbnailPlaceholder(),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: AppTextView.body2(
                        module.title,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showDeleteAction)
            Positioned(
              top: 0,
              right: 6,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDeleting ? null : onDeleteTap,
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.88),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isDeleting
                          ? FastCircularProgressIndicator(width: 12, height: 12)
                          : const Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeleteModuleDialog extends StatelessWidget {
  const _DeleteModuleDialog({required this.module});

  final SeatDescriptionTrainingModule module;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return AppConfirmationDialog(
      title: AppStrings.trainingDeleteModuleTitle,
      description: AppStrings.trainingDeleteModuleDescription(module.title),
      confirmText: AppStrings.trainingDeleteModuleAction,
      cancelText: AppStrings.trainingCancel,
      isConfirmLoading: controller.isDeletingModule(module.uuid),
      onCancelCallback: () async {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      onConfirmCallback: () async {
        final didDelete = await context
            .read<TrainingModuleController>()
            .deleteModule(module.uuid);
        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pop(didDelete);
      },
    );
  }
}

class _DeleteTrainingVideoDialog extends StatelessWidget {
  const _DeleteTrainingVideoDialog({required this.moduleTitle});

  final String moduleTitle;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return AppConfirmationDialog(
      title: AppStrings.trainingDeleteVideoTitle,
      description: AppStrings.trainingDeleteVideoDescription(moduleTitle),
      confirmText: AppStrings.trainingDeleteVideoAction,
      cancelText: AppStrings.trainingCancel,
      isConfirmLoading: controller.isDeletingVideo,
      onCancelCallback: () async {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      onConfirmCallback: () async {
        final didDelete = await context
            .read<TrainingModuleController>()
            .deleteVideoForSelectedModule();
        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pop(didDelete);
      },
    );
  }
}

class _DeleteQuestionDialog extends StatelessWidget {
  const _DeleteQuestionDialog({required this.question});

  final SeatDescriptionTrainingQuestion question;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return AppConfirmationDialog(
      title: AppStrings.trainingDeleteQuestionTitle,
      description: AppStrings.trainingDeleteQuestionDescription,
      confirmText: AppStrings.trainingDeleteQuestionAction,
      cancelText: AppStrings.trainingCancel,
      isConfirmLoading: controller.isDeletingQuestion(question.uuid),
      onCancelCallback: () async {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      onConfirmCallback: () async {
        final didDelete = await context
            .read<TrainingModuleController>()
            .deleteQuestion(questionId: question.uuid);
        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pop(didDelete);
      },
    );
  }
}

class _TrainingThumbnailPickerDialog extends StatelessWidget {
  const _TrainingThumbnailPickerDialog({
    required this.onSelectThumbnailTap,
    required this.onSkipTap,
  });

  final Future<void> Function() onSelectThumbnailTap;
  final VoidCallback onSkipTap;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const AppTextView.body1(
        AppStrings.trainingAddThumbnailTitle,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppTextView.body(
            AppStrings.trainingAddThumbnailDescription,
            color: AppColors.textPrimary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: controller.isUploadingThumbnail
                  ? null
                  : onSelectThumbnailTap,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mainBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.secondaryColor.withValues(alpha: 0.28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: controller.isUploadingThumbnail
                            ? FastCircularProgressIndicator(
                                width: 18,
                                height: 18,
                              )
                            : const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: AppColors.textPrimary,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const AppTextView.body2(
                      AppStrings.trainingSelectThumbnailAction,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const AppTextView.body4(
                      AppStrings.trainingSelectThumbnailHint,
                      color: AppColors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: controller.isUploadingThumbnail ? null : onSkipTap,
          child: const AppTextView.body(
            AppStrings.trainingSkipThumbnailAction,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ModuleThumbnailPlaceholder extends StatelessWidget {
  const _ModuleThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.mainBg,
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_outline_rounded,
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }
}

class _VideoTabContent extends StatelessWidget {
  const _VideoTabContent({
    required this.detail,
    required this.localVideoPath,
    required this.isReadOnly,
    required this.isUploadEnabled,
    required this.isPickingVideo,
    required this.isFinalizingVideoSetup,
    required this.isUploadingVideo,
    required this.isDeletingVideo,
    required this.isUploadingThumbnail,
    required this.canEditSummary,
    required this.isEditingSummary,
    required this.isSavingSummary,
    required this.summaryController,
    this.onUploadVideoTap,
    this.onDeleteVideoTap,
    this.onUpdateThumbnailTap,
    this.onEditSummaryTap,
    this.onCancelSummaryTap,
    this.onSaveSummaryTap,
  });

  final SeatDescriptionTrainingModuleDetail? detail;
  final String? localVideoPath;
  final bool isReadOnly;
  final bool isUploadEnabled;
  final bool isPickingVideo;
  final bool isFinalizingVideoSetup;
  final bool isUploadingVideo;
  final bool isDeletingVideo;
  final bool isUploadingThumbnail;
  final bool canEditSummary;
  final bool isEditingSummary;
  final bool isSavingSummary;
  final TextEditingController summaryController;
  final VoidCallback? onUploadVideoTap;
  final VoidCallback? onDeleteVideoTap;
  final VoidCallback? onUpdateThumbnailTap;
  final VoidCallback? onEditSummaryTap;
  final VoidCallback? onCancelSummaryTap;
  final Future<bool> Function()? onSaveSummaryTap;

  @override
  Widget build(BuildContext context) {
    final video = detail?.trainingVideo;
    final videoUrl = video?.url?.trim();
    final summary = detail?.description?.trim();
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final canRevealVideo = hasVideo && !isFinalizingVideoSetup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canRevealVideo)
          ComplianceVideoPlayer(
            key: ValueKey<String>(videoUrl),
            videoUrl: videoUrl,
            localVideoPath: localVideoPath,
            title: detail?.title ?? '',
            thumbnailLink: detail?.previewThumbnailLink,
            fillBounds: true,
            topRightActions: !isReadOnly
                ? [
                    _TrainingVideoActionMenu(
                      isLoading: isDeletingVideo || isUploadingThumbnail,
                      onSelected: (action) {
                        if (action == _TrainingVideoMenuAction.delete) {
                          onDeleteVideoTap?.call();
                          return;
                        }

                        onUpdateThumbnailTap?.call();
                      },
                    ),
                  ]
                : const <Widget>[],
          )
        else if (isReadOnly)
          const _ContentMessage(message: AppStrings.trainingNoVideoAvailable)
        else
          _TrainingVideoEmptyState(
            isEnabled: isUploadEnabled && !isFinalizingVideoSetup,
            isPickingVideo: isPickingVideo || isFinalizingVideoSetup,
            isUploading: isUploadingVideo,
            isFinalizingSetup: isFinalizingVideoSetup,
            isLoading:
                isUploadingVideo ||
                isDeletingVideo ||
                isPickingVideo ||
                isFinalizingVideoSetup,
            onTap: onUploadVideoTap,
          ),
        if (canRevealVideo) ...[
          const SizedBox(height: 16),
          const _TrainingSectionHeader(title: AppStrings.trainingSummaryLabel),
          const SizedBox(height: 10),
          _TrainingDisplayCard(
            child: AppTextView.body3(
              summary != null && summary.isNotEmpty
                  ? CustomFunctions.stripHtmlTags(summary)
                  : AppStrings.trainingNoSummaryAvailable,
              color: AppColors.textPrimary,
              height: 1.65,
            ),
          ),
        ],
      ],
    );
  }
}

class _TrainingVideoPickerSelection {
  const _TrainingVideoPickerSelection.camera()
    : asset = null,
      usesCamera = true,
      usesSystemGalleryPicker = false;

  const _TrainingVideoPickerSelection.systemGallery()
    : asset = null,
      usesCamera = false,
      usesSystemGalleryPicker = true;

  const _TrainingVideoPickerSelection.asset(AssetEntity selectedAsset)
    : asset = selectedAsset,
      usesCamera = false,
      usesSystemGalleryPicker = false;

  final AssetEntity? asset;
  final bool usesCamera;
  final bool usesSystemGalleryPicker;
}

class _PickedTrainingVideo {
  const _PickedTrainingVideo({
    required this.file,
    required this.isSavedDirectlyToGallery,
  });

  final File file;
  final bool isSavedDirectlyToGallery;
}

class _TrainingVideoGalleryPickerStateController extends ChangeNotifier {
  PermissionState? permissionState;
  AssetPathEntity? videoAlbum;
  final List<AssetEntity> videos = <AssetEntity>[];
  bool isLoadingInitial = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  bool get hasGalleryAccess => permissionState?.hasAccess ?? false;

  void showInitialLoader() {
    isLoadingInitial = true;
    errorMessage = null;
    notifyListeners();
  }

  void showPermissionDenied(PermissionState nextPermissionState) {
    permissionState = nextPermissionState;
    videoAlbum = null;
    videos.clear();
    hasMore = false;
    isLoadingInitial = false;
    isLoadingMore = false;
    errorMessage = null;
    notifyListeners();
  }

  void showInitialVideos({
    required PermissionState nextPermissionState,
    required AssetPathEntity? nextVideoAlbum,
    required List<AssetEntity> nextVideos,
    required int pageSize,
  }) {
    permissionState = nextPermissionState;
    videoAlbum = nextVideoAlbum;
    videos
      ..clear()
      ..addAll(nextVideos);
    hasMore = nextVideos.length == pageSize;
    isLoadingInitial = false;
    isLoadingMore = false;
    errorMessage = null;
    notifyListeners();
  }

  void showInitialError(String message) {
    isLoadingInitial = false;
    isLoadingMore = false;
    hasMore = false;
    errorMessage = message;
    notifyListeners();
  }

  void startLoadingMore() {
    isLoadingMore = true;
    errorMessage = null;
    notifyListeners();
  }

  void appendVideos(List<AssetEntity> nextVideos, int pageSize) {
    videos.addAll(nextVideos);
    hasMore = nextVideos.length == pageSize;
    isLoadingMore = false;
    notifyListeners();
  }

  void showLoadMoreError(String message) {
    isLoadingMore = false;
    errorMessage = message;
    notifyListeners();
  }
}

class _TrainingVideoGalleryPickerSheet extends StatefulWidget {
  const _TrainingVideoGalleryPickerSheet();

  @override
  State<_TrainingVideoGalleryPickerSheet> createState() =>
      _TrainingVideoGalleryPickerSheetState();
}

class _TrainingVideoGalleryPickerSheetState
    extends State<_TrainingVideoGalleryPickerSheet>
    with WidgetsBindingObserver {
  static const int _pageSize = 24;

  final ScrollController _scrollController = ScrollController();
  final _TrainingVideoGalleryPickerStateController _galleryState =
      _TrainingVideoGalleryPickerStateController();

  bool get _isGalleryAccessLimited =>
      _galleryState.permissionState == PermissionState.limited;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    _loadInitialVideos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _galleryState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInitialVideos(showLoader: false);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _galleryState.isLoadingInitial ||
        _galleryState.isLoadingMore ||
        !_galleryState.hasMore ||
        _galleryState.videoAlbum == null) {
      return;
    }

    if (_scrollController.position.extentAfter < 280) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadInitialVideos({bool showLoader = true}) async {
    if (showLoader && mounted) {
      _galleryState.showInitialLoader();
    }

    try {
      final permissionState = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: false,
          ),
        ),
      );
      if (!mounted) {
        return;
      }

      if (!permissionState.hasAccess) {
        _galleryState.showPermissionDenied(permissionState);
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );
      if (!mounted) {
        return;
      }

      final videoAlbum = albums.isNotEmpty ? albums.first : null;
      final videos = videoAlbum == null
          ? <AssetEntity>[]
          : await videoAlbum.getAssetListPaged(
              page: 0,
              size: _pageSize,
              type: RequestType.video,
            );
      if (!mounted) {
        return;
      }

      _galleryState.showInitialVideos(
        nextPermissionState: permissionState,
        nextVideoAlbum: videoAlbum,
        nextVideos: videos,
        pageSize: _pageSize,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _galleryState.showInitialError(AppStrings.pickVideoError);
    }
  }

  Future<void> _loadMoreVideos() async {
    final videoAlbum = _galleryState.videoAlbum;
    if (videoAlbum == null ||
        _galleryState.isLoadingInitial ||
        _galleryState.isLoadingMore ||
        !_galleryState.hasMore) {
      return;
    }

    _galleryState.startLoadingMore();

    try {
      final nextPage = _galleryState.videos.length ~/ _pageSize;
      final nextVideos = await videoAlbum.getAssetListPaged(
        page: nextPage,
        size: _pageSize,
        type: RequestType.video,
      );
      if (!mounted) {
        return;
      }

      _galleryState.appendVideos(nextVideos, _pageSize);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _galleryState.showLoadMoreError(AppStrings.pickVideoError);
    }
  }

  Future<void> _presentLimitedVideoAccessPicker() async {
    try {
      await PhotoManager.presentLimited(type: RequestType.video);
      if (!mounted) {
        return;
      }

      await _loadInitialVideos(showLoader: false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _galleryState.showLoadMoreError(AppStrings.pickVideoError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _galleryState,
      builder: (context, _) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark3,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBorder.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextView.body1(
                              AppStrings.trainingSelectVideoSource,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            SizedBox(height: 8),
                            AppTextView.body2(
                              AppStrings.trainingSelectVideoSourceHint,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const AppTextView.body3(
                    AppStrings.trainingRecentVideos,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GridView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 118,
                                ),
                            itemCount:
                                _galleryState.videos.length +
                                1 +
                                (_isGalleryAccessLimited ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _TrainingVideoCameraTile(
                                  onTap: () => Navigator.of(context).pop(
                                    const _TrainingVideoPickerSelection.camera(),
                                  ),
                                );
                              }

                              if (_isGalleryAccessLimited && index == 1) {
                                return _TrainingVideoManageAccessTile(
                                  onTap: _presentLimitedVideoAccessPicker,
                                );
                              }

                              final assetIndex =
                                  index - (_isGalleryAccessLimited ? 2 : 1);
                              final asset = _galleryState.videos[assetIndex];
                              return _TrainingVideoGalleryTile(
                                asset: asset,
                                onTap: () => Navigator.of(context).pop(
                                  _TrainingVideoPickerSelection.asset(asset),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
}

class _TrainingVideoSystemPickerSheet extends StatelessWidget {
  const _TrainingVideoSystemPickerSheet();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.46,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBorder.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextView.body1(
                          AppStrings.trainingSelectVideoSource,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 8),
                        AppTextView.body2(
                          AppStrings.trainingSelectVideoSourceHint,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _TrainingVideoSystemPickerOptionTile(
                icon: Icons.videocam_rounded,
                title: AppStrings.trainingRecordVideo,
                subtitle: AppStrings.trainingRecordVideoHint,
                accentColor: AppColors.secondaryColor,
                onTap: () => Navigator.of(
                  context,
                ).pop(const _TrainingVideoPickerSelection.camera()),
              ),
              const SizedBox(height: 12),
              _TrainingVideoSystemPickerOptionTile(
                icon: Icons.video_library_outlined,
                title: AppStrings.trainingUploadVideo,
                subtitle: AppStrings.trainingUploadVideoHint,
                onTap: () => Navigator.of(
                  context,
                ).pop(const _TrainingVideoPickerSelection.systemGallery()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoCameraTile extends StatelessWidget {
  const _TrainingVideoCameraTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondaryColor.withValues(alpha: 0.4),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_rounded,
                color: AppColors.secondaryColor,
                size: 32,
              ),
              SizedBox(height: 10),
              AppTextView.body3(
                AppStrings.trainingRecordVideo,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoSystemPickerOptionTile extends StatelessWidget {
  const _TrainingVideoSystemPickerOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextView.body3(
                      title,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 6),
                    AppTextView.body4(
                      subtitle,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoManageAccessTile extends StatelessWidget {
  const _TrainingVideoManageAccessTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.fieldBorder.withValues(alpha: 0.34),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_add_outlined,
                color: AppColors.textPrimary,
                size: 30,
              ),
              SizedBox(height: 10),
              AppTextView.body3(
                AppStrings.trainingManageGalleryAccess,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingVideoGalleryTile extends StatelessWidget {
  const _TrainingVideoGalleryTile({required this.asset, required this.onTap});

  final AssetEntity asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: asset.thumbnailDataWithSize(
                  const ThumbnailSize.square(420),
                ),
                builder: (context, snapshot) {
                  final thumbnail = snapshot.data;
                  if (thumbnail != null) {
                    return Image.memory(
                      thumbnail,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    );
                  }

                  return Container(
                    color: AppColors.surfaceDark,
                    child: const Center(
                      child: Icon(
                        Icons.video_library_rounded,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatVideoDuration(asset.videoDuration),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatVideoDuration(Duration duration) {
  final hours = duration.inHours;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  return '${duration.inMinutes}:$seconds';
}

class _NewLessonTitleField extends StatelessWidget {
  const _NewLessonTitleField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSubmitting,
    required this.canSubmit,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppTextView.body3(
          AppStrings.trainingLessonTitle,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (canSubmit) {
                      onSubmit();
                    }
                  },
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: AppStrings.trainingLessonTitleHint,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: canSubmit ? onSubmit : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: canSubmit
                        ? AppColors.secondaryColor
                        : AppColors.fieldBorder.withValues(alpha: 0.24),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isSubmitting
                        ? FastCircularProgressIndicator(width: 14, height: 14)
                        : Icon(
                            Icons.check_rounded,
                            color: canSubmit
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TrainingVideoMenuAction { delete, thumbnail }

class _TrainingVideoActionMenu extends StatelessWidget {
  const _TrainingVideoActionMenu({
    required this.isLoading,
    required this.onSelected,
  });

  final bool isLoading;
  final ValueChanged<_TrainingVideoMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 34,
        height: 34,
        child: Center(
          child: FastCircularProgressIndicator(width: 14, height: 14),
        ),
      );
    }

    return PopupMenuButton<_TrainingVideoMenuAction>(
      tooltip: AppStrings.trainingVideoMoreActions,
      color: AppColors.surfaceDark3,
      surfaceTintColor: AppColors.surfaceDark3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem<_TrainingVideoMenuAction>(
          value: _TrainingVideoMenuAction.delete,
          child: _TrainingVideoMenuItemContent(
            icon: Icons.delete_outline_rounded,
            label: AppStrings.trainingDeleteVideoAction,
            color: AppColors.red,
          ),
        ),
        PopupMenuItem<_TrainingVideoMenuAction>(
          value: _TrainingVideoMenuAction.thumbnail,
          child: _TrainingVideoMenuItemContent(
            icon: Icons.image_outlined,
            label: AppStrings.trainingThumbnailAction,
            color: AppColors.secondaryColor,
          ),
        ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.mainBg,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.fieldBorder.withValues(alpha: 0.25),
          ),
        ),
        child: const Icon(
          Icons.more_vert_rounded,
          color: AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}

class _TrainingVideoMenuItemContent extends StatelessWidget {
  const _TrainingVideoMenuItemContent({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        AppTextView.body3(label, color: color, fontWeight: FontWeight.w700),
      ],
    );
  }
}

class _TrainingVideoEmptyState extends StatelessWidget {
  const _TrainingVideoEmptyState({
    required this.isEnabled,
    required this.isPickingVideo,
    required this.isUploading,
    required this.isFinalizingSetup,
    required this.isLoading,
    this.onTap,
  });

  final bool isEnabled;
  final bool isPickingVideo;
  final bool isUploading;
  final bool isFinalizingSetup;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled && !isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: CustomPaint(
          painter: _DottedRoundedBorderPainter(
            color: isEnabled
                ? AppColors.secondaryColor.withValues(alpha: 0.75)
                : AppColors.fieldBorder.withValues(alpha: 0.38),
            radius: 14,
          ),
          child: Ink(
            width: double.infinity,
            height: 440,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: AppColors.secondaryColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isPickingVideo
                          ? FastCircularProgressIndicator(width: 20, height: 20)
                          : const Icon(
                              Icons.video_library_outlined,
                              color: AppColors.textPrimary,
                              size: 30,
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextView.body(
                    isFinalizingSetup
                        ? AppStrings.trainingFinishingVideoSetup
                        : isUploading
                        ? AppStrings.trainingUploadingVideo
                        : AppStrings.trainingUploadVideo,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                  if (!isUploading && !isFinalizingSetup) ...<Widget>[
                    const SizedBox(height: 8),
                    const AppTextView.body3(
                      AppStrings.trainingUploadVideoHint,
                      color: AppColors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (isUploading || isFinalizingSetup) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: AppColors.secondaryColor.withValues(
                          alpha: 0.18,
                        ),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SopTabContent extends StatelessWidget {
  const _SopTabContent({
    required this.isLoading,
    required this.canManageGeneration,
    required this.canGenerate,
    required this.isGeneratingSop,
    required this.canEditDocument,
    required this.isSavingDocument,
    required this.documentController,
    required this.onGenerateSopTap,
    this.onBoldTap,
    this.onItalicTap,
    this.onUnderlineTap,
    this.onBulletListTap,
    this.onNumberedListTap,
    this.onQuoteTap,
    this.onHeadingTap,
  });

  final bool isLoading;
  final bool canManageGeneration;
  final bool canGenerate;
  final bool isGeneratingSop;
  final bool canEditDocument;
  final bool isSavingDocument;
  final TrainingRichTextEditingController documentController;
  final VoidCallback onGenerateSopTap;
  final VoidCallback? onBoldTap;
  final VoidCallback? onItalicTap;
  final VoidCallback? onUnderlineTap;
  final VoidCallback? onBulletListTap;
  final VoidCallback? onNumberedListTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onHeadingTap;

  @override
  Widget build(BuildContext context) {
    final hasEditorContent = documentController.text.trim().isNotEmpty;
    final sopContent = isLoading && !hasEditorContent
        ? SizedBox(
            height: 180,
            child: Center(child: FastCircularProgressIndicator()),
          )
        : _TrainingEditableTextCard(
            controller: documentController,
            hintText: AppStrings.trainingSopHint,
            minLines: 10,
            maxLines: 18,
            readOnly: !canEditDocument || isSavingDocument,
            wrapWithCard: !canEditDocument,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: AppTextView.body3(
                AppStrings.trainingCreateSop,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (canManageGeneration)
              _AiGenerateButton(
                label: AppStrings.trainingGenerateWithAi,
                isEnabled: canGenerate,
                isLoading: isGeneratingSop,
                verticalPadding: 8,
                onTap: canGenerate ? onGenerateSopTap : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (canEditDocument)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.fieldBorder.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrainingFormattingToolbar(
                  controller: documentController,
                  isSaving: isSavingDocument,
                  onBoldTap: onBoldTap,
                  onItalicTap: onItalicTap,
                  onUnderlineTap: onUnderlineTap,
                  onBulletListTap: onBulletListTap,
                  onNumberedListTap: onNumberedListTap,
                  onQuoteTap: onQuoteTap,
                  onHeadingTap: onHeadingTap,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: AppColors.mainBg,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                  child: sopContent,
                ),
              ],
            ),
          )
        else
          sopContent,
      ],
    );
  }
}

class _AssignmentTabContent extends StatelessWidget {
  const _AssignmentTabContent({
    required this.isLoading,
    required this.canEditAssignment,
    required this.isSavingAssignment,
    required this.hasSavedAssignment,
    required this.titleController,
    required this.descriptionController,
    required this.onSaveTap,
    this.onBoldTap,
    this.onItalicTap,
    this.onUnderlineTap,
    this.onBulletListTap,
    this.onNumberedListTap,
    this.onQuoteTap,
    this.onHeadingTap,
  });

  final bool isLoading;
  final bool canEditAssignment;
  final bool isSavingAssignment;
  final bool hasSavedAssignment;
  final TextEditingController titleController;
  final TrainingRichTextEditingController descriptionController;
  final Future<bool> Function() onSaveTap;
  final VoidCallback? onBoldTap;
  final VoidCallback? onItalicTap;
  final VoidCallback? onUnderlineTap;
  final VoidCallback? onBulletListTap;
  final VoidCallback? onNumberedListTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onHeadingTap;

  @override
  Widget build(BuildContext context) {
    final hasTitleContent = titleController.text.trim().isNotEmpty;
    final hasDescriptionContent = descriptionController.text.trim().isNotEmpty;
    final hasVisibleContent = hasTitleContent || hasDescriptionContent;
    final actionHeader = hasSavedAssignment
        ? AppStrings.trainingEditAction
        : AppStrings.trainingLibraryCreate;
    final actionLabel = hasSavedAssignment
        ? AppStrings.trainingSaveAction
        : AppStrings.trainingCreateAssignment;
    final actionIcon = hasSavedAssignment
        ? Icons.save_rounded
        : Icons.assignment_rounded;
    final descriptionContent = isLoading && !hasDescriptionContent
        ? SizedBox(
            height: 180,
            child: Center(child: FastCircularProgressIndicator()),
          )
        : _TrainingEditableTextCard(
            controller: descriptionController,
            hintText: AppStrings.trainingAssignmentDescriptionHint,
            minLines: 10,
            maxLines: 18,
            readOnly: !canEditAssignment || isSavingAssignment,
            wrapWithCard: !canEditAssignment,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          );

    if (!canEditAssignment && !hasVisibleContent) {
      if (isLoading) {
        return SizedBox(
          height: 180,
          child: Center(child: FastCircularProgressIndicator()),
        );
      }

      return const _ContentMessage(
        message: AppStrings.trainingNoAssignmentAvailable,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canEditAssignment) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AppTextView.body3(
                  actionHeader,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _GradientTrainingActionButton(
                label: actionLabel,
                icon: actionIcon,
                isEnabled: !isLoading,
                isLoading: isSavingAssignment,
                showLoaderInIconSlot: true,
                verticalPadding: 8,
                onTap: !isLoading
                    ? () {
                        unawaited(onSaveTap());
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const _TrainingSectionHeader(title: AppStrings.trainingLessonTitle),
        const SizedBox(height: 8),
        _TrainingSingleLineInputCard(
          controller: titleController,
          hintText: AppStrings.trainingAssignmentTitleHint,
          readOnly: !canEditAssignment || isSavingAssignment,
        ),
        const SizedBox(height: 18),
        const _TrainingSectionHeader(
          title: AppStrings.trainingAssignmentDescriptionLabel,
        ),
        const SizedBox(height: 8),
        if (canEditAssignment)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.fieldBorder.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrainingFormattingToolbar(
                  controller: descriptionController,
                  isSaving: isSavingAssignment,
                  onBoldTap: onBoldTap,
                  onItalicTap: onItalicTap,
                  onUnderlineTap: onUnderlineTap,
                  onBulletListTap: onBulletListTap,
                  onNumberedListTap: onNumberedListTap,
                  onQuoteTap: onQuoteTap,
                  onHeadingTap: onHeadingTap,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: AppColors.mainBg,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                  ),
                  child: descriptionContent,
                ),
              ],
            ),
          )
        else
          descriptionContent,
      ],
    );
  }
}

class _QuizTabContent extends StatelessWidget {
  const _QuizTabContent({
    required this.isLoading,
    required this.questions,
    required this.canManageQuestions,
    required this.canAddQuestion,
    required this.canGenerateQuiz,
    required this.isGeneratingQuiz,
    required this.isAddingQuestion,
    required this.savingQuestionId,
    required this.deletingQuestionId,
    required this.onAddQuestionTap,
    required this.onGenerateQuizTap,
    required this.onDeleteQuestionTap,
    required this.onSaveQuestionTap,
  });

  final bool isLoading;
  final List<SeatDescriptionTrainingQuestion> questions;
  final bool canManageQuestions;
  final bool canAddQuestion;
  final bool canGenerateQuiz;
  final bool isGeneratingQuiz;
  final bool isAddingQuestion;
  final String? savingQuestionId;
  final String? deletingQuestionId;
  final VoidCallback onAddQuestionTap;
  final VoidCallback onGenerateQuizTap;
  final Future<void> Function(SeatDescriptionTrainingQuestion question)
  onDeleteQuestionTap;
  final Future<bool> Function(
    String questionId,
    List<SeatDescriptionTrainingQuestionOption> options,
    String? correctOptionUuid,
  )
  onSaveQuestionTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canManageQuestions) ...[
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _SecondaryTrainingActionButton(
                  label: AppStrings.trainingAddQuestion,
                  icon: Icons.add_rounded,
                  isEnabled: canAddQuestion,
                  isLoading: isAddingQuestion,
                  isDottedBorder: true,
                  horizontalPadding: 16,
                  verticalPadding: 10,
                  borderRadius: 14,
                  backgroundColor: AppColors.secondaryColor.withValues(
                    alpha: 0.05,
                  ),
                  activeBorderColor: AppColors.secondaryColor.withValues(
                    alpha: 0.58,
                  ),
                  activeTextColor: AppColors.secondaryColor,
                  activeIconColor: AppColors.secondaryColor,
                  onTap: canAddQuestion ? onAddQuestionTap : null,
                ),
                _AiGenerateButton(
                  label: AppStrings.trainingGenerateQuiz,
                  isEnabled: canGenerateQuiz,
                  isLoading: isGeneratingQuiz,
                  onTap: canGenerateQuiz ? onGenerateQuizTap : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(child: FastCircularProgressIndicator()),
          )
        else if (questions.isEmpty)
          const _ContentMessage(
            message: AppStrings.trainingNoQuizQuestionsAvailable,
          )
        else
          for (var index = 0; index < questions.length; index++) ...[
            _QuizQuestionCard(
              number: index + 1,
              question: questions[index],
              canManageQuestions: canManageQuestions,
              isSaving: savingQuestionId == questions[index].uuid,
              isDeleting: deletingQuestionId == questions[index].uuid,
              onDeleteQuestionTap: onDeleteQuestionTap,
              onSaveQuestionTap: onSaveQuestionTap,
            ),
            if (index != questions.length - 1) const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _AiGenerateButton extends StatelessWidget {
  const _AiGenerateButton({
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.verticalPadding = 11,
  });

  final String label;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback? onTap;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return _GradientTrainingActionButton(
      label: label,
      icon: Icons.auto_awesome_rounded,
      isEnabled: isEnabled,
      isLoading: isLoading,
      verticalPadding: verticalPadding,
      onTap: onTap,
    );
  }
}

class _GradientTrainingActionButton extends StatelessWidget {
  const _GradientTrainingActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.showLoaderInIconSlot = false,
    this.verticalPadding = 11,
  });

  final String label;
  final IconData icon;
  final bool isEnabled;
  final bool isLoading;
  final bool showLoaderInIconSlot;
  final VoidCallback? onTap;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final isEnabledAppearance = isEnabled && onTap != null;
    final isInteractive = isEnabledAppearance && !isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            gradient: isEnabledAppearance
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [AppColors.purple1, AppColors.secondaryColor],
                  )
                : null,
            color: isEnabledAppearance ? null : AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEnabledAppearance
                  ? AppColors.lightPurple1.withValues(alpha: 0.35)
                  : AppColors.fieldBorder.withValues(alpha: 0.22),
            ),
            boxShadow: isEnabledAppearance
                ? [
                    BoxShadow(
                      color: AppColors.purple1.withValues(alpha: 0.36),
                      blurRadius: 10,
                      offset: const Offset(-6, 0),
                      spreadRadius: -1,
                    ),
                    BoxShadow(
                      color: AppColors.secondaryColor.withValues(alpha: 0.42),
                      blurRadius: 16,
                      offset: const Offset(12, 0),
                      spreadRadius: -2,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLoaderInIconSlot && isLoading)
                FastCircularProgressIndicator(width: 16, height: 16)
              else
                Icon(
                  icon,
                  size: 16,
                  color: isEnabledAppearance
                      ? Colors.white.withValues(alpha: 0.96)
                      : AppColors.textSecondary,
                ),
              const SizedBox(width: 8),
              AppTextView.body2(
                label,
                color: isEnabledAppearance
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              if (isLoading && !showLoaderInIconSlot) ...[
                const SizedBox(width: 10),
                FastCircularProgressIndicator(width: 14, height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryTrainingActionButton extends StatelessWidget {
  const _SecondaryTrainingActionButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.isEnabled = true,
    this.isLoading = false,
    this.isDottedBorder = false,
    this.horizontalPadding = 14,
    this.verticalPadding = 10,
    this.borderRadius = 999,
    this.backgroundColor,
    this.activeBorderColor,
    this.activeTextColor,
    this.activeIconColor,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isEnabled;
  final bool isLoading;
  final bool isDottedBorder;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? activeBorderColor;
  final Color? activeTextColor;
  final Color? activeIconColor;

  @override
  Widget build(BuildContext context) {
    final isInteractive = isEnabled && !isLoading && onTap != null;
    final borderColor = isInteractive
        ? activeBorderColor ?? AppColors.fieldBorder.withValues(alpha: 0.22)
        : AppColors.fieldBorder.withValues(alpha: 0.14);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          foregroundPainter: isDottedBorder
              ? _DottedRoundedBorderPainter(
                  color: borderColor,
                  radius: borderRadius,
                )
              : null,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(borderRadius),
              border: isDottedBorder ? null : Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isInteractive
                        ? activeIconColor ?? AppColors.secondaryColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                AppTextView.body2(
                  label,
                  color: isInteractive
                      ? activeTextColor ?? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                if (isLoading) ...[
                  const SizedBox(width: 10),
                  FastCircularProgressIndicator(width: 14, height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrainingSectionHeader extends StatelessWidget {
  const _TrainingSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppTextView.body3(
      title,
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w700,
    );
  }
}

class _TrainingDisplayCard extends StatelessWidget {
  const _TrainingDisplayCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: child,
    );
  }
}

class _TrainingEditableTextCard extends StatelessWidget {
  const _TrainingEditableTextCard({
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
    this.readOnly = false,
    this.wrapWithCard = true,
    this.padding = const EdgeInsets.all(16),
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;
  final bool readOnly;
  final bool wrapWithCard;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textField = Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        cursorColor: Colors.white,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.65,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.74),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.65,
          ),
        ),
      ),
    );

    if (!wrapWithCard) {
      return textField;
    }

    return _TrainingDisplayCard(child: textField);
  }
}

class _TrainingSingleLineInputCard extends StatelessWidget {
  const _TrainingSingleLineInputCard({
    required this.controller,
    required this.hintText,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return _TrainingDisplayCard(
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        cursorColor: Colors.white,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.74),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TrainingFormattingToolbar extends StatelessWidget {
  const _TrainingFormattingToolbar({
    required this.controller,
    required this.isSaving,
    this.onBoldTap,
    this.onItalicTap,
    this.onUnderlineTap,
    this.onBulletListTap,
    this.onNumberedListTap,
    this.onQuoteTap,
    this.onHeadingTap,
  });

  final TrainingRichTextEditingController controller;
  final bool isSaving;
  final VoidCallback? onBoldTap;
  final VoidCallback? onItalicTap;
  final VoidCallback? onUnderlineTap;
  final VoidCallback? onBulletListTap;
  final VoidCallback? onNumberedListTap;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onHeadingTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _TrainingFormattingButton(
                tooltip: AppStrings.trainingBoldAction,
                icon: Icons.format_bold_rounded,
                isActive: controller.isFormatActive(
                  TrainingDocumentFormatKind.bold,
                ),
                onTap: isSaving ? null : onBoldTap,
              ),
              const SizedBox(width: 8),
              _TrainingFormattingButton(
                tooltip: AppStrings.trainingItalicAction,
                icon: Icons.format_italic_rounded,
                isActive: controller.isFormatActive(
                  TrainingDocumentFormatKind.italic,
                ),
                onTap: isSaving ? null : onItalicTap,
              ),
              const SizedBox(width: 8),
              _TrainingFormattingButton(
                tooltip: AppStrings.trainingUnderlineAction,
                icon: Icons.format_underline_rounded,
                isActive: controller.isFormatActive(
                  TrainingDocumentFormatKind.underline,
                ),
                onTap: isSaving ? null : onUnderlineTap,
              ),
              const SizedBox(width: 8),
              _TrainingFormattingButton(
                tooltip: AppStrings.trainingBulletListAction,
                icon: Icons.format_list_bulleted_rounded,
                isActive: controller.isBulletListActive,
                onTap: isSaving ? null : onBulletListTap,
              ),
              const SizedBox(width: 8),
              _TrainingFormattingButton(
                tooltip: AppStrings.trainingNumberedListAction,
                icon: Icons.format_list_numbered_rounded,
                isActive: controller.isNumberedListActive,
                onTap: isSaving ? null : onNumberedListTap,
              ),
              const SizedBox(width: 8),
              _TrainingFormattingButton(
                tooltip: AppStrings.trainingQuoteAction,
                icon: Icons.format_quote_rounded,
                isActive: controller.isFormatActive(
                  TrainingDocumentFormatKind.quote,
                ),
                onTap: isSaving ? null : onQuoteTap,
              ),
              const SizedBox(width: 8),
              _TrainingFormattingButton(
                tooltip: AppStrings.trainingHeadingAction,
                icon: Icons.title_rounded,
                isActive: controller.isFormatActive(
                  TrainingDocumentFormatKind.heading,
                ),
                onTap: isSaving ? null : onHeadingTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingFormattingButton extends StatelessWidget {
  const _TrainingFormattingButton({
    required this.tooltip,
    required this.icon,
    this.isActive = false,
    this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null;
    final borderColor = isActive
        ? AppColors.secondaryColor.withValues(alpha: 0.64)
        : AppColors.fieldBorder.withValues(alpha: isInteractive ? 0.22 : 0.12);
    final backgroundColor = isActive
        ? AppColors.secondaryColor.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: isInteractive ? 0.08 : 0.04);
    final iconColor = isActive
        ? AppColors.secondaryColor
        : isInteractive
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.58);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ),
      ),
    );
  }
}

class _GenerateQuizDialog extends StatelessWidget {
  const _GenerateQuizDialog();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: AppTextView.body1(
                      AppStrings.trainingGenerateQuizDialogTitle,
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _DialogCloseButton(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _DividerDot(),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.fieldBorder.withValues(alpha: 0.34),
                    ),
                  ),
                  _DividerDot(),
                ],
              ),
              const SizedBox(height: 20),
              const Center(
                child: AppTextView.body(
                  AppStrings.trainingGenerateQuizDialogTitle,
                  color: AppColors.hexd9deff,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: AppTextView.body2(
                  AppStrings.trainingGenerateQuizDialogDescription,
                  color: AppColors.lightPurple1,
                  fontSize: 12,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 18),
              _QuizSettingsCard(controller: controller),
              const SizedBox(height: 18),
              Center(
                child: SizedBox(
                  width: 196,
                  child: TextButton.icon(
                    onPressed: controller.isGeneratingQuiz
                        ? null
                        : () async {
                            final didGenerate = await context
                                .read<TrainingModuleController>()
                                .generateQuizForSelectedModule();
                            if (!context.mounted || !didGenerate) {
                              return;
                            }

                            Navigator.of(context).pop(true);
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      disabledForegroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.secondaryColor,
                      disabledBackgroundColor: AppColors.secondaryColor
                          .withValues(alpha: 0.55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: AppColors.secondaryColor),
                      ),
                    ),
                    icon: controller.isGeneratingQuiz
                        ? FastCircularProgressIndicator(width: 16, height: 16)
                        : const Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: AppColors.textPrimary,
                          ),
                    label: AppTextView.body(
                      AppStrings.trainingGenerateQuiz,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
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

class _AddQuestionDialog extends StatefulWidget {
  const _AddQuestionDialog();

  @override
  State<_AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogFormController extends ChangeNotifier {
  _AddQuestionDialogFormController({required int initialOptionCount}) {
    for (var index = 0; index < initialOptionCount; index++) {
      optionControllers.add(_buildOptionController());
    }
  }

  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      <TextEditingController>[];
  int selectedCorrectOptionIndex = 0;
  String? validationMessage;

  TextEditingController _buildOptionController() {
    return TextEditingController()..addListener(clearValidationMessage);
  }

  void addOptionField() {
    if (optionControllers.length >=
        TrainingModuleController.maxQuizOptionsPerQuestion) {
      return;
    }

    optionControllers.add(_buildOptionController());
    validationMessage = null;
    notifyListeners();
  }

  void removeOptionField(int index, {required int minOptionCount}) {
    if (optionControllers.length <= minOptionCount) {
      return;
    }

    final controller = optionControllers.removeAt(index);
    controller
      ..removeListener(clearValidationMessage)
      ..dispose();

    if (selectedCorrectOptionIndex >= optionControllers.length) {
      selectedCorrectOptionIndex = optionControllers.length - 1;
    } else if (index < selectedCorrectOptionIndex) {
      selectedCorrectOptionIndex -= 1;
    }

    validationMessage = null;
    notifyListeners();
  }

  void selectCorrectOption(int index) {
    if (selectedCorrectOptionIndex == index && validationMessage == null) {
      return;
    }

    selectedCorrectOptionIndex = index;
    validationMessage = null;
    notifyListeners();
  }

  void setValidationMessage(String message) {
    validationMessage = message;
    notifyListeners();
  }

  void clearValidationMessage() {
    if (validationMessage == null) {
      return;
    }

    validationMessage = null;
    notifyListeners();
  }

  String? validate({required int minOptionCount}) {
    if (questionController.text.trim().isEmpty) {
      return AppStrings.trainingQuestionRequired;
    }

    if (optionControllers.length < minOptionCount) {
      return AppStrings.trainingQuestionMinOptionsRequired;
    }

    final hasEmptyOption = optionControllers.any(
      (controller) => controller.text.trim().isEmpty,
    );
    if (hasEmptyOption) {
      return AppStrings.trainingQuestionOptionsRequired;
    }

    if (selectedCorrectOptionIndex < 0 ||
        selectedCorrectOptionIndex >= optionControllers.length) {
      return AppStrings.trainingQuestionCorrectOptionRequired;
    }

    return null;
  }

  @override
  void dispose() {
    questionController.dispose();
    for (final controller in optionControllers) {
      controller
        ..removeListener(clearValidationMessage)
        ..dispose();
    }
    super.dispose();
  }
}

class _AddQuestionDialogState extends State<_AddQuestionDialog> {
  static const int _minOptionCount = 2;
  static const int _initialOptionCount = 3;
  late final _AddQuestionDialogFormController _formController;

  @override
  void initState() {
    super.initState();
    _formController = _AddQuestionDialogFormController(
      initialOptionCount: _initialOptionCount,
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validationMessage = _formController.validate(
      minOptionCount: _minOptionCount,
    );
    if (validationMessage != null) {
      _formController.setValidationMessage(validationMessage);
      return;
    }

    final didAdd = await context
        .read<TrainingModuleController>()
        .addQuestionToSelectedModule(
          questionText: _formController.questionController.text.trim(),
          optionTexts: _formController.optionControllers
              .map((controller) => controller.text.trim())
              .toList(growable: false),
          correctOptionIndex: _formController.selectedCorrectOptionIndex,
        );
    if (!mounted || !didAdd) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return AnimatedBuilder(
      animation: _formController,
      builder: (context, _) => Dialog(
        backgroundColor: AppColors.surfaceDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: AppTextView.body1(
                        AppStrings.trainingAddQuestionDialogTitle,
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _DialogCloseButton(
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _DividerDot(),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.fieldBorder.withValues(alpha: 0.34),
                      ),
                    ),
                    _DividerDot(),
                  ],
                ),
                const SizedBox(height: 20),
                const AppTextView.body2(
                  AppStrings.trainingAddQuestionDialogDescription,
                  color: AppColors.lightPurple1,
                  fontSize: 13,
                  height: 1.5,
                ),
                const SizedBox(height: 20),
                _QuizDialogField(
                  label: AppStrings.trainingQuestionLabel,
                  hintText: AppStrings.trainingQuestionHint,
                  controller: _formController.questionController,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: _formController.clearValidationMessage,
                ),
                const SizedBox(height: 18),
                const AppTextView.body3(
                  AppStrings.trainingQuestionOptionsLabel,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 6),
                const AppTextView.body4(
                  AppStrings.trainingQuestionSelectCorrectAnswerHint,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                const SizedBox(height: 14),
                for (
                  var index = 0;
                  index < _formController.optionControllers.length;
                  index++
                ) ...[
                  _QuizOptionEditorCard(
                    label: AppStrings.trainingQuestionOptionLabel(index + 1),
                    hintText: AppStrings.trainingQuestionOptionHint(index + 1),
                    controller: _formController.optionControllers[index],
                    isSelected:
                        _formController.selectedCorrectOptionIndex == index,
                    onSelect: () => _formController.selectCorrectOption(index),
                    onChanged: _formController.clearValidationMessage,
                    onRemove:
                        _formController.optionControllers.length >
                            _minOptionCount
                        ? () => _formController.removeOptionField(
                            index,
                            minOptionCount: _minOptionCount,
                          )
                        : null,
                  ),
                  if (index != _formController.optionControllers.length - 1)
                    const SizedBox(height: 12),
                ],
                const SizedBox(height: 14),
                if (_formController.optionControllers.length <
                    TrainingModuleController.maxQuizOptionsPerQuestion)
                  _InlineTextAction(
                    label: AppStrings.trainingQuestionAddOption,
                    icon: Icons.add_circle_outline_rounded,
                    onTap: _formController.addOptionField,
                  ),
                if (_formController.validationMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.22),
                      ),
                    ),
                    child: AppTextView.body3(
                      _formController.validationMessage!,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Center(
                  child: SizedBox(
                    width: 210,
                    child: TextButton.icon(
                      onPressed: controller.isAddingQuestion ? null : _submit,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        disabledForegroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: AppColors.secondaryColor,
                        disabledBackgroundColor: AppColors.secondaryColor
                            .withValues(alpha: 0.55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: const BorderSide(
                            color: AppColors.secondaryColor,
                          ),
                        ),
                      ),
                      icon: controller.isAddingQuestion
                          ? FastCircularProgressIndicator(width: 16, height: 16)
                          : const Icon(
                              Icons.playlist_add_rounded,
                              size: 17,
                              color: AppColors.textPrimary,
                            ),
                      label: const AppTextView.body(
                        AppStrings.trainingQuestionSaveAction,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizDialogField extends StatelessWidget {
  const _QuizDialogField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final int minLines;
  final int maxLines;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextView.body3(
          label,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          minLines: minLines,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          cursorColor: Colors.white,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.72),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.mainBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.18),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.18),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizOptionEditorCard extends StatelessWidget {
  const _QuizOptionEditorCard({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.isSelected,
    required this.onSelect,
    required this.onChanged,
    this.onRemove,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? AppColors.secondaryColor
              : AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected
                          ? AppColors.secondaryColor
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    AppTextView.body3(
                      label,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                _InlineTextAction(
                  label: AppStrings.trainingRemoveOption,
                  icon: Icons.remove_circle_outline_rounded,
                  color: AppColors.red,
                  onTap: onRemove!,
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.sentences,
            cursorColor: Colors.white,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppColors.surfaceDark2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.fieldBorder.withValues(alpha: 0.18),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.fieldBorder.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.secondaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineTextAction extends StatelessWidget {
  const _InlineTextAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = AppColors.secondaryColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            AppTextView.body3(label, color: color, fontWeight: FontWeight.w700),
          ],
        ),
      ),
    );
  }
}

class _QuizSettingsCard extends StatelessWidget {
  const _QuizSettingsCard({required this.controller});

  final TrainingModuleController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.bgGlow.withValues(alpha: 0.95),
                AppColors.surfaceDark.withValues(alpha: 0.98),
              ],
            ),
            border: Border.all(
              color: AppColors.secondaryColor.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AppTextView.body1(
                      AppStrings.trainingGenerateQuiz,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _QuizGenerationStepper(
                label: AppStrings.trainingQuizNumberOfQuestions,
                value: controller.quizGenerationQuestionCount,
                onIncrement: controller.incrementQuizQuestionCount,
                onDecrement: controller.decrementQuizQuestionCount,
                canIncrement:
                    controller.quizGenerationQuestionCount <
                    TrainingModuleController.maxQuizQuestionCount,
                canDecrement:
                    controller.quizGenerationQuestionCount >
                    TrainingModuleController.minQuizQuestionCount,
              ),
              const SizedBox(height: 10),
              _QuizGenerationStepper(
                label: AppStrings.trainingQuizOptionsPerQuestion,
                value: controller.quizGenerationOptionsPerQuestion,
                onIncrement: controller.incrementQuizOptionsPerQuestion,
                onDecrement: controller.decrementQuizOptionsPerQuestion,
                canIncrement:
                    controller.quizGenerationOptionsPerQuestion <
                    TrainingModuleController.maxQuizOptionsPerQuestion,
                canDecrement:
                    controller.quizGenerationOptionsPerQuestion >
                    TrainingModuleController.minQuizOptionsPerQuestion,
              ),
              const SizedBox(height: 10),
              const AppTextView.body3(
                AppStrings.trainingQuizDifficultyLevel,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuizDifficultyChip(
                    label: AppStrings.trainingQuizDifficultyEasy,
                    isSelected:
                        controller.quizGenerationDifficulty ==
                        QuizGenerationDifficulty.easy,
                    onTap: () => controller.setQuizGenerationDifficulty(
                      QuizGenerationDifficulty.easy,
                    ),
                  ),
                  _QuizDifficultyChip(
                    label: AppStrings.trainingQuizDifficultyMedium,
                    isSelected:
                        controller.quizGenerationDifficulty ==
                        QuizGenerationDifficulty.medium,
                    onTap: () => controller.setQuizGenerationDifficulty(
                      QuizGenerationDifficulty.medium,
                    ),
                  ),
                  _QuizDifficultyChip(
                    label: AppStrings.trainingQuizDifficultyHard,
                    isSelected:
                        controller.quizGenerationDifficulty ==
                        QuizGenerationDifficulty.hard,
                    onTap: () => controller.setQuizGenerationDifficulty(
                      QuizGenerationDifficulty.hard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _QuizReplaceToggle(
                value: controller.replaceExistingQuestions,
                onChanged: controller.setReplaceExistingQuestions,
              ),
            ],
          ),
        ),
        Positioned(
          top: -6,
          right: -2,
          child: IgnorePointer(
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withValues(alpha: 0.26),
                    blurRadius: 70,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenerateSopDialog extends StatefulWidget {
  const _GenerateSopDialog();

  @override
  State<_GenerateSopDialog> createState() => _GenerateSopDialogState();
}

class _GenerateSopDialogState extends State<_GenerateSopDialog> {
  final TextEditingController _confirmationController = TextEditingController();

  bool get _canRegenerate {
    return _confirmationController.text.trim().toUpperCase() ==
        AppStrings.trainingGenerateSopConfirmation;
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();
    final hasExistingSop = controller.hasSelectedModuleDocumentText;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _confirmationController,
      builder: (context, _, __) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 620),
              decoration: const BoxDecoration(
                color: AppColors.mainBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const AppTextView.body1(
                      AppStrings.trainingGenerateWithAi,
                      color: AppColors.secondaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _DividerDot(),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.fieldBorder.withValues(
                              alpha: 0.24,
                            ),
                          ),
                        ),
                        _DividerDot(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondaryColor.withValues(alpha: 0.08),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 28,
                          color: AppColors.secondaryColor.withValues(
                            alpha: 0.96,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextView.body1(
                      hasExistingSop
                          ? AppStrings.trainingRegenerate
                          : AppStrings.trainingGenerateSop,
                      color: AppColors.hexd9deff,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    AppTextView.body(
                      hasExistingSop
                          ? AppStrings.trainingGenerateSopAlertDescription
                          : AppStrings.trainingGenerateSopSubtitle,
                      color: AppColors.lightPurple1,
                      fontSize: 13,
                      height: 1.45,
                      textAlign: TextAlign.center,
                    ),
                    if (hasExistingSop) ...[
                      const SizedBox(height: 18),
                      _SopAlertCard(
                        confirmationController: _confirmationController,
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _DividerDot(),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.fieldBorder.withValues(
                              alpha: 0.24,
                            ),
                          ),
                        ),
                        _DividerDot(),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed:
                            (controller.isGeneratingSop ||
                                (hasExistingSop && !_canRegenerate))
                            ? null
                            : () async {
                                final didGenerate = await context
                                    .read<TrainingModuleController>()
                                    .generateSopForSelectedModule();
                                if (!context.mounted || !didGenerate) {
                                  return;
                                }

                                Navigator.of(context).pop(true);
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          disabledForegroundColor: AppColors.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor:
                              (controller.isGeneratingSop ||
                                  (hasExistingSop && !_canRegenerate))
                              ? AppColors.surfaceDark3
                              : AppColors.secondaryColor,
                          disabledBackgroundColor: AppColors.surfaceDark3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color:
                                  (controller.isGeneratingSop ||
                                      (hasExistingSop && !_canRegenerate))
                                  ? AppColors.fieldBorder.withValues(
                                      alpha: 0.12,
                                    )
                                  : AppColors.secondaryColor,
                            ),
                          ),
                        ),
                        icon: controller.isGeneratingSop
                            ? FastCircularProgressIndicator(
                                width: 14,
                                height: 14,
                              )
                            : const Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                        label: AppTextView.body(
                          hasExistingSop
                              ? AppStrings.trainingRegenerate
                              : AppStrings.trainingGenerateWithAi,
                          fontSize: 14,
                          color:
                              (controller.isGeneratingSop ||
                                  (hasExistingSop && !_canRegenerate))
                              ? AppColors.textSecondary.withValues(alpha: 0.7)
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.78),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.textPrimary,
          size: 16,
        ),
      ),
    );
  }
}

class _QuizGenerationStepper extends StatelessWidget {
  const _QuizGenerationStepper({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    required this.canIncrement,
    required this.canDecrement,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool canIncrement;
  final bool canDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextView.body2(
              label,
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          _StepperActionButton(
            icon: Icons.remove_rounded,
            onTap: canDecrement ? onDecrement : null,
          ),
          SizedBox(
            width: 38,
            child: AppTextView.body1(
              '$value',
              fontSize: 16,
              textAlign: TextAlign.center,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          _StepperActionButton(
            icon: Icons.add_rounded,
            onTap: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepperActionButton extends StatelessWidget {
  const _StepperActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: onTap == null
              ? AppColors.surfaceDark.withValues(alpha: 0.45)
              : AppColors.surfaceDark,
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap == null
                ? AppColors.fieldBorder.withValues(alpha: 0.1)
                : AppColors.fieldBorder.withValues(alpha: 0.16),
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null
              ? AppColors.textSecondary.withValues(alpha: 0.45)
              : AppColors.textPrimary,
          size: 14,
        ),
      ),
    );
  }
}

class _QuizDifficultyChip extends StatelessWidget {
  const _QuizDifficultyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondaryColor.withValues(alpha: 0.16)
              : AppColors.mainBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryColor
                : AppColors.fieldBorder.withValues(alpha: 0.18),
          ),
        ),
        child: AppTextView.body2(
          label,
          fontSize: 13,
          color: isSelected
              ? AppColors.secondaryColor
              : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuizReplaceToggle extends StatelessWidget {
  const _QuizReplaceToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: AppTextView.body3(
              AppStrings.trainingQuizReplaceExistingQuestions,
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppTextView.body4(
            value
                ? AppStrings.trainingQuizEnabled
                : AppStrings.trainingQuizDisabled,
            color: value ? AppColors.secondaryColor : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.secondaryColor,
            activeTrackColor: AppColors.secondaryColor.withValues(alpha: 0.4),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DividerDot extends StatelessWidget {
  const _DividerDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: AppColors.hex51597a,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SopAlertCard extends StatelessWidget {
  const _SopAlertCard({required this.confirmationController});

  final TextEditingController confirmationController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: AppTextView.body1(
                  AppStrings.trainingGenerateSopAlertTitle,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const AppTextView.body(
            AppStrings.trainingGenerateSopAlertInstruction,
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmationController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.trainingGenerateSopConfirmation,
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.72),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
              filled: true,
              fillColor: AppColors.surfaceDark2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({
    required this.number,
    required this.question,
    required this.canManageQuestions,
    required this.isSaving,
    required this.isDeleting,
    required this.onDeleteQuestionTap,
    required this.onSaveQuestionTap,
  });

  final int number;
  final SeatDescriptionTrainingQuestion question;
  final bool canManageQuestions;
  final bool isSaving;
  final bool isDeleting;
  final Future<void> Function(SeatDescriptionTrainingQuestion question)
  onDeleteQuestionTap;
  final Future<bool> Function(
    String questionId,
    List<SeatDescriptionTrainingQuestionOption> options,
    String? correctOptionUuid,
  )
  onSaveQuestionTap;

  @override
  Widget build(BuildContext context) {
    return _EditableQuizQuestionCard(
      number: number,
      question: question,
      canManageQuestions: canManageQuestions,
      isSaving: isSaving,
      isDeleting: isDeleting,
      onDeleteQuestionTap: onDeleteQuestionTap,
      onSaveQuestionTap: onSaveQuestionTap,
    );
  }
}

class _EditableQuizQuestionCard extends StatefulWidget {
  const _EditableQuizQuestionCard({
    required this.number,
    required this.question,
    required this.canManageQuestions,
    required this.isSaving,
    required this.isDeleting,
    required this.onDeleteQuestionTap,
    required this.onSaveQuestionTap,
  });

  final int number;
  final SeatDescriptionTrainingQuestion question;
  final bool canManageQuestions;
  final bool isSaving;
  final bool isDeleting;
  final Future<void> Function(SeatDescriptionTrainingQuestion question)
  onDeleteQuestionTap;
  final Future<bool> Function(
    String questionId,
    List<SeatDescriptionTrainingQuestionOption> options,
    String? correctOptionUuid,
  )
  onSaveQuestionTap;

  @override
  State<_EditableQuizQuestionCard> createState() =>
      _EditableQuizQuestionCardState();
}

class _EditableQuizQuestionCardState extends State<_EditableQuizQuestionCard> {
  late final _QuizQuestionEditorController _editorController;

  @override
  void initState() {
    super.initState();
    _editorController = _QuizQuestionEditorController(
      question: widget.question,
    );
  }

  @override
  void didUpdateWidget(covariant _EditableQuizQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _editorController.syncWithQuestion(widget.question);
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (widget.isSaving || widget.isDeleting) {
      return;
    }

    final validationMessage = _editorController.validate(widget.question);
    if (validationMessage != null) {
      _editorController.setValidationMessage(validationMessage);
      return;
    }

    await widget.onSaveQuestionTap(
      widget.question.uuid,
      _editorController.buildOptions(widget.question),
      _editorController.selectedCorrectOptionUuid,
    );
  }

  Future<void> _deleteQuestion() async {
    if (widget.isSaving || widget.isDeleting) {
      return;
    }

    await widget.onDeleteQuestionTap(widget.question);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(
      widget.question.imageUrl,
    );

    return AnimatedBuilder(
      animation: _editorController,
      builder: (context, _) {
        final isBusy = widget.isSaving || widget.isDeleting;
        final visibleOptions = _editorController.visibleExistingOptions(
          widget.question,
        );
        final correctOptionChoices = [
          for (var index = 0; index < visibleOptions.length; index++)
            _QuizCorrectOptionChoice(
              uuid: visibleOptions[index].uuid,
              label: AppStrings.trainingQuestionChoiceLabel(index + 1),
            ),
          if (_editorController.showsDraftOption)
            _QuizCorrectOptionChoice(
              uuid: _editorController.draftOptionUuid,
              label: AppStrings.trainingQuestionChoiceLabel(
                visibleOptions.length + 1,
              ),
            ),
        ];
        final canAddOption =
            widget.canManageQuestions &&
            _editorController.canAddOption() &&
            !isBusy;
        final canSaveQuestion =
            widget.canManageQuestions &&
            !isBusy &&
            _editorController.canSave(question: widget.question);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextView.body3(
                      '${widget.number}. ${widget.question.question}',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              if (resolvedImageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: resolvedImageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              if (visibleOptions.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (var index = 0; index < visibleOptions.length; index++) ...[
                  _QuizOptionTile(
                    controller: _editorController.optionControllerFor(
                      visibleOptions[index],
                    ),
                    hintText: AppStrings.trainingQuestionOptionHint(index + 1),
                    isSelected: _editorController.isOptionSelected(
                      visibleOptions[index].uuid,
                    ),
                    isEditable: widget.canManageQuestions && !isBusy,
                    canDelete: widget.canManageQuestions,
                    onTap:
                        widget.canManageQuestions &&
                            !isBusy &&
                            !_editorController.showsDraftOption
                        ? () => _editorController.selectOption(
                            visibleOptions[index].uuid,
                          )
                        : null,
                    onDeleteTap: isBusy
                        ? null
                        : () => _editorController.removeExistingOption(
                            visibleOptions[index].uuid,
                          ),
                  ),
                  if (index != visibleOptions.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
              if (_editorController.showsDraftOption) ...[
                const SizedBox(height: 10),
                _DraftQuizOptionTile(
                  controller: _editorController.draftOptionController,
                  hintText: AppStrings.trainingQuestionOptionHint(
                    visibleOptions.length + 1,
                  ),
                  isSelected: false,
                  onSelect: null,
                  onDeleteTap: isBusy
                      ? null
                      : () => _editorController.removeDraftOption(
                          widget.question,
                        ),
                ),
              ],
              if (canAddOption) ...[
                const SizedBox(height: 12),
                _InlineTextAction(
                  label: AppStrings.trainingQuestionAddOption,
                  icon: Icons.add_rounded,
                  onTap: () =>
                      _editorController.showDraftOption(widget.question),
                ),
              ],
              if (_editorController.validationMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.22),
                    ),
                  ),
                  child: AppTextView.body3(
                    _editorController.validationMessage!,
                    color: AppColors.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
              if (widget.canManageQuestions) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _QuizCorrectOptionDropdown(
                        value: _editorController.selectedCorrectOptionUuid,
                        options: correctOptionChoices,
                        onChanged: isBusy
                            ? null
                            : _editorController.selectCorrectOption,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 44,
                        child: TextButton(
                          onPressed: canSaveQuestion ? _saveQuestion : null,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            disabledForegroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            backgroundColor: AppColors.secondaryColor,
                            disabledBackgroundColor: AppColors.secondaryColor
                                .withValues(alpha: 0.42),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: AppColors.secondaryColor,
                              ),
                            ),
                          ),
                          child: widget.isSaving
                              ? FastCircularProgressIndicator(
                                  width: 16,
                                  height: 16,
                                )
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AppTextView.body(
                                    AppStrings.trainingQuestionSaveAction,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: AppStrings.trainingDeleteQuestionAction,
                      child: InkWell(
                        onTap: isBusy ? null : _deleteQuestion,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          width: 38,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.32),
                            ),
                          ),
                          child: Center(
                            child: widget.isDeleting
                                ? FastCircularProgressIndicator(
                                    width: 14,
                                    height: 14,
                                  )
                                : const Icon(
                                    Icons.delete_forever_rounded,
                                    color: AppColors.red,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QuizQuestionEditorController extends ChangeNotifier {
  _QuizQuestionEditorController({
    required SeatDescriptionTrainingQuestion question,
  }) : draftOptionController = TextEditingController() {
    draftOptionController.addListener(_handleDraftOptionChanged);
    syncWithQuestion(question, force: true);
  }

  final TextEditingController draftOptionController;
  final Map<String, TextEditingController> _optionControllers =
      <String, TextEditingController>{};
  final List<String> _activeOptionUuids = <String>[];

  String _questionSignature = '';
  String _selectedOptionUuid = '';
  String _initialSelectedOptionUuid = '';
  String _draftOptionUuid = '';
  String _draftCorrectOptionUuid = '';
  bool _showsDraftOption = false;
  String? _validationMessage;
  bool _isSyncingDraftText = false;

  String get selectedOptionUuid => _selectedOptionUuid;
  String get selectedCorrectOptionUuid =>
      _showsDraftOption ? _draftCorrectOptionUuid : _selectedOptionUuid;
  String get draftOptionUuid => _draftOptionUuid;
  bool get showsDraftOption => _showsDraftOption;
  String? get validationMessage => _validationMessage;

  bool isOptionSelected(String optionUuid) => _selectedOptionUuid == optionUuid;

  TextEditingController optionControllerFor(
    SeatDescriptionTrainingQuestionOption option,
  ) {
    return _optionControllers.putIfAbsent(
      option.uuid,
      () =>
          TextEditingController(text: option.text)
            ..addListener(_handleExistingOptionChanged),
    );
  }

  bool canAddOption() => !_showsDraftOption;

  List<SeatDescriptionTrainingQuestionOption> visibleExistingOptions(
    SeatDescriptionTrainingQuestion question,
  ) {
    final originalOptionsByUuid =
        <String, SeatDescriptionTrainingQuestionOption>{
          for (final option in question.options) option.uuid: option,
        };

    return _activeOptionUuids
        .map((uuid) => originalOptionsByUuid[uuid])
        .whereType<SeatDescriptionTrainingQuestionOption>()
        .toList(growable: false);
  }

  bool canSave({required SeatDescriptionTrainingQuestion question}) {
    final hasCorrectSelectionChange =
        selectedCorrectOptionUuid != _initialSelectedOptionUuid;
    final hasDraftChange =
        _showsDraftOption && draftOptionController.text.trim().isNotEmpty;
    final hasExistingOptionStructureChanges =
        _hasExistingOptionStructureChanges(question);
    final hasExistingOptionChanges = _hasExistingOptionTextChanges(question);
    if (!hasCorrectSelectionChange &&
        !hasDraftChange &&
        !hasExistingOptionStructureChanges &&
        !hasExistingOptionChanges) {
      return false;
    }

    if (_hasEmptyExistingOptionText(question) ||
        (_showsDraftOption && draftOptionController.text.trim().isEmpty)) {
      return false;
    }

    final options = buildOptions(question);
    if (options.length < TrainingModuleController.minQuizOptionsPerQuestion) {
      return false;
    }

    return options.any((option) => option.uuid == selectedCorrectOptionUuid);
  }

  void syncWithQuestion(
    SeatDescriptionTrainingQuestion question, {
    bool force = false,
  }) {
    final nextSignature = _buildQuestionSignature(question);
    if (!force && nextSignature == _questionSignature) {
      return;
    }

    _questionSignature = nextSignature;
    _initialSelectedOptionUuid = _resolveSelectedOptionUuid(question);
    _selectedOptionUuid = _initialSelectedOptionUuid;
    _showsDraftOption = false;
    _draftOptionUuid = '';
    _draftCorrectOptionUuid = '';
    _validationMessage = null;
    _syncOptionControllers(question);
    _activeOptionUuids
      ..clear()
      ..addAll(question.options.map((option) => option.uuid));
    _setDraftText('');
    notifyListeners();
  }

  void showDraftOption(SeatDescriptionTrainingQuestion question) {
    if (!canAddOption()) {
      return;
    }

    _showsDraftOption = true;
    _draftOptionUuid = TrainingModuleController.generateClientUuid();
    _draftCorrectOptionUuid = _selectedOptionUuid;
    _validationMessage = null;
    notifyListeners();
  }

  void removeDraftOption(SeatDescriptionTrainingQuestion question) {
    if (!_showsDraftOption) {
      return;
    }

    _showsDraftOption = false;
    _draftOptionUuid = '';
    _draftCorrectOptionUuid = '';
    _validationMessage = null;
    _setDraftText('');
    if (_selectedOptionUuid.isEmpty) {
      _selectedOptionUuid = _firstActiveOptionUuid();
    }
    notifyListeners();
  }

  void selectOption(String optionUuid) {
    if (_showsDraftOption) {
      return;
    }

    final resolvedOptionUuid = optionUuid.trim();
    if (resolvedOptionUuid.isEmpty) {
      return;
    }

    if (_selectedOptionUuid == resolvedOptionUuid &&
        _validationMessage == null) {
      return;
    }

    _selectedOptionUuid = resolvedOptionUuid;
    _validationMessage = null;
    notifyListeners();
  }

  void selectCorrectOption(String? optionUuid) {
    final resolvedOptionUuid = optionUuid?.trim() ?? '';
    if (resolvedOptionUuid.isEmpty) {
      return;
    }

    if (_showsDraftOption) {
      if (_draftCorrectOptionUuid == resolvedOptionUuid &&
          _validationMessage == null) {
        return;
      }

      _draftCorrectOptionUuid = resolvedOptionUuid;
    } else {
      if (_selectedOptionUuid == resolvedOptionUuid &&
          _validationMessage == null) {
        return;
      }

      _selectedOptionUuid = resolvedOptionUuid;
    }

    _validationMessage = null;
    notifyListeners();
  }

  void removeExistingOption(String optionUuid) {
    final resolvedOptionUuid = optionUuid.trim();
    if (resolvedOptionUuid.isEmpty ||
        !_activeOptionUuids.remove(resolvedOptionUuid)) {
      return;
    }

    final removedController = _optionControllers.remove(resolvedOptionUuid);
    removedController
      ?..removeListener(_handleExistingOptionChanged)
      ..dispose();

    if (_selectedOptionUuid == resolvedOptionUuid) {
      _selectedOptionUuid = _firstActiveOptionUuid();
    }

    if (_draftCorrectOptionUuid == resolvedOptionUuid) {
      _draftCorrectOptionUuid = _resolveDraftCorrectOptionUuid();
    }

    _validationMessage = null;
    notifyListeners();
  }

  void setValidationMessage(String message) {
    _validationMessage = message;
    notifyListeners();
  }

  String? validate(SeatDescriptionTrainingQuestion question) {
    if (_hasEmptyExistingOptionText(question) ||
        (_showsDraftOption && draftOptionController.text.trim().isEmpty)) {
      return AppStrings.trainingQuestionOptionsRequired;
    }

    final options = buildOptions(question);
    if (options.length < TrainingModuleController.minQuizOptionsPerQuestion) {
      return AppStrings.trainingQuestionMinOptionsRequired;
    }

    final resolvedCorrectOptionUuid = selectedCorrectOptionUuid.trim();
    if (resolvedCorrectOptionUuid.isEmpty ||
        !options.any((option) => option.uuid == resolvedCorrectOptionUuid)) {
      return AppStrings.trainingQuestionCorrectOptionRequired;
    }

    return null;
  }

  List<SeatDescriptionTrainingQuestionOption> buildOptions(
    SeatDescriptionTrainingQuestion question,
  ) {
    final originalOptionsByUuid =
        <String, SeatDescriptionTrainingQuestionOption>{
          for (final option in question.options) option.uuid: option,
        };
    final options = _activeOptionUuids
        .map((uuid) => originalOptionsByUuid[uuid])
        .whereType<SeatDescriptionTrainingQuestionOption>()
        .map(
          (option) => SeatDescriptionTrainingQuestionOption(
            uuid: option.uuid,
            text: optionControllerFor(option).text.trim(),
          ),
        )
        .toList(growable: true);
    final draftText = draftOptionController.text.trim();
    if (_showsDraftOption &&
        draftText.isNotEmpty &&
        _draftOptionUuid.isNotEmpty) {
      options.add(
        SeatDescriptionTrainingQuestionOption(
          uuid: _draftOptionUuid,
          text: draftText,
        ),
      );
    }
    return options;
  }

  void _handleExistingOptionChanged() {
    _validationMessage = null;
    notifyListeners();
  }

  void _handleDraftOptionChanged() {
    if (_isSyncingDraftText) {
      return;
    }

    _validationMessage = null;
    notifyListeners();
  }

  void _syncOptionControllers(SeatDescriptionTrainingQuestion question) {
    final retainedControllers = <String, TextEditingController>{};

    for (final option in question.options) {
      final controller =
          _optionControllers.remove(option.uuid) ??
          (TextEditingController(text: option.text)
            ..addListener(_handleExistingOptionChanged));
      if (controller.text != option.text) {
        controller.value = controller.value.copyWith(
          text: option.text,
          selection: TextSelection.collapsed(offset: option.text.length),
          composing: TextRange.empty,
        );
      }
      retainedControllers[option.uuid] = controller;
    }

    for (final controller in _optionControllers.values) {
      controller
        ..removeListener(_handleExistingOptionChanged)
        ..dispose();
    }

    _optionControllers
      ..clear()
      ..addAll(retainedControllers);
  }

  bool _hasEmptyExistingOptionText(SeatDescriptionTrainingQuestion question) {
    return visibleExistingOptions(
      question,
    ).any((option) => optionControllerFor(option).text.trim().isEmpty);
  }

  bool _hasExistingOptionTextChanges(SeatDescriptionTrainingQuestion question) {
    return visibleExistingOptions(question).any(
      (option) => optionControllerFor(option).text.trim() != option.text.trim(),
    );
  }

  bool _hasExistingOptionStructureChanges(
    SeatDescriptionTrainingQuestion question,
  ) {
    if (question.options.length != _activeOptionUuids.length) {
      return true;
    }

    for (var index = 0; index < question.options.length; index++) {
      if (question.options[index].uuid != _activeOptionUuids[index]) {
        return true;
      }
    }

    return false;
  }

  void _setDraftText(String value) {
    _isSyncingDraftText = true;
    draftOptionController.value = draftOptionController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
    _isSyncingDraftText = false;
  }

  String _resolveSelectedOptionUuid(SeatDescriptionTrainingQuestion question) {
    final currentSelectedOptionUuid = question.selectedOptionUuid?.trim() ?? '';
    final hasCurrentSelection = question.options.any(
      (option) => option.uuid == currentSelectedOptionUuid,
    );
    if (hasCurrentSelection) {
      return currentSelectedOptionUuid;
    }

    return question.options.isNotEmpty ? question.options.first.uuid : '';
  }

  String _firstActiveOptionUuid() {
    if (_activeOptionUuids.isNotEmpty) {
      return _activeOptionUuids.first;
    }

    return '';
  }

  String _resolveDraftCorrectOptionUuid() {
    final selectedOptionUuid = _selectedOptionUuid.trim();
    if (selectedOptionUuid.isNotEmpty &&
        _activeOptionUuids.contains(selectedOptionUuid)) {
      return selectedOptionUuid;
    }

    return _firstActiveOptionUuid();
  }

  String _buildQuestionSignature(SeatDescriptionTrainingQuestion question) {
    final optionsSignature = question.options
        .map((option) => '${option.uuid}:${option.text}')
        .join('|');
    return [
      question.uuid,
      question.question,
      question.selectedOptionUuid ?? '',
      question.imageUrl ?? '',
      optionsSignature,
    ].join('::');
  }

  @override
  void dispose() {
    for (final controller in _optionControllers.values) {
      controller
        ..removeListener(_handleExistingOptionChanged)
        ..dispose();
    }
    draftOptionController.removeListener(_handleDraftOptionChanged);
    draftOptionController.dispose();
    super.dispose();
  }
}

class _DraftQuizOptionTile extends StatelessWidget {
  const _DraftQuizOptionTile({
    required this.controller,
    required this.hintText,
    required this.isSelected,
    this.onSelect,
    this.onDeleteTap,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final isTextEditable = onDeleteTap != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark2.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onSelect,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? AppColors.secondaryColor
                    : AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isTextEditable,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: Colors.white,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onDeleteTap,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.fieldBorder.withValues(alpha: 0.22),
                ),
              ),
              child: const Icon(
                Icons.remove_circle_outline_rounded,
                color: AppColors.red,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCorrectOptionChoice {
  const _QuizCorrectOptionChoice({required this.uuid, required this.label});

  final String uuid;
  final String label;
}

class _QuizCorrectOptionDropdown extends StatelessWidget {
  const _QuizCorrectOptionDropdown({
    required this.value,
    required this.options,
    this.onChanged,
  });

  final String value;
  final List<_QuizCorrectOptionChoice> options;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = options.any((option) => option.uuid == value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppTextView.body3(
          AppStrings.trainingQuestionCorrectAnswerLabel,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: ValueKey<String>(value),
          initialValue: hasValue ? value : null,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: AppColors.surfaceDark,
          iconEnabledColor: AppColors.textPrimary,
          iconSize: 18,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surfaceDark2.withValues(alpha: 0.32),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.24),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.fieldBorder.withValues(alpha: 0.24),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.secondaryColor),
            ),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.uuid,
                  child: Text(
                    option.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.controller,
    required this.hintText,
    required this.isSelected,
    required this.isEditable,
    this.onTap,
    this.canDelete = false,
    this.onDeleteTap,
  });

  final TextEditingController controller;
  final String hintText;
  final bool isSelected;
  final bool isEditable;
  final VoidCallback? onTap;
  final bool canDelete;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark2.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 10, bottom: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? AppColors.secondaryColor
                    : AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isEditable,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: Colors.white,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                height: 1.45,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: onDeleteTap,
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.fieldBorder.withValues(alpha: 0.22),
                  ),
                ),
                child: Tooltip(
                  message: AppStrings.trainingDeleteOption,
                  child: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.red,
                    size: 15,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrainingReadOnlyBanner extends StatelessWidget {
  const _TrainingReadOnlyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.22),
        ),
      ),
      child: const AppTextView.body3(
        AppStrings.trainingReadOnlyAccessMessage,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    );
  }
}

class _ContentMessage extends StatelessWidget {
  const _ContentMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.fieldBorder.withValues(alpha: 0.18),
        ),
      ),
      child: AppTextView.body3(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DottedRoundedBorderPainter extends CustomPainter {
  const _DottedRoundedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + 6;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance = nextDistance + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedRoundedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
