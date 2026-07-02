import '../entities/department.dart';
import '../entities/seat_profile_detail.dart';
import '../entities/seat_profile_page.dart';
import '../repositories/seat_profile_repository.dart';

class GetSeatProfilesUseCase {
  const GetSeatProfilesUseCase(this._repository);

  final SeatProfileRepository _repository;

  Future<SeatProfilePage> call({
    required int page,
    int pageSize = 10,
    String? departmentId,
  }) {
    return _repository.getSeatProfiles(
      page: page,
      pageSize: pageSize,
      departmentId: departmentId,
    );
  }

  Future<List<Department>> getDepartments() {
    return _repository.getDepartments();
  }

  Future<SeatProfileDetail> getSeatProfileDetail(String seatId) {
    return _repository.getSeatProfileDetail(seatId);
  }
}
