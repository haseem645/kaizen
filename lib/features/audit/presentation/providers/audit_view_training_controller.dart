import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/services/file_uploader.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../domain/entities/seat_description_training.dart';
import '../../domain/repositories/audit_repository.dart';

enum QuizGenerationDifficulty {
  easy('easy'),
  medium('medium'),
  hard('hard');

  const QuizGenerationDifficulty(this.apiValue);

  final String apiValue;
}

class AuditViewTrainingController extends ChangeNotifier {
  AuditViewTrainingController(
    this._auditRepository, {
    FileUploader? fileUploader,
  }) : _fileUploader = fileUploader ?? const FileUploader() {
    newLessonTitleController.addListener(_handleNewLessonTitleChanged);
  }

  static const int minQuizQuestionCount = 1;
  static const int maxQuizQuestionCount = 10;
  static const int minQuizOptionsPerQuestion = 2;
  static const int maxQuizOptionsPerQuestion = 4;
  static const int maxTrainingVideoTitleLength = 128;
  static final Random _uuidRandom = Random.secure();

  final AuditRepository _auditRepository;
  final FileUploader _fileUploader;
  final TextEditingController newLessonTitleController =
      TextEditingController();

  bool _isLoading = false;
  bool _isDocumentLoading = false;
  bool _isQuestionsLoading = false;
  bool _isCreatingNewLessonDraft = false;
  bool _isCreatingModule = false;
  bool _isUploadingVideo = false;
  String? _errorMessage;
  String? _documentErrorMessage;
  String? _questionsErrorMessage;
  List<SeatDescriptionTrainingModule> _modules =
      const <SeatDescriptionTrainingModule>[];
  SeatDescriptionTrainingModuleDetail? _selectedModuleDetail;
  SeatDescriptionTrainingDocument? _selectedModuleDocument;
  List<SeatDescriptionTrainingQuestion> _selectedModuleQuestions =
      const <SeatDescriptionTrainingQuestion>[];
  String _selectedModuleId = '';
  bool _hasResolvedQuestions = false;
  int _quizGenerationQuestionCount = 3;
  int _quizGenerationOptionsPerQuestion = 4;
  QuizGenerationDifficulty _quizGenerationDifficulty =
      QuizGenerationDifficulty.medium;
  bool _replaceExistingQuestions = true;
  bool _isGeneratingQuiz = false;
  bool _isGeneratingSop = false;
  String? _deletingQuestionOptionKey;
  String? _deletingModuleId;
  String _jobId = '';
  String _descriptionId = '';

  bool get isLoading => _isLoading;
  bool get isDocumentLoading => _isDocumentLoading;
  bool get isQuestionsLoading => _isQuestionsLoading;
  bool get isCreatingNewLessonDraft => _isCreatingNewLessonDraft;
  bool get isCreatingModule => _isCreatingModule;
  bool get isUploadingVideo => _isUploadingVideo;
  String? get errorMessage => _errorMessage;
  String? get documentErrorMessage => _documentErrorMessage;
  String? get questionsErrorMessage => _questionsErrorMessage;
  List<SeatDescriptionTrainingModule> get modules => _modules;
  String get selectedModuleId => _selectedModuleId;
  bool get hasSelectedModule => _selectedModuleId.trim().isNotEmpty;
  SeatDescriptionTrainingModuleDetail? get selectedModuleDetail =>
      _selectedModuleDetail;
  SeatDescriptionTrainingDocument? get selectedModuleDocument =>
      _selectedModuleDocument;
  List<SeatDescriptionTrainingQuestion> get selectedModuleQuestions =>
      _selectedModuleQuestions;
  int get quizGenerationQuestionCount => _quizGenerationQuestionCount;
  int get quizGenerationOptionsPerQuestion => _quizGenerationOptionsPerQuestion;
  QuizGenerationDifficulty get quizGenerationDifficulty =>
      _quizGenerationDifficulty;
  bool get replaceExistingQuestions => _replaceExistingQuestions;
  bool get isGeneratingQuiz => _isGeneratingQuiz;
  bool get isGeneratingSop => _isGeneratingSop;
  String? get deletingQuestionOptionKey => _deletingQuestionOptionKey;
  String? get deletingModuleId => _deletingModuleId;
  bool get canSubmitNewLessonTitle =>
      !_isCreatingModule && newLessonTitleController.text.trim().isNotEmpty;
  bool get canAccessSelectedModuleExtras =>
      !_isCreatingNewLessonDraft && hasSelectedModule;
  bool get canUploadSelectedModuleVideo =>
      !_isCreatingNewLessonDraft &&
      hasSelectedModule &&
      !_isUploadingVideo &&
      !_isLoading;
  bool get hasSelectedModuleDocumentText {
    final text = _selectedModuleDocument?.text?.trim();
    return text != null && text.isNotEmpty;
  }

