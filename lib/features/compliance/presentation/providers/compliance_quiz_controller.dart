import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/custom_functions.dart';
import '../../domain/entities/compliance_quiz_question.dart';
import '../../domain/entities/compliance_quiz_result.dart';
import '../../domain/usecases/get_compliance_quiz_usecase.dart';
import '../../domain/usecases/get_compliance_quiz_result_usecase.dart';
import '../../domain/usecases/pause_compliance_quiz_usecase.dart';
import '../../domain/usecases/start_compliance_quiz_usecase.dart';
import '../../domain/usecases/submit_compliance_quiz_usecase.dart';

class ComplianceQuizController extends ChangeNotifier {
  ComplianceQuizController(
    this._getComplianceQuizUseCase,
    this._getComplianceQuizResultUseCase,
    this._startComplianceQuizUseCase,
    this._pauseComplianceQuizUseCase,
    this._submitComplianceQuizUseCase,
  );

  final GetComplianceQuizUseCase _getComplianceQuizUseCase;
  final GetComplianceQuizResultUseCase _getComplianceQuizResultUseCase;
  final StartComplianceQuizUseCase _startComplianceQuizUseCase;
  final PauseComplianceQuizUseCase _pauseComplianceQuizUseCase;
  final SubmitComplianceQuizUseCase _submitComplianceQuizUseCase;

  bool _isLoading = false;
  bool _isStartingQuiz = false;
  bool _isLoadingQuizResult = false;
  bool _isPausingQuiz = false;
  bool _isSubmittingQuiz = false;
  bool _hasStartedQuiz = false;
  bool _hasPassedQuizResult = false;
  int _quizElapsedSeconds = 0;
  Timer? _quizTimer;
  ComplianceQuizResult? _quizResult;
  String? _loadedTrackAssignmentUuid;
  String? _loadedTrainingModuleUuid;
  String? _quizAttemptUuid;
  List<ComplianceQuizQuestion> _questions = const [];
  Map<String, String> _temporaryAnswers = const {};
  Map<String, String> _selectedAnswers = {};

  bool get isLoading => _isLoading;
  bool get isStartingQuiz => _isStartingQuiz;
  bool get isLoadingQuizResult => _isLoadingQuizResult;
  bool get isPausingQuiz => _isPausingQuiz;
  bool get isSubmittingQuiz => _isSubmittingQuiz;
  bool get hasStartedQuiz => _hasStartedQuiz;
  bool get hasPassedQuizResult => _hasPassedQuizResult;
  bool get canResumeQuiz => _hasStartedQuiz && _quizElapsedSeconds > 0;
  bool get hasAnsweredAllQuestions =>
      CustomFunctions.hasAnsweredAllRequiredItems(
        requiredIds: _questions.map((question) => question.uuid),
        answers: _selectedAnswers,
      );
  int get quizElapsedSeconds => _quizElapsedSeconds;
  String get quizElapsedTimeText =>
      CustomFunctions.formatHoursMinutesSeconds(_quizElapsedSeconds);

  ComplianceQuizResult? get quizResult => _quizResult;
  List<ComplianceQuizQuestion> get questions => _questions;
  Map<String, String> get selectedAnswers =>
      Map<String, String>.unmodifiable(_selectedAnswers);

  Future<void> initialize({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _loadedTrackAssignmentUuid == trackAssignmentUuid &&
        _loadedTrainingModuleUuid == trainingModuleUuid &&
        (_questions.isNotEmpty || _temporaryAnswers.isNotEmpty)) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final quiz = await _getComplianceQuizUseCase(
        trackAssignmentUuid: trackAssignmentUuid,
        trainingModuleUuid: trainingModuleUuid,
      );
      final isDifferentQuiz =
          _loadedTrackAssignmentUuid != trackAssignmentUuid ||
          _loadedTrainingModuleUuid != trainingModuleUuid;
      _loadedTrackAssignmentUuid = trackAssignmentUuid;
      _loadedTrainingModuleUuid = trainingModuleUuid;
      final fetchedQuizAttemptUuid = quiz.quizAttemptUuid?.trim();
      if (fetchedQuizAttemptUuid != null && fetchedQuizAttemptUuid.isNotEmpty) {
        _quizAttemptUuid = fetchedQuizAttemptUuid;
      } else if (!_hasStartedQuiz) {
        _quizAttemptUuid = null;
      }
      if (isDifferentQuiz) {
        _quizResult = null;
        _hasPassedQuizResult = false;
      }
      final restoredTimeSpent = quiz.timeSpent;
      if (restoredTimeSpent != null) {
        _quizElapsedSeconds = restoredTimeSpent < 0 ? 0 : restoredTimeSpent;
      } else if (isDifferentQuiz) {
        _quizElapsedSeconds = 0;
      }
      if (restoredTimeSpent != null && restoredTimeSpent > 0) {
        _hasStartedQuiz = true;
        _hasPassedQuizResult = false;
        _quizResult = null;
      } else if (isDifferentQuiz) {
        _hasStartedQuiz = false;
      }
      _questions = quiz.questions;
      _temporaryAnswers = quiz.temporaryAnswers;
      _selectedAnswers = Map<String, String>.from(quiz.temporaryAnswers);
    } catch (_) {
      _quizAttemptUuid = null;
      _questions = const [];
      _temporaryAnswers = const {};
      _selectedAnswers = {};
      _quizResult = null;
      _hasPassedQuizResult = false;
      _quizElapsedSeconds = 0;
    }

