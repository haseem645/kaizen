import '../repositories/audit_repository.dart';

class MarkUnfavoriteSubordinateUseCase {
  const MarkUnfavoriteSubordinateUseCase(this._repository);

  final AuditRepository _repository;

  Future<void> call({required String profileJobId}) {
    return _repository.markUnfavoriteSubordinate(profileJobId: profileJobId);
  }
}
