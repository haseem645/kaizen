import '../../../seat_profile/domain/entities/department.dart';

abstract class DepartmentsRepository {
  Future<List<Department>> getDepartments();

  Future<void> updateDepartment({
    required Department department,
    required String name,
    required String colorHex,
  });
}
