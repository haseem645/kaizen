import '../entities/quarterly_audit.dart';
import '../repositories/audit_repository.dart';

class GetQuarterlyAuditUseCase {
  const GetQuarterlyAuditUseCase(this._repository);

  final AuditRepository _repository;

  Future<QuarterlyAudit> call({
    required String quarterlyAuditId,
    required String date,
  }) {
    return _repository.getQuarterlyAudit(
      quarterlyAuditId: quarterlyAuditId,
      date: date,
    );
  }
}
