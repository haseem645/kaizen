import '../../../seat_profile/domain/entities/department.dart';
import '../repositories/departments_repository.dart';

class ManageDepartmentsUseCase {
  const ManageDepartmentsUseCase(this._repository);

  final DepartmentsRepository _repository;

  Future<List<Department>> getDepartments() {
    return _repository.getDepartments();
  }

  Future<void> updateDepartment({
    required Department department,
    required String name,
    required String colorHex,
  }) {
    return _repository.updateDepartment(
      department: department,
      name: name,
      colorHex: colorHex,
    );
  }
}
