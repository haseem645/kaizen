import '../entities/learning_module_detail_track.dart';
import '../repositories/compliance_repository.dart';

class GetComplianceTracksUseCase {
  const GetComplianceTracksUseCase(this._repository);

  final ComplianceRepository _repository;

  Future<List<LearningTrackModuleDetail>> call({required String trackAssignmentUuid}) {
    return _repository.getComplianceTracks(trackAssignmentUuid: trackAssignmentUuid);
  }
}
