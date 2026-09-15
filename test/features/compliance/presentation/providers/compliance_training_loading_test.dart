import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/compliance/domain/entities/compliance_quiz.dart';
import 'package:sparrowkaizen/features/compliance/domain/entities/compliance_quiz_result.dart';
import 'package:sparrowkaizen/features/compliance/domain/entities/compliance_track_item_detail.dart';
import 'package:sparrowkaizen/features/compliance/domain/entities/learning_module_detail_track.dart';
import 'package:sparrowkaizen/features/compliance/domain/repositories/compliance_repository.dart';
import 'package:sparrowkaizen/features/compliance/domain/usecases/get_compliance_quiz_result_usecase.dart';
import 'package:sparrowkaizen/features/compliance/domain/usecases/get_compliance_quiz_usecase.dart';
import 'package:sparrowkaizen/features/compliance/domain/usecases/get_compliance_track_item_detail_usecase.dart';
import 'package:sparrowkaizen/features/compliance/domain/usecases/get_compliance_tracks_usecase.dart';
import 'package:sparrowkaizen/features/compliance/domain/usecases/pause_compliance_quiz_usecase.dart';
import 'package:sparrowkaizen/features/compliance/domain/usecases/start_compliance_quiz_usecase.dart';
import 'package:sparrowkaizen/features/compliance/domain/usecases/submit_compliance_quiz_usecase.dart';
import 'package:sparrowkaizen/features/compliance/presentation/providers/compliance_quiz_controller.dart';
import 'package:sparrowkaizen/features/compliance/presentation/providers/compliance_training_controller.dart';

