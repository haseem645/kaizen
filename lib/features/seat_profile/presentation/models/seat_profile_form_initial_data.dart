import '../../domain/entities/department.dart';
import '../../domain/entities/seat_profile_detail.dart';

class SeatProfileFormInitialData {
  const SeatProfileFormInitialData({
    required this.seatId,
    this.actualId,
    required this.name,
    this.department,
    this.paygradeUnit,
    this.initialCategory,
  });

  final String seatId;
  final String? actualId;
  final String name;
  final Department? department;
  final String? paygradeUnit;
  final SeatProfileCategory? initialCategory;

  bool get isValid => seatId.trim().isNotEmpty;

  String get updateTargetId {
    final resolvedActualId = actualId?.trim() ?? '';
    if (resolvedActualId.isNotEmpty) {
      return resolvedActualId;
    }

    return seatId.trim();
  }
}
