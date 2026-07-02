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
    String title = '',
  }) {
    return _remoteDataSource.getPaygrades(
      page: page,
      pageSize: pageSize,
      departmentId: departmentId,
      title: title,
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
}