void main() {
  test('starts video detail and track requests together', () async {
    final repository = _Repository();
    final tracks = Completer<List<LearningTrackModuleDetail>>();
    final detail = Completer<ComplianceTrackItemDetail>();
    repository.loadTracks = () => tracks.future;
    repository.loadDetail = (_) => detail.future;
    final controller = _trainingController(repository);
    addTearDown(controller.dispose);

    final loading = controller.initialize(trackAssignmentUuid: 'assignment', itemUuid: 'second');
    expect(repository.requests, containsAll(['tracks', 'detail:second']));
    expect(controller.isLoading, isTrue);

    detail.complete(_detail('second'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.isLoading, isTrue);
    tracks.complete(_tracks);

    expect(await loading, isTrue);
    expect(controller.isLoading, isFalse);
    expect(controller.detail?.videoUrl, 'https://example.com/video.mp4');
    expect(controller.currentTrack?.trainingModuleItemId, 'second');
    expect(controller.currentModuleNumber, 2);
    expect(controller.moduleCount, 2);
    expect(repository.requests, isNot(contains('quiz')));
  });

  test('video stays ready while quiz questions and results are pending', () async {
    final repository = _Repository();
    final quiz = Completer<ComplianceQuiz>();
    final result = Completer<ComplianceQuizResult>();
    repository.loadQuiz = () => quiz.future;
    repository.loadResult = () => result.future;
    final trainingController = _trainingController(repository);
    final quizController = _quizController(repository);
    addTearDown(trainingController.dispose);
    addTearDown(quizController.dispose);

    await trainingController.initialize(trackAssignmentUuid: 'assignment', itemUuid: 'first');
    final preparation = quizController.prepareQuiz(
      trackAssignmentUuid: 'assignment',
      trainingModuleUuid: 'module-first',
    );
    expect(trainingController.isLoading, isFalse);
    expect(trainingController.detail?.videoUrl, isNotNull);
    expect(quizController.isPreparingQuiz, isTrue);

    var readyForQuiz = false;
    final waiting = quizController.waitForPreparation().then((_) => readyForQuiz = true);
    quiz.complete(_quiz);
    await Future<void>.delayed(Duration.zero);
    expect(repository.requests, contains('result'));
    expect(trainingController.isLoading, isFalse);
    expect(quizController.isPreparingQuiz, isTrue);
    expect(readyForQuiz, isFalse);

    result.complete(_result);
    await preparation;
    await waiting;
    expect(readyForQuiz, isTrue);
    expect(quizController.isPreparingQuiz, isFalse);
    expect(quizController.hasPassedQuizResult, isTrue);
  });

  test('shares an in-flight quiz preparation between callers', () async {
    final repository = _Repository();
    final quiz = Completer<ComplianceQuiz>();
    repository.loadQuiz = () => quiz.future;
    final controller = _quizController(repository);
    addTearDown(controller.dispose);

    final first = controller.prepareQuiz(
      trackAssignmentUuid: 'assignment',
      trainingModuleUuid: 'module-first',
    );
    final second = controller.prepareQuiz(
      trackAssignmentUuid: 'assignment',
      trainingModuleUuid: 'module-first',
    );
    expect(identical(first, second), isTrue);
    quiz.complete(_quiz);
    await first;
    expect(repository.requests.where((request) => request == 'quiz').length, 1);
    expect(repository.requests.where((request) => request == 'result').length, 1);
  });

  test('does not expose details for an item absent from the current track', () async {
    final repository = _Repository();
    final controller = _trainingController(repository);
    addTearDown(controller.dispose);

    expect(
      await controller.initialize(trackAssignmentUuid: 'assignment', itemUuid: 'missing'),
      isFalse,
    );
    expect(controller.detail, isNull);
    expect(controller.currentTrack, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('keeps the newest module when an older detail response finishes last', () async {
    final repository = _Repository();
    final firstDetail = Completer<ComplianceTrackItemDetail>();
    repository.loadDetail = (item) async => item == 'first' ? firstDetail.future : _detail(item);
    final controller = _trainingController(repository);
    addTearDown(controller.dispose);

    final first = controller.initialize(trackAssignmentUuid: 'assignment', itemUuid: 'first');
    expect(
      await controller.initialize(trackAssignmentUuid: 'assignment', itemUuid: 'second'),
      isTrue,
    );
    firstDetail.complete(_detail('first'));
    expect(await first, isFalse);
    expect(controller.detail?.uuid, 'second');
    expect(controller.currentModuleNumber, 2);
  });

  test('failed detail or track requests leave a finished empty state', () async {
    for (final failTracks in [false, true]) {
      final repository = _Repository();
      if (failTracks) {
        repository.loadTracks = () async => throw StateError('Track request failed');
      } else {
        repository.loadDetail = (_) async => throw StateError('Detail request failed');
      }
      final controller = _trainingController(repository);
      addTearDown(controller.dispose);

      expect(
        await controller.initialize(trackAssignmentUuid: 'assignment', itemUuid: 'first'),
        isFalse,
      );
      expect(controller.isLoading, isFalse);
      expect(controller.detail, isNull);
    }
  });

  test('ignores training responses after leaving the screen', () async {
    final repository = _Repository();
    final detail = Completer<ComplianceTrackItemDetail>();
    repository.loadDetail = (_) => detail.future;
    final controller = _trainingController(repository);
    final loading = controller.initialize(trackAssignmentUuid: 'assignment', itemUuid: 'first');
    controller.dispose();
    detail.complete(_detail('first'));
    expect(await loading, isFalse);
  });

  test('does not request quiz results after leaving during question loading', () async {
    final repository = _Repository();
    final quiz = Completer<ComplianceQuiz>();
    repository.loadQuiz = () => quiz.future;
    final controller = _quizController(repository);
    final preparation = controller.prepareQuiz(
      trackAssignmentUuid: 'assignment',
      trainingModuleUuid: 'module-first',
    );
    controller.dispose();
    quiz.complete(_quiz);
    await preparation;
    expect(repository.requests, isNot(contains('result')));
  });

  test('ignores quiz results that finish after leaving the screen', () async {
    final repository = _Repository();
    final result = Completer<ComplianceQuizResult>();
    repository.loadResult = () => result.future;
    final controller = _quizController(repository);
    final preparation = controller.prepareQuiz(
      trackAssignmentUuid: 'assignment',
      trainingModuleUuid: 'module-first',
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.requests, contains('result'));
    controller.dispose();
    result.complete(_result);
    await preparation;
  });
}

ComplianceTrainingController _trainingController(_Repository repository) {
  return ComplianceTrainingController(
    GetComplianceTrackItemDetailUseCase(repository),
    GetComplianceTracksUseCase(repository),
  );
}

ComplianceQuizController _quizController(_Repository repository) {
  return ComplianceQuizController(
    GetComplianceQuizUseCase(repository),
    GetComplianceQuizResultUseCase(repository),
    StartComplianceQuizUseCase(repository),
    PauseComplianceQuizUseCase(repository),
    SubmitComplianceQuizUseCase(repository),
  );
}

class _Repository implements ComplianceRepository {
  final requests = <String>[];
  Future<List<LearningTrackModuleDetail>> Function() loadTracks = () async => _tracks;
  Future<ComplianceTrackItemDetail> Function(String) loadDetail = (item) async => _detail(item);
  Future<ComplianceQuiz> Function() loadQuiz = () async => _quiz;
  Future<ComplianceQuizResult> Function() loadResult = () async => _result;

  @override
  Future<List<LearningTrackModuleDetail>> getComplianceTracks({
    required String trackAssignmentUuid,
  }) {
    requests.add('tracks');
    return loadTracks();
  }

  @override
  Future<ComplianceTrackItemDetail> getComplianceTrackItemDetail({
    required String trackAssignmentUuid,
    required String itemUuid,
  }) {
    requests.add('detail:$itemUuid');
    return loadDetail(itemUuid);
  }

  @override
  Future<ComplianceQuiz> getComplianceQuiz({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
  }) {
    requests.add('quiz');
    return loadQuiz();
  }

  @override
  Future<ComplianceQuizResult> getComplianceQuizResult({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
  }) {
    requests.add('result');
    return loadResult();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _tracks = [
  LearningTrackModuleDetail(trainingModuleItemId: 'first'),
  LearningTrackModuleDetail(breakPointTitle: 'Break'),
  LearningTrackModuleDetail(trainingModuleItemId: 'second'),
];

ComplianceTrackItemDetail _detail(String item) => ComplianceTrackItemDetail(
  uuid: item,
  position: 1,
  trainingModuleUuid: 'module-$item',
  title: 'Training',
  quizStatus: '',
  videoUrl: 'https://example.com/video.mp4',
  videoDuration: 10,
  videoTranscript: '[00:00] Introduction',
  videoThumbnailLink: null,
  trainingDocument: null,
  quizCompletionPercentage: 0,
);

const _quiz = ComplianceQuiz(
  timeSpent: 0,
  questions: [],
  temporaryAnswers: {},
  quizAttemptUuid: null,
);

const _result = ComplianceQuizResult(
  uuid: 'result',
  completionPercentage: 100,
  totalAttempts: 1,
  correctAnswers: 1,
  totalQuestions: 1,
  totalTimeSpent: 5,
  isPassed: true,
  questionResponses: [],
);
