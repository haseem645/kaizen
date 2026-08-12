import '../../../seat_profile/domain/entities/department.dart';
import '../../domain/entities/paygrade_detail.dart';
import '../../domain/entities/paygrade_page.dart';
import '../../domain/repositories/paygrade_repository.dart';
import '../datasources/paygrade_remote_data_source.dart';

class PaygradeRepositoryImpl implements PaygradeRepository {
  const PaygradeRepositoryImpl(this._remoteDataSource);

  final PaygradeRemoteDataSource _remoteDataSource;

  @override
  Future<PaygradePage> getPaygrades({
    required int page,
    int pageSize = 10,
    String? departmentId,
    String name = '',
  }) {
    return _remoteDataSource.getPaygrades(
      page: page,
      pageSize: pageSize,
      departmentId: departmentId,
      name: name,
    );
  }

  @override
  Future<List<Department>> getDepartments({required bool isOwner}) {
    return _remoteDataSource.getDepartmentsByAccess(isOwner: isOwner);
  }

  @override
  Future<PaygradeDetail> getPaygradeDetail({
    required String paygradeId,
    required String type,
  }) {
    return _remoteDataSource.getPaygradeDetail(
      paygradeId: paygradeId,
      type: type,
    );
  }

  @override
  Future<void> generatePaygrades({
    required String actualId,
    required int numPaygrades,
  }) {
    return _remoteDataSource.generatePaygrades(
      actualId: actualId,
      numPaygrades: numPaygrades,
    );
  }

  @override
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
    return _remoteDataSource.createPaygrade(
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

  @override
  Future<void> updatePaygrade({
    required String paygradeId,
    required String title,
    required String description,
    required String promotionRequirement,
  }) {
    return _remoteDataSource.updatePaygrade(
      paygradeId: paygradeId,
      title: title,
      description: description,
      promotionRequirement: promotionRequirement,
    );
  }

  @override
  Future<void> deletePaygrade(String paygradeId) {
    return _remoteDataSource.deletePaygrade(paygradeId);
  }
}
