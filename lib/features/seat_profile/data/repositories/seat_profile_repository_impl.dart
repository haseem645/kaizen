import '../../domain/entities/department.dart';
import '../../domain/entities/seat_profile_detail.dart';
import '../../domain/entities/seat_profile_page.dart';
import '../../domain/repositories/seat_profile_repository.dart';
import '../datasources/seat_profile_remote_data_source.dart';

class SeatProfileRepositoryImpl implements SeatProfileRepository {
  const SeatProfileRepositoryImpl(this._remoteDataSource);

  final SeatProfileRemoteDataSource _remoteDataSource;

  @override
  Future<SeatProfilePage> getSeatProfiles({
    required int page,
    int pageSize = 10,
    String? departmentId,
  }) {
    return _remoteDataSource.getSeatProfiles(
      page: page,
      pageSize: pageSize,
      departmentId: departmentId,
    );
  }

  @override
  Future<SeatProfileDetail> getSeatProfileDetail(String seatId) {
    return _remoteDataSource.getSeatProfileDetail(seatId);
  }

  @override
  Future<List<Department>> getDepartments() {
    return _remoteDataSource.getDepartments();
  }

  @override
  Future<List<SeatProfileDetail>> seatProfileCategoryTrainings() {
    return _remoteDataSource.getSeatProfileCategoryTrainings();
  }
}
