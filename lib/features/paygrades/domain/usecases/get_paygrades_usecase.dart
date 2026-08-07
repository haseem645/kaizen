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

  Future<void> generatePaygrades({
    required String actualId,
    required int numPaygrades,
  }) {
    return _repository.generatePaygrades(
      actualId: actualId,
      numPaygrades: numPaygrades,
    );
  }

  Future<PaygradeEntry> createPaygrade({
    required String jobId,
    required String type,
    required String level,
    required String title,
    required String description,
    required String promotionRequirement,
    required int position,
    required bool fromSandbox,
  }) {
    return _repository.createPaygrade(
      jobId: jobId,
      type: type,
      level: level,
      title: title,
      description: description,
      promotionRequirement: promotionRequirement,
      position: position,
      fromSandbox: fromSandbox,
    );
  }

  Future<void> updatePaygrade({
    required String paygradeId,
    required String title,
    required String description,
    required String promotionRequirement,
  }) {
    return _repository.updatePaygrade(
      paygradeId: paygradeId,
      title: title,
      description: description,
      promotionRequirement: promotionRequirement,
    );
  }

  Future<void> deletePaygrade(String paygradeId) {
    return _repository.deletePaygrade(paygradeId);
  }
}
