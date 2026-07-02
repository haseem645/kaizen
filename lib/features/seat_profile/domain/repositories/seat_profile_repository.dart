import '../entities/department.dart';
import '../entities/seat_profile_detail.dart';
import '../entities/seat_profile_page.dart';

abstract class SeatProfileRepository {
  Future<SeatProfilePage> getSeatProfiles({
    required int page,
    int pageSize = 10,
    String? departmentId,
  });
  Future<SeatProfileDetail> getSeatProfileDetail(String seatId);
  Future<List<Department>> getDepartments();
}
