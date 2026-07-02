import 'seat_profile.dart';

class SeatProfilePage {
  const SeatProfilePage({required this.items, required this.hasNextPage});

  final List<SeatProfile> items;
  final bool hasNextPage;
}
