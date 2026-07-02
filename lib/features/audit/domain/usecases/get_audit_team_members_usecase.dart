import '../entities/audit_main_list.dart';
import '../repositories/audit_repository.dart';

class GetAuditTeamMembersUseCase {
  const GetAuditTeamMembersUseCase(this._repository);

  final AuditRepository _repository;

  Future<AuditMainList> call({int page = 1, int pageSize = 10}) {
    return _repository.getAuditTeamMembers(page: page, pageSize: pageSize);
  }
}
