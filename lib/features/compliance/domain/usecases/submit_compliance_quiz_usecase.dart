import '../repositories/compliance_repository.dart';

class SubmitComplianceQuizUseCase {
  const SubmitComplianceQuizUseCase(this._repository);

  final ComplianceRepository _repository;

  Future<void> call({
    required String trackAssignmentUuid,
    required String quizAttemptUuid,
    required Map<String, String> currentAnswers,
    required int timeSpent,
  }) {
    return _repository.submitComplianceQuiz(
      trackAssignmentUuid: trackAssignmentUuid,
      quizAttemptUuid: quizAttemptUuid,
      currentAnswers: currentAnswers,
      timeSpent: timeSpent,
    );
  }
}
