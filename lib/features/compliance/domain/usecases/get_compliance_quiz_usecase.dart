import '../entities/compliance_quiz.dart';
import '../repositories/compliance_repository.dart';

class GetComplianceQuizUseCase {
  const GetComplianceQuizUseCase(this._repository);

  final ComplianceRepository _repository;

  Future<ComplianceQuiz> call({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
  }) {
    return _repository.getComplianceQuiz(
      trackAssignmentUuid: trackAssignmentUuid,
      trainingModuleUuid: trainingModuleUuid,
    );
  }
}
