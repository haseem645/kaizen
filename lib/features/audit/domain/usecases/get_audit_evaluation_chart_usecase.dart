import '../entities/audit_evaluation_chart.dart';
import '../repositories/audit_repository.dart';

class GetAuditEvaluationChartUseCase {
  const GetAuditEvaluationChartUseCase(this._repository);

  final AuditRepository _repository;

  Future<List<AuditEvaluationChart>> call({required String profileJobId}) {
    return _repository.getAuditEvaluationChart(profileJobId: profileJobId);
  }
}
