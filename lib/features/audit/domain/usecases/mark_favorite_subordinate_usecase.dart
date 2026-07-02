import '../repositories/audit_repository.dart';

class MarkFavoriteSubordinateUseCase {
  const MarkFavoriteSubordinateUseCase(this._repository);

  final AuditRepository _repository;

  Future<void> call({required String profileJobId}) {
    return _repository.markFavoriteSubordinate(profileJobId: profileJobId);
  }
}
