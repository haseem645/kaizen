import '../entities/compliance_quiz_result.dart';
import '../repositories/compliance_repository.dart';

class GetComplianceQuizResultUseCase {
  const GetComplianceQuizResultUseCase(this._repository);

  final ComplianceRepository _repository;

  Future<ComplianceQuizResult> call({
    required String trackAssignmentUuid,
    required String trainingModuleUuid,
  }) {
    return _repository.getComplianceQuizResult(
      trackAssignmentUuid: trackAssignmentUuid,
      trainingModuleUuid: trainingModuleUuid,
    );
  }
}
