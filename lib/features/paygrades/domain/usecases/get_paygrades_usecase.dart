import '../../../seat_profile/domain/entities/department.dart';
import '../entities/paygrade_detail.dart';
import '../entities/paygrade_page.dart';
import '../repositories/paygrade_repository.dart';

class GetPaygradesUseCase {
  const GetPaygradesUseCase(this._repository);

  final PaygradeRepository _repository;

  Future<PaygradePage> call({
    required int page,
    int pageSize = 10,
    String? departmentId,
    String title = '',
  }) {
    return _repository.getPaygrades(
      page: page,
      pageSize: pageSize,
      departmentId: departmentId,
      title: title,
    );
  }

  Future<List<Department>> getDepartments({required bool isOwner}) {
    return _repository.getDepartments(isOwner: isOwner);
  }

  Future<PaygradeDetail> getPaygradeDetail({
    required String paygradeId,
    required String type,
  }) {
    return _repository.getPaygradeDetail(paygradeId: paygradeId, type: type);
  }
}
