import '../../../seat_profile/domain/entities/department.dart';
import '../../domain/repositories/departments_repository.dart';
import '../datasources/departments_remote_data_source.dart';

class DepartmentsRepositoryImpl implements DepartmentsRepository {
  DepartmentsRepositoryImpl(this._remoteDataSource);

  final DepartmentsRemoteDataSource _remoteDataSource;

  @override
  Future<List<Department>> getDepartments() {
    return _remoteDataSource.getDepartments();
  }

  @override
  Future<void> updateDepartment({
    required Department department,
    required String name,
    required String colorHex,
  }) {
    return _remoteDataSource.updateDepartment(
      department: department,
      name: name,
      colorHex: colorHex,
    );
  }
}