  bool isDeletingModule(String moduleId) =>
      _deletingModuleId == moduleId.trim();

  String get selectedModuleTitle {
    if (_isCreatingNewLessonDraft) {
      return newLessonTitleController.text.trim();
    }

    final detailTitle = _selectedModuleDetail?.title.trim();
    if (detailTitle != null && detailTitle.isNotEmpty) {
      return detailTitle;
    }

    for (final module in _modules) {
      if (module.uuid == _selectedModuleId) {
        return module.title;
      }
    }

    return '';
  }

  Future<void> initialize({
    required String jobId,
    required String descriptionId,
  }) async {
    final resolvedJobId = jobId.trim();
    final resolvedDescriptionId = descriptionId.trim();
    if (resolvedDescriptionId.isEmpty) {
      _errorMessage = AppStrings.loginSomethingWentWrong;
      notifyListeners();
      return;
    }

    _jobId = resolvedJobId;
    _descriptionId = resolvedDescriptionId;
    _isLoading = true;
    _errorMessage = null;
    _documentErrorMessage = null;
    _questionsErrorMessage = null;
    _isCreatingNewLessonDraft = false;
    _isCreatingModule = false;
    _isUploadingVideo = false;
    _modules = const <SeatDescriptionTrainingModule>[];
    _selectedModuleId = '';
    _selectedModuleDetail = null;
    _selectedModuleDocument = null;
    _selectedModuleQuestions = const <SeatDescriptionTrainingQuestion>[];
    _hasResolvedQuestions = false;
    newLessonTitleController.clear();
    notifyListeners();

    try {
      final modules = await _auditRepository.getSeatDescriptionTrainingModules(
        descriptionId: resolvedDescriptionId,
      );
      _modules = modules;

      if (modules.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _selectedModuleId = modules.first.uuid;
      notifyListeners();
      await _loadSelectedModuleDetail();
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectModule(String moduleId) async {
    final resolvedModuleId = moduleId.trim();
    if (resolvedModuleId.isEmpty) {
      return;
    }

    if (_selectedModuleId == resolvedModuleId &&
        _selectedModuleDetail != null &&
        _errorMessage == null) {
      return;
    }

    _isCreatingNewLessonDraft = false;
    _selectedModuleId = resolvedModuleId;
    _selectedModuleDetail = null;
    _selectedModuleDocument = null;
    _selectedModuleQuestions = const <SeatDescriptionTrainingQuestion>[];
    _documentErrorMessage = null;
    _questionsErrorMessage = null;
    _hasResolvedQuestions = false;
    await _loadSelectedModuleDetail();
  }

  void startCreatingNewLessonDraft() {
    if (_isCreatingModule) {
      return;
    }

    _isCreatingNewLessonDraft = true;
    _errorMessage = null;
    _documentErrorMessage = null;
    _questionsErrorMessage = null;
    _selectedModuleId = '';
    _selectedModuleDetail = null;
    _selectedModuleDocument = null;
    _selectedModuleQuestions = const <SeatDescriptionTrainingQuestion>[];
    _hasResolvedQuestions = false;
    newLessonTitleController.clear();
    notifyListeners();
  }

  Future<bool> createModuleFromDraft() async {
    final resolvedTitle = newLessonTitleController.text.trim();
    if (_isCreatingModule ||
        resolvedTitle.isEmpty ||
        _jobId.isEmpty ||
        _descriptionId.isEmpty) {
      return false;
    }

    _isCreatingModule = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final createdModule = await _auditRepository
          .createSeatDescriptionTrainingModule(
            jobId: _jobId,
            descriptionId: _descriptionId,
            title: resolvedTitle,
          );

      _modules = List<SeatDescriptionTrainingModule>.from(
        _modules,
        growable: true,
      )..add(createdModule);
      _isCreatingNewLessonDraft = false;
      _selectedModuleId = createdModule.uuid;
      _selectedModuleDetail = _buildModuleDetailFromModule(createdModule);
      _selectedModuleDocument = null;
      _selectedModuleQuestions = const <SeatDescriptionTrainingQuestion>[];
      _documentErrorMessage = null;
      _questionsErrorMessage = null;
      _hasResolvedQuestions = false;
      newLessonTitleController.clear();
      notifyListeners();
      unawaited(_loadSelectedModuleDetail());
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isCreatingModule = false;
      notifyListeners();
    }
  }

  Future<void> loadDocumentForSelectedModule() async {
    if (_selectedModuleDocument != null) {
      return;
    }

    try {
      await refreshDocumentForSelectedModule();
    } catch (_) {
      // Error state is already stored for the UI by refreshDocumentForSelectedModule.
    }
  }

  Future<void> refreshDocumentForSelectedModule() async {
    if (_selectedModuleId.isEmpty || _isDocumentLoading) {
      return;
    }

    _isDocumentLoading = true;
    _documentErrorMessage = null;
    notifyListeners();

    try {
      _selectedModuleDocument = await _auditRepository
          .getSeatDescriptionTrainingModuleDocument(
            moduleId: _selectedModuleId,
          );
    } catch (error) {
      _selectedModuleDocument = null;
      _documentErrorMessage = error.toString();
      rethrow;
    } finally {
      _isDocumentLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuestionsForSelectedModule() async {
    if (_selectedModuleId.isEmpty ||
        _isQuestionsLoading ||
        _hasResolvedQuestions) {
      return;
    }

    try {
      await refreshQuestionsForSelectedModule();
    } catch (_) {
      // Error state is already stored for the UI by refreshQuestionsForSelectedModule.
    }
  }

  Future<void> refreshQuestionsForSelectedModule() async {
    if (_selectedModuleId.isEmpty || _isQuestionsLoading) {
      return;
    }

    _isQuestionsLoading = true;
    _questionsErrorMessage = null;
    notifyListeners();

    try {
      final questions = await _auditRepository
          .getSeatDescriptionTrainingModuleQuestions(
            moduleId: _selectedModuleId,
          );
      _updateSelectedModuleQuestions(questions);
    } catch (error) {
      _selectedModuleQuestions = const <SeatDescriptionTrainingQuestion>[];
      _questionsErrorMessage = error.toString();
      _hasResolvedQuestions = false;
      rethrow;
    } finally {
      _isQuestionsLoading = false;
      notifyListeners();
    }
  }

  void resetQuizGenerationForm() {
    _quizGenerationQuestionCount = 3;
    _quizGenerationOptionsPerQuestion = 4;
    _quizGenerationDifficulty = QuizGenerationDifficulty.medium;
    _replaceExistingQuestions = true;
    _questionsErrorMessage = null;
    notifyListeners();
  }

  void incrementQuizQuestionCount() {
    if (_quizGenerationQuestionCount >= maxQuizQuestionCount) {
      return;
    }

    _quizGenerationQuestionCount += 1;
    notifyListeners();
  }

  void decrementQuizQuestionCount() {
    if (_quizGenerationQuestionCount <= minQuizQuestionCount) {
      return;
    }

    _quizGenerationQuestionCount -= 1;
    notifyListeners();
  }

  void incrementQuizOptionsPerQuestion() {
    if (_quizGenerationOptionsPerQuestion >= maxQuizOptionsPerQuestion) {
      return;
    }

    _quizGenerationOptionsPerQuestion += 1;
    notifyListeners();
  }

  void decrementQuizOptionsPerQuestion() {
    if (_quizGenerationOptionsPerQuestion <= minQuizOptionsPerQuestion) {
      return;
    }

    _quizGenerationOptionsPerQuestion -= 1;
    notifyListeners();
  }

  void setQuizGenerationDifficulty(QuizGenerationDifficulty difficulty) {
    if (_quizGenerationDifficulty == difficulty) {
      return;
    }

    _quizGenerationDifficulty = difficulty;
    notifyListeners();
  }

  void setReplaceExistingQuestions(bool value) {
    if (_replaceExistingQuestions == value) {
      return;
    }

    _replaceExistingQuestions = value;
    notifyListeners();
  }

  Future<bool> generateQuizForSelectedModule() async {
    if (_selectedModuleId.isEmpty || _isGeneratingQuiz) {
      return false;
    }

    _isGeneratingQuiz = true;
    _questionsErrorMessage = null;
    notifyListeners();

    try {
      await _auditRepository.generateSeatDescriptionTrainingModuleQuiz(
        moduleId: _selectedModuleId,
        numQuestions: _quizGenerationQuestionCount,
        optionsPerQuestion: _quizGenerationOptionsPerQuestion,
        difficultyLevel: _quizGenerationDifficulty.apiValue,
        replaceExistingQuestions: _replaceExistingQuestions,
      );
      await refreshQuestionsForSelectedModule();
      return true;
    } catch (error) {
      _questionsErrorMessage = error.toString();
      return false;
    } finally {
      _isGeneratingQuiz = false;
      notifyListeners();
    }
  }

  Future<bool> generateSopForSelectedModule() async {
    if (_selectedModuleId.isEmpty || _isGeneratingSop) {
      return false;
    }

    _isGeneratingSop = true;
    _documentErrorMessage = null;
    notifyListeners();

    try {
      await _auditRepository.generateSeatDescriptionTrainingModuleSop(
        moduleId: _selectedModuleId,
      );
      await refreshDocumentForSelectedModule();
      return true;
    } catch (error) {
      _documentErrorMessage = error.toString();
      return false;
    } finally {
      _isGeneratingSop = false;
      notifyListeners();
    }
  }

  Future<bool> uploadVideoForSelectedModule(File videoFile) async {
    final resolvedModuleId = _selectedModuleId.trim();
    if (!canUploadSelectedModuleVideo || resolvedModuleId.isEmpty) {
      return false;
    }

    _isUploadingVideo = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fileName = CustomFunctions.fileNameFromPath(videoFile.path);
      final presignedUpload = await _fileUploader.generatePresignedUpload(
        key: 'lms',
        fileName: fileName,
      );
      final normalizedUploadUrl = presignedUpload.uploadUrl.trim();

      await _fileUploader.uploadBinaryFile(
        uploadUrl: normalizedUploadUrl,
        fileBytes: await videoFile.readAsBytes(),
        contentType: CustomFunctions.contentTypeFromPath(videoFile.path),
      );

      final videoUrl =
          presignedUpload.fileUrl?.trim() ??
          _fileUploader.publicUrlFromUploadUrl(normalizedUploadUrl);

      final videoDurationInSeconds = await _resolveVideoDurationInSeconds(
        videoFile,
      );
      final videoTitle = _buildTrainingVideoTitle(fileName);
      final uploadedVideo = await _auditRepository
          .addSeatDescriptionTrainingModuleVideo(
            moduleId: resolvedModuleId,
            videoUuid: _generateClientUuid(),
            title: videoTitle,
            videoUrl: videoUrl,
            duration: videoDurationInSeconds,
          );
      _applySelectedModuleVideo(uploadedVideo);
      try {
        final generatedDescription = await _auditRepository
            .generateSeatDescriptionTrainingModuleSummary(
              moduleId: resolvedModuleId,
            );
        _applySelectedModuleDescription(generatedDescription);
      } catch (error) {
        debugPrint('Unable to generate training summary: $error');
      }
      return true;
    } catch (error) {
      _errorMessage = _resolveVideoUploadErrorMessage(error);
      return false;
    } finally {
      _isUploadingVideo = false;
      notifyListeners();
    }
  }

  Future<bool> deleteModule(String moduleId) async {
    final resolvedModuleId = moduleId.trim();
    if (resolvedModuleId.isEmpty || _descriptionId.isEmpty) {
      return false;
    }

    if (_deletingModuleId == resolvedModuleId) {
      return false;
    }

    final currentSelectedModuleId = _selectedModuleId.trim();
    _deletingModuleId = resolvedModuleId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auditRepository.deleteSeatDescriptionTrainingModule(
        moduleId: resolvedModuleId,
      );

      final refreshedModules = await _auditRepository
          .getSeatDescriptionTrainingModules(descriptionId: _descriptionId);
      _modules = refreshedModules;

      if (refreshedModules.isEmpty) {
        _selectedModuleId = '';
        _selectedModuleDetail = null;
        _selectedModuleDocument = null;
        _selectedModuleQuestions = const <SeatDescriptionTrainingQuestion>[];
        _documentErrorMessage = null;
        _questionsErrorMessage = null;
        _hasResolvedQuestions = false;
        notifyListeners();
        return true;
      }

      final canKeepCurrentSelection =
          currentSelectedModuleId.isNotEmpty &&
          currentSelectedModuleId != resolvedModuleId &&
          refreshedModules.any(
            (module) => module.uuid == currentSelectedModuleId,
          );

      if (canKeepCurrentSelection) {
        _selectedModuleId = currentSelectedModuleId;
        _syncSelectedModuleSummaryFromDetail();
        notifyListeners();
        return true;
      }

      _selectedModuleId = refreshedModules.first.uuid;
      _selectedModuleDetail = null;
      _selectedModuleDocument = null;
      _selectedModuleQuestions = const <SeatDescriptionTrainingQuestion>[];
      _documentErrorMessage = null;
      _questionsErrorMessage = null;
      _hasResolvedQuestions = false;
      await _loadSelectedModuleDetail();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _deletingModuleId = null;
      notifyListeners();
    }
  }

  Future<bool> deleteQuestionOption({
    required String questionId,
    required String optionId,
  }) async {
    final resolvedQuestionId = questionId.trim();
    final resolvedOptionId = optionId.trim();
    if (resolvedQuestionId.isEmpty || resolvedOptionId.isEmpty) {
      return false;
    }

    final targetQuestion = _findQuestionById(resolvedQuestionId);
    if (targetQuestion == null) {
      return false;
    }

    final deleteKey = '$resolvedQuestionId::$resolvedOptionId';
    if (_deletingQuestionOptionKey == deleteKey) {
      return false;
    }

    final remainingOptions = targetQuestion.options
        .where((option) => option.uuid != resolvedOptionId)
        .toList(growable: false);
    final currentCorrectOptionUuid = targetQuestion.selectedOptionUuid?.trim();
    final hasCurrentCorrectOption = remainingOptions.any(
      (option) => option.uuid == currentCorrectOptionUuid,
    );
    final resolvedCorrectOptionUuid = hasCurrentCorrectOption
        ? currentCorrectOptionUuid
        : null;

    _deletingQuestionOptionKey = deleteKey;
    _questionsErrorMessage = null;
    notifyListeners();

    try {
      final updatedQuestion = await _auditRepository
          .updateSeatDescriptionTrainingQuestion(
            questionId: resolvedQuestionId,
            questionText: targetQuestion.question,
            options: remainingOptions,
            correctOptionUuid: resolvedCorrectOptionUuid,
          );
      _replaceSelectedQuestion(updatedQuestion);
      return true;
    } catch (error) {
      _questionsErrorMessage = error.toString();
      return false;
    } finally {
      _deletingQuestionOptionKey = null;
      notifyListeners();
    }
  }

  Future<void> _loadSelectedModuleDetail() async {
    if (_selectedModuleId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedModuleDetail = await _auditRepository
          .getSeatDescriptionTrainingModuleDetail(moduleId: _selectedModuleId);
      _updateSelectedModuleQuestions(
        _selectedModuleDetail?.questions ??
            const <SeatDescriptionTrainingQuestion>[],
      );
      _syncSelectedModuleSummaryFromDetail();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _updateSelectedModuleQuestions(
    List<SeatDescriptionTrainingQuestion> questions,
  ) {
    _selectedModuleQuestions = List<SeatDescriptionTrainingQuestion>.from(
      questions,
      growable: false,
    );
    _hasResolvedQuestions = _selectedModuleQuestions.isNotEmpty;

    final detail = _selectedModuleDetail;
    if (detail == null) {
      return;
    }

    _selectedModuleDetail = SeatDescriptionTrainingModuleDetail(
      uuid: detail.uuid,
      title: detail.title,
      thumbnails: List<String>.from(detail.thumbnails, growable: false),
      description: detail.description,
      questions: _selectedModuleQuestions,
      thumbnailLink: detail.thumbnailLink,
      trainingVideo: detail.trainingVideo,
      isPubliclyAvailable: detail.isPubliclyAvailable,
      learningTrackCount: detail.learningTrackCount,
    );
  }

  void _replaceSelectedQuestion(
    SeatDescriptionTrainingQuestion updatedQuestion,
  ) {
    final updatedQuestions = _selectedModuleQuestions
        .map(
          (question) => question.uuid == updatedQuestion.uuid
              ? updatedQuestion
              : question,
        )
        .toList(growable: false);
    _updateSelectedModuleQuestions(updatedQuestions);
  }

  SeatDescriptionTrainingQuestion? _findQuestionById(String questionId) {
    for (final question in _selectedModuleQuestions) {
      if (question.uuid == questionId) {
        return question;
      }
    }

    return null;
  }

  SeatDescriptionTrainingModuleDetail _buildModuleDetailFromModule(
    SeatDescriptionTrainingModule module,
  ) {
    return SeatDescriptionTrainingModuleDetail(
      uuid: module.uuid,
      title: module.title,
      thumbnails: const <String>[],
      description: null,
      questions: const <SeatDescriptionTrainingQuestion>[],
      thumbnailLink: module.thumbnailLink,
      trainingVideo: null,
      isPubliclyAvailable: false,
      learningTrackCount: 0,
    );
  }

  void _syncSelectedModuleSummaryFromDetail() {
    final detail = _selectedModuleDetail;
    if (detail == null) {
      return;
    }

    final updatedModule = SeatDescriptionTrainingModule(
      uuid: detail.uuid,
      title: detail.title,
      thumbnailLink: detail.previewThumbnailLink,
    );
    _modules = _modules
        .map(
          (module) =>
              module.uuid == updatedModule.uuid ? updatedModule : module,
        )
        .toList(growable: false);
  }

  void _applySelectedModuleDescription(String? description) {
    final detail = _selectedModuleDetail;
    if (detail == null) {
      return;
    }

    _selectedModuleDetail = SeatDescriptionTrainingModuleDetail(
      uuid: detail.uuid,
      title: detail.title,
      thumbnails: List<String>.from(detail.thumbnails, growable: false),
      description: description?.trim(),
      questions: List<SeatDescriptionTrainingQuestion>.from(
        detail.questions,
        growable: false,
      ),
      thumbnailLink: detail.thumbnailLink,
      trainingVideo: detail.trainingVideo,
      isPubliclyAvailable: detail.isPubliclyAvailable,
      learningTrackCount: detail.learningTrackCount,
    );
    notifyListeners();
  }

  void _applySelectedModuleVideo(SeatDescriptionTrainingVideo video) {
    final detail = _selectedModuleDetail;
    if (detail == null) {
      return;
    }

    _selectedModuleDetail = SeatDescriptionTrainingModuleDetail(
      uuid: detail.uuid,
      title: detail.title,
      thumbnails: List<String>.from(detail.thumbnails, growable: false),
      description: detail.description,
      questions: List<SeatDescriptionTrainingQuestion>.from(
        detail.questions,
        growable: false,
      ),
      thumbnailLink: detail.thumbnailLink,
      trainingVideo: video,
      isPubliclyAvailable: detail.isPubliclyAvailable,
      learningTrackCount: detail.learningTrackCount,
    );
    notifyListeners();
  }

  Future<int> _resolveVideoDurationInSeconds(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);
    try {
      await controller.initialize();
      final seconds = controller.value.duration.inSeconds;
      return seconds < 0 ? 0 : seconds;
    } catch (error) {
      debugPrint('Unable to resolve training video duration: $error');
      return 0;
    } finally {
      await controller.dispose();
    }
  }

  String _buildTrainingVideoTitle(String fileName) {
    final trimmedName = fileName.trim();
    if (trimmedName.length <= maxTrainingVideoTitleLength) {
      return trimmedName;
    }

    final extensionIndex = trimmedName.lastIndexOf('.');
    if (extensionIndex <= 0 || extensionIndex >= trimmedName.length - 1) {
      return trimmedName.substring(0, maxTrainingVideoTitleLength);
    }

    final extension = trimmedName.substring(extensionIndex);
    final availableBaseLength = maxTrainingVideoTitleLength - extension.length;
    if (availableBaseLength <= 0) {
      return trimmedName.substring(0, maxTrainingVideoTitleLength);
    }

    final baseName = trimmedName.substring(0, extensionIndex);
    final resolvedBaseLength = availableBaseLength.clamp(0, baseName.length);
    final truncatedBaseName = baseName.substring(0, resolvedBaseLength);
    return '$truncatedBaseName$extension';
  }

  String _resolveVideoUploadErrorMessage(Object error) {
    if (error is ApiError) {
      return error.toString();
    }

    if (error is SocketException ||
        error is HttpException ||
        error is http.ClientException) {
      return AppStrings.trainingVideoUploadFailed;
    }

    return error.toString();
  }

  String _generateClientUuid() {
    final bytes = List<int>.generate(
      16,
      (_) => _uuidRandom.nextInt(256),
      growable: false,
    );
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  void _handleNewLessonTitleChanged() {
    if (_isCreatingNewLessonDraft) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    newLessonTitleController.removeListener(_handleNewLessonTitleChanged);
    newLessonTitleController.dispose();
    super.dispose();
  }
}
