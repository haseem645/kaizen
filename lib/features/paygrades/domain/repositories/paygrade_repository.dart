import '../../../seat_profile/domain/entities/department.dart';
import '../entities/paygrade_detail.dart';
import '../entities/paygrade_page.dart';

abstract class PaygradeRepository {
  Future<PaygradePage> getPaygrades({
    required int page,
    int pageSize = 10,
    String? departmentId,
    String title = '',
  });

  Future<List<Department>> getDepartments({required bool isOwner});
  Future<PaygradeDetail> getPaygradeDetail({
    required String paygradeId,
    required String type,
  });
}
