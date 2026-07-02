import '../repositories/compliance_repository.dart';

class StartComplianceQuizUseCase {
  const StartComplianceQuizUseCase(this._repository);

  final ComplianceRepository _repository;

  Future<String?> call({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
  }) {
    return _repository.startComplianceQuiz(
      trackAssignmentUuid: trackAssignmentUuid,
      trainingModuleUuid: trainingModuleUuid,
    );
  }
}