    _isLoading = false;
    notifyListeners();
  }

  String? selectedOptionUuid(String questionUuid) =>
      _selectedAnswers[questionUuid];

  void selectOption({
    required String questionUuid,
    required String optionUuid,
  }) {
    if (_selectedAnswers[questionUuid] == optionUuid) {
      return;
    }

    _selectedAnswers = Map<String, String>.from(_selectedAnswers)
      ..[questionUuid] = optionUuid;
    notifyListeners();
  }

  void startQuizTimer() {
    if (!_hasStartedQuiz || _quizTimer != null) {
      return;
    }

    _quizTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _quizElapsedSeconds += 1;
      notifyListeners();
    });
  }

  void cancelQuizTimer({bool reset = false}) {
    final hadTimer = _quizTimer != null;
    _quizTimer?.cancel();
    _quizTimer = null;

    if (reset) {
      _quizElapsedSeconds = 0;
    }

    if (hadTimer || reset) {
      notifyListeners();
    }
  }

  Future<bool> startQuiz({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
    bool clearAnswers = false,
  }) async {
    if (_isStartingQuiz) {
      return false;
    }

    _isStartingQuiz = true;
    notifyListeners();

    try {
      final quizAttemptUuid = await _startComplianceQuizUseCase(
        trackAssignmentUuid: trackAssignmentUuid,
        trainingModuleUuid: trainingModuleUuid,
      );
      final startedQuizAttemptUuid = quizAttemptUuid?.trim();
      if (startedQuizAttemptUuid == null || startedQuizAttemptUuid.isEmpty) {
        return false;
      }

      _quizAttemptUuid = startedQuizAttemptUuid;
      _hasStartedQuiz = true;
      _hasPassedQuizResult = false;
      _quizResult = null;
      if (clearAnswers) {
        _selectedAnswers = {};
        _quizElapsedSeconds = 0;
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isStartingQuiz = false;
      notifyListeners();
    }
  }

  Future<bool> pauseQuiz({required String trackAssignmentUuid}) async {
    if (_isPausingQuiz) {
      return false;
    }

    final quizAttemptUuid = _quizAttemptUuid?.trim();
    if (quizAttemptUuid == null || quizAttemptUuid.isEmpty) {
      return false;
    }

    _isPausingQuiz = true;
    notifyListeners();

    try {
      await _pauseComplianceQuizUseCase(
        trackAssignmentUuid: trackAssignmentUuid,
        quizAttemptUuid: quizAttemptUuid,
        currentAnswers: _selectedAnswers,
        timeSpent: _quizElapsedSeconds,
      );
      cancelQuizTimer(reset: true);
      _hasStartedQuiz = false;
      _quizAttemptUuid = null;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isPausingQuiz = false;
      notifyListeners();
    }
  }

  Future<bool> submitQuiz({required String trackAssignmentUuid}) async {
    if (_isSubmittingQuiz) {
      return false;
    }

    if (!hasAnsweredAllQuestions) {
      return false;
    }

    final quizAttemptUuid = _quizAttemptUuid?.trim();
    if (quizAttemptUuid == null || quizAttemptUuid.isEmpty) {
      return false;
    }

    _isSubmittingQuiz = true;
    notifyListeners();

    try {
      await _submitComplianceQuizUseCase(
        trackAssignmentUuid: trackAssignmentUuid,
        quizAttemptUuid: quizAttemptUuid,
        currentAnswers: _selectedAnswers,
        timeSpent: _quizElapsedSeconds,
      );
      cancelQuizTimer(reset: true);
      _hasStartedQuiz = false;
      _hasPassedQuizResult = false;
      _quizResult = null;
      _quizAttemptUuid = null;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmittingQuiz = false;
      notifyListeners();
    }
  }

  Future<ComplianceQuizResult?> getQuizResult({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
  }) async {
    if (_isLoadingQuizResult) {
      return null;
    }

    _isLoadingQuizResult = true;
    notifyListeners();

    try {
      final result = await _getComplianceQuizResultUseCase(
        trackAssignmentUuid: trackAssignmentUuid,
        trainingModuleUuid: trainingModuleUuid,
      );
      _quizResult = result;
      _hasPassedQuizResult = result.isPassed;
      return result;
    } catch (_) {
      return null;
    } finally {
      _isLoadingQuizResult = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    super.dispose();
  }
}
