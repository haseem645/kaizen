import '../entities/compliance_track_item_detail.dart';
import '../repositories/compliance_repository.dart';

class GetComplianceTrackItemDetailUseCase {
  const GetComplianceTrackItemDetailUseCase(this._repository);

  final ComplianceRepository _repository;

  Future<ComplianceTrackItemDetail> call({
    required String trackAssignmentUuid,
    required String itemUuid,
  }) {
    return _repository.getComplianceTrackItemDetail(
      trackAssignmentUuid: trackAssignmentUuid,
      itemUuid: itemUuid,
    );
  }
}
