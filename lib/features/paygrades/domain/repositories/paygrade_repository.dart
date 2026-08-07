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

  Future<void> generatePaygrades({
    required String actualId,
    required int numPaygrades,
  });

  Future<PaygradeEntry> createPaygrade({
    required String jobId,
    required String type,
    required String level,
    required String title,
    required String description,
    required String promotionRequirement,
    required int position,
    required bool fromSandbox,
  });

  Future<void> updatePaygrade({
    required String paygradeId,
    required String title,
    required String description,
    required String promotionRequirement,
  });

  Future<void> deletePaygrade(String paygradeId);
}
