part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

extension _EditTrainingSectionViewStateHandlers
    on _EditTrainingSectionViewState {
  void _handleTabChanged() {
    if (_tabController.indexIsChanging ||
        _selectedTabIndex == _tabController.index) {
      return;
    }

    _selectedTabIndexNotifier.value = _tabController.index;
    if (_tabSwipeTargetIndexNotifier.value == _tabController.index &&
        _tabSwipeOffsetNotifier.value != 0) {
      _tabSwipeOffsetNotifier.value = 0;
      _tabSwipeTargetIndexNotifier.value = null;
    }

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

  int _maxAccessibleTabIndex(TrainingModuleController controller) {
    return controller.canAccessSelectedModuleExtras ? 3 : 0;
  }

  void _stopTabSwipeResetAnimation() {
    if (_tabSwipeResetController.isAnimating) {
      _tabSwipeResetController.stop();
    }
    _tabSwipeResetAnimation = null;
  }

  Future<void> _animateTabSwipeOffsetTo(
    double targetOffset, {
    Duration duration = const Duration(milliseconds: 180),
  }) async {
    final begin = _tabSwipeOffsetNotifier.value;
    if ((begin - targetOffset).abs() < 0.5) {
      _tabSwipeOffsetNotifier.value = targetOffset;
      return;
    }

    _stopTabSwipeResetAnimation();
    _tabSwipeResetController.duration = duration;
    _tabSwipeResetAnimation = Tween<double>(begin: begin, end: targetOffset)
        .animate(
          CurvedAnimation(
            parent: _tabSwipeResetController,
            curve: Curves.easeOutCubic,
          ),
        );
    _tabSwipeResetController.reset();
    await _tabSwipeResetController.forward().orCancel;
    _tabSwipeResetAnimation = null;
  }

  void _resetTabSwipeTracking() {
    _tabSwipePointerId = null;
    _tabSwipeStartPosition = null;
    _isTrackingTabSwipe = false;
  }

  void _handleTabContentPointerDown(PointerDownEvent event) {
    _tabSwipePointerId = event.pointer;
    _tabSwipeStartPosition = event.position;
    _isTrackingTabSwipe = false;
    _stopTabSwipeResetAnimation();
  }

  void _handleTabContentPointerMove(
    PointerMoveEvent event,
    TrainingModuleController controller,
    double contentWidth,
  ) {
    if (_tabSwipePointerId != event.pointer || contentWidth <= 0) {
      return;
    }

    final startPosition = _tabSwipeStartPosition;
    if (startPosition == null) {
      return;
    }

    final totalDelta = event.position - startPosition;
    final horizontalDistance = totalDelta.dx.abs();
    final verticalDistance = totalDelta.dy.abs();

    if (!_isTrackingTabSwipe) {
      if (horizontalDistance < 10) {
        return;
      }

      if (horizontalDistance <= verticalDistance * 1.1) {
        return;
      }

      _isTrackingTabSwipe = true;
    }

    _updateTabSwipeOffset(
      rawOffset: totalDelta.dx,
      controller: controller,
      contentWidth: contentWidth,
    );
  }

  void _updateTabSwipeOffset({
    required double rawOffset,
    required TrainingModuleController controller,
    required double contentWidth,
  }) {
    if (contentWidth <= 0) {
      return;
    }

    final maxTabIndex = _maxAccessibleTabIndex(controller);
    if (maxTabIndex == 0) {
      return;
    }

    if (rawOffset == 0) {
      _tabSwipeOffsetNotifier.value = 0;
      _tabSwipeTargetIndexNotifier.value = null;
      return;
    }

    final candidateIndex = rawOffset.isNegative
        ? _selectedTabIndex + 1
        : _selectedTabIndex - 1;
    final hasValidTarget = candidateIndex >= 0 && candidateIndex <= maxTabIndex;
    final clampedOffset = rawOffset.clamp(
      -contentWidth * 0.94,
      contentWidth * 0.94,
    );

    _tabSwipeTargetIndexNotifier.value = hasValidTarget ? candidateIndex : null;
    _tabSwipeOffsetNotifier.value = hasValidTarget
        ? clampedOffset
        : clampedOffset * 0.18;
  }

  Future<void> _handleTabContentPointerUp(
    TrainingModuleController controller,
    double contentWidth,
  ) async {
    _resetTabSwipeTracking();
    if (contentWidth <= 0) {
      return;
    }

    final currentOffset = _tabSwipeOffsetNotifier.value;
    if (currentOffset == 0) {
      _tabSwipeTargetIndexNotifier.value = null;
      return;
    }

    final targetIndex = _tabSwipeTargetIndexNotifier.value;
    final shouldAdvance =
        targetIndex != null && currentOffset.abs() > contentWidth * 0.22;

    if (!shouldAdvance) {
      await _animateTabSwipeOffsetTo(0);
      _tabSwipeTargetIndexNotifier.value = null;
      return;
    }

    final exitOffset = currentOffset.isNegative ? -contentWidth : contentWidth;
    await _animateTabSwipeOffsetTo(
      exitOffset,
      duration: const Duration(milliseconds: 120),
    );
    if (!mounted) {
      return;
    }

    _tabController.animateTo(targetIndex);
  }

  Future<void> _handleTabContentPointerCancel(
    TrainingModuleController controller,
    double contentWidth,
  ) async {
    _resetTabSwipeTracking();
    if (_tabSwipeOffsetNotifier.value == 0) {
      _tabSwipeTargetIndexNotifier.value = null;
      return;
    }

    await _animateTabSwipeOffsetTo(0);
    _tabSwipeTargetIndexNotifier.value = null;
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
        currentDocumentError != _lastDocumentErrorMessage &&
        !_isTrainingModalSheetOpen) {
      _showApiErrorSnackBar(currentDocumentError);
    }

    if (currentQuestionsError != null &&
        currentQuestionsError != _lastQuestionsErrorMessage &&
        !_isTrainingModalSheetOpen) {
      _showApiErrorSnackBar(currentQuestionsError);
    }

    if (currentAssignmentError != null &&
        currentAssignmentError != _lastAssignmentErrorMessage &&
        !_isTrainingModalSheetOpen) {
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
}
