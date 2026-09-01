part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

extension _EditTrainingSectionViewStateView on _EditTrainingSectionViewState {
  Widget _buildBody(TrainingModuleController controller) {
    if (controller.isLoading &&
        controller.modules.isEmpty &&
        !controller.isCreatingNewLessonDraft) {
      return Center(child: FastCircularProgressIndicator());
    }

    final showModuleSelector =
        controller.canManageTraining ||
        controller.modules.isNotEmpty ||
        controller.isCreatingNewLessonDraft;
    final contentChildren = <Widget>[
      if (showModuleSelector) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _EditModuleSelector(
            controller: controller,
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
        ),
      ],
      _buildContentCard(controller),
    ];

    if (widget.isEmbedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: contentChildren,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      physics: const BouncingScrollPhysics(),
      children: contentChildren,
    );
  }

  Widget _buildContentCard(TrainingModuleController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (controller.isCreatingNewLessonDraft) ...[
          Transform.translate(
            offset: const Offset(0, -4),
            child: _NewLessonTitleField(
              key: _newLessonTitleFieldKey,
              controller: controller.newLessonTitleController,
              focusNode: _newLessonTitleFocusNode,
              isSubmitting: controller.isCreatingModule,
              canSubmit: controller.canSubmitNewLessonTitle,
              onSubmit: () => _createModuleFromDraft(controller),
            ),
          ),
          const SizedBox(height: 10),
        ] else if (controller.hasSelectedModule &&
            controller.canEditSelectedModuleTitle) ...[
          Transform.translate(
            offset: const Offset(0, -10),
            child: _TrainingTapEditField(
              valueText: controller.selectedModuleTitle,
              hintText: AppStrings.trainingLessonTitleHint,
              onTap: controller.isSavingModuleTitle
                  ? null
                  : () => _showModuleTitleEditBottomSheet(controller),
              isLoading: controller.isSavingModuleTitle,
            ),
          ),
          const SizedBox(height: 4),
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
          const SizedBox(height: 16),
        ],
        _TrainingTabs(
          tabController: _tabController,
          areExtraTabsEnabled: controller.canAccessSelectedModuleExtras,
        ),
        const SizedBox(height: 18),
        _buildTabContent(controller),
      ],
    );
  }

  Widget _buildTabContent(TrainingModuleController controller) {
    final isBackgroundVideoUploadActive =
        widget.useNonBlockingVideoUpload &&
        TrainingVideoUploadController.instance.isUploadActiveForModule(
          descriptionId: widget.trainingDescriptionId,
          moduleId: controller.selectedModuleId,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final swipeTargetIndex = _tabSwipeTargetIndexNotifier.value;
        final swipeOffset = _tabSwipeOffsetNotifier.value;
        final currentPage = KeyedSubtree(
          key: ValueKey<int>(_selectedTabIndex),
          child: _buildTabPageForIndex(
            controller,
            tabIndex: _selectedTabIndex,
            isBackgroundVideoUploadActive: isBackgroundVideoUploadActive,
          ),
        );

        Widget swipeBody = currentPage;
        if (swipeTargetIndex != null &&
            swipeTargetIndex != _selectedTabIndex &&
            swipeOffset != 0) {
          final previewStartOffset = swipeOffset.isNegative
              ? contentWidth
              : -contentWidth;
          final swipeProgress = (swipeOffset.abs() / contentWidth).clamp(
            0.0,
            1.0,
          );
          swipeBody = ClipRect(
            child: Stack(
              alignment: Alignment.topLeft,
              children: [
                Transform.translate(
                  offset: Offset(previewStartOffset + swipeOffset, 0),
                  child: Opacity(
                    opacity: 0.78 + (swipeProgress * 0.22),
                    child: KeyedSubtree(
                      key: ValueKey<int>(swipeTargetIndex),
                      child: _buildTabPageForIndex(
                        controller,
                        tabIndex: swipeTargetIndex,
                        isBackgroundVideoUploadActive:
                            isBackgroundVideoUploadActive,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(swipeOffset, 0),
                  child: currentPage,
                ),
              ],
            ),
          );
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handleTabContentPointerDown,
          onPointerMove: (event) =>
              _handleTabContentPointerMove(event, controller, contentWidth),
          onPointerUp: (_) =>
              unawaited(_handleTabContentPointerUp(controller, contentWidth)),
          onPointerCancel: (_) => unawaited(
            _handleTabContentPointerCancel(controller, contentWidth),
          ),
          child: swipeBody,
        );
      },
    );
  }

  Widget _buildTabPageForIndex(
    TrainingModuleController controller, {
    required int tabIndex,
    required bool isBackgroundVideoUploadActive,
  }) {
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
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(child: FastCircularProgressIndicator()),
      );
    }

    if (controller.errorMessage != null &&
        controller.selectedModuleDetail == null) {
      return _ContentMessage(message: controller.errorMessage!);
    }

    if (tabIndex == 0) {
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

    if (tabIndex == 1) {
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

    if (tabIndex == 2) {
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

    if (tabIndex == 3) {
      return _AssignmentTabContent(
        isLoading: controller.isAssignmentLoading,
        hasResolvedAssignment: controller.hasResolvedSelectedModuleAssignment,
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
}
