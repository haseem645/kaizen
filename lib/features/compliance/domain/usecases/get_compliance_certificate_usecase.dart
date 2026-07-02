import '../entities/compliance_certificate.dart';
import '../repositories/compliance_repository.dart';

class GetComplianceCertificateUseCase {
  const GetComplianceCertificateUseCase(this._repository);

  final ComplianceRepository _repository;

  Future<ComplianceCertificate> call({required String trackAssignmentUuid}) {
    return _repository.getCertificate(trackAssignmentUuid: trackAssignmentUuid);
  }
}
